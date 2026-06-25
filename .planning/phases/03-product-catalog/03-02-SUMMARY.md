---
phase: 03-product-catalog
plan: 02
subsystem: frontend/shop
tags: [plp, alpine, supabase, product-grid, filters, url-sync]
completed: 2026-06-14T08:18:40Z
duration: ~25min
tasks_completed: 2
tasks_total: 2
files_created: 3
files_modified: 2
requirements_addressed: [F-008, F-009, F-010, F-012]

dependency_graph:
  requires: [03-01]
  provides: [shop.html-plp, css-plp-components]
  affects: [product.html, components.js]

tech_stack:
  added: []
  patterns:
    - Alpine x-data async init() with URL param bootstrap
    - Product data normalisation (activeImage, uniqueColours deduplication)
    - Alpine computed getter (subCategoriesForActivity) referencing window global
    - history.replaceState URL sync on filter/sort change
    - Skeleton shimmer loading pattern via CSS animation
    - Toastify ATC stub notification

key_files:
  created:
    - js/components.js
    - js/subcategory-styles.js
  modified:
    - shop.html
    - src/input.css
    - js/products.js

decisions:
  - No Load More button — 22 seeded products fit on one page at assessment scale; adding a non-functional button is worse than none
  - training category key used in SUBCATEGORY_STYLES (aligned with ACTIVITY_TOP_SLUGS) — original subcategory-styles.js used 'gym' but Plan 02 spec and products.js use 'training'
  - subcategory-styles.js added window.SUBCATEGORY_STYLES exposure so Alpine inline x-data getter can access without ES module import
  - products.js loaded before subcategory-styles.js and both before components.js — ensures window globals available at Alpine init time
---

# Phase 03 Plan 02: PLP — shop.html + CSS Summary

**One-liner:** Supabase-backed shop.html PLP with Alpine activity filters, sub-category pills, colour swatch hover, URL sync, skeleton loading, empty state, and all PLP/PDP CSS component classes.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add PLP CSS classes to src/input.css | a4eeb2e | src/input.css, js/products.js, js/components.js, js/subcategory-styles.js |
| 2 | Rewrite shop.html as Supabase-backed PLP | 75d9dd0 | shop.html |

---

## What Was Built

### Task 1 — CSS Component Classes

Added to `src/input.css` after the Shop Page section:

- **`.subcategory-pills`** — flex container, overflow-x auto, no scrollbar (scrollbar-width: none + ::-webkit-scrollbar hide)
- **`.subcategory-pill` / `.sub-pill`** — 11px font, 50px border-radius, sage active fill, rose hover border; alternate class names as plan specified
- **`.shop-empty`** — 240px min-height, white bg, 16px border-radius, flex column centered, used when 0 results
- **`.load-more-btn`** — centered, pill style, matches .btn-secondary, hover: charcoal fill + white text
- **`@keyframes skeleton-shimmer`** + **`.skeleton-shimmer`** — beige sweep gradient, background-size 200%, 1.5s infinite; uses `var(--white)` and `var(--beige)` only
- **`.pdp-swatch`** — 24px dot, active outline ring `var(--charcoal)` 2px offset 3px, hover scale(1.1)

Also brought the worktree up to the Plan 01 baseline (Rule 3 deviation — see Deviations section):
- Full `src/input.css` from main branch (worktree had only token stub)
- Full `js/products.js` implementation (worktree had stub only)
- `js/components.js` — nav/footer injector + Alpine store registration
- `js/subcategory-styles.js` — 15 sub-categories, `training` category key

### Task 2 — shop.html Rewrite

Complete replacement of hardcoded prototype with Supabase-backed PLP:

**Alpine x-data state:**
- `products: []`, `loading: true`, `category: 'all'`, `sub: null`, `sort: 'new-arrivals'`, `search: ''`
- Computed getter `subCategoriesForActivity` — filters `window.SUBCATEGORY_STYLES` by `this.category`

**async init():** Reads URL params FIRST (Pitfall 4 prevention), sets state, awaits fetchProducts()

**fetchProducts():** Calls `window.getProducts()`, normalises each product:
- `activeImage` / `defaultImage` — first image by display_order
- `uniqueColours` — deduped array from product_variants, each with `colour_hex` + matched `image`
- Error-caught with console.error fallback to empty array

**syncURL():** `history.replaceState` with URLSearchParams; omits defaults (all/null/new-arrivals/empty)

**Activity tabs:** All, Padel, Pilates, Tennis, Training, Running — `aria-pressed` bound, click clears sub

**Sub-category pills:** `x-show="category !== 'all'"`, toggle sub on click (same slug = clear, different = set)

**Sort select:** `x-model="sort"` + `@change="fetchProducts()"`, 4 options

**Hero sub count:** `x-text="products.length + ' styles · Free shipping above Rp 500K'"`

**Skeleton loading:** 6 skeleton cards with `.skeleton-shimmer` shown during `loading: true`

**Product grid:** `x-for="(p, index) in products"`, `href="/product.html?slug="`, img `?w=800&q=80`, first 4 `loading="eager"`, rest `loading="lazy"`

**Colour swatches:** mouseenter/mouseleave update activeImage/activeColour; click.prevent pins selection; `aria-label` per colour; `aria-pressed` active state

**ATC stub:** `Alpine.store('cart').add()` + Toastify toast (charcoal bg, white text, bottom-right, 2.5s)

**Empty state:** `x-show="!loading && products.length === 0"` — heading, body copy, "Browse All Styles" CTA

**Script loading order:** `__env.js` → `supabase.js` → `products.js` → `subcategory-styles.js` → `components.js`

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree missing Plan 01 outputs**
- **Found during:** Task 1 pre-flight (checking worktree file state)
- **Issue:** Worktree was created at commit `42ad16e` (pre-Plan 01). Files missing from worktree: `js/components.js`, `js/subcategory-styles.js`. Old stubs: `js/products.js` (no implementation), `src/input.css` (tokens only, no component classes).
- **Fix:** Wrote all missing/stub files from main branch content into the worktree before proceeding with Plan 02 tasks. `js/__env.js` was correctly gitignored and not committed.
- **Files modified:** js/products.js, js/components.js, js/subcategory-styles.js, src/input.css
- **Commit:** a4eeb2e

**2. [Rule 2 - Missing Critical] subcategory-styles.js category key alignment**
- **Found during:** Task 1 analysis of subcategory-styles.js
- **Issue:** Original `subcategory-styles.js` used `category: 'gym'` for training sub-categories (power-mood, built-different, hot-girl-lift). Plan 02 spec uses `category: 'training'` as the filter key (matching `ACTIVITY_TOP_SLUGS` in products.js). Mismatch would break `subCategoriesForActivity` getter.
- **Fix:** Updated training sub-categories in worktree's `subcategory-styles.js` to use `category: 'training'`. Added comment explaining the alignment.
- **Files modified:** js/subcategory-styles.js
- **Commit:** a4eeb2e

**3. [Rule 2 - Missing Critical] window.SUBCATEGORY_STYLES exposure**
- **Found during:** Task 2 implementation
- **Issue:** Alpine `x-data` computed getters run in global scope — cannot use ES module imports. `SUBCATEGORY_STYLES` needed to be on `window` for `subCategoriesForActivity` getter to work.
- **Fix:** Added `window.SUBCATEGORY_STYLES = SUBCATEGORY_STYLES;` at bottom of `js/subcategory-styles.js`. Added `<script type="module" src="/js/subcategory-styles.js">` to shop.html before `components.js`.
- **Files modified:** js/subcategory-styles.js, shop.html
- **Commit:** a4eeb2e, 75d9dd0

---

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| `Alpine.store('cart').add()` — count/items not persisted | shop.html | Phase 6 scope — cart store stub registered in components.js with count:0, items:[] only |
| Wishlist button — @click.prevent does nothing | shop.html | Phase 4 scope — static UI only as documented in plan |

---

## Threat Flags

All T-03-06 through T-03-09 threats handled per plan:
- T-03-07 (XSS via product name): all product data uses `x-text` — no `x-html` anywhere in shop.html
- T-03-06 (URL ?category=): category used only as computed getter key, unrecognised values return empty `subCategoriesForActivity`
- T-03-08 (URL ?sort=): sort used as switch key in getProducts(), unrecognised values fall to default
- T-03-09 (colour swatch image URL): images are Unsplash CDN URLs from Supabase, not user-supplied

No new threat surface introduced beyond what the plan's threat model covers.

---

## Self-Check

**Files exist:**
- shop.html: FOUND
- src/input.css: FOUND
- js/products.js: FOUND
- js/components.js: FOUND
- js/subcategory-styles.js: FOUND

**Commits exist:**
- a4eeb2e: FOUND
- 75d9dd0: FOUND

**Acceptance criteria:**
- `subcategory-pill` in input.css: 5 occurrences — PASS
- `load-more-btn` in input.css: 2 occurrences — PASS
- `shop-empty` with min-height in input.css — PASS
- `@keyframes skeleton-shimmer` in input.css — PASS
- No hardcoded hex in new blocks: all use var(--*) — PASS
- `window.getProducts` in shop.html: 1 occurrence — PASS
- products.js before components.js in script order — PASS
- Activity tab @click for padel/pilates/tennis/training/running — PASS
- `x-show="category !== 'all'"` for sub-pill row — PASS
- href uses `/product.html?slug=` — PASS
- img src uses `?w=800&q=80` — PASS
- `history.replaceState` in syncURL — PASS
- `x-model="sort"` + `@change="fetchProducts()"` — PASS
- `Alpine.store('cart').add(` call — PASS
- empty state `x-show="!loading && products.length === 0"` — PASS
- Toastify CDN in head — PASS

## Self-Check: PASSED
