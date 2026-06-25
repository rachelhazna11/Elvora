---
phase: 03-product-catalog
plan: 05
subsystem: frontend/pdp-social-proof
tags: [pdp, reviews, pairings, related-products, alpine, supabase, social-proof]
completed: 2026-06-14T08:31:23Z
duration: ~7min
tasks_completed: 2
tasks_total: 2
files_created: 0
files_modified: 3
requirements_addressed: [F-017, F-018, F-019]

dependency_graph:
  requires: [03-04]
  provides: [pdp-social-proof, pdp-complete]
  affects: [product.html]

tech_stack:
  added: []
  patterns:
    - Separate aggregate rating query (loadAggregateRating) from paginated text query (loadReviews) — Pitfall 7 fix from RESEARCH.md
    - window.supabase exposure in supabase.js to bridge ES module/Alpine inline x-data boundary
    - Promise.all([loadAggregateRating, loadPairings, loadRelated, loadReviews]) parallel fetch after loading=false
    - Supabase FK alias join syntax: products!product_pairings_paired_product_id_fkey
    - .range(offset, offset+pageSize-1) paginated reviews with { count: 'exact' }
    - allReviewsLoaded = reviews.length >= (reviewsTotal || totalReviewCount) guard

key_files:
  created: []
  modified:
    - js/supabase.js — added window.supabase = supabase at bottom for Alpine inline access
    - product.html — new state props + loadAggregateRating/loadPairings/loadRelated/loadReviews methods + three social proof HTML sections
    - src/input.css — new PDP social proof classes: .look-grid, .look-card, .related-grid, .review-summary, .review-rating-number, .review-stars, .star.filled, .star.empty, .review-count, .review-card, .review-header, .reviewer-name, .review-date, .review-text, .fit-badge + variants, .reviews-load-more

decisions:
  - loadAggregateRating() fetches all ratings without pagination so the displayed star average always reflects the full review dataset — not just the 5 visible rows (RESEARCH.md Pitfall 7)
  - window.supabase added to js/supabase.js (not js/products.js) because the Supabase client is the natural home; consistent with the Phase 2 window.supabase precedent in components.js
  - averageRating is a plain data property (not Alpine computed getter) because it is set asynchronously by loadAggregateRating — computed getters cannot be async
  - Promise.all called after this.loading = false so the gallery/purchase path renders immediately while social proof sections load in background
  - .look-card uses flex-shrink 0 + min-width on mobile for horizontal scroll, switches to full-width grid columns on desktop (min-width: 901px) — no JavaScript needed
  - fit-badge class mapping: runs_small → runs-small, runs_large → runs-large, anything else → true-to-size (safe default)
---

# Phase 03 Plan 05: PDP Social Proof Sections Summary

**One-liner:** PDP extended with live Supabase social proof — Complete the Look pairings (FK join), same-category Related Products, and Customer Reviews with separate aggregate rating query, fit feedback badges, and load-more pagination.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add social proof CSS classes to src/input.css | 3626180 | src/input.css |
| 2 | Add Complete the Look, Related Products, and Reviews sections to product.html | 0210aa0 | js/supabase.js, product.html |

---

## What Was Built

### Task 1 — Social Proof CSS (src/input.css)

New `/* ─── PDP Social Proof Sections ─── */` block appended before responsive rules:

**Complete the Look grid:**
- `.look-grid`: flex + horizontal scroll on mobile (scrollbar-width:none), 3-col grid on desktop (min-width 901px)
- `.look-card`: white bg, border-radius 16px, overflow hidden, hover box-shadow

**Related products grid:**
- `.related-grid`: 4-col desktop → 2-col at 900px → 2-col at 600px (gap 12px)

**Review aggregate:**
- `.review-summary`: flex align-items center, gap 16px, margin-bottom 32px
- `.review-rating-number`: Playfair Display 48px weight 400
- `.review-stars`: flex gap 2px
- `.star.filled`: color #F0C060 (extends existing `.star` class as modifier)
- `.star.empty`: color rgba(168,191,163,0.4)
- `.review-count`: 11px text-muted, margin-top 4px

**Review card:**
- `.review-card`: white bg, border-radius 16px, padding 24px, margin-bottom 16px
- `.review-header`, `.reviewer-name`, `.review-date`, `.review-text`: structured card layout

**Fit badges:**
- `.fit-badge`: base pill — 10px uppercase, letter-spacing 1px, border-radius 20px
- `.fit-badge.runs-small`: bg #FEF3C7, color #92400E
- `.fit-badge.true-to-size`: bg var(--sage-light), color var(--charcoal)
- `.fit-badge.runs-large`: bg #FEE2E2, color #991B1B

**Load more:**
- `.reviews-load-more`: underline link style, centered, font-family var(--font-body), hover color var(--charcoal)

### Task 2 — product.html + js/supabase.js

**js/supabase.js:** Added `window.supabase = supabase` at bottom of file with explanatory comment.

**product.html — new state properties:**
`pairings`, `relatedProducts`, `reviews`, `reviewsOffset`, `reviewsPageSize`, `reviewsTotal`, `allReviewsLoaded`, `reviewsLoading`, `averageRating`, `totalReviewCount`

**product.html — new methods:**
- `loadAggregateRating()`: Fetches ALL ratings (no range) → computes average → sets `averageRating` and `totalReviewCount`. Stable average not dependent on pagination state.
- `loadPairings()`: Queries `product_pairings` with FK alias join `products!product_pairings_paired_product_id_fkey` → maps to flat card objects → sets `this.pairings`
- `loadRelated()`: Queries `products` filtered by `category_id` + `neq(id)` → deduplicates `uniqueColours` per product → sets `this.relatedProducts`
- `loadReviews()`: Paginated query with `.range(offset, offset+pageSize-1)` and `{ count: 'exact' }` → appends to `this.reviews` → increments offset → sets `allReviewsLoaded`

**product.html — init() update:**
`Promise.all([this.loadAggregateRating(), this.loadPairings(), this.loadRelated(), this.loadReviews()])` called after `this.loading = false`

**product.html — HTML sections (inserted before sticky ATC bar):**

Section 1 — "Complete the Look" (`x-show="pairings.length > 0"`):
- `.look-grid` with `x-for="pair in pairings"` → `.look-card` → img (`?w=600&q=80`, loading="lazy") + name + price
- All hrefs: `/product.html?slug=` + pair.slug

Section 2 — "You Might Also Love" (`x-show="relatedProducts.length > 0"`):
- `.related-grid` with `x-for="p in relatedProducts"` → `.product-card` structure with wishlist btn + colour swatches
- All hrefs: `/product.html?slug=` + p.slug

Section 3 — "What Our Community Says":
- `.review-summary` block: `.review-rating-number` (`x-text="averageRating"`), 5-star row, `totalReviewCount + ' Reviews'`
- `x-for="r in reviews"` → `.review-card` with header (name + date + per-review stars + fit badge) + `.review-text`
- Fit badge `:class` ternary: `runs_small → runs-small`, `runs_large → runs-large`, else → `true-to-size`
- Load more: `<button class="reviews-load-more" x-show="!allReviewsLoaded && !reviewsLoading" @click="loadReviews()">`
- Loading indicator: `x-show="reviewsLoading"`

---

## Deviations from Plan

None — plan executed exactly as written.

Minor implementation notes:
1. `.star.filled` and `.star.empty` added as modifier classes extending the existing `.star { color: #F0C060 }` (line 681). The base `.star` class pre-existed from Plan 02 PLP additions; modifiers override color only.
2. `Promise.all` is called after `this.loading = false` (not before) per plan spec — ensures gallery renders immediately without waiting for social proof data.
3. Related products `uniqueColours` deduplication computed inline in `loadRelated()` (not as Alpine getter) because the data lives in an array of products, not the root Alpine component.

---

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| Wishlist button in related products grid | product.html | Phase 4 scope — static UI only, no persistence |
| `product_pairings` table must exist in Supabase | — | Migration 002_product_pairings.sql was in plan scope (Plan 01); if table absent, pairings array stays empty and section is hidden via x-show |

---

## Threat Flags

No new threat surface beyond the plan's threat model:
- T-03-19 (XSS via review_text, reviewer_name): All review data rendered via `x-text` only — no `x-html` — MITIGATED
- T-03-20 (product_pairings joined data): admin-seeded, RLS public SELECT only — ACCEPTED
- T-03-21 (RLS on reviews): pre-existing RLS from 001_schema.sql — ACCEPTED
- T-03-22 (slug href injection): Alpine :href escapes attribute values; slugs are admin-controlled — ACCEPTED

---

## Self-Check

**Files exist:**
- /Users/andika/Desktop/Elvora/js/supabase.js: FOUND
- /Users/andika/Desktop/Elvora/product.html: FOUND
- /Users/andika/Desktop/Elvora/src/input.css: FOUND

**Commits exist:**
- 3626180: FOUND (CSS task)
- 0210aa0: FOUND (HTML + supabase.js task)

**Acceptance criteria:**
- .review-card with border-radius and padding in src/input.css — PASS
- .fit-badge.runs-small, .true-to-size, .runs-large in src/input.css — PASS
- .related-grid with grid-template-columns: repeat(4, 1fr) — PASS
- .look-grid in src/input.css — PASS
- .star.filled with color #F0C060 in src/input.css — PASS
- .reviews-load-more class in src/input.css — PASS
- loadAggregateRating() querying window.supabase.from('reviews').select('rating') without range — PASS
- loadPairings() calling window.supabase.from('product_pairings') — PASS
- loadRelated() calling window.supabase.from('products') filtered by category_id — PASS
- loadReviews() with .range(this.reviewsOffset, ...) — PASS
- this.allReviewsLoaded boolean check — PASS
- x-for="pair in pairings" section exists — PASS
- x-for="p in relatedProducts" section exists — PASS
- x-for="r in reviews" section exists — PASS
- "Load More Reviews" button with x-show="!allReviewsLoaded" and @click="loadReviews()" — PASS
- fit-badge span with :class binding for runs-small, true-to-size, runs-large — PASS
- averageRating is data property (not computed getter) set by loadAggregateRating() — PASS
- x-text="totalReviewCount + ' Reviews'" uses totalReviewCount — PASS
- Section headings: "Complete the Look", "You Might Also Love", "What Our Community Says" — PASS
- All pairing/related hrefs use '/product.html?slug=' pattern — PASS
- Promise.all([loadAggregateRating, loadPairings, loadRelated, loadReviews]) in init() — PASS
- window.supabase = supabase in js/supabase.js — PASS
- All supabase query methods use window.supabase — PASS

## Self-Check: PASSED
