# Phase 2: Brand Shell + Homepage - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

The visitor-facing brand shell — this phase makes Elvora look and feel like a premium brand. Deliverables: the complete Tailwind v4 design system (tokens, typography, component utilities), the 8-section homepage (`index.html`), the About/Brand Story page (`about.html`), the Contact/FAQ page (`contact.html`), shared nav + footer injected via `js/components.js`, and the Alpine.js interactive behaviors for this set of pages (mobile nav drawer, FAQ accordion, newsletter form submit to Supabase).

Best sellers and testimonials are fetched live from the seeded Supabase database. Auth state and cart badge are stubbed in Phase 2 and wired in Phases 4 and 6 respectively.

**Phase 2 does NOT include:** product listing/filtering (Phase 3), auth flows (Phase 4), cart/checkout (Phase 6), admin panel (Phase 7).

</domain>

<decisions>
## Implementation Decisions

### Prototype Fidelity

- **D-01:** Port `elvora_updated-3.html` faithfully as the implementation reference. The planner and executor treat it as the approved design — not a rough sketch but the specific layout, section structure, and visual hierarchy to reproduce. Deviations require a documented reason.
- **D-02:** Migration from the prototype's inline `<style>` CSS to Tailwind v4 utility classes should match the visual intent loosely using the standard Tailwind scale (e.g., `py-24`, `px-16`, `text-4xl`) rather than pixel-perfect arbitrary values. The result should be visually near-identical, not mathematically identical.
- **D-03:** The hero image slot is filled with a curated Unsplash editorial URL — premium women's activewear/lifestyle photography, neutral tones, consistent with the Alo Yoga aesthetic benchmark established in Phase 1 (D-03). The URL is hardcoded in the HTML; no CMS required for the hero in Phase 2.

### Mobile Navigation

- **D-04:** On mobile (below `md:` breakpoint), the horizontal nav links collapse. A hamburger icon (top-right) opens a full-height slide-out drawer from the right side. The drawer contains all nav links, the nav icons (search, user, bag), and a close button. Implemented with Alpine.js `x-show` + transition.
- **D-05:** Nav scroll behavior: starts transparent over the hero (on `index.html`); transitions to the beige backdrop-blur background (`bg-beige/90 backdrop-blur-md`) after scrolling ~80px. This matches the prototype's existing behavior. Implemented via `window.scroll` listener inside an Alpine `x-init`.

### Shared Nav & Footer

- **D-06:** A new `js/components.js` ES module exports the nav and footer as HTML strings and inserts them into placeholder `<div id="nav-root">` and `<div id="footer-root">` elements on each page. This is the single source of truth — changing the nav means editing one file. All 11 HTML shells receive these placeholders.
- **D-07:** Phase 2 renders the nav with static icons (bag, user icon). `Alpine.store('cart')` and `Alpine.store('auth')` are initialized with empty/null defaults in `js/components.js` so the store shape is ready for Phase 4 (auth wiring) and Phase 6 (cart count badge). The nav does NOT show dynamic state in Phase 2.

### About + Contact Pages

- **D-08:** The About page (`about.html`) is a full editorial brand story layout: brand mission headline in Playfair Display, 2–3 paragraphs of premium brand copy (Elvora's values, the women it serves, the lifestyle it enables), one or two Unsplash lifestyle images, and a CTA linking back to the catalog (`shop.html`). No data from Supabase — pure HTML/CSS.
- **D-09:** The Contact/FAQ page (`contact.html`) contains: an expandable FAQ accordion (~6 questions covering shipping, returns, sizing, sustainability) implemented with Alpine.js `x-show`, plus brand contact information (email address, Instagram handle). No contact form submission in Phase 2.

### Alpine.js Interactive Behaviors (Phase 2 scope)

- **D-10:** Alpine.js behaviors scoped to Phase 2:
  1. Mobile nav drawer open/close (`x-show`, transition classes)
  2. Nav scroll transparency → frosted glass (window scroll listener in `x-init`)
  3. FAQ accordion expand/collapse (`x-show` per FAQ item)
  4. Newsletter form submit → `supabase.from('newsletter_subscribers').insert()` → show success message
- **D-11:** Best sellers section fetches 4 products from Supabase (`products` table, ordered by `created_at` or a `is_featured` flag). Testimonials section fetches 3+ rows from `testimonials` table. Both are Alpine.js `x-data` components using `async` `init()` that calls `supabase`. Rendered with `template x-for`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design Reference
- `elvora_updated-3.html` — **Primary implementation reference.** Port this prototype faithfully into Tailwind v4. Defines: nav structure, hero layout (split two-column), marquee strip, collections grid, brand story, testimonials grid, newsletter form, footer. All sections in this file are the approved design.
- `src/input.css` — Tailwind v4 `@theme` block with all color tokens (`--color-sage`, `--color-rose`, `--color-beige`, `--color-charcoal`, `--color-lavender`) and font tokens (`--font-display`, `--font-body`). DO NOT redefine these — extend if needed.

### Requirements (Phase 2 scope)
- `.planning/REQUIREMENTS.md` §F-001 — Editorial Hero Section (full-screen/near-full-screen, headline, CTA, mobile-responsive)
- `.planning/REQUIREMENTS.md` §F-002 — Featured Activity Collections (Padel, Pilates, Tennis, Training cards → filtered PLP)
- `.planning/REQUIREMENTS.md` §F-003 — Best Sellers Section (4+ products from Supabase, product cards with image/name/price/swatches)
- `.planning/REQUIREMENTS.md` §F-004 — Lifestyle/Lookbook Grid (4–6 editorial images, editorial layout)
- `.planning/REQUIREMENTS.md` §F-005 — Brand Story Section (editorial text, links to About page)
- `.planning/REQUIREMENTS.md` §F-006 — Testimonials Section (3+ from Supabase, quote/name/activity label)
- `.planning/REQUIREMENTS.md` §F-007 — Newsletter Signup (email input, Supabase insert, confirmation message, email validation)
- `.planning/REQUIREMENTS.md` §F-043 — About / Brand Story page
- `.planning/REQUIREMENTS.md` §F-044 — Contact / FAQ page
- `.planning/REQUIREMENTS.md` §F-045 — Global navigation (consistent across all pages, active state indicators)
- `.planning/REQUIREMENTS.md` §NF-001 — Responsive design (375px, 768px, 1024px, 1280px+ breakpoints)
- `.planning/REQUIREMENTS.md` §NF-002 — Performance (target sub-3s LCP)
- `.planning/REQUIREMENTS.md` §NF-003 — Accessibility (semantic HTML, WCAG AA contrast)
- `.planning/REQUIREMENTS.md` §NF-004 — Cross-browser (Chrome, Safari, Firefox)

### Project Decisions
- `.planning/PROJECT.md` §Key Decisions — brand aesthetic benchmark: Alo Yoga / Varley tier quiet luxury
- `.planning/phases/01-foundation/01-CONTEXT.md` §D-04 to D-07 — file structure, JS module organization, CSS compilation path

### Technology
- Alpine.js 3.15.12 CDN: `https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js` — include via `<script defer>` in `<head>`
- Supabase JS SDK 2.x CDN: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm` (already used in `js/supabase.js`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/input.css` — All color and font tokens are already defined. Import and extend; never redefine.
- `js/supabase.js` — Exports `supabase` client initialized from `window.__ENV.SUPABASE_URL` / `window.__ENV.SUPABASE_ANON_KEY`. **Note:** current implementation uses `import.meta.env` (Vite-style) which won't work without a build step. Phase 2 should read env from a `<script>` block injecting `window.__ENV = { SUPABASE_URL: "...", SUPABASE_ANON_KEY: "..." }` in each HTML page's `<head>`, or use a `config.js` module with the literal values (anon key is public-safe per CLAUDE.md).
- `js/products.js`, `js/auth.js`, `js/cart.js` — Stub modules created in Phase 1. Phase 2 does NOT populate these — only `js/components.js` (new) and inline Alpine `x-data` on the homepage are Phase 2's JS scope.

### Established Patterns
- HTML shells at root, each with `<link rel="stylesheet" href="/css/style.css">` and `<script type="module" src="/js/supabase.js">` (from Phase 1 scaffold).
- Tailwind v4 CLI compiles `src/input.css → css/style.css`. Add classes freely — the CLI picks up any class used in HTML.
- Unsplash URL pattern from Phase 1 seed data: `https://images.unsplash.com/photo-{id}?w=800&q=80`

### Integration Points
- `index.html` ← Phase 2 fills entirely (8 sections + nav/footer placeholders)
- `about.html`, `contact.html` ← Phase 2 fills
- `js/components.js` ← New file Phase 2 creates; all other pages reference it for nav/footer injection
- `newsletter_subscribers` Supabase table ← Phase 2 writes to it (already in schema from Phase 1)
- `products` table ← Phase 2 reads for best sellers (schema + seed data from Phase 1)
- `testimonials` table ← Phase 2 reads for homepage section (schema + seed data from Phase 1)
- All other HTML shells (shop, product, cart, checkout, auth, account, style-match, admin) ← Phase 2 adds nav/footer placeholder divs to these stubs but does NOT fill their content

</code_context>

<specifics>
## Specific Ideas

- **Quiet luxury visual benchmark:** Alo Yoga / Varley — editorial photography, generous whitespace, serif display type, restrained colour palette. Every section should feel like a premium fashion brand, not a generic sports shop.
- **Lookbook grid:** 4–6 hardcoded Unsplash URLs of editorial activewear photography. No Supabase management needed for the lookbook in Phase 2 (admin panel management is Phase 7 scope for best sellers and collections, not lookbook).
- **Marquee strip:** The prototype has a scrolling marquee strip (brand keywords / lifestyle phrases) between the hero and the collections section. Include this — it's a key brand expression element.
- **Collections grid links:** Each collection card (Padel, Pilates, Tennis, Training) links to `shop.html?category={slug}` — the query param will be consumed by Phase 3's PLP filter.
- **Best sellers product cards:** At minimum show product image, name, price, and a colour swatch indicator (dot or small square per variant colour). The full swatch + hover interactions are Phase 3 scope.
- **Hero CTA:** "Discover the Collection" (or similar) → `shop.html`. A secondary CTA "Find My Style" → `style-match.html`.

</specifics>

<deferred>
## Deferred Ideas

- **Contact form submission:** A functional contact form with email delivery is appropriate for a production project but out of scope here (no email sending infrastructure). Could be added post-assessment.
- **Hero video background:** Video loop over the hero would elevate the premium feel but adds performance complexity and is not required by any ROADMAP criterion.
- **Animated scroll transitions:** Section fade-in on scroll (Intersection Observer) would enhance the editorial feel. Nice-to-have; the executor can include if time allows but it's not a requirement.
- **Swiper.js carousel for testimonials/best sellers:** CLAUDE.md lists Swiper.js as an option. If the testimonials section has more than 4 items or best sellers are > 4, a carousel is cleaner on mobile. This is executor discretion — not required.

</deferred>

---

*Phase: 2-Brand Shell + Homepage*
*Context gathered: 2026-06-11*
