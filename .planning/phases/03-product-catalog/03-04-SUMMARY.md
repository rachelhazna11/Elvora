---
phase: 03-product-catalog
plan: 04
subsystem: frontend/pdp
tags: [pdp, alpine, swiper, modal, sticky-atc, accordion, focus-trap]
completed: 2026-06-14T09:00:00Z
duration: ~20min
tasks_completed: 2
tasks_total: 2
files_created: 0
files_modified: 2
requirements_addressed: [F-013, F-014, F-015, F-016]

dependency_graph:
  requires: [03-02, 03-03]
  provides: [product.html-pdp, css-pdp-components]
  affects: [components.js]

tech_stack:
  added:
    - Swiper.js v11 (CDN) — image carousel with thumbs module
  patterns:
    - Swiper thumbs-first init order (thumbs instance before main — Pitfall 2 prevention)
    - IntersectionObserver for sticky ATC bar visibility toggle
    - Manual focus trap via @keydown.window + trapFocus(e) method
    - Focus return on modal close (document.querySelector('.size-guide-btn')?.focus())
    - Alpine computed getters (uniqueColours, uniqueSizes) for deduplication
    - selectColour() syncing gallery slide index to colour variant first image

key_files:
  created: []
  modified:
    - product.html — full PDP: Swiper gallery, colour/size selectors, sticky ATC, size guide modal, accordion
    - src/input.css — PDP CSS: .swiper-main/.swiper-thumbs, .sticky-atc*, .size-guide-overlay/.size-guide-modal/.size-guide-close, .size-table, .accordion-*, .size-grid/.size-btn, .atc-main

decisions:
  - Swiper thumbs initialised FIRST before main Swiper instance (per RESEARCH.md Pitfall 2 — thumbs must exist before main references them)
  - loading: false set AFTER $nextTick (initSwiper + initStickyObserver) to ensure DOM is rendered before Swiper init
  - uniqueColours and uniqueSizes as Alpine computed getters (get prefix) to derive deduplicated arrays reactively from product.product_variants
  - trapFocus early-returns if showSizeGuide is false to avoid interfering with other keyboard events on the page
  - x-text used for all Supabase-sourced text fields (product name, fabric_details, care_instructions) — never x-html (T-03-15 XSS mitigation)
  - .atc-main implemented as standalone CSS class (not extending .btn-primary) to allow height:56px and w-full without conflicting with .btn-primary display:inline-block
---

# Phase 03 Plan 04: PDP Core Purchase Path Summary

**One-liner:** Full product.html PDP with Swiper.js gallery + thumbnail sync, colour swatch→slide navigation, size selector, sticky ATC bar via IntersectionObserver, size guide modal with focus trap, and fabric/care accordion — all driven from Supabase via window.getProduct().

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add PDP-specific CSS classes to src/input.css | b1d4b07 | src/input.css |
| 2 | Implement product.html PDP — core purchase path | 3bc1d57 | product.html |

---

## What Was Built

### Task 1 — PDP CSS Classes (src/input.css)

Added a new `/* ─── Product Detail Page ─── */` section after the existing PLP additions:

- **Swiper gallery:** `.swiper-main` (border-radius 16px), `.swiper-thumbs` (margin-top 12px), `.swiper-thumbs .swiper-slide` (opacity 0.5, transition), `.swiper-slide-thumb-active` (opacity 1)
- **Sticky ATC bar:** `.sticky-atc` (position fixed, bottom 0, z-index 90, height 64px, shadow), `.sticky-atc-name` (font-display, flex 1, truncate), `.sticky-atc-meta` (12px, muted), `.sticky-atc-price` (14px, semibold)
- **Size guide modal:** `.size-guide-overlay` (fixed inset, z-index 200, backdrop-filter blur), `.size-guide-modal` (white, border-radius 24px, max-height 80vh), `.size-guide-close` (absolute top-right, beige bg, rose-light hover)
- **Size chart:** `.size-table` (border-collapse), `.size-table th` (uppercase, beige bg), `.size-table td` (border-bottom sage)
- **Accordion:** `.accordion-item` (border-top), `.accordion-trigger` (flex space-between, uppercase 13px), `.accordion-body` (14px, 1.8 line-height)
- **Size selector:** `.size-grid` (flex wrap), `.size-btn` (border 1.5px, radius 8px, 12px), `.size-btn.selected` (charcoal fill), `.size-btn:disabled` (opacity 0.35)
- **ATC button:** `.atc-main` (56px height, full pill, disabled state opacity 0.7)

All values use `var(--*)` tokens — no hardcoded hex.

### Task 2 — product.html Full PDP

**Head additions:** Swiper CSS + JS CDN (v11 jsDelivr), Toastify CSS + JS CDN

**Script order:** `__env.js` → `supabase.js (module)` → `products.js (module)` → `components.js (module)` — products.js before components.js ensures window.getProduct available at Alpine init time.

**Alpine x-data state:**
- `product`, `loading`, `selectedColour`, `selectedSize`, `showSizeGuide`, `stickyVisible`, `accordionFabric`, `accordionCare`, `_mainSwiper`
- Computed getters: `uniqueColours` (deduplicated from product_variants by colour), `uniqueSizes` (deduplicated by size)

**Methods:**
- `init()` — reads `?slug=`, redirects to shop.html if missing/not found, sets product, calls `$nextTick(initSwiper + initStickyObserver)`, sets loading=false
- `initSwiper()` — thumbs Swiper FIRST (`spaceBetween:8, slidesPerView:4, freeMode, watchSlidesProgress`), then main Swiper (`thumbs:{swiper:thumbsSwiper}, lazy:{loadPrevNext:true}`)
- `initStickyObserver()` — IntersectionObserver on `.atc-main`, sets `stickyVisible = !e.isIntersecting`
- `openSizeGuide()` — sets showSizeGuide=true, `$nextTick` focuses first focusable in modal
- `closeSizeGuide()` — sets showSizeGuide=false, returns focus to `.size-guide-btn`
- `trapFocus(e)` — early-returns if !showSizeGuide; handles Tab/Shift+Tab cycles, Escape closes
- `addToBag()` — guards !selectedSize with alert; calls `Alpine.store('cart').add({productId, name, slug, colour, size, price})`; shows Toastify toast (charcoal bg, white text, bottom-right, 2.5s)
- `selectColour(colour)` — sets selectedColour, finds first image index for colour, calls `_mainSwiper.slideTo(idx)`

**HTML sections:**
- Loading skeleton: `.skeleton-shimmer` full-width shown while `loading: true`
- Two-column desktop layout: `lg:grid lg:grid-cols-2 lg:gap-16`
- Gallery (left): main Swiper `aspect-ratio:3/4`, thumbnail Swiper below, `x-for` over `product.product_images`, main images `?w=1200&q=80`, thumbnails `?w=200&q=60`
- Product info (right): h1 (clamp 22–28px), price, colour swatches with `pdp-swatch`, size grid with `size-btn`, main `atc-main` button
- Sticky ATC bar: product name (truncate), colour·size meta, price, compact ATC button; `x-show="stickyVisible"`, slide-up transition
- Size guide modal: overlay with `@click.self="closeSizeGuide()"`, `@keydown.window="trapFocus($event)"`; dialog `role="dialog" aria-modal="true" aria-labelledby="size-guide-title"`; size chart XS–XL (Bust/Waist/Hips in cm); "How to Measure" instructions
- Fabric & Care accordion: two `.accordion-item` blocks with `x-transition`, `aria-expanded`, `aria-controls`

**Accessibility (NF-003):**
- All text fields via `x-text` (XSS-safe per T-03-15)
- Size buttons: `aria-label`, `aria-pressed`, `aria-disabled` for sold-out
- Modal: `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, focus trap, Escape close, outside-click close, focus return to trigger
- Sticky ATC: `:aria-hidden="!stickyVisible"`
- Accordion: `aria-expanded`, `aria-controls`, `role="region"`

---

## Deviations from Plan

None — plan executed exactly as written. Minor implementation notes:

1. `$nextTick` in `openSizeGuide()` escaped as `this.$nextTick` (not `this.\$nextTick`) — standard Alpine method call inside x-data string template.
2. `loading: false` positioned after `$nextTick` call (not before) so DOM is rendered when Swiper.js initialises — prevents Swiper from finding an empty `.swiper-wrapper`.
3. `trapFocus` adds `if (!this.showSizeGuide) return` guard (not in plan spec) as Rule 2 addition — prevents the window keydown listener from interfering with keyboard navigation on the rest of the page when modal is closed.

---

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| `Alpine.store('cart').add()` — items not persisted | product.html | Phase 6 scope — cart store stub only |
| Colour swatch → gallery sync falls back gracefully if no image found for colour | product.html | Seed images may not be colour-tagged; graceful no-op |
| Wishlist button | not implemented in PDP | Phase 4 scope |

---

## Threat Flags

All threats from plan's threat model handled:
- T-03-14 (slug param → Supabase): window.getProduct uses `.eq('slug', slug)` — parameterized, no injection. Missing/invalid slug → redirect.
- T-03-15 (XSS via product data): all Supabase-sourced fields use `x-text` only — no `x-html` in product.html.
- T-03-18 (focus trap escape): `trapFocus()` handles Tab/Shift+Tab/Escape; focus returns to trigger on close.

No new threat surface beyond plan's threat model.

---

## Self-Check

**Files exist:**
- product.html: FOUND
- src/input.css: FOUND

**Commits exist:**
- b1d4b07: FOUND (CSS task)
- 3bc1d57: FOUND (product.html task)

**Acceptance criteria:**
- `swiper-main` in product.html: 2 occurrences — PASS
- `IntersectionObserver` in product.html: 1 occurrence — PASS
- Swiper CSS + JS CDN in head — PASS
- Toastify CSS + JS CDN in head — PASS
- products.js before components.js — PASS
- window.getProduct(slug) call in init() — PASS
- window.location.href = '/shop.html' redirect — PASS
- $nextTick + initSwiper + initStickyObserver — PASS
- swiper-thumbs init BEFORE swiper-main — PASS
- ?w=1200&q=80 for main images — PASS
- ?w=200&q=60 for thumbnails — PASS
- .sticky-atc with x-show="stickyVisible" — PASS
- :aria-hidden="!stickyVisible" on sticky bar — PASS
- role="dialog" + aria-modal="true" on modal — PASS
- @click.self="closeSizeGuide()" on overlay — PASS
- @keydown.window="trapFocus($event)" — PASS
- 5 size rows (XS, S, M, L, XL) in .size-table — PASS
- accordion-trigger with aria-expanded — PASS
- atc-main class on main ATC button — PASS
- Alpine.store('cart').add( call — PASS
- Toastify( call in addToBag() — PASS
- sticky-atc in src/input.css (4 occurrences) — PASS
- size-guide-overlay with z-index 200 — PASS

## Self-Check: PASSED
