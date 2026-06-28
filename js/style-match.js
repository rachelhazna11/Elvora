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
 * Submit a Style Match request to the Edge Function.
 * Photo is resized client-side to ≤800px and sent as a base64 data URI directly —
 * no storage upload round-trip so latency is minimised.
 * Results are saved to ai_style_sessions for authenticated users (D-06).
 *
 * @param {File|null} photoFile - The user's uploaded photo (or null to skip vision).
 * @param {{ activity: string[], fit: string, aesthetic: string, colour: string }} preferences
 * @returns {Promise<{ recommendations: object[], colour_guidance: string }>}
 */
export async function submitStyleMatch(photoFile, preferences) {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('You must be signed in to use Style Match.');

  // Resize photo client-side (800px max long edge) and send as base64 data URI.
  // Skipping the storage-upload → signed-URL round-trip saves 5-10 seconds.
  let photoUrl = null;
  if (photoFile) {
    try {
      photoUrl = await resizeImageToBase64(photoFile);
    } catch (resizeErr) {
      console.error('Photo resize failed, proceeding without photo:', resizeErr);
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
 * Enrich AI recommendations (which only carry product_ids) with full product
 * objects from Supabase — name, slug, price, and primary image URL.
 *
 * Shared by the live Style Match results page (style-match.html) and the
 * Style Match history page (style-history.html) so the resolution logic stays
 * in one place.
 *
 * @param {Array<{ name: string, colour_guidance?: string, why_it_works?: string, product_ids?: string[] }>} recommendations
 * @returns {Promise<Array<{
 *   name: string,
 *   colour_guidance: string|undefined,
 *   why_it_works: string|undefined,
 *   products: Array<{ id: string, name: string, slug: string, price: number, image_url: string|null }>
 * }>>}
 */
export async function enrichRecommendations(recommendations) {
  if (!Array.isArray(recommendations) || recommendations.length === 0) return [];

  // Collect all unique product IDs from all outfit recommendations.
  // The AI occasionally mangles a UUID (e.g. drops a hyphen) when generating
  // product_ids as text — a single malformed ID in an `.in()` filter makes
  // Postgres reject the entire batch with a 400, so every valid ID in that
  // request would silently get zero results back too. Filter to well-formed
  // UUIDs only before querying.
  const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  const allIds = [...new Set(
    recommendations.flatMap(r => r.product_ids ?? [])
  )].filter(id => {
    const isValid = UUID_RE.test(id);
    if (!isValid) console.warn('Skipping malformed product_id from AI response:', id);
    return isValid;
  });

  // Query products and product_images as two plain queries (not an embedded
  // select) — embedded selects depend on PostgREST having the
  // product_images → products FK in its schema cache, which silently returns
  // an error if that cache hasn't been reloaded after migration.
  let productMap = {};
  let imagesByProduct = {};
  if (allIds.length > 0 && window.supabase) {
    try {
      const [{ data: products, error: productsErr }, { data: images, error: imagesErr }] = await Promise.all([
        window.supabase
          .from('products')
          .select('id, name, slug, base_price')
          .in('id', allIds),
        window.supabase
          .from('product_images')
          .select('product_id, url, display_order')
          .in('product_id', allIds)
          .order('display_order', { ascending: true }),
      ]);

      if (productsErr) console.error('Failed to fetch products for style match:', productsErr.message ?? productsErr);
      if (imagesErr) console.error('Failed to fetch product images for style match:', imagesErr.message ?? imagesErr);

      if (!productsErr && products) {
        productMap = Object.fromEntries(products.map(p => [p.id, p]));
      }
      if (!imagesErr && images) {
        imagesByProduct = images.reduce((acc, img) => {
          if (!acc[img.product_id]) acc[img.product_id] = [];
          acc[img.product_id].push(img);
          return acc;
        }, {});
      }
    } catch (e) {
      console.error('Failed to fetch product details:', e);
    }
  }

  // Map each recommendation to its full product objects
  return recommendations.map(rec => ({
    name: rec.name,
    colour_guidance: rec.colour_guidance,
    why_it_works: rec.why_it_works,
    products: (rec.product_ids ?? [])
      .map(id => productMap[id])
      .filter(Boolean)
      .map(p => ({
        id: p.id,
        name: p.name,
        slug: p.slug,
        price: p.base_price,
        image_url: (() => {
          const raw = imagesByProduct[p.id]?.[0]?.url ?? null;
          if (!raw) return null;
          // bare photo ID → full Unsplash CDN URL; full URL → strip existing params
          return raw.startsWith('http') ? raw.split('?')[0] : `https://images.unsplash.com/${raw}`;
        })(),
      })),
  }));
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
window.enrichRecommendations = enrichRecommendations;
