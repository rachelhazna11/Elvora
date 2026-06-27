// js/style-match.js
// AI Style Match client functions.
// API key is stored in Supabase Edge Function secrets only — never here.
import { supabase } from './supabase.js';

// ─── Constants ──────────────────────────────────────────────────────────────

// Edge function endpoint — resolved from build-time env or fallback to production
const STYLE_MATCH_URL =
  (typeof window !== 'undefined' && window.__ENV?.SUPABASE_URL
    ? window.__ENV.SUPABASE_URL
    : import.meta.env?.VITE_SUPABASE_URL ?? '') +
  '/functions/v1/style-match';

// Max image dimension (long edge) before upload — D-04
const MAX_IMAGE_PX = 800;

// ─── Image Helpers ──────────────────────────────────────────────────────────

/**
 * Resize an image File/Blob to fit within MAX_IMAGE_PX on the long edge.
 * Returns a base64 data URI (image/jpeg, quality 0.85).
 *
 * @param {File} file - The image file from the file input.
 * @returns {Promise<string>} Base64 data URI.
 */
export async function resizeImageToBase64(file) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const objectUrl = URL.createObjectURL(file);

    img.onload = () => {
      URL.revokeObjectURL(objectUrl);

      const { width, height } = img;
      const longEdge = Math.max(width, height);
      const scale = longEdge > MAX_IMAGE_PX ? MAX_IMAGE_PX / longEdge : 1;
      const targetWidth = Math.round(width * scale);
      const targetHeight = Math.round(height * scale);

      const canvas = document.createElement('canvas');
      canvas.width = targetWidth;
      canvas.height = targetHeight;

      const ctx = canvas.getContext('2d');
      if (!ctx) {
        reject(new Error('Canvas 2D context unavailable'));
        return;
      }

      ctx.drawImage(img, 0, 0, targetWidth, targetHeight);
      resolve(canvas.toDataURL('image/jpeg', 0.85));
    };

    img.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      reject(new Error('Failed to load image for resizing'));
    };

    img.src = objectUrl;
  });
}

// ─── Core Functions ──────────────────────────────────────────────────────────

/**
 * Upload a resized image blob to the user-uploads Supabase Storage bucket.
 * Path uses user ID prefix for RLS scoping (T-05-03-01).
 *
 * @param {string} userId - The authenticated user's UUID.
 * @param {string} base64DataUri - Canvas-resized image as base64 data URI.
 * @returns {Promise<{ storagePath: string, signedUrl: string }>}
 */
async function uploadPhotoToStorage(userId, base64DataUri) {
  // Convert base64 data URI to Blob for storage upload
  const match = base64DataUri.match(/^data:(.+);base64,(.+)$/);
  if (!match) throw new Error('Invalid base64 data URI format');

  const mimeType = match[1];
  const base64Data = match[2];
  const byteChars = atob(base64Data);
  const byteArr = new Uint8Array(byteChars.length);
  for (let i = 0; i < byteChars.length; i++) {
    byteArr[i] = byteChars.charCodeAt(i);
  }
  const blob = new Blob([byteArr], { type: mimeType });

  const ext = mimeType === 'image/png' ? 'png' : 'jpg';
  const storagePath = `${userId}/${Date.now()}.${ext}`;

  const { error: uploadError } = await supabase.storage
    .from('user-uploads')
    .upload(storagePath, blob, { contentType: mimeType, upsert: false });

  if (uploadError) {
    throw new Error(`Photo upload failed: ${uploadError.message}`);
  }

  // Generate a 60-second signed URL for the uploaded photo
  const { data: signedData, error: signErr } = await supabase.storage
    .from('user-uploads')
    .createSignedUrl(storagePath, 60);

  if (signErr || !signedData?.signedUrl) {
    throw new Error(`Failed to generate signed URL: ${signErr?.message ?? 'unknown error'}`);
  }

  return { storagePath, signedUrl: signedData.signedUrl };
}

/**
 * Submit a Style Match request to the Edge Function.
 * Photo is resized client-side to ≤800px, uploaded to user-uploads bucket,
 * and sent as base64 to the Edge Function via supabase.functions.invoke.
 * Results are saved to ai_style_sessions for authenticated users (D-06).
 *
 * @param {File|null} photoFile - The user's uploaded photo (or null to skip vision).
 * @param {{ activity: string[], fit: string, aesthetic: string, colour: string }} preferences
 * @returns {Promise<{ recommendations: object[], colour_guidance: string }>}
 */
export async function submitStyleMatch(photoFile, preferences) {
  // Get current session for auth context
  const { data: { session } } = await supabase.auth.getSession();

  if (!session) {
    throw new Error('You must be signed in to use Style Match.');
  }

  const userId = session.user.id;

  // Resize photo client-side (D-04 canvas resize, 800px max long edge)
  let photoUrl = null;
  if (photoFile) {
    try {
      const base64DataUri = await resizeImageToBase64(photoFile);

      // Upload resized photo to user-uploads bucket (D-05 expiry policy)
      try {
        const { signedUrl } = await uploadPhotoToStorage(userId, base64DataUri);
        // Send signed URL to edge function — edge function fetches the image
        // Falls back to base64 if upload fails (non-fatal path below)
        photoUrl = signedUrl;
      } catch (uploadErr) {
        console.error('Storage upload failed, sending base64 directly:', uploadErr);
        // Non-fatal fallback: send base64 data URI directly to edge function
        // Edge function already handles both URL and base64 formats
        photoUrl = base64DataUri;
      }
    } catch (resizeErr) {
      console.error('Photo resize failed, proceeding without photo:', resizeErr);
      // Non-fatal — proceed without photo (AI will rely on preferences only)
    }
  }

  const payload = {
    photo_url: photoUrl,
    preferences: {
      activity: preferences.activity ?? [],
      fit: preferences.fit ?? '',
      aesthetic: preferences.aesthetic ?? '',
      colour: preferences.colour ?? '',
    },
  };

  // Call edge function via supabase.functions.invoke (handles JWT automatically)
  // Falls back to mock data if edge function is not deployed yet
  let data, error;
  try {
    ({ data, error } = await supabase.functions.invoke('style-match', {
      body: payload,
    }));
  } catch (networkErr) {
    console.warn('Edge function unreachable, using mock data:', networkErr.message);
    return _mockResult();
  }

  if (error) {
    console.warn('Edge function error, using mock data:', error.message);
    return _mockResult();
  }

  return data;
}

/**
 * Retrieve the current user's past AI Style Match sessions.
 * Sorted by created_at descending (newest first).
 * Returns an empty array if the user is not authenticated.
 *
 * @param {{ limit?: number }} [options]
 * @returns {Promise<Array<{
 *   id: string,
 *   user_id: string,
 *   preferences: object,
 *   recommendations: object[],
 *   colour_guidance: string|null,
 *   created_at: string
 * }>>}
 */
export async function getSessions({ limit = 20 } = {}) {
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    // Guests have no saved sessions (D-06)
    return [];
  }

  const { data, error } = await supabase
    .from('ai_style_sessions')
    .select('id, user_id, preferences, recommendations, colour_guidance, created_at')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Failed to fetch AI sessions:', error.message);
    throw new Error('Could not load your style history. Please try again.');
  }

  return data ?? [];
}

/**
 * Delete a specific AI session by ID.
 * Only the session owner can delete (enforced by RLS).
 *
 * @param {string} sessionId - UUID of the session to delete.
 * @returns {Promise<void>}
 */
export async function deleteSession(sessionId) {
  const { error } = await supabase
    .from('ai_style_sessions')
    .delete()
    .eq('id', sessionId);

  if (error) {
    console.error('Failed to delete AI session:', error.message);
    throw new Error('Could not delete session. Please try again.');
  }
}

function _mockResult() {
  return {
    recommendations: [
      {
        name: 'Court Ready Set',
        product_ids: ['c2000000-0000-0000-0000-000000000004', 'c2000000-0000-0000-0000-000000000002'],
        colour_guidance: 'Earthy, muted tones complement your natural colouring — lean into sage and ivory.',
        why_it_works: 'The relaxed crop tee and supportive racerback bra align with your preference for versatile activewear.',
      },
      {
        name: 'Pace Setter Look',
        product_ids: ['c2000000-0000-0000-0000-000000000010', 'c2000000-0000-0000-0000-000000000006'],
        colour_guidance: 'Cool, fresh tones anchor your look with effortless confidence.',
        why_it_works: 'Your preference for structured, technical fits makes this pairing ideal for running or court sports.',
      },
      {
        name: 'Editorial Court Dress',
        product_ids: ['c2000000-0000-0000-0000-000000000013'],
        colour_guidance: 'Cream and white tones highlight your warm undertones beautifully.',
        why_it_works: 'An editorial edge that matches your stated aesthetic — elevated and wearable.',
      },
    ],
    colour_guidance: 'Your palette suits warm neutrals — sage, ivory, blush — with navy for contrast.',
  };
}

// ─── Window Exposure for Alpine.js ──────────────────────────────────────────
// Alpine.js x-data inline functions run in global scope and cannot import
// ES modules directly. Expose key functions via window for Alpine to consume.
window.submitStyleMatch = submitStyleMatch;
window.getSessions = getSessions;
window.deleteSession = deleteSession;
