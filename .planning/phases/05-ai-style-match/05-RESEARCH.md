# Phase 05: AI Style Match — Research

**Status:** Researching Gemini Vision integration and Style Match UX
**Date:** 2026-06-15

## 1. Gemini Vision Integration

### 1.1 Endpoint & Authentication
- **Endpoint**: Proxied via Supabase Edge Function `style-match` (stub already exists).
- **API**: Google Gemini Pro Vision (or latest vision-capable model).
- **Authentication**: `GEMINI_API_KEY` stored in Supabase Edge Function secrets.

### 1.2 Request Payload (Edge Function to Gemini)
- **Model**: `gemini-1.5-flash` or `gemini-1.5-pro`.
- **Content**:
  - System instructions (Style Guide).
  - User photo (base64 or signed URL).
  - User preferences (Activity, Fit, Aesthetic, Colour).
  - Catalog context (structured list of Elvora products).

### 1.3 Response Schema (Gemini to Edge Function)
The response must be structured JSON to allow client-side rendering of product cards.
```json
{
  "recommendations": [
    {
      "name": "The Court Master",
      "product_ids": ["uuid-1", "uuid-2", "uuid-3"],
      "colour_guidance": "Soft ivory tones highlight your natural warmth..."
    }
  ]
}
```

## 2. Client-Side Image Handling

### 2.1 Resizing
- Use `HTMLCanvasElement` or a lightweight library (e.g., `browser-image-compression`) to resize to max 800px on the long edge before upload.
- Format: `image/jpeg` with 0.8 quality.

### 2.2 Storage
- Upload to `user-uploads` bucket.
- User-scoped path: `{uid}/{timestamp}_{filename}`.
- RLS: User can only upload/read their own folder.

## 3. UI/UX Flow

1. **Discovery**: Nav link or Homepage CTA → `style-match.html`.
2. **Landing**: "Find Your Style" editorial hero explaining the 3-step flow.
3. **Form**:
   - Photo upload area (drag & drop + file picker).
   - Preference chips (multi-select activity, single-select fit/aesthetic/colour).
   - "Find My Match" submit button.
4. **Loading**: Progress messages ("Analysing your style...", "Exploring the catalog...").
5. **Results**:
   - Visual outfit cards (2–3 outfits).
   - Why this works (Colour guidance).
   - Save to Profile button (for logged-in users).

## 4. Database Schema for Sessions

- `ai_style_sessions` table (F-035):
  - `id` (uuid)
  - `user_id` (uuid, nullable for guests)
  - `preferences` (jsonb)
  - `recommendations` (jsonb)
  - `colour_guidance` (text)
  - `created_at` (timestamp)

## 5. Next Actions
- [ ] Implement `05-UI-SPEC.md`.
- [ ] Update `style-match/index.ts` with Gemini API logic.
- [ ] Create `style-match.html` layout.
- [ ] Wire client-side upload and API call.
