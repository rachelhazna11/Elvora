# Phase 3: Product Catalog - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

The core shopping discovery experience. This phase delivers:
- **PLP (`shop.html`):** Complete product listing page with activity-based filtering, sub-category pills, sort options, search (via nav), and Supabase-backed product cards with colour swatches
- **PDP (`product.html`):** Full product detail page with Swiper.js image gallery, colour swatch selection, size selection, sticky ATC bar, size guide modal, fabric/care accordion, "Complete the Look" outfit pairings, related products grid, and customer reviews
- **Schema migration:** `002_product_pairings.sql` — new table for "Complete the Look" pairing data
- **`js/products.js`:** All stub functions populated (getProducts, getProduct, getCategories, searchProducts)
- **Nav search:** Click-to-expand search bar in the Phase 2 nav with ilike autosuggest dropdown

**Phase 3 does NOT include:** Cart/wishlist interactions beyond Add to Cart stub (Phase 6), auth gating (Phase 4), admin panel product management (Phase 7), AI Style Match (Phase 5).

</domain>

<decisions>
## Implementation Decisions

### PLP Activity Filter

- **D-01:** Primary filter axis is **activity** (All, Padel, Pilates, Tennis, Training, Running), NOT garment type. The existing `shop.html` garment-type filters (leggings, tops, jackets) are replaced entirely.
- **D-02:** Activity filtering queries Supabase via the `collection_products` join table. Activity tab "Padel" maps to collection slug `padel-edit`; "Pilates" → `studio-essentials`; "Tennis" → a tennis-focused collection; "Training" → gym collections; "Running" → `run-era`. The planner must confirm the exact collection slug → activity tab mapping from seed data.
- **D-03:** When an activity tab is selected, a second row of **sub-category pills** appears below the tabs (e.g., Padel → Matcha Babe, Court Crush, Rally Ready). Sub-categories map to the named sub-collections in the `collections` table. Clicking a sub-category pill further filters products to that specific sub-collection.
- **D-04:** Filter and sort state are reflected in URL query params: `?category=padel&sub=matcha-babe&sort=price-asc`. On page load, Alpine reads params from `window.location.search` and initialises filters accordingly. Browser back/forward must restore filter state.
- **D-05:** Every tab/pill change fires a **new Supabase query** (re-fetch on change). No client-side-only filtering — ensures correct results as product count grows and honours the collection join data model.

### Sort Options

- **D-06:** Sort options: New Arrivals (default, ordered by `created_at` desc), Price Low–High, Price High–Low, Best Sellers (`is_best_seller = true` first, then by `created_at`). Sort state reflected in URL (`?sort=price-asc` etc.).

### Product Pairings ("Complete the Look")

- **D-07:** Add a new `product_pairings (product_id, paired_product_id, display_order)` table via a new migration file `supabase/migrations/002_product_pairings.sql`. RLS policy: public read (same pattern as `collection_products`).
- **D-08:** The planner must write `002_product_pairings.sql` and add pairing seed rows to `supabase/seed.sql` (or a new `supabase/seed_pairings.sql`). Pairing logic: activity-context-relevant (padel skirt pairs with padel top, not running gear). 2–3 pairings per product, seeded for all 22 products.
- **D-09:** A blocking PLAN step must apply `002_product_pairings.sql` to Supabase via SQL Editor — same cloud-only D-08 workflow from Phase 1.

### PDP Image Gallery

- **D-10:** Use **Swiper.js via CDN** for the PDP image gallery. Add `<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.css">` and `<script src="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js">` to `product.html`. Configure with thumbnail (thumbs) module: large main image + scrollable thumbnail strip below.
- **D-11:** Seed images are Unsplash CDN URLs — use them as-is in Phase 3. Do NOT apply Supabase Storage transform params (`?width=1200&quality=80`) to Unsplash URLs — they use a different parameter format (`?w=1200&q=80`). Apply `?w=1200&q=80` to the main gallery image and `?w=200&q=60` to thumbnails. Document the Supabase transform pattern in a code comment for Phase 7 when real uploads arrive.

### PDP URL Routing

- **D-12:** PDP URL uses `?slug=serenity-ribbed-legging` (human-readable). The PDP JS reads `URLSearchParams` for `slug` and queries `supabase.from('products').select(...).eq('slug', slug).single()`. Update `shop.html` product card links from `?id=${p.id}` to `?slug=${p.slug}`.
- **D-13:** If the slug is not found in Supabase (null result), redirect to `/shop.html` immediately — no error page, no broken layout.

### Nav Search

- **D-14:** Search icon in the Phase 2 nav triggers a **click-to-expand** text input in-place (Alpine.js `x-show` + transition). The expanded input overlays the right side of the nav. A dropdown autosuggest list appears below the input showing matching product names.
- **D-15:** Search queries Supabase with `.from('products').select('name, slug').ilike('name', '%query%').limit(6)`. Minimum 2 characters to trigger. Selecting a suggestion navigates to `product.html?slug=${result.slug}`. Pressing Enter navigates to `shop.html?search=${query}`.
- **D-16:** The PLP must also consume a `?search=` URL param — if present, pre-fill the search state and filter products by name match.
- **D-17:** `searchProducts(query)` function in `js/products.js` (already stubbed) implements the ilike query.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design Reference
- `elvora_updated-3.html` — Primary visual reference for card layouts, typography scale, and section structure. Adapt PLP/PDP sections to match the premium aesthetic established here.
- `src/input.css` — All colour and font tokens. Use existing `--color-sage`, `--color-beige`, `--color-charcoal` etc. — do NOT redefine.

### Requirements (Phase 3 scope)
- `.planning/REQUIREMENTS.md` §F-008 — Product Listing Page (all products, cards with image/name/price/swatches, pagination/load-more if >12)
- `.planning/REQUIREMENTS.md` §F-009 — Activity Category Filtering (All, Padel, Pilates, Tennis, Training, Running; URL state; no full reload)
- `.planning/REQUIREMENTS.md` §F-010 — Color Swatches on Product Cards (up to 4 swatches; hover updates card image; active swatch indicated)
- `.planning/REQUIREMENTS.md` §F-011 — Product Search with Autosuggest (header search; 2-char trigger; dropdown; Enter → PLP filtered)
- `.planning/REQUIREMENTS.md` §F-012 — Sort Options (New Arrivals, Price Low–High, Price High–Low, Best Sellers; URL state)
- `.planning/REQUIREMENTS.md` §F-013 — Multi-Image Product Gallery (3+ images; thumbnails; touch/swipe mobile)
- `.planning/REQUIREMENTS.md` §F-014 — Sticky Add to Cart Bar (appears after scrolling past main ATC; shows name/size/colour/price; ATC button)
- `.planning/REQUIREMENTS.md` §F-015 — Size Guide Modal (modal overlay; size chart; closeable via button/Escape/outside click; focus trap)
- `.planning/REQUIREMENTS.md` §F-016 — Fabric & Material Details (accordion or dedicated section; structured fields from Supabase)
- `.planning/REQUIREMENTS.md` §F-017 — Complete the Look / Outfit Pairing (2–3 cards; activity-relevant; links to PDPs; from `product_pairings` table)
- `.planning/REQUIREMENTS.md` §F-018 — Related Products Grid (4+ products from same activity category)
- `.planning/REQUIREMENTS.md` §F-019 — Customer Reviews on PDP (aggregate star rating; individual reviews with fit feedback; 5+ load-more)
- `.planning/REQUIREMENTS.md` §NF-001 — Responsive design (375px, 768px, 1024px, 1280px+ breakpoints)
- `.planning/REQUIREMENTS.md` §NF-002 — Performance (sub-3s LCP target)
- `.planning/REQUIREMENTS.md` §NF-003 — Accessibility (semantic HTML, WCAG AA contrast, focus trap in modals)

### Database
- `supabase/migrations/001_schema.sql` — Existing schema. Read before writing migration 002. Key tables: `products`, `categories`, `collections`, `collection_products`, `product_variants`, `product_images`, `reviews`.
- `supabase/seed.sql` — Seeded catalog: 22 products, 7 categories, 9+15 collections, variants, images, reviews. Planners must understand the collection slug → activity mapping before writing queries.

### Technology
- `js/subcategory-styles.js` — Authoritative list of 15 sub-categories (slugs, names, category, tones, aesthetic). PLP sub-category pills must use slugs from this file to match `collections.slug` values in the database.
- `js/products.js` — Stub file Phase 3 populates. All 4 exported functions must be implemented.
- `js/components.js` — Phase 2 nav/footer injection. Phase 3 modifies the nav's search icon behavior — must edit `components.js` to wire up search expand/collapse Alpine state.
- `.planning/phases/02-brand-shell-homepage/02-CONTEXT.md` §D-06 — components.js pattern (nav/footer as single source of truth)
- `.planning/phases/01-foundation/01-CONTEXT.md` §D-08 — Cloud-only Supabase workflow; apply SQL via SQL Editor dashboard

### Project Decisions
- `.planning/PROJECT.md` §Key Decisions — brand aesthetic benchmark: Alo Yoga / Varley tier quiet luxury. Every card and section must reinforce this.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/input.css` — All design tokens defined. Use Tailwind utility classes referencing these tokens; do not add arbitrary values.
- `js/supabase.js` — Singleton Supabase client. All product queries import `{ supabase }` from this module.
- `js/components.js` — Nav/footer injection. **Phase 3 must extend this file** to add search expand/collapse behavior to the nav search icon. Planner should decide whether to add an Alpine.js data attribute to the nav root div or handle search state separately in `js/products.js`.
- `js/subcategory-styles.js` — Already built. Import `SUBCATEGORY_STYLES` and `getSubcategoryBySlug` — do NOT recreate this data inline in HTML.
- `shop.html` — Partial prototype exists with hardcoded Alpine.js data. Phase 3 replaces the hardcoded `x-data` block with Supabase-fetched data and updates the filter pills from garment-type to activity tabs.

### Established Patterns
- CDN-only loading (no npm for Alpine, Swiper, Supabase) — all libraries via `<script>` CDN tags in `<head>`.
- Alpine.js `x-data` + `init()` async pattern for Supabase fetches (established in Phase 2 best sellers / testimonials sections).
- `window.__ENV` env var injection via `js/__env.js` (loaded as plain `<script>` before ES modules).
- Unsplash URL sizing: `?w=800&q=80` for cards, `?w=1200&q=80` for PDP main image, `?w=200&q=60` for thumbnails.

### Integration Points
- `shop.html` ← Phase 3 completely rewrites this page (replaces hardcoded data prototype with Supabase-backed PLP)
- `product.html` ← Phase 3 fills the `<main>` stub entirely
- `js/products.js` ← Phase 3 populates all 4 stub functions
- `js/components.js` ← Phase 3 extends nav with search expand/collapse
- `supabase/migrations/` ← Phase 3 adds `002_product_pairings.sql`
- `supabase/seed.sql` ← Phase 3 adds pairing seed rows (or separate seed_pairings.sql)
- Alpine.store('cart') ← Phase 3 wires the "Add to Bag" button to `Alpine.store('cart').add(item)` — the store shape was stubbed in Phase 2 (D-07), actual cart logic is Phase 6 scope. For Phase 3, ATC should call the store method even if it's a no-op stub.
- Alpine.store('auth') ← Phase 3 may read auth state to show/hide wishlist icon active state — but full auth wiring is Phase 4 scope.

</code_context>

<specifics>
## Specific Ideas

- **Activity tab → collection slug mapping** (to be confirmed by planner from seed data): All → no filter, Padel → `padel-edit`, Pilates → `studio-essentials`, Tennis → a tennis collection (check seed), Training → gym collections (`power-mood` / `built-different` / `hot-girl-lift`), Running → `run-era`.
- **Sub-category pills** should appear as a scrollable horizontal pill row (mobile-friendly, horizontally scrollable if overflow) below the main activity tabs — same pill style as the activity tabs but smaller.
- **Colour swatch hover on PLP cards** — hovering a colour swatch should update the card's main image to the corresponding variant's image. Query product_variants and product_images by variant_id to get the matching image URL. This requires either: pre-loading all variant images per card on PLP load (22 products × ~3 variants = ~66 images — fine for assessment scope), or lazy-loading on hover.
- **Sticky ATC bar** — Implemented with `IntersectionObserver` watching the main ATC button. When the main button leaves the viewport (scrolled past), Alpine reactive state shows the sticky bar via `x-show`. Dismiss when main button re-enters viewport.
- **Size guide modal** — Static size chart (hardcoded in HTML, not from Supabase): XS/S/M/L/XL mapped to bust/waist/hip measurements in cm. Include brief "How to measure" instructions. The same modal can be reused across all PDPs.
- **Reviews** — Aggregate star rating computed client-side from the reviews array (average of `rating` column). Fit feedback displayed as pill badges ("Runs Small" / "True to Size" / "Runs Large"). Show 5 reviews initially, "Load more" fetches next batch from Supabase.

</specifics>

<deferred>
## Deferred Ideas

- **Real Supabase Storage image transforms** — Seed images are Unsplash CDN URLs; Storage transform params (`?width=...&quality=...`) only work on Storage-hosted files. Document the pattern in code comments; activate in Phase 7 when admin panel enables real image uploads.
- **Review submission** — F-019 explicitly says "Review submission is not required for v1 (display only, admin-seedable)". Phase 7 or v2 scope.
- **Wishlist button active state** — Wishlist heart icon on PLP/PDP cards is Phase 4 scope (requires auth). Phase 3 renders the icon as a static UI element without persistence.
- **Promo code on ATC** — Phase 6 scope.
- **Advanced filtering** (price range slider, size filter) — Not in ROADMAP Phase 3 success criteria; defer to post-assessment v2 if desired.

</deferred>

---

*Phase: 3-Product Catalog*
*Context gathered: 2026-06-14*
