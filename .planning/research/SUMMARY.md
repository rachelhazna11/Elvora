# Project Research Summary

**Project:** Elvora — Premium Women's Activewear E-Commerce
**Domain:** Static frontend + Supabase backend + Claude AI vision integration
**Researched:** 2026-06-10
**Confidence:** HIGH

## Executive Summary

Elvora is a premium women's activewear e-commerce platform — a multi-page static web app backed entirely by Supabase (auth, PostgreSQL, file storage, edge functions) with no custom server. The architecture is well-precedented: static HTML/CSS/JS served via Netlify CDN, Supabase JS SDK for all data operations, and a Supabase Edge Function as the sole server-side compute layer (proxying calls to the Claude Vision API). Alpine.js handles reactive UI surfaces (cart, modals, auth state, filters) without introducing a build pipeline or component framework overhead. Tailwind CSS v4 enforces the design system. Every technology choice is validated against the "no custom server" constraint and the assessment context.

The recommended build order is strictly dependency-driven: schema and seed data first (everything else reads from it), then the design system (all pages inherit from it), then the product catalog (read-only against Phase 1 data), then auth and accounts, then cart and checkout, then the admin panel, and finally the AI Style Match feature (requires catalog, auth, and storage to all be in place). Attempting to build the AI feature or checkout before the foundation is established will force rewrites.

The three non-negotiable risks to address in Phase 1 are: (1) Supabase RLS disabled by default — tables without policies expose all data to anonymous queries; (2) the Anthropic API key must be in an Edge Function environment variable only, never in any client-side file; and (3) the design system must lock colours, typefaces, and spacing scale before any component is built — retrofitting brand aesthetics after pages exist requires touching every file. These three decisions cannot be deferred.

## Key Findings

### Recommended Stack

| Technology | Version | Role |
|------------|---------|------|
| Alpine.js | 3.15.12 (CDN) | Reactive UI — cart, modals, auth state, filters; `Alpine.store()` for global state |
| Supabase JS SDK | v2 (≥2.79) | All backend operations — DB, auth, storage; anon key safe to expose with RLS |
| Tailwind CSS | v4 (CLI) | Luxury design system — zero framework opinion, full design token control |
| Claude `claude-sonnet-4-6` | current | AI Style Match vision analysis — via Edge Function only |
| Supabase Edge Functions | Deno | Server-side AI proxy — ANTHROPIC_API_KEY in secrets, CORS-locked to domain |
| Netlify | current | Static hosting + environment variables — free tier sufficient |

**Do not use:** React/Next.js (overengineered for this scope), Bootstrap (imposes visual identity conflicting with luxury aesthetic), direct browser calls to Claude API (key exposure), `service_role` key in any frontend file.

### Expected Features

**Table stakes (must have):**
- Full-screen editorial hero with CTA
- Activity-based collection navigation (Padel, Pilates, Tennis, Training, Running)
- Color swatch display on PLP — 42% of sites fail this (Baymard 2025)
- Exposed size button selectors (not dropdowns)
- Size guide with body measurements
- Multiple product images per listing (3+ views: model, lifestyle, detail)
- Fabric and material details on PDP
- Slide-out mini cart (no redirect on add-to-cart)
- Sticky Add to Cart bar on PDP scroll
- Guest checkout — forced account creation causes 26% of cart abandonments
- Order confirmation page
- Customer account: order history, wishlist
- Customer reviews with aggregate star rating and fit scale
- Search with autosuggest
- Mobile-responsive navigation
- Brand story / About page
- Newsletter signup form (UI only; email delivery not required for assessment)

**Differentiators (competitive advantage):**
- AI Style Match (photo upload → Claude Vision → catalog recommendations) — the core differentiator; no competitor at this scope tier has it
- Activity-specific outfit pairings on PDP ("Complete the Look" by sport context)
- Saved AI style preferences in customer account
- Quiet luxury editorial homepage rhythm (7–8 sections)
- Curated lookbook grid on homepage

**Anti-features (do not build):**
Virtual try-on, real payment processing, live inventory counters, live chat, flash sale timers, loyalty points gamification, live social feed embeds, custom ML sizing model, full CMS/blog engine, countdown urgency banners.

### Architecture Approach

Two-tier managed service pattern: Netlify serves static files; Supabase handles all backend. No custom API server. Security enforced entirely by RLS policies — not by hiding the anon key.

**Key decisions:**
- **Admin role** stored in `raw_app_meta_data` (not `raw_user_meta_data`, which users can self-modify); checked via `is_admin()` SQL function in RLS policies
- **Cart** uses localStorage/Supabase hybrid: localStorage for guests, Supabase `cart_items` for authenticated users, merged on login via `onAuthStateChange`
- **Prices** snapshotted at order creation — `order_items` stores `unit_price`, `product_name`, `variant_label`; never joined back to live product prices
- **Storage** uses two buckets: `product-images` (public CDN) and `user-uploads` (private, signed URLs scoped to `{uid}/*`)
- **AI proxy** is a Supabase Edge Function: browser sends user JWT + signed photo URL → function verifies JWT, calls Claude, returns product IDs

### Critical Pitfalls

| # | Pitfall | Phase to Address | Prevention |
|---|---------|-----------------|------------|
| 1 | **RLS disabled by default** — anon key can read/write all tables | Phase 1 | Write `ENABLE ROW LEVEL SECURITY` + policies in same migration as table creation |
| 2 | **AI API key on the client** — extractable in <60s; documented $82K abuse case | Phase 1 (architecture decision) | Key lives in Edge Function secrets only; never in any HTML/JS file |
| 3 | **Premium aesthetic collapses** — framework defaults produce generic sports store | Phase 2 | Lock design tokens (colours, typeface pair, spacing scale) before writing any component |
| 4 | **Cart state desync** — localStorage and Supabase disagree | Phase 5 | Supabase = single truth for auth users; localStorage = single truth for guests; merge on login |
| 5 | **Supabase free tier pauses after 7 days idle** — demo URL returns connection error | Phase 1 (deployment) | GitHub Actions daily ping to `/auth/v1/health` on day one of deployment |

**Also moderate risk:** Admin routes with only client-side redirect (test from incognito every time); image performance on product pages (use Supabase Storage transform `?width=800&quality=80` from first catalog build); scope creep (treat PROJECT.md requirements as a signed contract).

## Implications for Roadmap

### Suggested Phases (7)

**Phase 1 — Foundation (Schema + Seed + Infrastructure)**
All tables with RLS enabled and policies written, admin role assigned via `raw_app_meta_data`, 20+ products seeded with images, two storage buckets configured, keep-alive ping deployed, deployment pipeline working.
*Addresses pitfalls 1, 2, 5. Everything else depends on this.*

**Phase 2 — Design System + Static Shell**
Tailwind v4 design tokens (colour palette, typefaces, spacing), component library (buttons, cards, inputs, nav, footer), homepage editorial sections, all 4 breakpoints (480/768/1024/1280px).
*Addresses pitfall 3. All pages inherit from this — build before any feature page.*

**Phase 3 — Product Catalog (PLP + PDP)**
Product listing page, product detail page, activity filtering, color swatches, size selectors, multiple images, size guide modal, fabric details, sticky ATC bar, "Complete the Look" pairing, reviews display, search.
*Read-only against Phase 1 data — no auth required. Most table-stakes features land here.*

**Phase 4 — Auth + Customer Account**
Login, signup, account pages (profile, order history, wishlist, saved AI preferences), session persistence, route guard, `onAuthStateChange` listener for cart merge.
*Required by Phase 5 (cart persistence) and Phase 7 (AI session saving).*

**Phase 5 — Cart + Checkout**
Mini cart drawer (Alpine.store), cart page, multi-step checkout, order creation with price snapshot, order confirmation, guest checkout, promo code UI.
*Requires Phase 3 (products) and Phase 4 (auth). Addresses pitfall 4.*

**Phase 6 — Admin Panel**
`/admin/` route section, product CRUD with image upload, category/collection management, testimonials, homepage content, order read view. Admin guard = client-side redirect AND RLS `is_admin()`.
*Independent of customer cart/checkout. Build after storefront is verified working.*

**Phase 7 — AI Style Match**
`/style-match.html`, Edge Function `style-match`, photo upload → resize → signed URL → Edge Function → Claude Vision → product recommendations, session saved to `ai_style_sessions`, recommendation cards, session history in account.
*Highest integration complexity. All prior phases must be stable. Reserve time for 2–3 prompt iteration cycles.*

### Phase Ordering Rationale

Schema before everything → design system before components → catalog before auth/cart (read-only, early testable surface) → auth before cart (merge-on-login dependency) → admin after customer flows (isolated CRUD, verify against working storefront) → AI last (all dependencies must be stable; highest iteration risk).

### Research Flags

- **Phase 7 (AI Style Match):** Claude Vision prompt engineering for reliable structured JSON output needs iteration. Plan 2–3 revision cycles.
- **Phase 5 (Cart + Checkout):** Guest-to-auth cart merge and order creation state machine are moderately complex; review ARCHITECTURE.md cart module pattern before coding.
- Standard patterns (no additional research needed): Phases 1, 2, 3, 4, 6 — all fully documented in STACK.md and ARCHITECTURE.md.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All choices verified against official docs; CDN install patterns confirmed; free tier limits verified |
| Features | HIGH | Baymard Institute UX research (21,000+ parameter study) + direct competitor analysis |
| Architecture | HIGH | RLS patterns, admin role storage, cart hybrid, Edge Function proxy fully documented with working SQL |
| Pitfalls | HIGH | CVE-2025-48757 documented, $82K API abuse case documented, Supabase pause behavior confirmed |

**Gaps to address during implementation:**
- Claude prompt structure for structured JSON output — needs iteration in Phase 7
- Tailwind v4 config syntax changed from v3 — verify token definition format at Phase 2
- Edge Function local dev requires Docker; Netlify Functions is the fallback if Docker unavailable

---
*Research completed: 2026-06-10 | Ready for roadmap: yes*
