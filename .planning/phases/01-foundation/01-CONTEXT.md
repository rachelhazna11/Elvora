# Phase 1: Foundation - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Infrastructure only — no user-facing UI. This phase delivers: the complete Supabase PostgreSQL schema (16 tables, RLS on all), storage buckets, a deployed Supabase Edge Function stub, seeded product catalog (20+ products with Unsplash image URLs), deployment pipeline on Netlify, GitHub Actions keep-alive ping, and the full repository directory scaffold that all downstream phases build into.

Every subsequent phase depends on this phase being complete and stable.

</domain>

<decisions>
## Implementation Decisions

### Seed Image Strategy

- **D-01:** Use Unsplash CDN URLs directly in the `product_images` table — no upload to Supabase Storage during seeding. Reference format: `https://images.unsplash.com/photo-{id}?w=800&q=80`.
- **D-02:** No Supabase Storage mirror for seed images. Phase 3 renders images directly from Unsplash CDN URLs. Unsplash URL params (`w=800&q=80`) handle sizing — Supabase transform params are not required for seed data.
- **D-03:** When selecting Unsplash photos, target realistic premium activewear/lifestyle photography (neutral tones, editorial framing) consistent with the Alo Yoga / Varley visual benchmark.

### Repository Structure

- **D-04:** HTML pages live at the project root: `index.html`, `shop.html`, `product.html`, `cart.html`, `checkout.html`, `auth.html`, `account.html`, `style-match.html`, `about.html`, `contact.html`, `admin.html`.
- **D-05:** JavaScript organized as ES modules in `js/`: `js/supabase.js` (shared Supabase client — initialized once), `js/auth.js`, `js/cart.js`, `js/products.js`, `js/style-match.js`, `js/admin.js`. No inline `<script>` blocks in HTML (NF-006).
- **D-06:** Phase 1 establishes the full directory scaffold even though only the backend is implemented. Empty HTML shells with `<head>` boilerplate, `js/` with stub files, `css/` for the Tailwind output, `supabase/migrations/` and `supabase/functions/` are all created in Phase 1. Downstream phases fill content without restructuring.
- **D-07:** CSS output lives at `css/style.css` — compiled by Tailwind CSS v4 CLI from a `src/input.css` source file.

### Local Development Workflow

- **D-08:** Cloud-only development — no Supabase CLI, no local Docker. Schema and RLS policies are written as `.sql` files in `supabase/migrations/` and applied manually via the Supabase SQL editor. Seed data is a `supabase/seed.sql` file run once in the dashboard.
- **D-09:** Single Supabase project for both development and the assessment demo. No dev/prod split (free tier constraint: 1 active project).
- **D-10:** Local environment variables managed via `.env` (gitignored) containing `SUPABASE_URL` and `SUPABASE_ANON_KEY`. `.env.example` committed to the repository documents all required variables with placeholder values (NF-008).
- **D-11:** Netlify Function / Supabase Edge Function local testing is deferred to Phase 5. Phase 1 deploys the stub to Supabase cloud and verifies it via `curl` — no local `netlify dev` or Supabase CLI needed.

### Edge Function Scope (Phase 1)

- **D-12:** Deploy a working `style-match` Supabase Edge Function (Deno runtime) — NOT a Netlify Function. This matches F-049 which explicitly requires a Supabase Edge Function with `GEMINI_API_KEY` stored as a Supabase secret.
- **D-13:** Phase 1 stub behavior: validates the incoming JWT (reject unauthenticated requests with 401), accepts the expected request payload shape (`{ photo_url, preferences: { activity, fit, aesthetic, colour } }`), returns a hardcoded mock response, logs the request flow for debugging. Does NOT call the Gemini Vision API.
- **D-14:** Mock response shape (matches exactly what Phase 5 will replace with real output):
  ```json
  {
    "recommendations": [
      {
        "name": "Mock Outfit 1",
        "product_ids": ["seed-product-id-1", "seed-product-id-2"],
        "colour_guidance": "Earthy tones complement your natural colouring — lean into sage and ivory."
      }
    ]
  }
  ```
- **D-15:** CORS headers locked to production Netlify domain. Phase 5 replaces only the function body with real Gemini calls — deployment, auth wiring, CORS, and request shape remain unchanged.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements (Phase 1 scope)
- `.planning/REQUIREMENTS.md` §F-046 — Supabase Database Schema: 16 table names, RLS requirement, `product_variants` row-per-variant, `order_items` snapshot fields
- `.planning/REQUIREMENTS.md` §F-047 — Supabase Auth Integration: email/password, `is_admin()` RLS function, `raw_app_meta_data` admin role
- `.planning/REQUIREMENTS.md` §F-048 — Supabase Storage Integration: `product-images` (public) and `user-uploads` (private, user-scoped paths)
- `.planning/REQUIREMENTS.md` §F-049 — AI Proxy Edge Function: Supabase Edge Function named `style-match`, GEMINI_API_KEY in secrets, JWT verification, CORS
- `.planning/REQUIREMENTS.md` §F-050 — Seeded Product Catalog: 20+ products, 6 types, 2+ colour variants, 2+ images, seed SQL script
- `.planning/REQUIREMENTS.md` §F-051 — Deployment Pipeline: Netlify, env vars in platform, Tailwind CLI build, GitHub Actions keep-alive ping to `/auth/v1/health`
- `.planning/REQUIREMENTS.md` §NF-005 — Security: ANON_KEY only in frontend, SERVICE_ROLE_KEY never committed, RLS on all tables
- `.planning/REQUIREMENTS.md` §NF-006 — Code Maintainability: file organization, shared `js/supabase.js`, no inline JS, `/supabase/` directory for SQL
- `.planning/REQUIREMENTS.md` §NF-008 — Deployment Readiness: `.env.example`, no hardcoded localhost, reproducible build

### Project Decisions
- `.planning/PROJECT.md` §Key Decisions — locked choices: Supabase as sole backend, Gemini Vision for AI Style Match, seeded catalog
- `.planning/ROADMAP.md` §Phase 1 — success criteria: 5 verifiable conditions the phase must satisfy

### Design Reference (visual direction only — not production code)
- `elvora_updated-3.html` — existing prototype showing font choices (Playfair Display + Poppins), colour tokens, nav pattern, and page structure. Reference for visual direction; not used as production code.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet — greenfield project. No existing components, hooks, or utilities.

### Established Patterns
- `elvora_updated-3.html` prototype establishes: CSS custom properties pattern (`--sage`, `--beige`, `--charcoal`), fixed nav with blur backdrop, Playfair Display serif for headlines + Poppins for body. These patterns should be carried forward into the Tailwind design tokens in Phase 2.

### Integration Points
- Phase 1 creates the full directory scaffold. Phase 2 fills `index.html` and the Tailwind design system. Phase 3 fills `shop.html` and `product.html`. Phase 4 fills `auth.html` and `account.html`. Phase 5 fills `style-match.html` and replaces the Edge Function body. Phase 6 fills `cart.html` and `checkout.html`. Phase 7 fills `admin.html`.
- `js/supabase.js` is the single shared Supabase client — every other JS module imports from it. Created as a stub in Phase 1, populated with real connection logic.

</code_context>

<specifics>
## Specific Ideas

- Edge Function mock response must use the exact JSON shape that Phase 5 will produce — Phase 5 should only need to replace the response body, not change any surrounding infrastructure.
- Seed data should feel like a real premium activewear catalog: considered product names (not "Product 1"), realistic fabric descriptions (e.g., "78% recycled nylon, 22% elastane"), premium price points (£65–£145 range), proper colour names (Sage, Ivory, Chalk, Forest, Slate, Rose).
- Unsplash image selection should target editorial activewear photography — search terms like "women activewear", "padel tennis outfit", "pilates studio", "yoga lifestyle" — not generic sports stock photography.

</specifics>

<deferred>
## Deferred Ideas

- Supabase CLI + local Docker development environment — appropriate for a production project but adds complexity beyond student scope. Could be revisited if the project is extended post-assessment.
- Separate dev/prod Supabase projects — free tier constraint makes this impractical; single project is the right call for assessment scope.
- Netlify Function local testing via `netlify dev` — deferred to Phase 5 when the actual AI feature is built and the function body needs real testing.
- Real image upload to Supabase Storage for seed data — feasible but adds seeding complexity without meaningful benefit for assessment scope; Unsplash CDN URLs serve the same purpose.

</deferred>

---

*Phase: 1-Foundation*
*Context gathered: 2026-06-10*
