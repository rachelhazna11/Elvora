# Phase 5: AI Style Match - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

The core differentiator and technical "wow" factor of Elvora. This phase delivers:
- **Gemini Vision Integration:** A fully functional Supabase Edge Function (`style-match`) that calls Gemini 1.5 Flash to analyze a user's photo and preferences.
- **Smart Catalog Mapping:** The AI maps appearance and preferences to a curated context of Elvora's 22 hero products.
- **Client-Side Image Pipeline:** `js/style-match.js` handles image resizing (max 800px), Supabase Storage upload (24h TTL), and the Edge Function API bridge.
- **Dynamic Recommendation UI:** `style-match.html` transitions from its current mock state to a live, data-driven experience with "Stylist's Notes" explaining the reasoning.
- **Session Persistence:** Authenticated users have their analysis sessions saved to the `ai_style_sessions` table for later viewing in their account dashboard.

**Phase 5 does NOT include:** Virtual try-on (generative imagery), real-time stock checks, or guest session persistence in the database (guest history is ephemeral/local only).

</domain>

<decisions>
## Implementation Decisions

### AI Brain (Gemini 1.5 Flash)

- **D-01: Model Choice:** Use `gemini-1.5-flash` for all style match requests. Prioritize response speed and cost-efficiency over the deeper reasoning of Pro, as the task (matching clothes to photos) is well within Flash's capabilities.
- **D-02: Catalog Context:** Do not send the full variant list (220+ items). Send a structured JSON block of the **22 hero products** containing: `id`, `name`, `category`, `description`, `price`, `primary_color`, and `aesthetic_tags` (minimal/sporty/editorial).
- **D-03: Stylist Reasoning:** The AI must return a "Why this works" field for each outfit, referencing specific visual attributes from the user's photo (e.g., "The sage green complements your hazel eyes").

### Image Handling & Privacy

- **D-04: Resizing:** `js/style-match.js` must use a canvas-based resize to ensure the uploaded image is no larger than 800px on the long edge. This reduces latency and token costs.
- **D-05: Expiry Policy:** User photos are stored in the `user-uploads` bucket with a logical 24-hour expiry. A GitHub Action or Edge Function cron (if available) will clean these up, but for MVP, the UI will treat them as ephemeral.
- **D-06: Guest vs. User Auth:** Only authenticated users (`Alpine.store('auth').loggedIn`) will have their sessions saved to the Supabase `ai_style_sessions` table. Guests see their results once; if they navigate away without signing up, the session is lost.

### Edge Function Contract

- **D-07: Endpoint Protection:** The `style-match` function verifies the user's JWT. It rejects requests without a valid session (T-05-01).
- **D-08: Prompt Strategy:** The system prompt will enforce a strict JSON response format to prevent parsing errors. If the AI cannot find a good match, it must return a fallback recommendation of "Bestsellers" rather than an error.
- **D-09: CORS:** Origin is locked to `https://elvora.netlify.app` per D-15.

</decisions>

<canonical_refs>
## Canonical References

### Requirements (Phase 5 scope)
- `.planning/REQUIREMENTS.md` §F-030 — Style Match Landing Page
- `.planning/REQUIREMENTS.md` §F-031 — Photo Upload (resizing, private bucket, 60s signed URLs)
- `.planning/REQUIREMENTS.md` §F-032 — Style Preference Input Form (Activity, Fit, Aesthetic, Colour)
- `.planning/REQUIREMENTS.md` §F-033 — AI Outfit Combination Recommendations (Gemini Vision via Edge Function)
- `.planning/REQUIREMENTS.md` §F-034 — Complementary Colour Guidance
- `.planning/REQUIREMENTS.md` §F-035 — Style Match Session Persistence (authenticated users)
- `.planning/REQUIREMENTS.md` §F-049 — AI Proxy Edge Function (Secrets, JWT, CORS)

### Design & Research
- `.planning/phases/05-ai-style-match/05-RESEARCH.md` — Gemini payload and response schema.
- `.planning/phases/05-ai-style-match/05-UI-SPEC.md` — Loading states and result card layouts.
- `style-match.html` — The current UI shell (Alpine.js state structure).

### Technical Standards
- `.planning/research/PITFALLS.md` §Pitfall 10 — "AI Vision API Calls Are Slow or Expensive" (Explains the 800px resize and catalog scoping mandate).

</canonical_refs>

<code_context>
## Existing Code Insights

### Integration Points
- `js/style-match.js` ← Planner must populate stubs for `submitStyleMatch` and `getSessions`.
- `supabase/functions/style-match/index.ts` ← Currently a mock stub; needs Gemini API integration.
- `style-match.html` ← `findMatch()` method currently uses a `setTimeout` mock; needs to call `submitStyleMatch`.
- `ai_style_sessions` table ← Needs to be created via migration if not already in schema.

</code_context>

<specifics>
## Specific Ideas

- **The Stylist Prompt**: "You are Elvy, the premium personal stylist for ELVORA activewear. Your goal is to make the user feel confident and understood. Use a sophisticated yet encouraging tone. Reference their photo directly ('Based on your cool skin tone...', 'Since you have an athletic build...')."
- **Result Cards**: Each recommendation from the AI should map to a `product_id`. The frontend will then use these IDs to fetch the full product objects (images, prices) from the `products` table for rendering.
- **Loading Messages**: "Analyzing your coloring...", "Curating your wardrobe...", "Drafting your stylist's notes...".

</specifics>

<deferred>
## Deferred Ideas

- **Image Generation**: Explicitly out of scope (PROJECT.md). No DALL-E/Midjourney.
- **Virtual Try-On**: Deferred to v2.
- **Social Sharing**: Deferred to v2.
- **Guest Session Database Persistence**: To keep Phase 5 lean, guest history is not saved in Supabase.

</deferred>

---

*Phase: 5-AI Style Match*
*Context gathered: 2026-06-15*
