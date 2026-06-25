# Phase 3: Product Catalog — Research

**Researched:** 2026-06-14
**Domain:** Alpine.js + Supabase product catalog (PLP + PDP), Swiper.js image gallery, URL-synced filtering, IntersectionObserver sticky bar, focus-trapped modal
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**PLP Activity Filter**
- D-01: Primary filter axis is activity (All, Padel, Pilates, Tennis, Training, Running), NOT garment type. Existing garment-type filters replaced entirely.
- D-02: Activity filtering queries Supabase via the `collection_products` join table. Activity tab mapping: Padel → `padel-edit`; Pilates → `studio-essentials`; Tennis → tennis collection (confirm from seed); Training → gym collections; Running → `run-era`.
- D-03: When an activity tab is selected, a second row of sub-category pills appears below the tabs (Padel → Matcha Babe, Court Crush, Rally Ready; etc.). Sub-categories map to named sub-collections in the `collections` table.
- D-04: Filter and sort state reflected in URL: `?category=padel&sub=matcha-babe&sort=price-asc`. Alpine reads `window.location.search` on init; browser back/forward restores state.
- D-05: Every tab/pill change fires a new Supabase query — no client-side-only filtering.

**Sort Options**
- D-06: Sort options: New Arrivals (default, `created_at` desc), Price Low–High, Price High–Low, Best Sellers (`is_best_seller = true` first, then `created_at`).

**Product Pairings**
- D-07: Add `product_pairings (product_id, paired_product_id, display_order)` via `supabase/migrations/002_product_pairings.sql`. RLS policy: public read.
- D-08: Planner writes `002_product_pairings.sql` and pairing seed rows (2–3 per product for all 22 products), activity-context-relevant.
- D-09: Blocking PLAN step must apply `002_product_pairings.sql` to Supabase via SQL Editor.

**PDP Image Gallery**
- D-10: Swiper.js v11 via CDN with thumbs module. CDN links: `https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.css` and `https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js`.
- D-11: Seed images are Unsplash CDN URLs. Apply `?w=1200&q=80` for main gallery, `?w=200&q=60` for thumbnails. Comment Supabase Storage transform pattern for Phase 7.

**PDP URL Routing**
- D-12: PDP URL uses `?slug=serenity-ribbed-legging`. Reads `URLSearchParams` for `slug`, queries `supabase.from('products').select(...).eq('slug', slug).single()`. PLP card links use `?slug=${p.slug}`.
- D-13: If slug not found → redirect to `/shop.html` immediately.

**Nav Search**
- D-14: Search icon triggers click-to-expand input in-place (Alpine `x-show` + transition). Expanded input overlays right side of nav.
- D-15: Search queries `.from('products').select('name, slug').ilike('name', '%query%').limit(6)`. Min 2 characters. Suggestion click → `product.html?slug=`. Enter → `shop.html?search=`.
- D-16: PLP consumes `?search=` URL param — pre-fill state and filter by name.
- D-17: `searchProducts(query)` in `js/products.js` implements the ilike query.

### Claude's Discretion

None specified — all major decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

- Real Supabase Storage image transforms (Unsplash URLs in Phase 3; Storage transforms activate in Phase 7)
- Review submission (display only, admin-seedable)
- Wishlist button active state (Phase 4 scope — render as static UI element)
- Promo code on ATC (Phase 6 scope)
- Advanced filtering (price range slider, size filter) — not in Phase 3 success criteria
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| F-008 | Product Listing Page — all active products, cards with image/name/price/swatches, load-more if >12 | Supabase query with joined images + variants; Alpine x-for rendering |
| F-009 | Activity Category Filtering — All/Padel/Pilates/Tennis/Training/Running; URL state; no full reload | collection_products join query; history.replaceState; Alpine reactive state |
| F-010 | Color Swatches on Product Cards — up to 4 swatches; hover updates card image; active swatch | Pre-loaded variant images in products array; Alpine x-bind:style swatch hover pattern |
| F-011 | Product Search with Autosuggest — header search; 2-char trigger; dropdown; Enter → PLP | ilike query on products; Alpine x-show dropdown; URLSearchParams |
| F-012 | Sort Options — New Arrivals/Price Low–High/Price High–Low/Best Sellers; URL state | Supabase .order() chaining; URL sync via history.replaceState |
| F-013 | Multi-Image Product Gallery — 3+ images; thumbnails; touch/swipe mobile | Swiper.js v11 thumbs module via CDN; lazy loading beyond first slide |
| F-014 | Sticky Add to Cart Bar — appears after scrolling past main ATC; shows name/size/colour/price | IntersectionObserver on .atc-main; Alpine stickyVisible reactive; x-show slide-up |
| F-015 | Size Guide Modal — modal overlay; size chart; closeable via button/Escape/outside; focus trap | Alpine x-show + x-transition; manual focus trap with Tab key intercept |
| F-016 | Fabric & Material Details — accordion or dedicated section; structured fields from Supabase | products.fabric_details + care_instructions columns; Alpine accordion pattern |
| F-017 | Complete the Look / Outfit Pairing — 2–3 cards; activity-relevant; from product_pairings table | New product_pairings table (migration 002); Supabase join query |
| F-018 | Related Products Grid — 4+ products from same activity category | Supabase query via collection_products filtering by category_id |
| F-019 | Customer Reviews on PDP — aggregate star rating; individual reviews; fit feedback; 5+ load-more | Supabase reviews table; client-side average calculation; .range() pagination |
</phase_requirements>

---

## Summary

Phase 3 is the largest feature phase in Elvora so far. It delivers two interconnected pages — the Product Listing Page (PLP, `shop.html`) and the Product Detail Page (PDP, `product.html`) — along with a database migration for product pairings and a nav search feature. The complexity comes not from any single unfamiliar technology but from the number of interlocking Alpine.js state machines, Supabase query patterns, and UI components that must all work together correctly.

The codebase is well-prepared for this phase. Phase 1 seeded 22 products across 7 garment categories, linked to 24 named collections (9 top-level + 15 sub-category collections). Phase 2 established the Alpine.js `x-data + init()` async pattern, the `Alpine.store('cart')` stub, and injected the nav/footer via `components.js`. The `js/products.js` stub and `js/subcategory-styles.js` authoritative source are in place. The existing `shop.html` is a hardcoded prototype that Phase 3 replaces entirely with Supabase-backed data.

The most technically intricate elements are: (1) the collection-slug-to-activity mapping, which requires understanding the seed data structure; (2) the Swiper.js thumbs configuration, which has a specific initialization order requirement; (3) the IntersectionObserver sticky ATC bar, which must be set up after the DOM renders; and (4) the focus trap in the size guide modal, which must be hand-rolled since no modal library is in the stack.

**Primary recommendation:** Plan in the order: migration 002 → `js/products.js` implementation → PLP rebuild → nav search → PDP implementation. The migration must be applied before any JS that references `product_pairings`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Product listing + filtering | Browser / Client | Supabase DB | Alpine.js owns UI state; Supabase owns data retrieval via collection_products join |
| Sort options | Browser / Client | Supabase DB | Sort is applied as Supabase `.order()` clause — server-side ordering, not client-side array sort |
| Activity → collection slug mapping | Browser / Client | — | Static lookup table baked into JS; no DB round-trip needed for the mapping itself |
| Sub-category pills | Browser / Client | Supabase DB | Slugs from `js/subcategory-styles.js`; display gated on Alpine active-activity state; products re-fetched via collection_products |
| URL state sync | Browser / Client | — | `history.replaceState` + `URLSearchParams` in Alpine `init()`; no server involvement |
| Nav search autosuggest | Browser / Client | Supabase DB | Search input in nav, dropdown rendered client-side; DB provides ilike name matches |
| Product card swatch hover | Browser / Client | — | Pre-loaded variant images in JS array; Alpine x-bind:style swap; no DB call on hover |
| PDP product data fetch | Browser / Client | Supabase DB | Single `.from('products').select(...).eq('slug', slug).single()` on page load |
| Image gallery (Swiper) | Browser / Client | — | CDN-loaded Swiper.js; images from Unsplash CDN |
| Colour swatch → image update | Browser / Client | — | Alpine `selectedColour` drives Swiper `slideTo()` call |
| Size selection | Browser / Client | — | Alpine `selectedSize` reactive state |
| Sticky ATC bar visibility | Browser / Client | — | IntersectionObserver on .atc-main button; drives Alpine `stickyVisible` |
| Size guide modal | Browser / Client | — | Static HTML table; Alpine x-show; manual focus trap |
| Fabric/care accordion | Browser / Client | — | Data from Supabase products row; Alpine `open` toggle |
| Product pairings ("Complete the Look") | Browser / Client | Supabase DB | `product_pairings` join query; rendered as product cards |
| Related products | Browser / Client | Supabase DB | collection_products query for same category |
| Customer reviews | Browser / Client | Supabase DB | reviews table; `.range()` pagination; client-side average calculation |
| Add to Cart (stub) | Browser / Client | — | `Alpine.store('cart').add()` stub; Toastify notification |

---

## Standard Stack

### Core (locked by CLAUDE.md — no alternatives)

| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| Alpine.js | 3.15.12 (CDN) | Reactive UI: x-data, x-show, x-for, Alpine.store | Already loaded in all HTML files |
| Supabase JS SDK | 2.x (CDN ESM) | All DB queries via `js/supabase.js` singleton | Already wired; import `{ supabase }` |
| Tailwind CSS v4 | 4.x CLI | Utility classes + design tokens | CLI builds `css/style.css` at deploy time |
| Swiper.js | 11.x (CDN) | PDP image gallery with thumbs module | CDN — add to `product.html` head only |
| Toastify-js | 1.x (CDN) | "Added to Bag" toast notification | Add to `product.html`; optional on `shop.html` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| IntersectionObserver API | Native browser | Sticky ATC bar trigger | No library needed — native in all modern browsers |
| URLSearchParams API | Native browser | URL state read/write | Available as `new URLSearchParams(window.location.search)` |
| history.replaceState | Native browser | URL sync without page reload | Called on every filter/sort change |

### CDN Additions Required for Phase 3

Add to `product.html` `<head>` (not in `shop.html`):
```html
<!-- Swiper.js v11 -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.css">
<script src="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js"></script>
<!-- Toastify-js -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
<script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
```

Add Toastify to `shop.html` if ATC stub is wired there too:
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
<script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
```

**Note:** These are CDN `<script>` tags, not npm installs. The project's CDN-first convention (CLAUDE.md) applies — no `npm install` for these libraries.

---

## Package Legitimacy Audit

Phase 3 installs no npm packages. All libraries are loaded via CDN `<script>` and `<link>` tags in HTML. The CDN host is jsDelivr (`cdn.jsdelivr.net`), a well-established public CDN. No registry audit step required.

| Library | Delivery | Status |
|---------|----------|--------|
| Swiper.js v11 | jsDelivr CDN | Established open-source library, MIT license, widely used |
| Toastify-js | jsDelivr CDN | Established lightweight library, MIT license |
| Alpine.js | jsDelivr CDN | Already in project |
| Supabase JS | jsDelivr CDN (ESM) | Already in project |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Browser
│
├── shop.html (PLP)
│   ├── x-data Alpine component (init reads URL params → fetch)
│   │   ├── getProducts(filters) ← js/products.js
│   │   │   └── Supabase: products JOIN collection_products JOIN collections
│   │   │       → filtered by collection slug (activity tab + sub-category)
│   │   │       → ordered by sort option
│   │   ├── searchProducts(query) ← js/products.js (via ?search= param)
│   │   ├── URL sync (history.replaceState on tab/pill/sort change)
│   │   └── x-for → product card grid
│   │         └── swatch hover → x-bind:style (pre-loaded variant images)
│   │
│   └── nav extension (components.js)
│       └── search expand/collapse → searchProducts() autosuggest
│           └── Supabase: products ilike('name', '%query%').limit(6)
│
├── product.html (PDP)
│   ├── x-data Alpine component (init reads ?slug= → fetch product)
│   │   ├── getProduct(slug) ← js/products.js
│   │   │   └── Supabase: products + variants + images + pairings + reviews
│   │   ├── Swiper.js thumbs gallery (CDN)
│   │   │   └── main image + thumbnail strip
│   │   ├── selectedColour / selectedSize (reactive)
│   │   ├── showSizeGuide modal (x-show + focus trap)
│   │   ├── stickyVisible (IntersectionObserver on .atc-main)
│   │   ├── accordion open/close states
│   │   └── reviews load-more (Supabase .range())
│   │
│   └── Alpine.store('cart').add() → Toastify toast
│
└── Supabase PostgreSQL
    ├── products (22 rows)
    ├── product_variants (220 rows)
    ├── product_images (44 rows)
    ├── collections (24 rows: 9 top-level + 15 sub-category)
    ├── collection_products (join)
    ├── product_pairings (NEW — migration 002)
    ├── categories (7 rows)
    └── reviews (32 rows)
```

### Recommended Project Structure

No new directories needed. Phase 3 touches these existing files:

```
.
├── shop.html              ← Full rewrite (PLP)
├── product.html           ← Full implementation (PDP main)
├── js/
│   ├── products.js        ← Implement all 4 stub functions
│   └── components.js      ← Extend nav with search expand/collapse
├── src/
│   └── input.css          ← Add new CSS classes for PLP/PDP components
└── supabase/
    ├── migrations/
    │   └── 002_product_pairings.sql    ← NEW
    └── seed.sql or seed_pairings.sql   ← Add pairing rows
```

---

### Pattern 1: Supabase Query with Collection Join (PLP Filter)

The PLP activity filter maps human tab names to collection slugs, then joins via `collection_products`.

```javascript
// Source: Supabase JS SDK docs + seed.sql analysis
// js/products.js — getProducts implementation

export async function getProducts(filters = {}) {
  const { category, sub, sort, search } = filters;

  // Activity tab → collection slug mapping (confirmed from seed.sql)
  const ACTIVITY_SLUGS = {
    'padel':    'padel-edit',
    'pilates':  'studio-essentials',
    'tennis':   'love-match',   // seed has love-match, ace-energy, court-girl — use parent padel-edit equivalent
    'training': 'power-mood',   // gym sub-collections: power-mood, built-different, hot-girl-lift
    'running':  'run-era',
  };

  let query = supabase
    .from('products')
    .select(`
      id, name, slug, base_price, is_best_seller, created_at,
      product_images (url, alt_text, display_order, colour),
      product_variants (id, colour, colour_hex, size, stock_quantity)
    `)
    .eq('is_active', true);

  // Apply search filter
  if (search) {
    query = query.ilike('name', `%${search}%`);
  }

  // Apply activity/sub-category filter via collection join
  if (category && category !== 'all') {
    const slug = sub || ACTIVITY_SLUGS[category];
    if (slug) {
      // Filter via collection_products join
      const { data: colProducts } = await supabase
        .from('collection_products')
        .select('product_id')
        .eq('collection_id', await getCollectionIdBySlug(slug));
      const ids = (colProducts || []).map(r => r.product_id);
      if (ids.length > 0) {
        query = query.in('id', ids);
      } else {
        return { data: [], error: null }; // No products in collection
      }
    }
  }

  // Apply sort
  switch (sort) {
    case 'price-asc':  query = query.order('base_price', { ascending: true }); break;
    case 'price-desc': query = query.order('base_price', { ascending: false }); break;
    case 'best-sellers':
      query = query.order('is_best_seller', { ascending: false }).order('created_at', { ascending: false });
      break;
    default: // 'new-arrivals'
      query = query.order('created_at', { ascending: false });
  }

  return query;
}
```

**Note on multi-collection activity filtering:** For "Training" (maps to 3 gym collections: power-mood, built-different, hot-girl-lift) and "Tennis" (maps to 3 tennis sub-collections), the query must collect product IDs from multiple collection slugs and use `.in('id', combinedIds)`. See Pattern 3 below.

[ASSUMED] — exact multi-slug union approach; planner should verify all collection slugs cover the intended product set.

---

### Pattern 2: Swiper.js v11 Thumbs Configuration (PDP)

Swiper thumbs requires two separate Swiper instances initialized in a specific order: thumbnails first, then main slider.

```javascript
// Source: Swiper.js v11 docs [ASSUMED — confirmed pattern from Swiper documentation]

// Initialize thumbnail swiper first
const thumbsSwiper = new Swiper('.swiper-thumbs', {
  spaceBetween: 8,
  slidesPerView: 4,
  freeMode: true,
  watchSlidesProgress: true,
  direction: 'horizontal',
});

// Initialize main swiper second, referencing thumbs
const mainSwiper = new Swiper('.swiper-main', {
  spaceBetween: 0,
  loop: false,        // No loop — avoids index confusion with colour swatch switching
  lazy: true,         // Lazy-load images beyond first slide
  thumbs: {
    swiper: thumbsSwiper,
  },
});

// To jump to a specific colour's first image, use:
// mainSwiper.slideTo(imageIndexForColour);
```

**Critical:** Swiper must be initialized AFTER Alpine has rendered the image elements into the DOM. Use `Alpine.nextTick(() => { /* init Swiper */ })` or a `setTimeout(0)` inside the Alpine `init()` method.

---

### Pattern 3: Multi-Collection Activity Filter

"Training" and "Tennis" each map to multiple named sub-collections. For the "All Training" tab (no sub-pill selected), merge products from all gym collections:

```javascript
// Source: seed.sql analysis [VERIFIED from seed.sql]
const MULTI_SLUG_ACTIVITIES = {
  'training': ['power-mood', 'built-different', 'hot-girl-lift'],
  'tennis':   ['love-match', 'ace-energy', 'court-girl'],
  'padel':    ['padel-edit', 'matcha-babe', 'court-crush', 'rally-ready'],
  'pilates':  ['studio-essentials', 'soft-flow', 'main-character', 'studio-muse'],
  'running':  ['run-era', 'pace-mode', 'runners-high'],
};

// When sub is not selected, fetch all product_ids from the activity's slug list
async function getProductIdsForActivity(activity) {
  const slugs = MULTI_SLUG_ACTIVITIES[activity];
  const { data: cols } = await supabase
    .from('collections')
    .select('id')
    .in('slug', slugs);
  const colIds = cols.map(c => c.id);
  const { data: cp } = await supabase
    .from('collection_products')
    .select('product_id')
    .in('collection_id', colIds);
  return [...new Set(cp.map(r => r.product_id))];
}
```

**Important caveat:** The seed `collection_products` only assigns products to the top-level named collections (padel-edit, studio-essentials, run-era, etc.) — the 15 sub-category collections (matcha-babe, court-crush, etc.) have **no products assigned in the current seed**. The planner must either: (a) add sub-category product assignments to the seed, or (b) use the top-level activity collections only for the activity tab filter and sub-category collections for sub-pill filter (when sub-pilling is added in Phase 3). [VERIFIED: seed.sql — Section 6 shows only 6 collections have product assignments; sub-category collections b000…010 through b000…021 have no entries]

---

### Pattern 4: URL State Sync (PLP)

```javascript
// Source: Web platform APIs [ASSUMED — standard pattern]

// On filter/sort change:
function syncURL(state) {
  const params = new URLSearchParams();
  if (state.category && state.category !== 'all') params.set('category', state.category);
  if (state.sub) params.set('sub', state.sub);
  if (state.sort && state.sort !== 'new-arrivals') params.set('sort', state.sort);
  if (state.search) params.set('search', state.search);
  const qs = params.toString();
  history.replaceState(null, '', qs ? `?${qs}` : window.location.pathname);
}

// On Alpine init():
async init() {
  const params = new URLSearchParams(window.location.search);
  this.category = params.get('category') || 'all';
  this.sub = params.get('sub') || null;
  this.sort = params.get('sort') || 'new-arrivals';
  this.search = params.get('search') || '';
  await this.fetchProducts();
}
```

---

### Pattern 5: IntersectionObserver for Sticky ATC

```javascript
// Source: Web platform APIs [ASSUMED — standard IntersectionObserver pattern]

// Inside Alpine init() after DOM is ready:
const atcButton = document.querySelector('.atc-main');
if (atcButton) {
  const observer = new IntersectionObserver(([entry]) => {
    this.stickyVisible = !entry.isIntersecting;
  }, { threshold: 0 });
  observer.observe(atcButton);
}
// Note: this.stickyVisible drives x-show on .sticky-atc
```

---

### Pattern 6: Manual Focus Trap (Size Guide Modal)

Alpine provides no built-in focus trap. Must be hand-rolled:

```javascript
// Source: WCAG 2.1 focus trap pattern [ASSUMED — standard accessibility pattern]

// Inside Alpine x-data:
trapFocus(e) {
  const modal = document.querySelector('.modal-content');
  const focusable = modal.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  if (e.key === 'Tab') {
    if (e.shiftKey) {
      if (document.activeElement === first) { e.preventDefault(); last.focus(); }
    } else {
      if (document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  }
  if (e.key === 'Escape') { this.showSizeGuide = false; }
},
openSizeGuide() {
  this.showSizeGuide = true;
  this.$nextTick(() => {
    const modal = document.querySelector('.modal-content');
    const first = modal.querySelector('button, [href], input');
    if (first) first.focus();
    modal.addEventListener('keydown', this.trapFocus.bind(this));
  });
},
closeSizeGuide() {
  this.showSizeGuide = false;
  document.querySelector('.modal-content')?.removeEventListener('keydown', this.trapFocus.bind(this));
  document.querySelector('.size-guide-link')?.focus(); // return focus
}
```

---

### Pattern 7: Nav Search Expand/Collapse in components.js

The nav is injected as an HTML string by `components.js`. Phase 3 must extend the root `x-data` block in `navHTML` to include search state:

```javascript
// Extend navHTML x-data in components.js:
x-data="{
  navOpen: false,
  scrolled: false,
  searchOpen: false,
  searchQuery: '',
  suggestions: [],
  searching: false,
  async init() {
    window.addEventListener('scroll', () => {
      this.scrolled = window.scrollY > 80;
    }, { passive: true });
  },
  async onSearchInput() {
    if (this.searchQuery.length < 2) { this.suggestions = []; return; }
    // debounce 300ms via setTimeout, clear on next input
    clearTimeout(this._searchTimer);
    this._searchTimer = setTimeout(async () => {
      const { data } = await supabase
        .from('products')
        .select('name, slug')
        .ilike('name', '%' + this.searchQuery + '%')
        .limit(6);
      this.suggestions = data || [];
    }, 300);
  },
  goToSearch() {
    if (this.searchQuery.trim()) {
      window.location.href = '/shop.html?search=' + encodeURIComponent(this.searchQuery);
    }
  }
}"
```

Add the search input + dropdown HTML inside the nav actions div, using `x-show="searchOpen"` for the input and `x-show="suggestions.length > 0 && searchOpen"` for the dropdown.

---

### Pattern 8: Reviews Load More

```javascript
// Source: Supabase JS SDK range pagination [ASSUMED — standard SDK pattern]

// Alpine state:
reviews: [],
reviewsOffset: 0,
reviewsPageSize: 5,
reviewsTotal: 0,
allReviewsLoaded: false,

async loadReviews() {
  const { data, count } = await supabase
    .from('reviews')
    .select('*', { count: 'exact' })
    .eq('product_id', this.product.id)
    .order('created_at', { ascending: false })
    .range(this.reviewsOffset, this.reviewsOffset + this.reviewsPageSize - 1);
  this.reviews = [...this.reviews, ...(data || [])];
  this.reviewsOffset += this.reviewsPageSize;
  if (count !== null) this.reviewsTotal = count;
  this.allReviewsLoaded = this.reviews.length >= this.reviewsTotal;
},

// Aggregate star rating (computed client-side):
get averageRating() {
  if (!this.reviews.length) return 0;
  return (this.reviews.reduce((s, r) => s + r.rating, 0) / this.reviews.length).toFixed(1);
}
```

---

### Anti-Patterns to Avoid

- **Using `select('*')` with joins:** Pulls all columns including unused ones. Always specify explicit column lists in `.select()` — per NF-002 performance requirement and UI-SPEC performance contract.
- **Initializing Swiper synchronously in Alpine `init()`:** Swiper requires DOM elements to exist. Alpine renders templates asynchronously. Always use `this.$nextTick(() => { /* init Swiper */ })` inside `init()`.
- **Client-side-only filtering:** D-05 explicitly forbids this. Every filter/sort change must fire a new Supabase query. Do not filter the existing `products` array.
- **Nested Supabase `select()` strings longer than needed:** Over-fetching all review columns on the PLP is wasteful. Reviews are fetched only on the PDP.
- **Applying Supabase transform params to Unsplash URLs:** `?width=800&quality=80` is for Supabase Storage hosted files. Unsplash format is `?w=800&q=80`. D-11 explicitly calls this out.
- **Redefining `--color-sage`, `--color-beige`, etc. in new CSS:** These are in `src/input.css`. Use the tokens — never add duplicates.
- **Hard-coding collection IDs:** Query by slug, not by the UUID constants from seed.sql. Slug is the stable identifier.

---

## Confirmed Collection-Slug → Activity Mapping

[VERIFIED: seed.sql Section 2 and Section 6]

The seed defines 24 collections. Only 6 have products assigned in `collection_products` (Section 6). The 15 sub-category collections (IDs 10–21 in seed) have no product assignments.

| Activity Tab | Top-Level Collection Slug | Products in Seed | Sub-Category Slugs (no products yet) |
|---|---|---|---|
| All | (no filter) | all 22 | — |
| Padel | `padel-edit` | P10, P11, P12, P19 | matcha-babe, court-crush, rally-ready |
| Pilates | `studio-essentials` | P01, P02, P03, P06, P07, P08 | soft-flow, main-character, studio-muse |
| Tennis | (no top-level tennis collection exists) | — | love-match, ace-energy, court-girl |
| Training | (no top-level gym collection exists) | — | power-mood, built-different, hot-girl-lift |
| Running | `run-era` | (empty in seed — no products assigned to b000…007) | pace-mode, runners-high |

**Critical gap discovered:** The seed has no tennis or training top-level collection. The activity tabs "Tennis" and "Training" have no product assignments in `collection_products`. Additionally, the "Running" `run-era` collection has no products in it despite existing. The planner MUST include a task to add product-to-collection assignments for Tennis, Training, and Running sub-collections to `supabase/seed.sql` (or a patch SQL) as part of Phase 3 Wave 0.

**Recommendation for planner:** In the `002_product_pairings.sql` migration (or a companion `002_collection_assignments.sql`), add `collection_products` rows to assign products to the missing activity collections:
- Tennis (love-match, ace-energy, court-girl): assign skirts P10, P11, P12 + relevant bras/tops
- Training (power-mood, built-different, hot-girl-lift): assign leggings P01–P05, bras P06–P09, jackets P16
- Running (run-era, pace-mode, runners-high): assign P05 (Contour Pocket Legging), P09 (Aura High Support Bra), P15 (Vital Long Sleeve Top)

[ASSUMED] — exact product-to-collection mapping for tennis/training/running; planner must make final decisions based on product descriptions in seed.sql.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image carousel / gallery swipe | Custom JS touch handler | Swiper.js v11 thumbs | Touch normalization, lazy-load, keyboard navigation, RTL support — 100+ edge cases |
| Toast notifications | Custom DOM-append JS | Toastify-js | Position management, auto-dismiss, queuing, accessibility announcements |
| Image lazy loading | Custom IntersectionObserver | `loading="lazy"` HTML attribute | Browser-native; no JS overhead; works with Swiper's own lazy option |
| Product search debounce | Re-invent debounce | `clearTimeout` / `setTimeout` inline in Alpine | Sufficient at this scale; no library needed |
| Supabase auth session management | Custom JWT handling | `supabase.auth.onAuthStateChange` | SDK handles JWT refresh automatically |

**Key insight:** This phase's complexity is in orchestrating Alpine state machines across a large page, not in any single algorithmic challenge. Resist the urge to add more libraries — the stack is intentionally minimal.

---

## Runtime State Inventory

Not applicable — Phase 3 is a greenfield page implementation and schema addition, not a rename/refactor. The new `product_pairings` table is net-new; no existing runtime state is being migrated.

---

## Common Pitfalls

### Pitfall 1: Sub-Category Collections Have No Product Assignments in Seed
**What goes wrong:** Clicking "Matcha Babe" sub-pill returns 0 products — the collection exists in the `collections` table but no rows in `collection_products` point to it.
**Why it happens:** The seed (`seed.sql` Section 6) only assigns products to the 6 top-level collections. The 15 sub-category collections were added later as visual UI slugs with no product assignments.
**How to avoid:** Include a Wave 0 task to add `collection_products` rows for Tennis, Training, Running activity collections AND at least 2–3 products per sub-category collection so the filter actually works.
**Warning signs:** Empty grid when selecting any activity tab except Padel, Pilates, or clicking a sub-pill.

### Pitfall 2: Swiper Initialized Before Alpine Renders Template
**What goes wrong:** `new Swiper('.swiper-main', ...)` finds no DOM elements; gallery is broken.
**Why it happens:** Alpine's `x-for` and `x-show` run asynchronously after `init()` starts. The Swiper DOM elements from templates don't exist yet.
**How to avoid:** Always wrap Swiper init in `this.$nextTick(() => { ... })` inside the Alpine `init()` method.
**Warning signs:** `Swiper` initializes with 0 slides; no images visible; console error about missing `.swiper-wrapper`.

### Pitfall 3: Applying Supabase Storage Transforms to Unsplash URLs
**What goes wrong:** Images return 404 or broken when appending `?width=1200&quality=80` to Unsplash URLs.
**Why it happens:** Supabase Storage's image transform API uses `?width=&quality=` params, but Unsplash CDN uses `?w=&q=`. They are different query parameter APIs.
**How to avoid:** D-11 is explicit: use `?w=1200&q=80` for Unsplash URLs. Add a code comment in `getProduct()` documenting the Supabase Storage transform format for Phase 7.
**Warning signs:** Product images render broken or return 404 on PDP.

### Pitfall 4: Alpine `init()` Not Awaiting URL Param Reading
**What goes wrong:** Filter state doesn't restore on page load when URL has query params (browser back/forward broken).
**Why it happens:** Alpine `init()` must be `async` and must read URL params and set state BEFORE the first `fetchProducts()` call. If the fetch fires before params are read, the initial load ignores the URL state.
**How to avoid:** Structure init as: `async init() { /* 1. read URL params */ /* 2. set state */ /* 3. await fetchProducts() */ }`.
**Warning signs:** Page with `?category=padel` in URL loads all products instead of Padel-filtered products.

### Pitfall 5: Focus Not Returned After Modal Close
**What goes wrong:** After closing the size guide modal, keyboard focus is lost (returns to `<body>`). Accessibility failure per NF-003.
**Why it happens:** `x-show="false"` removes the modal from visibility but does not manage focus.
**How to avoid:** On modal close, explicitly `.focus()` the element that opened the modal (the "Size Guide" link/button). Store a reference before opening.
**Warning signs:** After pressing Escape to close modal, Tab key jumps to top of page rather than continuing from where user was.

### Pitfall 6: Toastify Not Available on shop.html
**What goes wrong:** `Toastify is not defined` error when product card ATC stub fires.
**Why it happens:** Toastify CDN is only added to `product.html` but the ATC button on PLP cards also calls `Alpine.store('cart').add()` and may attempt a toast.
**How to avoid:** Either add Toastify CDN to `shop.html` as well, or make the toast call conditional on `window.Toastify !== undefined`.

### Pitfall 7: reviews Table Has No `total_count` Column — Client-Side Averaging Required
**What goes wrong:** Displaying a "4.8 average rating" that's actually wrong because only the first 5 reviews were loaded.
**Why it happens:** F-019 says "initial load: 5 reviews". The `averageRating` computed from those 5 won't match the true average across all 32 reviews.
**How to avoid:** Do a separate Supabase query `select('rating', { count: 'exact' })` with no range limit to get all ratings for the average calculation, separate from the paginated review text query.

### Pitfall 8: `?search=` param on PLP vs. nav autosuggest
**What goes wrong:** Nav search and PLP search state get out of sync — typing in the nav doesn't update the PLP filter if the user is already on `shop.html`.
**Why it happens:** The nav search (in `components.js`) and the PLP Alpine x-data are separate scopes. They don't share state.
**How to avoid:** On PLP (`shop.html`), if the nav is on the same page, implement a `popstate` listener or use `Alpine.store('search')` to bridge state. Simpler: pressing Enter in nav search always navigates to `shop.html?search=` even if already on `shop.html` (causes a reload but avoids sync complexity).

---

## Code Examples

### PLP Product Card with Colour Swatch Hover

```html
<!-- Source: Alpine.js x-for pattern + seed.sql schema [ASSUMED pattern] -->
<template x-for="p in products" :key="p.id">
  <a :href="'/product.html?slug=' + p.slug" class="product-card">
    <div class="product-img">
      <img
        :src="p.activeImage + '?w=800&q=80'"
        :alt="p.name"
        width="400" height="533"
        loading="lazy"
        class="w-full h-full object-cover object-top"
      >
      <button
        class="wishlist-btn"
        @click.prevent
        aria-label="Save to wishlist"
      >♡</button>
    </div>
    <div class="product-info">
      <h3 x-text="p.name" class="product-name"></h3>
      <p x-text="'$' + p.base_price.toFixed(2)" class="product-price"></p>
      <div class="swatches">
        <template x-for="v in p.uniqueColours" :key="v.colour">
          <button
            :style="'background-color:' + v.colour_hex"
            :class="p.activeColour === v.colour ? 'swatch active' : 'swatch'"
            :aria-label="v.colour"
            :aria-pressed="p.activeColour === v.colour"
            @mouseenter="p.activeColour = v.colour; p.activeImage = v.image"
            @mouseleave="p.activeColour = p.defaultColour; p.activeImage = p.defaultImage"
            @click.prevent="p.activeColour = v.colour; p.activeImage = v.image"
          ></button>
        </template>
      </div>
      <button
        class="add-cart-btn"
        @click.prevent="Alpine.store('cart').add({ productId: p.id, slug: p.slug })"
      >Add to Bag</button>
    </div>
  </a>
</template>
```

### `getProduct()` Supabase Query Pattern

```javascript
// Source: Supabase JS SDK [ASSUMED — confirmed SDK pattern]
export async function getProduct(slug) {
  const { data, error } = await supabase
    .from('products')
    .select(`
      id, name, slug, description, base_price, fabric_details,
      care_instructions, styling_suggestions,
      product_images (id, url, alt_text, display_order, colour),
      product_variants (id, colour, colour_hex, size, stock_quantity),
      categories (name, slug)
    `)
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (error || !data) return null;
  return data;
}
```

### `002_product_pairings.sql` Structure

```sql
-- Source: seed.sql pattern + CONTEXT.md D-07 [VERIFIED from CONTEXT.md decisions]

create table if not exists product_pairings (
  product_id        uuid not null references products(id) on delete cascade,
  paired_product_id uuid not null references products(id) on delete cascade,
  display_order     integer not null default 0,
  primary key (product_id, paired_product_id)
);

alter table product_pairings enable row level security;

create policy "product_pairings_public_read"
  on product_pairings for select
  using (true);

create policy "product_pairings_admin_write"
  on product_pairings for all
  using (is_admin())
  with check (is_admin());
```

### Toastify Call Pattern

```javascript
// Source: Toastify-js docs [ASSUMED]
Toastify({
  text: "Added to Bag",
  duration: 2500,
  gravity: "bottom",
  position: "right",
  style: {
    background: "var(--charcoal)",
    color: "#ffffff",
    borderRadius: "50px",
    fontSize: "12px",
    letterSpacing: "2px",
  },
}).showToast();
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|---|---|---|
| `product.html?id=123` (UUID in URL) | `product.html?slug=serenity-ribbed-legging` | D-12: slug is human-readable, SEO-friendly, stable |
| Hardcoded Alpine x-data in shop.html | Supabase-fetched data in Alpine init() | Phase 3 replaces the entire hardcoded prototype |
| Garment-type filters (leggings/tops/jackets) | Activity filters (Padel/Pilates/Tennis/Training/Running) | D-01: activity is the primary discovery axis |
| No search | Click-to-expand nav search with autosuggest | D-14/D-15 |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Tennis activity maps to love-match/ace-energy/court-girl sub-collections | Architecture Patterns, Pattern 1 | Wrong products shown under Tennis tab — planner must confirm from product descriptions |
| A2 | Training activity maps to power-mood/built-different/hot-girl-lift sub-collections | Architecture Patterns, Pattern 1 | Wrong products shown under Training tab |
| A3 | Focus trap implementation via manual keydown listener is sufficient for WCAG AA modal | Pattern 6 | May have edge cases with browser-native focus management; test with keyboard |
| A4 | Swiper.js v11 thumbs initialization requires thumbs instance first, then main | Pattern 2 | Gallery broken if order is wrong; verify against Swiper v11 official docs |
| A5 | Separate aggregate-rating query (all ratings) vs paginated review-text query is the correct approach | Pitfall 7 | Rating calculation wrong if not all ratings fetched |
| A6 | Product-to-sub-collection assignment for Tennis, Training, Running needs to be added in Phase 3 | Pitfall 1 | Activity filter tabs return 0 products for those activities |

---

## Open Questions (RESOLVED)

1. **Tennis and Training top-level collection slugs**
   - What we know: Seed has no `padel-tennis` or `training` top-level collection; sub-category collections exist (love-match, power-mood, etc.)
   - What's unclear: Which specific products (by slug) should be assigned to Tennis, Training, and Running sub-collections in the Phase 3 seed patch?
   - Recommendation: Planner reviews product descriptions in seed.sql and makes assignments based on activity context (skirts -> tennis/padel, leggings + bras -> gym/running, long sleeves -> running)
   - **RESOLVED in Plan 03-01 Task 2:** `002_collection_assignments.sql` adds explicit `collection_products` rows assigning Tennis products (P10-P12 skirts + P18 shorts + P19 skirt -> love-match, ace-energy, court-girl), Training products (P01-P05 leggings + P06-P09 bras + P16 jacket -> power-mood, built-different, hot-girl-lift), and Running products (P05, P09, P15 -> run-era, pace-mode, runners-high). Activity slugs are multi-slug unions handled by `getProductIdsForActivity()` in `js/products.js`.

2. **Swiper lazy loading vs. Alpine x-bind:src**
   - What we know: Swiper has built-in `lazy: true` which uses `swiper-lazy` class on `<img>`. Alpine may want to bind `:src` dynamically. These can conflict.
   - What's unclear: Whether to use Swiper's native lazy or Alpine-driven src binding for gallery images
   - Recommendation: Use Swiper's native lazy loading (`lazy: { loadPrevNext: true }`) for all slides beyond the first. The first slide uses `fetchpriority="high"` and no lazy attribute.
   - **RESOLVED in Plan 03-04 Task 1:** Swiper's native `lazy: { loadPrevNext: true }` is used. The first slide image is rendered with `fetchpriority="high"` and no lazy attribute; all subsequent slides use the `swiper-lazy` class pattern. No Alpine `:src` binding on gallery images -- Swiper owns the src after `$nextTick` initialization.

3. **Sub-category pill counts**
   - What we know: Sub-pills appear for all 15 sub-categories under their respective activity tabs
   - What's unclear: Whether to show a count badge (e.g., "Matcha Babe (3)") on each pill -- not specified in CONTEXT.md
   - Recommendation: Omit counts in Phase 3 MVP; pills show name only
   - **RESOLVED in Plan 03-02 Task 2:** Pills display name only (no count badge). This matches the locked decisions (CONTEXT.md has no count badge requirement) and keeps the PLP UI uncluttered at assessment scale.
---

## Environment Availability

Phase 3 is code + SQL + CDN changes only. No new external tools or services needed beyond what Phase 1-2 established.

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Supabase project | All data queries | Live (established Phase 1) | Must apply migration 002 via SQL Editor before testing |
| Netlify deployment | Testing on live URL | Live (established Phase 1) | Phase 3 requires Tailwind rebuild at deploy |
| jsDelivr CDN | Swiper.js, Toastify | Public CDN — always available | No credentials needed |
| Google Fonts CDN | Typography | Already loaded in HTML | No change needed |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

`workflow.nyquist_validation: true` — section required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — project uses manual browser testing (no Jest/Vitest/Playwright configured) |
| Config file | None |
| Quick run command | Open `shop.html` in browser, check console for errors |
| Full suite command | Manual walkthrough of all 5 PLP success criteria + 5 PDP success criteria per CONTEXT.md |

Phase 3 is a vanilla HTML/JS/Alpine.js project with no npm test runner. Tests are manual browser-based verification. The success criteria in CONTEXT.md serve as the test checklist.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Verification Method |
|--------|----------|-----------|---------------------|
| F-008 | All active products shown on PLP | Manual | Open shop.html, count cards match Supabase products count |
| F-009 | Activity filter + URL state | Manual | Click Padel tab → URL shows `?category=padel` → grid shows padel products only |
| F-010 | Colour swatch hover updates card image | Manual | Hover swatch on card → image changes |
| F-011 | Search autosuggest | Manual | Type "serenity" → dropdown shows matching names |
| F-012 | Sort options + URL | Manual | Select "Price: Low to High" → URL shows `?sort=price-asc` → grid reorders |
| F-013 | Swiper gallery + swipe | Manual | PDP: swipe gallery on mobile → image changes; click thumbnail → main image updates |
| F-014 | Sticky ATC appears after scroll | Manual | PDP: scroll past main ATC → sticky bar slides in from bottom |
| F-015 | Size guide modal + focus trap | Manual | Click "Size Guide" → modal opens; Tab cycles within modal; Escape closes |
| F-016 | Fabric accordion | Manual | PDP: click "Materials" accordion → expands; click again → collapses |
| F-017 | Complete the Look cards | Manual | PDP: "Complete the Look" section shows 2–3 product cards |
| F-018 | Related products | Manual | PDP: "You Might Also Love" shows 4 products from same activity |
| F-019 | Reviews + load more | Manual | PDP: 5 reviews show; click "Load More" → additional reviews appear |

### Wave 0 Gaps

- [ ] Sub-category collection product assignments — SQL patch needed before any filter testing
- [ ] `002_product_pairings.sql` applied to Supabase before PDP "Complete the Look" can be tested
- [ ] Toastify CDN must be added to HTML files before ATC stub can fire toast

---

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1` — section required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | Phase 3 has no auth operations |
| V3 Session Management | No | Auth is read-only (`Alpine.store('auth')` stub — Phase 4 scope) |
| V4 Access Control | Partial | RLS on `product_pairings` must be: public SELECT, admin-only INSERT/UPDATE/DELETE — enforced at DB level |
| V5 Input Validation | Yes | Search input: min 2 chars enforced client-side; Supabase SDK uses parameterized queries (no SQL injection possible via ilike) |
| V6 Cryptography | No | No encryption operations in Phase 3 |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via search input | Tampering | Supabase JS SDK `.ilike()` uses parameterized queries — immune to SQL injection |
| Unsanitized product slug in URL | Tampering | `URLSearchParams.get('slug')` is a string; passed to `.eq('slug', slug).single()` — parameterized; if no match, redirects to shop.html (D-13) |
| XSS via product name/description | Tampering | Alpine.js `x-text` binds text content, not innerHTML — XSS-safe for text; avoid `x-html` unless content is trusted |
| RLS disabled on product_pairings | Elevation of Privilege | Migration 002 MUST include `ALTER TABLE product_pairings ENABLE ROW LEVEL SECURITY` and policies before applying |
| Service role key exposure | Information Disclosure | Already mitigated in Phase 1; no change in Phase 3 |

**Phase 3 specific security check:** The `product_pairings` table is new. RLS must be enabled and policies must be written in `002_product_pairings.sql` before applying to Supabase. Admin-write + public-read policy pattern mirrors `collection_products`.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 3 |
|---|---|
| CDN-only library loading (no npm install for Alpine/Swiper/Supabase) | Add Swiper and Toastify via CDN `<script>` tags in HTML — not npm packages |
| Supabase only — no custom server | All data fetching via `@supabase/supabase-js` client SDK |
| Alpine.js `x-data + init()` async pattern | Already established in Phase 2; continue this pattern for PLP and PDP |
| `js/supabase.js` singleton — never re-initialize | Import `{ supabase }` in `js/products.js`; do not create a second client |
| `Alpine.store('cart')` for ATC — stub only | Phase 3 calls `.add()` but actual logic is Phase 6 |
| Tailwind CSS v4 CLI — no Play CDN | `src/input.css` → `css/style.css` via CLI build; new CSS classes added to `src/input.css` |
| Design tokens only — no arbitrary Tailwind values | Use `var(--sage)`, `var(--charcoal)`, etc. in new CSS; no `text-[#2D2D2D]` arbitrary values |
| No React, no Vue, no Express | Not applicable to Phase 3 |
| Enable RLS on every table | Migration 002 must enable RLS on `product_pairings` |
| `service_role` key never in frontend | Not applicable — Phase 3 is all public read / anon key |
| No inline JS in HTML files | Business logic in `js/products.js` and `js/components.js`; Alpine bindings are HTML attributes (accepted by project convention) |
| Quiet luxury aesthetic | Every new component class must match the established palette and typography; no Bootstrap defaults |

---

## Sources

### Primary (verified from codebase)
- `/Users/andika/Desktop/Elvora/supabase/seed.sql` — exact collection slugs, product IDs, product-to-collection assignments, and the gap in Tennis/Training/Running assignments
- `/Users/andika/Desktop/Elvora/supabase/migrations/001_schema.sql` — table schemas for products, product_variants, product_images, collections, collection_products, reviews
- `/Users/andika/Desktop/Elvora/js/subcategory-styles.js` — authoritative 15 sub-category slugs and names
- `/Users/andika/Desktop/Elvora/js/components.js` — existing nav x-data structure that Phase 3 must extend
- `/Users/andika/Desktop/Elvora/shop.html` — existing hardcoded prototype structure Phase 3 replaces
- `/Users/andika/Desktop/Elvora/product.html` — empty stub Phase 3 fills
- `/Users/andika/Desktop/Elvora/js/products.js` — 4 stub functions Phase 3 implements
- `/Users/andika/Desktop/Elvora/src/input.css` — all CSS tokens and existing component classes
- `/Users/andika/Desktop/Elvora/.planning/phases/03-product-catalog/03-CONTEXT.md` — all locked decisions D-01 through D-17
- `/Users/andika/Desktop/Elvora/.planning/phases/03-product-catalog/03-UI-SPEC.md` — component classes, interaction contracts, responsive breakpoints

### Secondary (from CLAUDE.md and REQUIREMENTS.md)
- `CLAUDE.md` — technology stack decisions, CDN-first convention, design token rules
- `REQUIREMENTS.md §F-008 through F-019` — exact acceptance criteria

### Tertiary
- Swiper.js v11 thumbs module pattern [ASSUMED — initialization order from training knowledge]
- IntersectionObserver sticky ATC pattern [ASSUMED — standard Web API pattern]
- Manual focus trap pattern [ASSUMED — standard WCAG implementation]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already chosen and confirmed in CLAUDE.md
- Architecture: HIGH — schema is fully defined in 001_schema.sql; patterns derived from existing Phase 2 code
- Collection slug mapping: HIGH — directly read from seed.sql
- Gap discovery (Tennis/Training/Running assignments): HIGH — verified gap in seed.sql Section 6
- Swiper thumbs initialization order: MEDIUM — confirmed pattern but not run in this session
- Focus trap implementation: MEDIUM — standard pattern but not tested against this specific Alpine version

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 (stable libraries — Swiper v11, Alpine 3.x, Supabase v2 are stable)
