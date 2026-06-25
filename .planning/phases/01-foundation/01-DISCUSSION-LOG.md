# Phase 1: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 1-Foundation
**Areas discussed:** Seed image strategy, Repository structure, Local dev workflow, Edge function scope

---

## Seed Image Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Unsplash CDN URLs | Direct Unsplash source URLs — free, no key, realistic activewear photography. Use Unsplash URL params for sizing. | ✓ |
| Supabase Storage uploads | Download and upload real images to product-images bucket during seeding. Self-hosted but complex seed script. | |
| Lorem Picsum / placeholders | picsum.photos or placeholder.com. Fastest setup but catalog looks like a dev fixture. | |

**User's choice:** Unsplash CDN URLs directly in the database.

**Follow-up — mirror to Supabase Storage?**

| Option | Description | Selected |
|--------|-------------|----------|
| Unsplash URLs directly | Reference Unsplash in DB, use their URL params for sizing. No extra seeding work. | ✓ |
| Mirror to Supabase Storage | Download + upload during seeding. Fully self-hosted, enables Supabase transform params. | |

**User's choice:** Unsplash URLs directly — no mirror.
**Notes:** Unsplash URL params (`w=800&q=80`) substitute for Supabase image transforms on seed data.

---

## Repository Structure

**Page organization:**

| Option | Description | Selected |
|--------|-------------|----------|
| HTML files at project root | index.html, shop.html etc. at root. Simple, conventional for multi-page static, natural Netlify routing. | ✓ |
| pages/ subdirectory | HTML inside pages/. Cleaner root but adds URL path complexity. | |
| Single-page Alpine.js router | One index.html + Alpine.js routing. Matches prototype but hard to maintain at scale. | |

**User's choice:** HTML files at project root.

**JavaScript organization:**

| Option | Description | Selected |
|--------|-------------|----------|
| js/ directory with per-feature modules | js/supabase.js (shared), js/auth.js, js/cart.js, js/products.js, js/style-match.js. Matches NF-006 exactly. | ✓ |
| One JS file per HTML page | index.js, shop.js etc. Less shared code, more repetition. Against NF-006. | |
| Inline scripts in HTML | `<script>` blocks in HTML. Explicitly prohibited by NF-006. | |

**User's choice:** js/ directory with per-feature ES modules.

**Scaffold in Phase 1?**

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — full scaffold | Create complete directory structure with placeholder files. Downstream phases fill content. | ✓ |
| No — backend only | Phase 1 creates only supabase/, netlify.toml, config. Frontend structure created per-phase. | |

**User's choice:** Full scaffold — empty HTML shells, js/, css/, supabase/ all created in Phase 1.

---

## Local Development Workflow

**Schema management:**

| Option | Description | Selected |
|--------|-------------|----------|
| Cloud-only via Supabase dashboard | Write SQL files in supabase/migrations/, apply manually. No Docker, no CLI setup. | ✓ |
| Supabase CLI with local Docker | Full local Supabase stack. Proper version control but requires Docker. | |
| Supabase CLI cloud-only | CLI targeting remote project without local stack. Middle ground — still requires CLI setup. | |

**User's choice:** Cloud-only — SQL applied via Supabase dashboard SQL editor, files committed to repo.

**Supabase project strategy:**

| Option | Description | Selected |
|--------|-------------|----------|
| Single project for everything | One free-tier project for dev and demo. Simple, no env sync issues. | ✓ |
| Separate dev and prod projects | More professional but free tier only allows 1 active project. | |

**User's choice:** Single Supabase project.

**Environment variables:**

| Option | Description | Selected |
|--------|-------------|----------|
| .env (gitignored) + .env.example | Standard pattern. Matches NF-008 requirement for .env.example. | ✓ |
| Config object in gitignored JS file | Non-standard, doesn't align with NF-008. | |

**User's choice:** .env + .env.example.

**Netlify Function local testing:**

| Option | Description | Selected |
|--------|-------------|----------|
| Netlify CLI (netlify dev) | Run locally with full function support. Standard pattern. | |
| Deploy and test on Netlify directly | Push and test via deployed URL. Slower iteration. | |
| Skip — functions tested in Phase 5 | Phase 1 just creates scaffold. Real testing in Phase 5. | ✓ |

**User's choice:** Defer function testing to Phase 5.

---

## Edge Function Scope

**What Phase 1 delivers:**

| Option | Description | Selected |
|--------|-------------|----------|
| Working auth-validated stub | Deploy real function: validates JWT, accepts expected shape, returns hardcoded mock, CORS locked, request logging. | ✓ (adapted) |
| Scaffold only — not deployed | File exists in supabase/functions/ but not deployed. F-049 marked partial. | |
| Skip — defer to Phase 5 | Phase 1 doesn't touch Edge Function at all. | |

**User's choice:** Working auth-validated stub, adapted for Gemini Vision. Full breakdown:
- Validates authenticated requests (JWT validation)
- Accepts expected request payload shape
- Returns mocked hardcoded recommendation response
- GEMINI_API_KEY stored as Supabase Edge Function secret
- Production-safe CORS configuration
- Request flow logging for debugging
- Does NOT call Gemini Vision yet (Phase 5 responsibility)

**Runtime:**

| Option | Description | Selected |
|--------|-------------|----------|
| Supabase Edge Function (Deno) | Matches F-049 exactly. Phase 5 uses same function for real Gemini calls. | ✓ |
| Netlify Function (Node.js) | Diverges from F-049; GEMINI_API_KEY would need to go in Netlify env vars, not Supabase secrets. | |

**User's choice:** Supabase Edge Function (Deno).

**Mock response shape:**

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcoded product IDs + colour guidance | JSON shaped exactly like Phase 5 output. Phase 5 replaces only the body. | ✓ |
| Just a 200 OK health check | Simpler but response shape not validated until Phase 5. | |

**User's choice:** Full mock response matching the Phase 5 contract.

---

## Claude's Discretion

- Specific Unsplash photo IDs to use for seed products — Claude selects photos matching premium activewear/lifestyle aesthetic
- Exact SQL migration file naming convention within `supabase/migrations/`
- Which 20+ products to include in seed data (names, descriptions, prices, fabric details) — within the constraints of 6 types, premium pricing, ≥2 colour variants

## Deferred Ideas

- Supabase CLI + local Docker setup — adds complexity beyond student scope
- Separate dev/prod Supabase projects — impractical under free tier constraints
- `netlify dev` local function testing — deferred to Phase 5
- Supabase Storage image mirroring for seed data — unnecessary complexity for assessment scope
