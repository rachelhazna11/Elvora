# AI Usage Documentation — ELVORA

**Project:** Elvora — Premium Women's Activewear E-Commerce Platform  
**Assessment:** University Portfolio Project  
**Last Updated:** 2026-06-16

---

## 1. Overview

This document describes how artificial intelligence (AI) tools were used in the development and operation of the Elvora platform. It covers two distinct areas:

1. **AI in Development** — AI assistants used to accelerate the creation of this codebase.
2. **AI in the Product** — The AI Style Match feature built into Elvora for end users.

---

## 2. AI Tools Used in Development

### 2.1 Claude (Anthropic) — Primary Development Assistant

**Model:** Claude Sonnet 4.6 (claude-sonnet-4-6)  
**Role:** Primary coding assistant throughout all phases of development.

**Tasks performed with Claude:**
- Writing and reviewing HTML/CSS (Tailwind v4) for all pages (home, catalog, product detail, cart, account, style match, lookbook).
- Implementing Alpine.js reactive components: shopping cart with localStorage persistence, wishlist toggle with Supabase sync, auth state management, Style Match 2-step form.
- Writing Supabase SQL migrations (001 through 005) — schema creation, RLS policies, seed data (22 products, 220 variants, 32 reviews, 5 testimonials).
- Building Supabase Edge Functions in Deno/TypeScript: the `style-match` function that proxies Gemini Vision API calls.
- Writing JavaScript ES modules: `supabase.js`, `cart.js`, `style-match.js`, `products.js`, `auth.js`, `components.js`.
- Writing `vercel.json` configuration and Vercel build pipeline setup.
- Debugging RLS policy errors, CORS configuration, and Alpine.js reactivity issues.
- Generating planning documents (PRD, architecture, task lists, risk registers).

**How Claude was used:**
- As a pair programmer — iterating on code through natural language descriptions of desired behavior.
- As a debugging assistant — diagnosing errors and proposing targeted fixes.
- As a planning tool — helping decompose large feature phases into atomic implementation tasks.

**Human oversight maintained:**
- All AI-generated code was reviewed before committing.
- Database migrations were applied manually in Supabase Dashboard after review.
- Critical decisions (model choice, security policies, architectural patterns) were decided by the developer, not delegated to AI.

---

## 3. AI in the Product: Style Match Feature

The Style Match feature is Elvora's core differentiator — a personal styling experience where users upload a photo and receive curated outfit recommendations from the Elvora catalog.

### 3.1 AI Model Used

**Provider:** Google AI (Gemini)  
**Model:** `gemini-1.5-flash`  
**Capability:** Multimodal — processes both images and text in a single request.

**Why Gemini 1.5 Flash:**
- Full vision capability (image + text input in one API call).
- Fast response time (2–4 seconds for outfit analysis).
- Cost-efficient: suitable for a student project with limited API budget.
- Sufficient reasoning for fashion recommendation tasks without needing a heavier model.

### 3.2 How the Style Match Feature Works

The end-to-end flow for a Style Match request:

```
User uploads photo (optional)
        |
        v
[Browser: js/style-match.js]
  1. Canvas-based resize to max 800px long edge
  2. Upload resized image to Supabase Storage (user-uploads bucket)
  3. Generate a 60-second signed URL for the photo
        |
        v
[Browser calls Supabase Edge Function via supabase.functions.invoke()]
  - Passes: signed URL (or base64 fallback), user preferences (activity, fit, aesthetic, colour)
  - JWT from Supabase session included automatically in Authorization header
        |
        v
[Supabase Edge Function: supabase/functions/style-match/index.ts]
  4. Verifies user JWT (rejects unauthenticated requests)
  5. Fetches photo from signed URL, converts to base64 for Gemini inline_data
  6. Calls Gemini 1.5 Flash API with:
     - System prompt (Elvy persona, JSON format enforcement)
     - Photo as inline image part
     - 22 hero product catalog as structured JSON context
     - User preferences as text
  7. Parses Gemini's JSON response (outfit recommendations)
  8. Saves session to ai_style_sessions table (non-fatal — failure does not block response)
  9. Returns recommendations to browser
        |
        v
[Browser: style-match.html Alpine.js]
  10. Receives product_ids from recommendations
  11. Queries Supabase products table to fetch full product data (name, image, price, slug)
  12. Renders outfit cards with "Why it works" notes from Elvy
```

### 3.3 The Elvy Persona Prompt

The Supabase Edge Function uses a structured system prompt to shape the AI's responses:

**Persona:** Elvy acts as a premium personal stylist for ELVORA — knowledgeable, encouraging, and specific to the user's photo.

**Tone directives:**
- Reference the user's photo directly: "Based on your cool undertone...", "Your athletic build suits..."
- Use a sophisticated but approachable voice — not generic AI output.
- Focus on outfit combinations, not individual items.

**Format enforcement:** The prompt instructs Gemini to return strictly valid JSON matching this schema:

```json
{
  "colour_guidance": "string — overall palette recommendation for the user",
  "recommendations": [
    {
      "name": "Outfit name",
      "why_it_works": "Explanation referencing photo and preferences",
      "colour_guidance": "Specific colour note for this outfit",
      "product_ids": ["uuid-1", "uuid-2"]
    }
  ]
}
```

**Fallback behavior:** If Gemini cannot make a confident recommendation from the photo, it returns the 3 bestselling products from the catalog as a safe fallback.

### 3.4 Catalog Context Mapping Strategy

Gemini does not have access to ELVORA's product catalog by default. The edge function injects a curated product context into every prompt.

**What is sent to Gemini:**
- A JSON array of 22 hero products, each containing: `id`, `name`, `category`, `description`, `primary_color`, `aesthetic_tags`.
- Example aesthetic tags: `["minimal", "quiet luxury", "neutral palette"]`, `["sporty", "bold", "compression fit"]`.

**What is NOT sent to Gemini:**
- All 220 product variants (too much token cost, not needed for outfit logic).
- Stock availability (not relevant to style recommendations).
- Prices (not relevant to style analysis).

**Why 22 hero products:**
- The catalog has 22 distinct product types seeded across categories (padel, pilates, gym, yoga, running, tennis, wellness).
- Sending all 22 in context allows Gemini to select the most appropriate combination for each outfit.
- Each recommendation returns `product_ids` (UUIDs) — the browser then fetches full product details from Supabase separately.

### 3.5 Privacy Measures

| Measure | Detail |
|---------|--------|
| Photo storage | Uploaded to private Supabase Storage bucket (`user-uploads`) — not publicly accessible |
| Signed URLs | Photos sent to Gemini via 60-second signed URLs — URL expires automatically |
| No permanent image storage | Photos are treated as ephemeral; no long-term retention after analysis |
| No third-party sharing | User photos are only sent to the Gemini API for the duration of one API call |
| API key protection | `GEMINI_API_KEY` is stored as an Edge Function secret — never exposed to the browser |
| Auth required | Style Match requires an authenticated Supabase session — no guest analysis |
| RLS enforced | `ai_style_sessions` table has Row Level Security: users can only read/write their own sessions |

### 3.6 Edge Function Proxy Pattern (Security Architecture)

Direct browser calls to the Gemini API would expose the API key in DevTools Network requests. To prevent this, ELVORA uses a server-side proxy:

```
Browser (no API key)
  → Vercel / Supabase (authenticated request via JWT)
    → Supabase Edge Function (Deno, Node.js 20 runtime)
      → Gemini API (server-side, GEMINI_API_KEY in secrets)
        ← JSON response
      ← JSON response
    ← JSON response
  ← Outfit recommendations
```

**Key security properties of this pattern:**
1. `GEMINI_API_KEY` lives only in Supabase Edge Function secrets — never in browser-visible code.
2. The edge function validates the user's JWT before making any Gemini call — unauthenticated requests return 401.
3. CORS is locked to `https://elvorastudio.vercel.app` — cross-origin requests from other domains are rejected.
4. The anon key (used to call the edge function) is safe to expose in browser code — it is a publishable key, and Row Level Security enforces data isolation.

---

## 4. Session Persistence

Style Match sessions for authenticated users are stored in the `ai_style_sessions` table in Supabase PostgreSQL.

**What is stored per session:**
```sql
- user_id        (FK to auth.users)
- preferences    (JSONB: activity, fit, aesthetic, colour)
- has_photo      (boolean: whether a photo was uploaded)
- results        (JSONB: full outfit recommendations from Gemini)
- created_at     (timestamp)
```

**Session save is non-fatal:** If the database insert fails (network error, RLS issue), the edge function still returns the AI recommendations to the user. The session is lost, but the user experience is not disrupted.

**Accessing saved sessions:** Users can view their Style Match history in their ELVORA account dashboard (`/account.html`). The `getSessions()` client function in `js/style-match.js` queries `ai_style_sessions` sorted by `created_at DESC`.

---

## 5. Limitations and Honest Disclosures

| Limitation | Detail |
|------------|--------|
| No virtual try-on | Elvora does not generate images or simulate how clothes look on the user's body. |
| No real-time inventory | Recommendations are not filtered by current stock levels. |
| AI subjectivity | Gemini's style interpretations may not match all users' preferences — results are suggestions, not prescriptions. |
| Photo quality dependence | Low-resolution or poorly lit photos may reduce recommendation accuracy. |
| No iterative refinement | Users cannot provide feedback on recommendations to improve future results within a session. |
| Guest sessions not saved | If a user completes Style Match without being logged in (future feature), their session is not persisted. |

---

## 6. Files and Locations

| File | Purpose |
|------|---------|
| `js/style-match.js` | Client-side pipeline: canvas resize, Supabase Storage upload, supabase.functions.invoke call, getSessions, deleteSession |
| `supabase/functions/style-match/index.ts` | Deno Edge Function: JWT verification, Gemini API call, session persistence |
| `supabase/migrations/005_style_sessions.sql` | Database schema for ai_style_sessions table with RLS policies |
| `style-match.html` | Alpine.js UI: 2-step form (photo + preferences), loading states, results with outfit cards |

---

*This document was written for assessment transparency. All AI usage in this project followed ethical principles: no plagiarism, no deception about what is AI-generated vs. human-authored, and no collection of user data beyond what is needed for the feature to function.*
