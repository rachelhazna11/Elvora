# Phase 3: Product Catalog — Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 7 (shop.html, product.html, js/products.js, js/components.js, src/input.css, supabase/migrations/002_product_pairings.sql, supabase/seed.sql pairing rows)
**Analogs found:** 6 / 7 (migration structure has partial analog in 001_schema.sql)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `shop.html` | page / Alpine component | request-response + CRUD | `shop.html` (existing hardcoded prototype) | self-update — replaces hardcoded x-data with Supabase-backed init() |
| `product.html` | page / Alpine component | request-response + CRUD | `index.html` (best-sellers + testimonials x-data pattern) | role-match |
| `js/products.js` | service / data module | CRUD | `js/auth.js` (stub-to-implement pattern) + `js/supabase.js` (client singleton) | role-match |
| `js/components.js` | utility / shared injector | event-driven | `js/components.js` (itself — extend navHTML x-data) | self-update |
| `src/input.css` | config / design tokens | — | `src/input.css` (itself — add new component classes) | self-update |
| `supabase/migrations/002_product_pairings.sql` | migration | CRUD | `supabase/migrations/001_schema.sql` | role-match |
| `supabase/seed.sql` (pairing rows) | config / seed data | batch | `supabase/seed.sql` (existing INSERT patterns) | exact |

---

## Pattern Assignments

### `shop.html` (page, request-response + CRUD)

**Analog:** `shop.html` lines 16–106 (existing hardcoded prototype) and `index.html` lines 1–11 (head structure)

**Head / CDN pattern** (from `shop.html` lines 1–12):
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Shop — ELVORA</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400;1,700&family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js"></script>
  <!-- Add Toastify for ATC stub -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
</head>
```

**Script loading order** (from `shop.html` lines 102–106 — MUST preserve):
```html
<script src="/js/__env.js"></script>
<script type="module" src="/js/supabase.js"></script>
<script type="module" src="/js/components.js"></script>
```
Note: `js/products.js` functions are called inside the Alpine `x-data` string via `window`-exposed helpers OR imported in a separate `<script type="module">` tag BEFORE `components.js`. The simplest pattern for Alpine inline access: expose product functions on `window` in `js/products.js`, load it as a module before `components.js`.

**Alpine x-data with async init() pattern** — replace the hardcoded `x-data` block in `shop.html` lines 17–33:

The existing hardcoded pattern uses synchronous `x-data` with inline product arrays. Phase 3 replaces this with an async `init()` that reads URL params first, then fetches from Supabase. Copy this structure (from `index.html` and the existing `x-data` pattern):

```html
<main
  x-data="{
    products: [],
    loading: true,
    category: 'all',
    sub: null,
    sort: 'new-arrivals',
    search: '',
    async init() {
      const params = new URLSearchParams(window.location.search);
      this.category = params.get('category') || 'all';
      this.sub      = params.get('sub') || null;
      this.sort     = params.get('sort') || 'new-arrivals';
      this.search   = params.get('search') || '';
      await this.fetchProducts();
    },
    async fetchProducts() {
      this.loading = true;
      const { data } = await getProducts({ category: this.category, sub: this.sub, sort: this.sort, search: this.search });
      this.products = data || [];
      this.loading = false;
      this.syncURL();
    },
    syncURL() {
      const params = new URLSearchParams();
      if (this.category && this.category !== 'all') params.set('category', this.category);
      if (this.sub) params.set('sub', this.sub);
      if (this.sort && this.sort !== 'new-arrivals') params.set('sort', this.sort);
      if (this.search) params.set('search', this.search);
      const qs = params.toString();
      history.replaceState(null, '', qs ? '?' + qs : window.location.pathname);
    }
  }"
>
```

**Filter pills pattern** — evolve the existing pills (lines 49–55) from garment-type to activity tabs:

```html
<!-- Existing pattern to copy structure from (shop.html lines 48–55): -->
<div class="filter-pills">
  <button class="filter-pill" :class="activeFilter === 'all' && 'active'" @click="activeFilter = 'all'">All</button>
  ...
</div>

<!-- Phase 3 replacement — same CSS classes, new values + Supabase fetch on click: -->
<div class="filter-pills">
  <button class="filter-pill" :class="category === 'all' && 'active'"
    @click="category='all'; sub=null; fetchProducts()">All</button>
  <button class="filter-pill" :class="category === 'padel' && 'active'"
    @click="category='padel'; sub=null; fetchProducts()">Padel</button>
  <!-- ...Tennis, Pilates, Training, Running -->
</div>
```
Reuse `.filter-pill` and `.filter-pill.active` classes from `src/input.css` lines 451–457. No new CSS needed for pill structure.

**Sub-category pills row** (new — appears below activity tabs when category !== 'all'):
```html
<div x-show="category !== 'all'" class="filter-pills mt-3 overflow-x-auto pb-2">
  <template x-for="sc in subCategoriesForActivity" :key="sc.slug">
    <button class="filter-pill text-[11px]"
      :class="sub === sc.slug && 'active'"
      @click="sub = (sub === sc.slug ? null : sc.slug); fetchProducts()"
      x-text="sc.name">
    </button>
  </template>
</div>
```
Import `SUBCATEGORY_STYLES` from `js/subcategory-styles.js` and filter by `category` field to build `subCategoriesForActivity`.

**Product card x-for pattern** — evolve from existing hardcoded loop (lines 69–95):
```html
<!-- Existing pattern (shop.html lines 69–95): -->
<template x-for="p in filtered" :key="p.id">
  <a :href="'/product.html?id=' + p.id" class="product-card">
    <div class="product-img">
      <div class="product-img-bg" :class="p.bgClass" :style="..."></div>
      ...
    </div>
    <div class="product-info">
      <h3 x-text="p.name" class="product-name"></h3>
      ...
    </div>
  </a>
</template>

<!-- Phase 3 replacement — same .product-card, .product-img, .product-info classes; update href and image binding: -->
<template x-for="p in products" :key="p.id">
  <a :href="'/product.html?slug=' + p.slug" class="product-card">
    <div class="product-img">
      <img
        :src="(p.activeImage || p.product_images[0]?.url) + '?w=800&q=80'"
        :alt="p.name"
        width="400" height="533"
        loading="lazy"
        class="w-full h-full object-cover object-top"
        style="transition: transform 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94);"
      >
      <button class="wishlist-btn" @click.prevent aria-label="Save to wishlist">♡</button>
    </div>
    <div class="product-info">
      <h3 x-text="p.name" class="product-name"></h3>
      <div class="product-price-row">
        <span x-text="'$' + Number(p.base_price).toFixed(2)" class="product-price"></span>
      </div>
      <!-- Colour swatches -->
      <div class="product-swatches">
        <template x-for="v in p.uniqueColours" :key="v.colour">
          <button
            class="swatch"
            :class="p.activeColour === v.colour ? 'ring-2 ring-charcoal ring-offset-1' : ''"
            :style="'background-color:' + v.colour_hex"
            :aria-label="v.colour"
            @mouseenter="p.activeColour = v.colour; p.activeImage = v.image"
            @mouseleave="p.activeColour = p.defaultColour; p.activeImage = p.defaultImage"
            @click.prevent="p.activeColour = v.colour; p.activeImage = v.image"
          ></button>
        </template>
      </div>
      <button
        class="add-cart-btn"
        @click.prevent="Alpine.store('cart').add({ productId: p.id, name: p.name, slug: p.slug, price: p.base_price })"
      >Add to Bag</button>
    </div>
  </a>
</template>
```

**Sort select pattern** — wire the existing `<select>` (lines 57–63) to Alpine state:
```html
<!-- Existing (shop.html line 58): -->
<select class="sort-select">
  <option>Newest</option>
  ...
</select>

<!-- Phase 3 replacement — bind x-model and trigger refetch: -->
<select class="sort-select" x-model="sort" @change="fetchProducts()">
  <option value="new-arrivals">New Arrivals</option>
  <option value="price-asc">Price: Low to High</option>
  <option value="price-desc">Price: High to Low</option>
  <option value="best-sellers">Best Sellers</option>
</select>
```

---

### `product.html` (page, request-response + CRUD)

**Analog:** `shop.html` head structure + `index.html` CDN pattern

**Head additions** (add to existing head in `product.html` lines 1–12):
```html
<!-- Swiper.js v11 — PDP only -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.css">
<script src="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js"></script>
<!-- Toastify-js -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
<script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
```
Insert before the closing `</head>`. The existing Alpine CDN tag, font links, and `style.css` link remain unchanged.

**Alpine x-data with async init()** — replace `<main><!-- Phase 3 fills this --></main>` (product.html line 15):
```html
<main x-data="{
  product: null,
  loading: true,
  selectedColour: null,
  selectedSize: null,
  showSizeGuide: false,
  stickyVisible: false,
  accordionFabric: false,
  reviews: [],
  reviewsOffset: 0,
  reviewsPageSize: 5,
  reviewsTotal: 0,
  allReviewsLoaded: false,
  pairings: [],
  relatedProducts: [],

  async init() {
    const params = new URLSearchParams(window.location.search);
    const slug = params.get('slug');
    if (!slug) { window.location.href = '/shop.html'; return; }

    const data = await getProduct(slug);
    if (!data) { window.location.href = '/shop.html'; return; }

    this.product = data;
    this.selectedColour = data.product_variants?.[0]?.colour || null;

    this.$nextTick(() => {
      this.initSwiper();
      this.initStickyObserver();
    });

    await this.loadReviews();
    await this.loadPairings();
    await this.loadRelated();
    this.loading = false;
  },

  initSwiper() {
    const thumbsSwiper = new Swiper('.swiper-thumbs', {
      spaceBetween: 8,
      slidesPerView: 4,
      freeMode: true,
      watchSlidesProgress: true,
    });
    this._mainSwiper = new Swiper('.swiper-main', {
      spaceBetween: 0,
      loop: false,
      thumbs: { swiper: thumbsSwiper },
      lazy: { loadPrevNext: true },
    });
  },

  initStickyObserver() {
    const atcBtn = document.querySelector('.atc-main');
    if (!atcBtn) return;
    const obs = new IntersectionObserver(([e]) => {
      this.stickyVisible = !e.isIntersecting;
    }, { threshold: 0 });
    obs.observe(atcBtn);
  },

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

  get averageRating() {
    if (!this.reviews.length) return '0.0';
    return (this.reviews.reduce((s, r) => s + r.rating, 0) / this.reviews.length).toFixed(1);
  },

  openSizeGuide() {
    this.showSizeGuide = true;
    this.$nextTick(() => {
      const modal = document.querySelector('.size-guide-modal');
      const first = modal?.querySelector('button, [href], input');
      if (first) first.focus();
    });
  },

  closeSizeGuide() {
    this.showSizeGuide = false;
    document.querySelector('.size-guide-btn')?.focus();
  },

  trapFocus(e) {
    const modal = document.querySelector('.size-guide-modal');
    if (!modal) return;
    const focusable = modal.querySelectorAll('button,[href],input,select,textarea,[tabindex]:not([tabindex=\'-1\'])');
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (e.key === 'Tab') {
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
    if (e.key === 'Escape') this.closeSizeGuide();
  },

  addToBag() {
    if (!this.selectedSize) { alert('Please select a size'); return; }
    Alpine.store('cart').add({
      productId: this.product.id,
      name: this.product.name,
      slug: this.product.slug,
      colour: this.selectedColour,
      size: this.selectedSize,
      price: this.product.base_price,
    });
    Toastify({
      text: 'Added to Bag',
      duration: 2500,
      gravity: 'bottom',
      position: 'right',
      style: {
        background: 'var(--charcoal)',
        color: '#ffffff',
        borderRadius: '50px',
        fontSize: '12px',
        letterSpacing: '2px',
      },
    }).showToast();
  }
}"
>
```

---

### `js/products.js` (service, CRUD)

**Analog:** `js/auth.js` (stub-to-implement pattern) + `js/supabase.js` (import pattern)

**Import pattern** (from `js/auth.js` line 1–3 and `js/products.js` lines 1–3):
```javascript
// js/products.js
import { supabase } from './supabase.js';
```
No additional imports. The `SUBCATEGORY_STYLES` import from `js/subcategory-styles.js` is used for the activity slug mapping helper but can be inlined as a constant to avoid circular dependency.

**getProducts() core pattern:**
```javascript
const ACTIVITY_TOP_SLUGS = {
  padel:    ['padel-edit'],
  pilates:  ['studio-essentials'],
  tennis:   ['love-match', 'ace-energy', 'court-girl'],
  training: ['power-mood', 'built-different', 'hot-girl-lift'],
  running:  ['run-era', 'pace-mode', 'runners-high'],
};

export async function getProducts(filters = {}) {
  const { category, sub, sort, search } = filters;

  let query = supabase
    .from('products')
    .select(`
      id, name, slug, base_price, is_best_seller, created_at,
      product_images (url, alt_text, display_order, colour),
      product_variants (id, colour, colour_hex, size, stock_quantity)
    `)
    .eq('is_active', true);

  if (search) {
    query = query.ilike('name', `%${search}%`);
  }

  if (category && category !== 'all') {
    const slugs = sub ? [sub] : ACTIVITY_TOP_SLUGS[category] || [];
    if (slugs.length > 0) {
      const { data: cols } = await supabase
        .from('collections')
        .select('id')
        .in('slug', slugs);
      const colIds = (cols || []).map(c => c.id);
      if (colIds.length === 0) return { data: [], error: null };
      const { data: cp } = await supabase
        .from('collection_products')
        .select('product_id')
        .in('collection_id', colIds);
      const ids = [...new Set((cp || []).map(r => r.product_id))];
      if (ids.length === 0) return { data: [], error: null };
      query = query.in('id', ids);
    }
  }

  switch (sort) {
    case 'price-asc':
      query = query.order('base_price', { ascending: true }); break;
    case 'price-desc':
      query = query.order('base_price', { ascending: false }); break;
    case 'best-sellers':
      query = query.order('is_best_seller', { ascending: false })
                   .order('created_at', { ascending: false }); break;
    default:
      query = query.order('created_at', { ascending: false });
  }

  return query;
}
```

**getProduct() pattern:**
```javascript
export async function getProduct(slug) {
  // Phase 7 note: For Supabase Storage images, use ?width=1200&quality=80 transform params.
  // Seed images are Unsplash CDN — use ?w=1200&q=80 (different API).
  const { data, error } = await supabase
    .from('products')
    .select(`
      id, name, slug, description, base_price, is_best_seller,
      fabric_details, care_instructions, styling_suggestions,
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

**searchProducts() pattern:**
```javascript
export async function searchProducts(query) {
  if (!query || query.length < 2) return { data: [] };
  return supabase
    .from('products')
    .select('name, slug')
    .ilike('name', `%${query}%`)
    .eq('is_active', true)
    .limit(6);
}
```

**getCategories() pattern:**
```javascript
export async function getCategories() {
  return supabase
    .from('categories')
    .select('id, name, slug')
    .order('name', { ascending: true });
}
```

**Window exposure** — add at bottom of `js/products.js` so Alpine inline x-data strings can call these functions:
```javascript
// Expose to window so Alpine inline x-data strings can call these functions.
// Alpine x-data strings run in the global scope — cannot use ES module imports.
window.getProducts    = getProducts;
window.getProduct     = getProduct;
window.getCategories  = getCategories;
window.searchProducts = searchProducts;
```

---

### `js/components.js` (utility, event-driven)

**Analog:** `js/components.js` itself (lines 26–138) — extend the navHTML `x-data` block

**Current nav x-data** (lines 28–37 — must be replaced, not appended):
```javascript
x-data="{
  navOpen: false,
  scrolled: false,
  init() {
    window.addEventListener('scroll', () => {
      this.scrolled = window.scrollY > 80;
    }, { passive: true });
  }
}"
```

**Phase 3 replacement x-data** — add search state while preserving existing navOpen + scrolled:
```javascript
x-data="{
  navOpen: false,
  scrolled: false,
  searchOpen: false,
  searchQuery: '',
  suggestions: [],
  _searchTimer: null,
  init() {
    window.addEventListener('scroll', () => {
      this.scrolled = window.scrollY > 80;
    }, { passive: true });
  },
  async onSearchInput() {
    if (this.searchQuery.length < 2) { this.suggestions = []; return; }
    clearTimeout(this._searchTimer);
    this._searchTimer = setTimeout(async () => {
      const { data } = await searchProducts(this.searchQuery);
      this.suggestions = data || [];
    }, 300);
  },
  goToSearch() {
    if (this.searchQuery.trim()) {
      window.location.href = '/shop.html?search=' + encodeURIComponent(this.searchQuery.trim());
    }
  },
  goToProduct(slug) {
    window.location.href = '/product.html?slug=' + slug;
    this.searchOpen = false;
    this.suggestions = [];
    this.searchQuery = '';
  }
}"
```

**Search button in nav actions** (replaces the static search button at lines 61–65):
```html
<!-- Replace static search button with Alpine-wired version -->
<div class="relative" @click.outside="searchOpen = false; suggestions = []">
  <button
    @click="searchOpen = !searchOpen; if (searchOpen) $nextTick(() => $refs.searchInput.focus())"
    aria-label="Search"
    class="w-11 h-11 flex items-center justify-center text-charcoal hover:text-rose transition-colors"
  >
    <!-- existing SVG icon unchanged -->
  </button>

  <!-- Expand input -->
  <div
    x-show="searchOpen"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0 scale-95"
    x-transition:enter-end="opacity-100 scale-100"
    class="absolute right-0 top-full mt-2 w-72 z-50"
    style="display:none;"
  >
    <input
      x-ref="searchInput"
      x-model="searchQuery"
      @input="onSearchInput()"
      @keydown.enter.prevent="goToSearch()"
      @keydown.escape="searchOpen = false; suggestions = []"
      type="search"
      placeholder="Search..."
      class="w-full px-5 py-3 rounded-full border border-sage/30 bg-white text-charcoal text-sm outline-none shadow-md"
    >

    <!-- Autosuggest dropdown -->
    <div
      x-show="suggestions.length > 0"
      class="mt-1 bg-white rounded-2xl shadow-lg border border-sage/20 overflow-hidden"
      style="display:none;"
    >
      <template x-for="s in suggestions" :key="s.slug">
        <button
          @click="goToProduct(s.slug)"
          class="w-full text-left px-5 py-3 text-sm text-charcoal hover:bg-beige transition-colors"
          x-text="s.name"
        ></button>
      </template>
    </div>
  </div>
</div>
```

---

### `src/input.css` (config, design tokens)

**Analog:** `src/input.css` itself — existing `@layer components` block (lines 39–89) and `.shop-*` section (lines 436–464)

**Existing CSS classes Phase 3 reuses without change:**
- `.filter-pill`, `.filter-pill.active`, `.filter-pill:hover:not(.active)` — lines 451–457
- `.shop-hero`, `.shop-hero-title`, `.shop-hero-sub`, `.shop-body`, `.shop-toolbar` — lines 437–448
- `.shop-grid` — line 464 (update to `repeat(3, 1fr)` already set; may need responsive override to `repeat(2, 1fr)` at md and `repeat(1, 1fr)` at sm)
- `.product-card`, `.product-img`, `.product-info`, `.product-name`, `.product-price`, `.swatch`, `.product-badge` — lines 217–252
- `.btn-primary`, `.btn-secondary` — lines 53–70
- `.section-label`, `.section-title` — lines 40–51

**New CSS classes to add** (no existing analogs — add to `src/input.css` after the `/* ─── Shop Page ───────────────────────────────────────────────────────────── */` block):

```css
/* ─── Shop Page — Phase 3 additions ──────────────────────────────────────── */

/* Sub-category pills row */
.subcategory-pills {
  display: flex; gap: 8px; flex-wrap: nowrap; overflow-x: auto;
  padding-bottom: 8px; margin-bottom: 24px;
  scrollbar-width: none;
}
.subcategory-pills::-webkit-scrollbar { display: none; }
.subcategory-pill {
  padding: 6px 16px; border-radius: 50px;
  border: 1px solid rgba(168,191,163,0.5);
  font-size: 11px; font-weight: 500; cursor: pointer; transition: all 0.2s;
  background: transparent; font-family: var(--font-body);
  color: var(--text-muted); white-space: nowrap; flex-shrink: 0;
}
.subcategory-pill.active { background: var(--sage); color: white; border-color: var(--sage); }
.subcategory-pill:hover:not(.active) { border-color: var(--rose); color: var(--rose); }

/* Load more / pagination */
.load-more-btn {
  display: block; margin: 48px auto 0;
  padding: 14px 40px; border: 1.5px solid rgba(46,46,46,0.2); border-radius: 50px;
  font-size: 12px; letter-spacing: 2px; text-transform: uppercase;
  font-weight: 500; cursor: pointer; transition: all 0.2s;
  background: transparent; font-family: var(--font-body); color: var(--charcoal);
}
.load-more-btn:hover { border-color: var(--charcoal); background: var(--charcoal); color: white; }

/* ─── Product Detail Page ──────────────────────────────────────────────────── */

/* Swiper gallery */
.swiper-main { border-radius: 16px; overflow: hidden; }
.swiper-thumbs { margin-top: 12px; }
.swiper-thumbs .swiper-slide {
  border-radius: 10px; overflow: hidden; cursor: pointer;
  opacity: 0.5; transition: opacity 0.2s;
}
.swiper-thumbs .swiper-slide-thumb-active { opacity: 1; }

/* Sticky ATC bar */
.sticky-atc {
  position: fixed; bottom: 0; left: 0; right: 0; z-index: 90;
  background: white; border-top: 1px solid rgba(168,191,163,0.3);
  padding: 16px 24px; display: flex; align-items: center; gap: 16px;
  box-shadow: 0 -4px 24px rgba(0,0,0,0.06);
}
.sticky-atc-name {
  font-family: var(--font-display);
  font-size: 14px; font-weight: 600; color: var(--charcoal); flex: 1;
}
.sticky-atc-price {
  font-size: 14px; font-weight: 600; color: var(--charcoal);
}

/* Size guide modal */
.size-guide-overlay {
  position: fixed; inset: 0; background: rgba(46,46,46,0.5);
  z-index: 200; display: flex; align-items: center; justify-content: center;
}
.size-guide-modal {
  background: white; border-radius: 24px; padding: 40px;
  max-width: 560px; width: 90%; max-height: 80vh; overflow-y: auto;
  position: relative;
}
.size-guide-close {
  position: absolute; top: 20px; right: 20px;
  width: 36px; height: 36px; border-radius: 50%;
  background: var(--beige); border: none; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  color: var(--charcoal); transition: background 0.2s;
}
.size-guide-close:hover { background: var(--rose-light); }

/* Size chart table */
.size-table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 13px; }
.size-table th {
  padding: 10px 14px; background: var(--beige); text-align: center;
  font-size: 11px; letter-spacing: 2px; text-transform: uppercase;
  color: var(--text-muted); font-weight: 500;
}
.size-table td { padding: 10px 14px; border-bottom: 1px solid rgba(168,191,163,0.2); text-align: center; }

/* Accordion */
.accordion-trigger {
  display: flex; justify-content: space-between; align-items: center;
  width: 100%; padding: 20px 0;
  border-bottom: 1px solid rgba(168,191,163,0.3);
  background: none; border-top: none; border-left: none; border-right: none;
  cursor: pointer; font-family: var(--font-body);
  font-size: 13px; letter-spacing: 2px; text-transform: uppercase;
  font-weight: 500; color: var(--charcoal);
}
.accordion-content { padding: 16px 0 24px; font-size: 14px; line-height: 1.8; color: var(--text-muted); }

/* Size / colour selector */
.size-grid { display: flex; gap: 8px; flex-wrap: wrap; margin: 12px 0; }
.size-btn {
  padding: 8px 16px; border-radius: 8px;
  border: 1.5px solid rgba(46,46,46,0.15);
  font-size: 12px; font-weight: 500; cursor: pointer;
  background: white; color: var(--charcoal); transition: all 0.2s;
  font-family: var(--font-body);
}
.size-btn:hover { border-color: var(--charcoal); }
.size-btn.selected { background: var(--charcoal); color: white; border-color: var(--charcoal); }
.size-btn:disabled { opacity: 0.3; cursor: not-allowed; }

/* Review stars */
.star-filled { color: var(--rose); }
.star-empty { color: rgba(168,191,163,0.4); }

/* Fit feedback badges */
.fit-badge {
  display: inline-block; padding: 4px 14px; border-radius: 20px;
  background: var(--beige); border: 1px solid rgba(168,191,163,0.4);
  font-size: 11px; letter-spacing: 1px; color: var(--text-muted);
}

/* Complete the Look / Related Products grids */
.pairings-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
.related-grid  { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; }
```

**Design token rule:** Never add arbitrary hex values. Always reference `var(--sage)`, `var(--rose)`, `var(--beige)`, `var(--charcoal)`, `var(--text-muted)` etc. from `:root` lines 17–27.

---

### `supabase/migrations/002_product_pairings.sql` (migration, CRUD)

**Analog:** `supabase/migrations/001_schema.sql` — copy the RLS enable + policy pattern

**Pattern to copy from 001_schema.sql** (create table + RLS enable + public read + admin write — the same structure used for `collection_products`):
```sql
-- supabase/migrations/002_product_pairings.sql

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

Also include `collection_products` assignment rows for Tennis, Training, Running in this file (or a companion `002_collection_assignments.sql`) per the gap discovered in RESEARCH.md:
```sql
-- Wave 0: fix missing collection_products assignments
-- Tennis → love-match, ace-energy, court-girl
-- Training → power-mood, built-different, hot-girl-lift
-- Running → run-era, pace-mode, runners-high
-- (planner must resolve exact product UUIDs from seed.sql before writing these INSERTs)
```

---

### `supabase/seed.sql` — pairing rows addition (config, batch)

**Analog:** `supabase/seed.sql` existing INSERT INTO blocks (same pattern)

```sql
-- Pairing seed pattern — copy the INSERT INTO collection_products style:
INSERT INTO product_pairings (product_id, paired_product_id, display_order) VALUES
  ('<product-uuid>', '<paired-uuid>', 1),
  ('<product-uuid>', '<paired-uuid>', 2),
  ...
ON CONFLICT DO NOTHING;
```
Activity-context-relevant pairings: padel skirt → padel top, pilates legging → pilates bra, etc. Planner resolves UUIDs from seed.sql Section 1 product listings.

---

## Shared Patterns

### Supabase client import
**Source:** `js/supabase.js` lines 1–15
**Apply to:** `js/products.js`
```javascript
import { supabase } from './supabase.js';
// Never re-initialize — import the singleton only.
```

### Alpine x-data async init() structure
**Source:** `shop.html` lines 17–33 (existing sync pattern) → Phase 3 converts to async
**Apply to:** `shop.html` main x-data, `product.html` main x-data
```javascript
async init() {
  // 1. Read URL params
  // 2. Set this.* state
  // 3. await fetch
}
```
Rule: Always read URL params BEFORE the first fetch call. Alpine `init()` must be declared `async`.

### window exposure for Alpine inline access
**Source:** No existing analog — new pattern for Phase 3
**Apply to:** `js/products.js` (bottom of file)
```javascript
window.getProducts    = getProducts;
window.getProduct     = getProduct;
window.searchProducts = searchProducts;
```
Rationale: Alpine `x-data` strings run in global scope and cannot use ES module imports. Exposing on `window` bridges the module/Alpine boundary. (Phase 2 precedent: `window.supabase = supabase` in `js/components.js` line 8.)

### Script loading order
**Source:** `shop.html` lines 102–106 and `product.html` lines 17–20
**Apply to:** Both pages
```html
<script src="/js/__env.js"></script>                      <!-- 1. env vars -->
<script type="module" src="/js/supabase.js"></script>     <!-- 2. Supabase client -->
<script type="module" src="/js/products.js"></script>     <!-- 3. product functions (exposes to window) -->
<script type="module" src="/js/components.js"></script>   <!-- 4. nav/footer + Alpine stores -->
```
`js/products.js` must be added before `components.js` so `window.getProducts` etc. are available when Alpine initializes the page.

### CSS design token usage
**Source:** `src/input.css` lines 17–27 (`:root` block) and lines 3–15 (`@theme` block)
**Apply to:** All new CSS classes in `src/input.css`
```css
/* Always use CSS custom properties — never hardcode hex values */
color: var(--charcoal);    /* #2E2E2E */
background: var(--beige);  /* #F5F1ED */
border-color: var(--sage); /* #A8BFA3 */
color: var(--rose);        /* #D8A7A7 */
```

### Unsplash image sizing
**Source:** `index.html` line 32 and CONTEXT.md D-11
**Apply to:** All `<img>` tags in `shop.html` and `product.html`
```
PLP cards:      ?w=800&q=80
PDP main image: ?w=1200&q=80
PDP thumbnails: ?w=200&q=60
```
Note: These params work only on Unsplash CDN URLs. For Supabase Storage (Phase 7), use `?width=1200&quality=80` instead. Add a code comment in `getProduct()` documenting this distinction.

### Alpine.store('cart').add() call
**Source:** `js/components.js` lines 14–16 (store registration stub)
**Apply to:** Both PLP add-to-bag button and PDP add-to-bag button
```javascript
Alpine.store('cart').add({ productId, name, slug, colour, size, price });
// The store stub was registered in components.js Phase 2.
// Phase 6 will implement actual cart logic.
```

### Toastify call
**Source:** RESEARCH.md Code Examples section
**Apply to:** `product.html` addToBag() method and optionally `shop.html` ATC stub
```javascript
Toastify({
  text: 'Added to Bag',
  duration: 2500,
  gravity: 'bottom',
  position: 'right',
  style: {
    background: 'var(--charcoal)',
    color: '#ffffff',
    borderRadius: '50px',
    fontSize: '12px',
    letterSpacing: '2px',
  },
}).showToast();
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Swiper.js thumbs init | utility | — | No existing carousel/slider in the codebase; pattern from RESEARCH.md Pattern 2 is the reference |
| IntersectionObserver sticky ATC | utility | event-driven | No existing scroll-triggered visibility in the codebase; RESEARCH.md Pattern 5 is the reference |
| Manual focus trap | utility | event-driven | No existing modal with focus management; RESEARCH.md Pattern 6 is the reference |

---

## Metadata

**Analog search scope:** `/Users/andika/Desktop/Elvora/js/`, `/Users/andika/Desktop/Elvora/*.html`, `/Users/andika/Desktop/Elvora/src/`, `/Users/andika/Desktop/Elvora/supabase/`
**Files scanned:** 10 (components.js, products.js, auth.js, supabase.js, subcategory-styles.js, shop.html, product.html, index.html, src/input.css, supabase/migrations/001_schema.sql)
**Pattern extraction date:** 2026-06-14
