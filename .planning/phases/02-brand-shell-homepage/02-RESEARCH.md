# Phase 02: Brand Shell + Homepage — Research

**Researched:** 2026-06-12
**Domain:** Static HTML multi-page frontend, Tailwind CSS v4 design system, Alpine.js reactivity, Supabase JS SDK v2 browser integration
**Confidence:** MEDIUM (all core patterns verified via official docs; some implementation details LOW from web search)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Port `elvora_updated-3.html` faithfully as the implementation reference. The planner and executor treat it as the approved design — not a rough sketch but the specific layout, section structure, and visual hierarchy to reproduce. Deviations require a documented reason.

**D-02:** Migration from the prototype's inline `<style>` CSS to Tailwind v4 utility classes should match the visual intent loosely using the standard Tailwind scale (e.g., `py-24`, `px-16`, `text-4xl`) rather than pixel-perfect arbitrary values. The result should be visually near-identical, not mathematically identical.

**D-03:** The hero image slot is filled with a curated Unsplash editorial URL — premium women's activewear/lifestyle photography, neutral tones, consistent with the Alo Yoga aesthetic benchmark. The URL is hardcoded in the HTML; no CMS required for the hero in Phase 2.

**D-04:** On mobile (below `md:` breakpoint), the horizontal nav links collapse. A hamburger icon (top-right) opens a full-height slide-out drawer from the right side. Implemented with Alpine.js `x-show` + transition.

**D-05:** Nav scroll behavior: starts transparent over the hero (on `index.html`); transitions to the beige backdrop-blur background (`bg-beige/90 backdrop-blur-md`) after scrolling ~80px. Implemented via `window.scroll` listener inside an Alpine `x-init`.

**D-06:** `js/components.js` ES module exports the nav and footer as HTML strings and inserts them into `<div id="nav-root">` and `<div id="footer-root">` on each page. Single source of truth.

**D-07:** Phase 2 renders the nav with static icons. `Alpine.store('cart')` and `Alpine.store('auth')` are initialized with empty/null defaults in `js/components.js` — not wired dynamically in Phase 2.

**D-08:** `about.html` is a full editorial brand story layout. No Supabase data — pure HTML/CSS.

**D-09:** `contact.html` contains FAQ accordion (~6 questions, Alpine.js `x-show`) and contact info. No form submission in Phase 2.

**D-10:** Alpine.js behaviors scoped to Phase 2: (1) mobile nav drawer, (2) nav scroll transparency, (3) FAQ accordion, (4) newsletter form → Supabase insert.

**D-11:** Best sellers fetches 4 products, testimonials fetches 3 from Supabase. Both use Alpine.js `x-data` async `init()` with `x-for`.

### Claude's Discretion

None documented in CONTEXT.md — all implementation choices follow locked decisions above.

### Deferred Ideas (OUT OF SCOPE)

- Contact form submission with email delivery
- Hero video background loop
- Animated scroll transitions (Intersection Observer fade-in)
- Swiper.js carousel for testimonials/best sellers (executor discretion if time allows)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| F-001 | Editorial Hero Section — full-screen/near-full-screen, headline, CTA, mobile-responsive | Two-column CSS grid on desktop, stacked on mobile; `clamp()` for fluid typography; fetchpriority="high" on hero img |
| F-002 | Featured Activity Collections — 4 cards → filtered PLP | CSS grid 2fr 1fr 1fr with grid-row span; href to shop.html?category={slug} |
| F-003 | Best Sellers — 4+ products from Supabase, product cards | Alpine async init(), x-for, Supabase select query, skeleton loading |
| F-004 | Lifestyle/Lookbook Grid — 4–6 editorial images, editorial layout | CSS grid-cols-6, hardcoded Unsplash URLs, aspect-ratio: 1/1, hover overlay |
| F-005 | Brand Story Section — editorial text, links to About | Dark charcoal bg, two-col grid, stats row |
| F-006 | Testimonials Section — 3+ from Supabase | Alpine async init(), supabase.from('testimonials').select().eq('is_active', true).limit(3) |
| F-007 | Newsletter Signup — email input, Supabase insert, confirmation | Alpine x-data form state, supabase.from('newsletter_subscribers').insert(), duplicate key error code 23505 |
| F-043 | About / Brand Story page — full editorial content | Shared nav/footer via components.js, pure HTML/CSS |
| F-044 | Contact / FAQ page — FAQ accordion + contact info | Alpine x-data { activeIndex: null }, x-show per FAQ item |
| F-045 | Global navigation — consistent across all pages, active state | components.js innerHTML injection + pathname-based active class |
| NF-001 | Responsive — 375px, 768px, 1024px, 1280px+ no horizontal scroll | Tailwind breakpoint prefixes sm: md: lg: xl:; overflow-x: hidden on body |
| NF-002 | Performance — sub-3s LCP | fetchpriority="high" on hero, loading="lazy" below fold, preconnect for Google Fonts, explicit width/height on all img |
| NF-003 | Accessibility — semantic HTML, WCAG AA contrast | aria-label on nav icons, aria-expanded on accordion, heading hierarchy h1/h2/h3, alt text |
| NF-004 | Cross-browser — Chrome, Safari, Firefox | Avoid CSS properties without broad support; backdrop-filter has wide support now |
</phase_requirements>

---

## Summary

Phase 02 is primarily a visual implementation challenge, not a technical one. The hard work is translating `elvora_updated-3.html` — a single-file prototype with inline CSS — into a maintainable multi-page architecture using Tailwind v4 utility classes and Alpine.js reactive components. The design tokens are already established in `src/input.css`; the phase should extend them minimally and use them consistently everywhere.

The two technical challenges are: (1) the `js/components.js` shared nav/footer injection pattern, which must initialize Alpine stores before Alpine boots, and (2) the three Alpine.js async data-fetching components (best sellers, testimonials, newsletter). Both have clean patterns with no gotchas once the Supabase client initialization sequence is understood.

The Supabase client already exists at `js/supabase.js` and reads from `window.__ENV` (injected at build time by Netlify). The `js/components.js` module must import the `supabase` client for the newsletter form and initialize Alpine stores in an `alpine:init` event listener before injecting nav/footer HTML.

**Primary recommendation:** Build `js/components.js` first — it unblocks nav/footer injection across all 11 HTML shells and establishes Alpine store shapes. Then build `index.html` section by section from top to bottom, matching the prototype. Finally build `about.html` and `contact.html` as pure HTML/CSS shells.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Nav + footer (HTML structure) | js/components.js | Each HTML page (placeholder divs) | Single source of truth — changes one file to update all 11 pages |
| Alpine store initialization | js/components.js | HTML page (alpine:init event) | Stores must be defined before Alpine processes x-data; components.js imports supabase.js |
| Hero, brand story, lookbook (static content) | index.html | src/input.css (tokens) | Pure HTML/CSS; no data fetching |
| Best sellers data fetch | Browser / Alpine component | Supabase PostgreSQL | Alpine async init() reads products table; rendered client-side |
| Testimonials data fetch | Browser / Alpine component | Supabase PostgreSQL | Alpine async init() reads testimonials table |
| Newsletter form submit | Browser / Alpine component | Supabase PostgreSQL | Alpine submit handler calls supabase.insert(); duplicate email handled client-side |
| Design tokens (colors, fonts, spacing) | src/input.css (@theme) | css/style.css (compiled output) | All tokens pre-defined; extend only, never redefine |
| About page content | about.html | src/input.css (tokens) | Pure editorial HTML/CSS; zero Supabase dependency |
| Contact FAQ accordion | contact.html | Alpine.js (x-show) | Accordion state managed by Alpine x-data { activeIndex } |
| Active nav link detection | js/components.js | window.location.pathname | Post-injection script compares link href to current path |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Tailwind CSS CLI | 4.3.0 [VERIFIED: npm registry] | Compile `src/input.css → css/style.css` | Already in package.json devDependencies; v4 @theme replaces config.js |
| Alpine.js | 3.15.12 [VERIFIED: npm registry] | Reactive UI — nav drawer, carousel, FAQ accordion, form state, data fetching | CDN-first; no build step; `Alpine.store()` for cross-page state |
| Supabase JS SDK | 2.108.1 [VERIFIED: npm registry] | Read products/testimonials, insert newsletter subscriber | CDN ESM; browser-safe with anon key + RLS |

### Supporting (CDN, no install required)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Google Fonts (CDN) | — | Playfair Display 700/700i, Poppins 400/600 | Load via `<link>` in `<head>` with preconnect optimization |
| Swiper.js | 11.x [ASSUMED] | Touch/swipe carousel (executor discretion) | Optional for testimonials/best sellers if > 4 items on mobile |

### Not Used in Phase 02

Per CLAUDE.md and CONTEXT.md locked decisions:
- No React/Vue/Svelte (overengineered for this scope)
- No Bootstrap (imposes visual identity conflicting with quiet luxury aesthetic)
- No Swiper.js required (deferred; executor discretion)
- No Tailwind Play CDN (CLI only for production)

### Build Command (unchanged from Phase 01)

```bash
npm run build:css
# = tailwindcss -i src/input.css -o css/style.css --minify
```

Development watch:
```bash
npx @tailwindcss/cli -i src/input.css -o css/style.css --watch
```

---

## Package Legitimacy Audit

> Package legitimacy gate run via `gsd-tools query package-legitimacy check --ecosystem npm`.

| Package | Registry | Age | Downloads/wk | Source Repo | Verdict | Disposition |
|---------|----------|-----|--------------|-------------|---------|-------------|
| tailwindcss | npm | 8+ yrs | 110M | github.com/tailwindlabs/tailwindcss | OK | Approved |
| alpinejs | npm | 5+ yrs | 543K | github.com/alpinejs/alpine | OK | Approved |
| @supabase/supabase-js | npm | 4+ yrs | 19.5M | github.com/supabase/supabase-js | SUS (recent release) | Approved — SUS verdict is "too-new" for latest release only; package is established with 19.5M weekly downloads and official Supabase org |
| swiper | npm | 10+ yrs | 4.2M | github.com/nolimits4web/Swiper | SUS (recent release) | Approved if used — same "too-new" signal on latest release; well-established package |

**Packages removed due to SLOP verdict:** none

**Packages flagged as suspicious SUS:** @supabase/supabase-js and swiper show "too-new" signal due to recent releases, not due to legitimacy concerns. Both are well-established packages from known organizations. No checkpoint:human-verify required given context.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser (visitor)
       │
       ▼
HTML page (index.html / about.html / contact.html)
       │ loads
       ├─── /css/style.css  ←── Tailwind CLI compiled from src/input.css
       ├─── Google Fonts CDN (Playfair Display, Poppins)
       ├─── Alpine.js CDN (defer)
       └─── <script type="module" src="/js/components.js">
                  │
                  ├── imports /js/supabase.js  ←── reads window.__ENV.*
                  │         │
                  │         └── createClient(URL, ANON_KEY) → supabase client
                  │
                  ├── registers Alpine stores (alpine:init event)
                  │       Alpine.store('cart', { count: 0 })
                  │       Alpine.store('auth', { user: null })
                  │
                  ├── injects navHTML → document.getElementById('nav-root')
                  ├── injects footerHTML → document.getElementById('footer-root')
                  └── sets active nav link class (window.location.pathname)

Alpine.js (after stores registered, processes x-data on DOM)
       │
       ├── Nav scroll behavior (x-init window.scroll listener on nav element)
       ├── Mobile nav drawer (x-show navOpen + transitions)
       ├── Best sellers (async init() → supabase.from('products').select().limit(4))
       ├── Testimonials (async init() → supabase.from('testimonials').select().eq(...).limit(3))
       ├── Newsletter form (x-on:submit.prevent → supabase.from('newsletter_subscribers').insert())
       └── FAQ accordion (x-data { activeIndex: null } + x-show per item)

Supabase (read/write)
       │
       ├── products table  ──→ best sellers section
       ├── testimonials table ──→ testimonials section
       └── newsletter_subscribers table ←── newsletter form insert
```

### Recommended Project Structure (Phase 02 additions)

```
/                          (project root)
├── index.html             FILL: 8 sections + nav/footer placeholder divs
├── about.html             FILL: editorial brand story layout
├── contact.html           FILL: FAQ accordion + contact info
├── shop.html              ADD: nav/footer placeholder divs only
├── product.html           ADD: nav/footer placeholder divs only
├── cart.html              ADD: nav/footer placeholder divs only
├── checkout.html          ADD: nav/footer placeholder divs only
├── auth.html              ADD: nav/footer placeholder divs only
├── account.html           ADD: nav/footer placeholder divs only
├── style-match.html       ADD: nav/footer placeholder divs only
├── admin.html             ADD: nav/footer placeholder divs only (no footer)
├── css/
│   └── style.css          OUTPUT from Tailwind CLI (do not edit manually)
├── js/
│   ├── components.js      CREATE: nav + footer HTML strings, store init, active link
│   ├── supabase.js        ALREADY EXISTS (reads window.__ENV)
│   ├── auth.js            STUB — do not modify in Phase 2
│   ├── cart.js            STUB — do not modify in Phase 2
│   ├── products.js        STUB — do not modify in Phase 2
│   └── __env.js           GENERATED by Netlify build command
└── src/
    └── input.css          EXTEND ONLY — tokens already defined
```

---

## Tailwind v4 @theme Tokens

### Current State (from `src/input.css`)

All brand color and font tokens are already defined. **Do not redefine them.** [VERIFIED: reading src/input.css]

```css
@import "tailwindcss";

@theme {
  --color-sage: #A8BFA3;
  --color-rose: #D8A7A7;
  --color-beige: #F5F1ED;
  --color-charcoal: #2E2E2E;
  --color-lavender: #C6B7E2;
  --color-sage-light: #E8F0E6;
  --color-rose-light: #F5E8E8;
  --color-text-muted: #8A8A8A;

  --font-display: 'Playfair Display', serif;
  --font-body: 'Poppins', sans-serif;
}
```

### How v4 @theme Works [CITED: tailwindcss.com/docs/theme]

Tokens in `@theme` automatically generate utility classes:
- `--color-sage` → `bg-sage`, `text-sage`, `border-sage`, `ring-sage`
- `--color-beige` → `bg-beige`, `text-beige`, etc.
- `--font-display` → `font-display` class
- `--font-body` → `font-body` class

**Color opacity modifier syntax:** Use Tailwind's slash syntax — e.g., `bg-beige/90` (90% opacity), `text-charcoal/65`, `border-sage/20`. This works automatically with the generated color utilities.

**Arbitrary values for clamp():** Use bracket notation for values outside the scale — `text-[clamp(48px,5vw,72px)]`. [CITED: tailwindcss.com/docs/adding-custom-styles]

**No `tailwind.config.js` in v4.** All configuration happens in CSS. The `@theme` block IS the config.

### Tokens to Add (if needed)

If the executor needs spacing tokens not in the default scale, add to `src/input.css`:

```css
@theme {
  /* Only add if Tailwind default scale is insufficient */
  /* Default scale already includes: 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96 */
  /* These map to px at 4px per unit: p-4=16px, py-24=96px, py-20=80px, py-25=100px (via p-[100px]) */
}
```

Most spacing in the UI-SPEC maps cleanly to existing Tailwind defaults:
- 4px → `gap-1`, `p-1`
- 8px → `gap-2`, `p-2`
- 16px → `p-4`, `gap-4`
- 24px → `p-6`, `gap-6`
- 32px → `p-8`
- 48px → `p-12`, `px-12`
- 64px → `p-16`, `px-16`
- 72px → `pt-[72px]` (no direct mapping)
- 80px → `p-20`, `py-20`
- 100px → `py-[100px]` or `py-25` (check if 25 exists in v4 default)

### Custom Component Utilities (@layer components)

Add semantic classes for frequently repeated patterns. In `src/input.css`:

```css
@layer components {
  .section-label {
    font-size: 10px;
    letter-spacing: 5px;
    text-transform: uppercase;
    color: var(--color-sage);
    font-weight: 500;
  }

  .section-title {
    font-family: var(--font-display);
    font-size: clamp(32px, 4vw, 52px);
    font-weight: 700;
    line-height: 1.15;
    color: var(--color-charcoal);
  }

  .btn-primary {
    background-color: var(--color-charcoal);
    color: white;
    padding: 16px 36px;
    border-radius: 9999px;
    font-size: 12px;
    letter-spacing: 2px;
    text-transform: uppercase;
    font-weight: 500;
    transition: all 0.3s;
    font-family: var(--font-body);
  }

  .btn-primary:hover {
    background-color: var(--color-rose);
    transform: translateY(-2px);
  }

  .btn-secondary {
    background-color: transparent;
    color: var(--color-charcoal);
    padding: 16px 36px;
    border: 1.5px solid var(--color-charcoal);
    border-radius: 9999px;
    font-size: 12px;
    letter-spacing: 2px;
    text-transform: uppercase;
    font-weight: 500;
    transition: all 0.3s;
    font-family: var(--font-body);
  }

  .btn-secondary:hover {
    border-color: var(--color-rose);
    color: var(--color-rose);
  }
}
```

**Note:** Tailwind utility classes override `@layer components` styles. The Tailwind-first approach (composing utilities in HTML) is preferred for one-off styling; `@layer components` is for patterns repeated 4+ times across pages.

---

## Architecture Patterns

### Pattern 1: js/components.js — Shared Nav + Footer

**What:** ES module that injects nav and footer HTML strings into placeholder divs, registers Alpine stores, and sets active nav link class.

**When to use:** Called via `<script type="module" src="/js/components.js">` on every page.

**Critical sequencing requirement:** Alpine stores must be registered in the `alpine:init` event (which fires before Alpine processes `x-data`). The script tag for `js/components.js` must appear BEFORE the Alpine.js `<script defer>` tag in HTML `<head>` — or more reliably, register stores inside the `alpine:init` event listener. [CITED: alpinejs.dev/globals/alpine-store]

```javascript
// js/components.js
import { supabase } from './supabase.js';

// Register Alpine stores BEFORE Alpine boots
document.addEventListener('alpine:init', () => {
  Alpine.store('cart', {
    count: 0,
    items: []
  });
  Alpine.store('auth', {
    user: null,
    loggedIn: false
  });
});

// Nav HTML string
const navHTML = `
<nav
  x-data="{
    navOpen: false,
    scrolled: false,
    init() {
      window.addEventListener('scroll', () => {
        this.scrolled = window.scrollY > 80;
      });
    }
  }"
  :class="scrolled
    ? 'bg-beige/90 backdrop-blur-md border-b border-sage/20'
    : 'bg-transparent'"
  class="fixed top-0 left-0 right-0 z-[100] flex items-center justify-between px-12 py-5 transition-all duration-300"
>
  <!-- Logo -->
  <a href="/index.html" class="font-display font-bold text-2xl tracking-widest text-charcoal no-underline">
    EL<span class="inline-block"><!-- flower SVG --></span>RA
  </a>

  <!-- Desktop nav links (hidden on mobile) -->
  <ul class="hidden md:flex gap-9 list-none">
    <li><a href="/index.html" data-page="/" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal no-underline hover:text-rose transition-colors">New Arrivals</a></li>
    <li><a href="/shop.html" data-page="/shop.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal no-underline hover:text-rose transition-colors">Collections</a></li>
    <li><a href="/style-match.html" data-page="/style-match.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal no-underline hover:text-rose transition-colors">Style Match</a></li>
    <li><a href="/about.html" data-page="/about.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal no-underline hover:text-rose transition-colors">About</a></li>
    <li><a href="/contact.html" data-page="/contact.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal no-underline hover:text-rose transition-colors">Contact</a></li>
  </ul>

  <!-- Nav actions -->
  <div class="flex items-center gap-5">
    <!-- Search icon -->
    <button aria-label="Search" class="w-11 h-11 flex items-center justify-center text-charcoal hover:text-rose transition-colors">
      <!-- SVG -->
    </button>
    <!-- User icon -->
    <a href="/auth.html" aria-label="Your account" class="w-11 h-11 flex items-center justify-center text-charcoal hover:text-rose transition-colors">
      <!-- SVG -->
    </a>
    <!-- Cart bag icon with badge -->
    <a href="/cart.html" aria-label="Shopping bag" class="relative w-11 h-11 flex items-center justify-center text-charcoal hover:text-rose transition-colors">
      <!-- SVG -->
      <span
        x-show="$store.cart.count > 0"
        x-text="$store.cart.count"
        class="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose text-white text-[9px] font-semibold flex items-center justify-center"
      ></span>
    </a>
    <!-- Hamburger (mobile only) -->
    <button
      @click="navOpen = true"
      aria-label="Open navigation menu"
      class="md:hidden w-11 h-11 flex items-center justify-center"
    >
      <!-- hamburger SVG -->
    </button>
  </div>

  <!-- Mobile Drawer -->
  <div
    x-show="navOpen"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="translate-x-full"
    x-transition:enter-end="translate-x-0"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="translate-x-0"
    x-transition:leave-end="translate-x-full"
    @keydown.escape.window="navOpen = false"
    class="fixed inset-y-0 right-0 w-72 bg-charcoal z-[200] flex flex-col p-8"
    style="display: none;"
  >
    <button @click="navOpen = false" aria-label="Close navigation menu" class="self-end mb-8 text-white"><!-- X SVG --></button>
    <ul class="list-none flex flex-col gap-6">
      <li><a href="/index.html" class="text-white text-base tracking-widest uppercase font-medium">New Arrivals</a></li>
      <!-- ... other links -->
    </ul>
  </div>
  <!-- Backdrop -->
  <div x-show="navOpen" @click="navOpen = false" class="fixed inset-0 bg-charcoal/50 z-[150]" style="display:none;"></div>
</nav>`;

// Footer HTML string (abbreviated — full content in implementation)
const footerHTML = `
<footer class="bg-charcoal text-white pt-[72px] pb-10">
  <!-- 4-column grid, social icons, links, copyright -->
</footer>`;

// Inject
const navRoot = document.getElementById('nav-root');
const footerRoot = document.getElementById('footer-root');
if (navRoot) navRoot.innerHTML = navHTML;
if (footerRoot) footerRoot.innerHTML = footerHTML;

// Set active nav link
const currentPath = window.location.pathname;
document.querySelectorAll('.nav-link').forEach(link => {
  const href = link.getAttribute('href');
  const isActive = href === currentPath
    || (currentPath === '/' && href === '/index.html')
    || (currentPath.endsWith('/') && href === '/index.html');
  if (isActive) {
    link.classList.add('text-sage', 'border-b', 'border-sage');
  }
});
```

**Source:** [CITED: alpinejs.dev/globals/alpine-store], [CITED: alpinejs.dev/directives/init]

### Pattern 2: Alpine.js Async Data Fetch (Best Sellers + Testimonials)

**What:** x-data component with async `init()` method, loading skeleton, x-for rendering.

**When to use:** Any section that fetches from Supabase on page load.

```html
<!-- Best Sellers section -->
<section
  x-data="{
    products: [],
    loading: true,
    error: false,
    async init() {
      try {
        const { data, error } = await supabase
          .from('products')
          .select('id, name, price, product_images(*), product_variants(color_name, color_hex)')
          .order('created_at', { ascending: false })
          .limit(4);
        if (error) throw error;
        this.products = data || [];
      } catch (e) {
        this.error = true;
        // Fallback: keep empty array, show static fallback cards
      } finally {
        this.loading = false;
      }
    }
  }"
  class="bg-beige py-[100px] px-16"
>
  <!-- Skeleton loading state -->
  <div x-show="loading" class="grid grid-cols-4 gap-6">
    <template x-for="i in 4" :key="i">
      <div class="bg-sage-light animate-pulse rounded-[20px] aspect-[3/4]"></div>
    </template>
  </div>

  <!-- Error fallback -->
  <div x-show="error && !loading" class="text-center text-text-muted py-12">
    <p class="font-display text-2xl mb-2">Our best sellers are on their way.</p>
    <a href="/shop.html" class="text-sage underline">Explore our full collection in the meantime.</a>
  </div>

  <!-- Product grid -->
  <div x-show="!loading && !error" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
    <template x-for="product in products" :key="product.id">
      <div class="bg-white rounded-[20px] overflow-hidden cursor-pointer transition-all duration-300 hover:-translate-y-1.5 hover:shadow-[0_20px_48px_rgba(0,0,0,0.08)]">
        <div class="aspect-[3/4] relative overflow-hidden">
          <img
            :src="product.product_images?.[0]?.image_url + '?width=400&quality=75'"
            :alt="product.name"
            class="w-full h-full object-cover transition-transform duration-[600ms] hover:scale-[1.08]"
            loading="lazy"
            width="400" height="533"
          />
        </div>
        <div class="p-5">
          <h3 x-text="product.name" class="font-display text-base font-semibold text-charcoal mb-1.5"></h3>
          <p class="text-[11px] text-text-muted tracking-[1px] uppercase mb-3">Activewear</p>
          <div class="flex items-center justify-between">
            <span x-text="'$' + product.price" class="font-body text-base font-semibold text-charcoal"></span>
          </div>
        </div>
      </div>
    </template>
  </div>
</section>
```

**Source:** [CITED: alpinejs.dev/advanced/async], [CITED: supabase.com/docs/reference/javascript/select]

### Pattern 3: Newsletter Form — Supabase Insert

**What:** Alpine.js form with email validation, loading state, success/error/duplicate handling.

**When to use:** `index.html` newsletter section.

```html
<section
  x-data="{
    email: '',
    submitted: false,
    loading: false,
    errorMsg: '',
    async submitNewsletter() {
      if (!this.email || !this.email.includes('@')) return;
      this.loading = true;
      this.errorMsg = '';
      try {
        const { error } = await supabase
          .from('newsletter_subscribers')
          .insert({ email: this.email });

        if (error) {
          if (error.code === '23505') {
            // Duplicate email — treat as success
            this.errorMsg = 'You\\'re already part of the inner circle.';
          } else {
            this.errorMsg = 'Something went wrong — please try again.';
          }
        } else {
          this.submitted = true;
        }
      } catch (e) {
        this.errorMsg = 'Something went wrong — please try again.';
      } finally {
        this.loading = false;
      }
    }
  }"
  class="bg-sage py-20 px-16 text-center"
>
  <!-- Success state -->
  <div x-show="submitted">
    <p class="font-display text-3xl font-bold text-white italic">
      You\\'re on the list. Welcome to Elvora.
    </p>
  </div>

  <!-- Form state -->
  <div x-show="!submitted">
    <h2 class="font-display text-[clamp(28px,4vw,48px)] font-bold text-white mb-3">Join the Inner Circle</h2>
    <p class="text-white/75 text-[15px] font-light mb-10">Be the first to discover new collections, exclusive offers, and style inspiration.</p>
    <form
      @submit.prevent="submitNewsletter"
      class="flex max-w-[480px] mx-auto bg-white rounded-full overflow-hidden shadow-[0_8px_32px_rgba(0,0,0,0.1)]"
    >
      <input
        type="email"
        x-model="email"
        placeholder="Your email address"
        aria-label="Email address"
        required
        class="flex-1 border-none outline-none px-7 bg-transparent text-charcoal font-body"
        style="font-size: 16px;"
      />
      <button
        type="submit"
        :disabled="loading"
        :class="loading ? 'opacity-60 cursor-not-allowed' : ''"
        class="bg-charcoal text-white px-8 rounded-full m-1 text-[12px] tracking-[2px] uppercase font-medium font-body transition-colors hover:bg-rose"
      >
        <span x-show="!loading">Join the Circle</span>
        <span x-show="loading">…</span>
      </button>
    </form>
    <!-- Error message -->
    <p x-show="errorMsg" x-text="errorMsg" class="text-white/80 text-sm mt-4"></p>
  </div>
</section>
```

**Source:** [CITED: supabase.com/docs/reference/javascript/insert], [CITED: alpinejs.dev/directives/init]

### Pattern 4: Nav Scroll Transparency

**What:** Alpine x-data on nav element listens to window scroll and toggles frosted glass class.

```html
<nav
  x-data="{
    scrolled: false,
    init() {
      // Use passive listener for performance
      window.addEventListener('scroll', () => {
        this.scrolled = window.scrollY > 80;
      }, { passive: true });
    }
  }"
  :class="scrolled
    ? 'bg-beige/90 backdrop-blur-md border-b border-sage/20'
    : 'bg-transparent'"
  class="fixed top-0 left-0 right-0 z-[100] transition-all duration-300 ..."
>
```

**Non-index pages:** Nav always uses the frosted glass state. Add `scrolled: true` as default for non-index pages. In `js/components.js`, detect `window.location.pathname !== '/'` and set a data attribute or use a different nav template. [ASSUMED]

**Source:** [CITED: lexingtonthemes.com tutorial (verified pattern)], [CITED: alpinejs.dev/directives/init]

### Pattern 5: FAQ Accordion

**What:** Alpine x-data with `activeIndex` state; only one item open at a time.

```html
<div x-data="{ activeIndex: null }" class="max-w-2xl mx-auto">
  <template x-for="(faq, i) in faqs" :key="i">
    <div class="border-b border-sage/20">
      <button
        @click="activeIndex = activeIndex === i ? null : i"
        :aria-expanded="activeIndex === i"
        class="flex items-center justify-between w-full py-5 text-left font-body text-[15px] font-medium text-charcoal"
      >
        <span x-text="faq.q"></span>
        <svg
          :class="activeIndex === i ? 'rotate-180' : ''"
          class="w-5 h-5 text-charcoal transition-transform duration-200 flex-shrink-0"
          ...
        />
      </button>
      <div
        x-show="activeIndex === i"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 -translate-y-2"
        x-transition:enter-end="opacity-100 translate-y-0"
        class="pb-5 text-[15px] font-light leading-[1.8] text-text-muted"
      >
        <p x-text="faq.a"></p>
      </div>
    </div>
  </template>
</div>
```

**Source:** [CITED: alpinejs.dev/directives/show], [CITED: 02-UI-SPEC.md interaction contracts]

### Pattern 6: Marquee Strip (CSS-only)

**What:** CSS keyframes animation on duplicated content for seamless infinite scroll.

```html
<div class="bg-charcoal py-4 overflow-hidden" aria-hidden="true">
  <div class="marquee-track flex gap-[60px] w-max">
    <!-- First set -->
    <div class="marquee-items flex gap-[60px] flex-shrink-0">
      <span class="marquee-item text-[11px] tracking-[4px] uppercase text-white/60 flex items-center gap-5">
        New Arrivals <span class="w-1 h-1 rounded-full bg-rose flex-shrink-0"></span>
      </span>
      <!-- repeat items -->
    </div>
    <!-- Duplicate set (aria-hidden already on parent) -->
    <div class="marquee-items flex gap-[60px] flex-shrink-0">
      <!-- same items duplicated -->
    </div>
  </div>
</div>
```

```css
/* In src/input.css @layer utilities or @layer base */
@keyframes marquee {
  from { transform: translateX(0); }
  to { transform: translateX(-50%); }
}

.marquee-track {
  animation: marquee 20s linear infinite;
}

@media (prefers-reduced-motion: reduce) {
  .marquee-track { animation: none; }
}
```

**Critical:** Translate exactly `-50%` — not pixels. The duplicate content makes the track 2x wide, so -50% returns to the start precisely. [CITED: ryanmulligan.dev/blog/css-marquee/]

### Pattern 7: CSS Grid — Asymmetric Collections Layout

**What:** `grid-template-columns: 2fr 1fr 1fr` with first card spanning 2 rows.

```html
<div class="grid gap-4" style="grid-template-columns: 2fr 1fr 1fr;">
  <!-- Card 1: large, spans 2 rows -->
  <a
    href="/shop.html?category=padel"
    class="rounded-[20px] overflow-hidden relative cursor-pointer hover:scale-[1.02] transition-transform duration-400"
    style="grid-row: span 2; min-height: 520px;"
  >
    <div class="absolute inset-0 bg-gradient-to-br from-sage to-[#7A9E75]"></div>
    <!-- content -->
  </a>
  <!-- Cards 2–4: medium, 248px min-height -->
  <a href="/shop.html?category=pilates" class="rounded-[20px] overflow-hidden relative" style="min-height: 248px;">
    <div class="absolute inset-0 bg-gradient-to-br from-rose to-[#C47B7B]"></div>
  </a>
  <!-- ... -->
</div>
```

**Tailwind v4 note:** Tailwind does not generate `grid-cols-[2fr_1fr_1fr]` by default. Use inline `style="grid-template-columns: 2fr 1fr 1fr;"` or add it as an arbitrary value `class="grid-cols-[2fr_1fr_1fr]"`. The inline style approach is more readable for this specific layout. [ASSUMED — Tailwind v4 arbitrary grid values should work but verify at build time]

### Pattern 8: HTML Placeholder Structure (All Pages)

Every HTML page needs these placeholders before components.js can inject:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PAGE TITLE — ELVORA</title>
  <!-- Preconnect for Google Fonts performance -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <!-- Load only weights used: Playfair 700/700i + Poppins 400/600 -->
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;1,700&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
  <!-- Alpine.js AFTER components.js reference but loaded defer -->
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js"></script>
</head>
<body>
  <div id="nav-root"></div>

  <main>
    <!-- page content -->
  </main>

  <div id="footer-root"></div>

  <!-- __env.js must load BEFORE supabase.js -->
  <script src="/js/__env.js"></script>
  <script type="module" src="/js/supabase.js"></script>
  <script type="module" src="/js/components.js"></script>
</body>
</html>
```

**Load order matters:** `__env.js` → `supabase.js` → `components.js` → Alpine (defer). The Alpine defer attribute means it runs after DOM is parsed, which means `alpine:init` fires after `components.js` has registered the listener. This is the correct order. [CITED: alpinejs.dev/essentials/installation]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Supabase duplicate email detection | Custom check-before-insert query | Check `error.code === '23505'` after insert | Race conditions; Postgres handles it atomically |
| Seamless marquee loop | JavaScript scroll reset on overflow | CSS `translateX(-50%)` on duplicated DOM content | JS approach has visible jump at reset; CSS is smooth |
| Alpine store cross-page state | localStorage sync or global JS variables | `Alpine.store()` with `alpine:init` | Alpine reactivity + CDN; no custom sync needed |
| Font subset loading | Manually subsetting font files | Google Fonts URL params (`wght@400;600`) | GF handles subsetting automatically |
| Mobile nav focus trap | Custom `tabindex` management | Escape key handler `@keydown.escape.window` | Browser handles most focus management; Escape is the critical one |
| Responsive grid breakpoints | Custom media queries | Tailwind `sm:`, `md:`, `lg:`, `xl:` prefixes | Already defined at 640px, 768px, 1024px, 1280px |
| Active nav link state | Server-side template logic | JavaScript `window.location.pathname` comparison | Static HTML; no server templates available |

**Key insight:** The most dangerous hand-roll in this phase is reinventing Alpine.js store initialization. The `alpine:init` event + `Alpine.store()` pattern is the official way and handles CDN script load ordering correctly.

---

## Common Pitfalls

### Pitfall 1: Alpine Store Registered After Alpine Boots

**What goes wrong:** `Alpine.store('cart', ...)` called outside `alpine:init` or after Alpine has already processed the DOM — stores are undefined when `x-data` components try to read `$store.cart`.

**Why it happens:** `js/components.js` is a module loaded with `<script type="module">` which is deferred. If Alpine's `defer` script executes before `components.js`, stores aren't registered when Alpine boots.

**How to avoid:** Always register stores inside `document.addEventListener('alpine:init', () => { ... })`. The `alpine:init` event fires synchronously during Alpine's startup, before `x-data` is processed. This event is safe to listen for even if the listener is added before Alpine's script is parsed. [CITED: alpinejs.dev/globals/alpine-store]

**Warning signs:** Console error "Cannot read properties of undefined (reading 'count')" when accessing `$store.cart.count`.

### Pitfall 2: Supabase Client Not Initialized Before Alpine Components Run

**What goes wrong:** `supabase.from(...)` throws because `window.__ENV` is undefined — `__env.js` hasn't loaded yet.

**Why it happens:** `__env.js` is a plain `<script src="...">` that generates `window.__ENV`. If it's placed after the module scripts in the HTML, modules that run first read `undefined`.

**How to avoid:** Place `<script src="/js/__env.js">` as the FIRST script in `<body>`, before any `<script type="module">` tags. Plain scripts (non-module, non-defer) execute in order and block subsequent module execution. [ASSUMED — standard script loading behavior]

**Warning signs:** "Cannot read properties of undefined (reading 'SUPABASE_URL')" in console. Products section shows loading skeleton indefinitely.

### Pitfall 3: iOS Safari Input Auto-Zoom

**What goes wrong:** Newsletter input causes the page to zoom in on iOS when tapped, breaking the fixed nav and creating a jarring UX.

**Why it happens:** iOS Safari auto-zooms on any `<input>` with `font-size` below 16px.

**How to avoid:** Set `style="font-size: 16px;"` on the newsletter `<input>` element. The larger font size only applies to the input — the surrounding form can still use smaller text. [CITED: 02-UI-SPEC.md typography rules]

**Warning signs:** Page zooms on iPhone when tapping newsletter email input.

### Pitfall 4: Marquee Animation Jump at Loop Point

**What goes wrong:** Scrolling marquee text visibly jumps/resets mid-animation.

**Why it happens:** Either the `translateX` amount doesn't exactly match the width of one content set, or the content isn't perfectly duplicated.

**How to avoid:** Duplicate the ENTIRE set of marquee items as a second child of `.marquee-track`. Animate `translateX(-50%)` — not a pixel value. Because the track is exactly 2x the content width, -50% returns to the exact start pixel. [CITED: ryanmulligan.dev/blog/css-marquee/]

**Warning signs:** Visible "reset" flash during marquee scroll. Fix: increase animation duration or verify duplication.

### Pitfall 5: `components.js` innerHTML and Alpine.js

**What goes wrong:** Injecting nav HTML with `element.innerHTML = navHTML` after Alpine has already booted means Alpine doesn't process the newly injected `x-data` attributes.

**Why it happens:** Alpine only processes elements present when it initializes (or added via `Alpine.initTree()`).

**How to avoid:** Either (a) inject HTML synchronously from a `<script type="module">` before Alpine's `defer` script executes (module scripts are deferred but deterministic after DOM parsing), or (b) call `Alpine.initTree(navRoot)` after injection. Option (a) is the safer pattern with CDN Alpine. The module script approach works because module scripts are queued after DOM parsing but before Alpine's `defer` script processes elements if `components.js` registers its content synchronously. [ASSUMED — verify with Alpine CDN behavior]

**Warning signs:** Hamburger button click does nothing; nav scroll class doesn't change.

### Pitfall 6: Tailwind Not Picking Up Classes in Injected HTML

**What goes wrong:** Tailwind CSS CLI doesn't generate utility classes for strings in `js/components.js` because the CLI scans `.html`, `.js`, `.ts` files but the nav HTML is a JavaScript string, not an HTML file.

**Why it happens:** Tailwind v4 CLI by default scans all files in the project directory. JS template literal strings ARE scanned — but only if the Tailwind CLI is pointed to the right directories.

**How to avoid:** Tailwind v4 CLI auto-detects all files (including `.js`) in the project. Since `js/components.js` contains the nav HTML as a string, Tailwind will scan it and pick up all utility classes used there. No additional configuration needed. [CITED: tailwindcss.com/docs/detecting-classes-in-source-files]

**Warning signs:** Nav appears unstyled after `npm run build:css`. Fix: run `npm run build:css` after writing `js/components.js`, not before.

### Pitfall 7: Google Fonts Loading Wrong Weights

**What goes wrong:** Existing HTML shells load Poppins weights 300, 400, 500, 600 — UI-SPEC says only 400 and 600 are used. Weight 300 adds extra bytes.

**Why it happens:** Phase 01 scaffold used a generic Google Fonts URL.

**How to avoid:** Update font URL in all HTML shells:

```html
<!-- Wrong (Phase 01) -->
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,500;0,700;1,400;1,500&family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">

<!-- Correct (Phase 02 — only weights used per UI-SPEC) -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;1,700&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
```

**Warning signs:** Poppins 300 (light weight) being applied incorrectly to elements; extra font bytes loaded unnecessarily.

---

## Code Examples

Verified patterns from official or authoritative sources:

### Supabase Insert with Duplicate Handling

```javascript
// Source: supabase.com/docs/reference/javascript/insert + PostgreSQL error codes
const { error } = await supabase
  .from('newsletter_subscribers')
  .insert({ email: this.email });

if (error) {
  if (error.code === '23505') {
    // PostgreSQL unique_violation — email already exists
    this.errorMsg = "You're already part of the inner circle.";
  } else {
    this.errorMsg = 'Something went wrong — please try again.';
  }
} else {
  this.submitted = true;
}
```

### Supabase Products Query (Best Sellers)

```javascript
// Source: supabase.com/docs/reference/javascript/select
const { data, error } = await supabase
  .from('products')
  .select('id, name, price, product_images(*), product_variants(color_name, color_hex)')
  .order('created_at', { ascending: false })
  .limit(4);
```

### Alpine Store Registration (CDN)

```javascript
// Source: alpinejs.dev/globals/alpine-store
document.addEventListener('alpine:init', () => {
  Alpine.store('cart', {
    count: 0,
    items: []
  });
  Alpine.store('auth', {
    user: null,
    loggedIn: false
  });
});
```

### Tailwind v4 Existing Token Usage

```html
<!-- Source: tailwindcss.com/docs/theme — tokens already defined in src/input.css -->
<div class="bg-beige text-charcoal font-body">   <!-- brand colors work -->
<h2 class="font-display text-sage">              <!-- custom fonts work -->
<div class="bg-charcoal/90 backdrop-blur-md">    <!-- opacity modifier works -->
<p class="text-[clamp(32px,4vw,52px)]">          <!-- arbitrary clamp works -->
```

### Active Nav Link Detection

```javascript
// Source: window.location API (standard browser API)
const currentPath = window.location.pathname;
document.querySelectorAll('[data-page]').forEach(link => {
  const href = link.getAttribute('href');
  // Normalize: /index.html should match /
  const isHome = href === '/index.html' && (currentPath === '/' || currentPath === '/index.html');
  const isActive = isHome || href === currentPath;
  if (isActive) {
    link.classList.add('text-rose'); // or text-sage per design preference
  }
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tailwind.config.js` for theme | `@theme {}` directive in CSS | Tailwind v4 (2024) | No JS config file; tokens are CSS variables directly |
| `purgeCSS` config array | Auto content detection | Tailwind v4 | CLI scans all project files automatically |
| `theme.extend.colors` object | `--color-*` CSS variables | Tailwind v4 | Utility classes auto-generated from CSS vars |
| Alpine v2 `x-data` initialization | `init()` method in x-data object | Alpine v3 | Cleaner; auto-called; supports async |
| `fetch('/header.html')` for shared nav | innerHTML string injection from JS module | Community standard for no-build static sites | fetch() blocked on file:// protocol; string injection works everywhere |

**Deprecated/outdated:**
- `font-display: optional` instead of `swap`: optional has lower CLS but shows blank on slow connections; `swap` is recommended for brand typography where the font is essential to identity
- Alpine v2 `@click` with `x-data="{ open: false }"` on separate elements: v3 uses `x-data` with `init()` method; same for this project but the pattern is backward compatible

---

## Runtime State Inventory

This is a build-phase / frontend phase with no renames or data migrations. Skip runtime state inventory — not applicable. [VERIFIED: phase is purely additive HTML/CSS/JS; no existing data structures renamed]

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Tailwind CLI build | ✓ | 20 (per netlify.toml) | — |
| npm | package.json dependencies | ✓ | bundled with Node.js | — |
| @tailwindcss/cli (npm) | CSS compilation | ✓ | ^4 in devDependencies | — |
| Supabase project | Products + testimonials data | ✓ (Phase 01 complete) | PostgreSQL with seeded data | Static fallback cards if DB unreachable |
| Google Fonts CDN | Typography | ✓ (external CDN) | — | System serif/sans fallback via CSS stack |
| Alpine.js CDN | UI reactivity | ✓ (external CDN) | 3.15.12 | No JS fallback needed; forms degrade gracefully |
| Netlify build environment | window.__ENV injection | ✓ | per netlify.toml | Local: create js/__env.js manually |

**Missing dependencies with no fallback:** None.

**Local development note:** The `js/__env.js` file is generated by the Netlify build command. For local development, create it manually:

```javascript
// js/__env.js (local dev — DO NOT COMMIT)
window.__ENV = {
  SUPABASE_URL: 'your-supabase-url',
  SUPABASE_ANON_KEY: 'your-anon-key'
};
```

---

## Validation Architecture

> `workflow.nyquist_validation` is not explicitly set to false in config.json; treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — no automated test framework detected |
| Config file | none |
| Quick run command | Manual browser inspection |
| Full suite command | Visual regression via 4-breakpoint browser testing |

No test framework is installed or expected for this phase. Assessment grading is visual/functional, not automated-test-based. Verification happens via browser testing at 4 breakpoints.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| F-001 | Hero renders at all 4 breakpoints, no horizontal scroll | Manual visual | Open index.html in browser at 375/768/1024/1280px | ❌ Wave 0 |
| F-002 | Collections cards link to shop.html?category={slug} | Manual click | Click each card, verify URL params | ❌ Wave 0 |
| F-003 | Best sellers fetches 4 products and renders | Manual visual | Load index.html, verify 4 cards appear | ❌ Wave 0 |
| F-004 | Lookbook grid shows 6 images with hover overlay | Manual visual | Hover each lookbook item | ❌ Wave 0 |
| F-005 | Brand story renders with stats, links to about.html | Manual click | Click "Discover Our Story" link | ❌ Wave 0 |
| F-006 | Testimonials fetches 3 rows from Supabase | Manual visual | Load index.html, verify 3 testimonial cards | ❌ Wave 0 |
| F-007 | Newsletter inserts email, shows success message | Manual form | Submit valid email, verify Supabase row created | ❌ Wave 0 |
| F-007 | Newsletter shows duplicate message on repeat | Manual form | Submit same email twice | ❌ Wave 0 |
| F-043 | About page renders editorial layout | Manual visual | Navigate to about.html | ❌ Wave 0 |
| F-044 | FAQ accordion opens/closes one item at a time | Manual click | Click FAQ items on contact.html | ❌ Wave 0 |
| F-045 | Nav consistent across all pages, active state correct | Manual navigation | Click through all pages, verify active link | ❌ Wave 0 |
| NF-001 | No horizontal scroll at 375px | Manual DevTools | Chrome DevTools: 375px device width | ❌ Wave 0 |
| NF-002 | Hero LCP < 3s | Lighthouse | Chrome Lighthouse audit on deployed URL | ❌ Wave 0 |
| NF-003 | Keyboard nav, aria-label on all interactive elements | Manual keyboard | Tab through page, verify focus order | ❌ Wave 0 |

### Wave 0 Gaps

None — no test infrastructure to create. All verification is manual browser testing per the assessment format.

---

## Security Domain

> `security_enforcement: true` per config.json. ASVS Level 1 required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No — Phase 2 has no auth flows (stubbed only) | — |
| V3 Session Management | No — no sessions in Phase 2 | — |
| V4 Access Control | Partial — newsletter_subscribers table must have RLS enabled | Supabase RLS: INSERT allowed for anon, no SELECT/DELETE for anon |
| V5 Input Validation | Yes — newsletter email input | HTML5 `type="email"` + Alpine `x-on:submit.prevent` checks non-empty; server validates via Postgres constraint |
| V6 Cryptography | No — no cryptographic operations | — |

### newsletter_subscribers RLS Policy

The newsletter_subscribers table (created in Phase 1) requires these RLS policies:
- `INSERT`: `USING (true)` — allow any anon insert
- `SELECT`: `USING (auth.uid() IS NOT NULL)` — logged-in users only (or `USING (false)` — admin only)
- No `UPDATE` or `DELETE` for anon

Verify these policies exist before testing the newsletter form. If missing, anonymous inserts will be rejected by RLS. [CITED: supabase.com/docs/guides/database/postgres/row-level-security]

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Newsletter spam / bulk inserts | Denial of Service | Rate limiting at Supabase/Netlify level (not Phase 2 scope); unique constraint prevents duplicate data |
| XSS via innerHTML injection (components.js) | Tampering | Nav/footer HTML is a static string authored by the developer — no user input interpolated. Safe. |
| API key exposure | Information Disclosure | Supabase anon key in browser code is by design — RLS enforces access. service_role key MUST NOT appear in any client file. |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Non-index pages should use `scrolled: true` default for nav (always frosted glass) | Pattern 4 | Nav appears transparent over page content on non-index pages — cosmetic issue |
| A2 | `js/components.js` module script + Alpine `defer` load ordering guarantees stores registered before Alpine boots | Pattern 1 / Pitfall 5 | Alpine x-data sees undefined $store — console errors, cart badge missing |
| A3 | Tailwind v4 CLI scans `.js` files automatically for utility classes in string literals | Pitfall 6 | Missing styles in nav/footer; executor would need to add content paths to CLI config |
| A4 | `grid-cols-[2fr_1fr_1fr]` arbitrary value works in Tailwind v4 for asymmetric collection grid | Pattern 7 | Inline style fallback; minimal risk |
| A5 | `newsletter_subscribers` table has INSERT-for-anon RLS policy from Phase 01 schema | Security Domain | Newsletter form gets 401/403 from Supabase; feature broken |

**If A5 is wrong:** The executor must run the Phase 01 RLS policy SQL for newsletter_subscribers before testing the newsletter form. Check via Supabase dashboard → Table Editor → newsletter_subscribers → RLS policies.

---

## Open Questions (RESOLVED)

1. **Alpine CDN + module script load order** — RESOLVED
   - Decision: Register Alpine stores inside `alpine:init` event (safest pattern, explicitly documented by Alpine). If `components.js` injects HTML containing Alpine directives, call `Alpine.initTree(element)` after injection.
   - Rationale: `alpine:init` fires before Alpine processes the DOM, guaranteeing store availability. This is the documented safe pattern.

2. **newsletter_subscribers table RLS policies** — RESOLVED
   - Decision: Executor checks via Supabase dashboard → Table Editor → newsletter_subscribers → RLS policies before testing. If INSERT policy for anon is missing, add: `CREATE POLICY "anon can insert" ON newsletter_subscribers FOR INSERT WITH CHECK (true);`
   - Rationale: Phase 01 schema created the table; the fallback SQL is documented in Plan 04 Task 2 as the verified remediation path.

3. **Tailwind v4 and `grid-cols-[2fr_1fr_1fr]` arbitrary syntax** — RESOLVED
   - Decision: Use inline `style="grid-template-columns: 2fr 1fr 1fr;"` as the safe implementation path for fr-unit grid layouts.
   - Rationale: Underscore-to-space conversion for `fr` units in Tailwind v4 is unverified at build time; inline style avoids the ambiguity entirely and is already the approach used in Plan 02.

---

## Sources

### Primary (MEDIUM confidence — Context7/official docs)

- [Tailwind CSS v4 @theme docs](https://tailwindcss.com/docs/theme) — @theme directive syntax, namespace conventions, v4 vs v3 differences
- [Tailwind CSS adding custom styles](https://tailwindcss.com/docs/adding-custom-styles) — @layer components pattern
- [Alpine.js store() docs](https://alpinejs.dev/globals/alpine-store) — Alpine.store() API, alpine:init event, $store magic
- [Alpine.js init directive](https://alpinejs.dev/directives/init) — x-init, async init(), auto-evaluating init()
- [Alpine.js async docs](https://alpinejs.dev/advanced/async) — async function support in Alpine directives
- [Supabase JS v2 insert reference](https://supabase.com/docs/reference/javascript/insert) — insert() API, error handling

### Secondary (LOW confidence — web search verified)

- [ryanmulligan.dev/blog/css-marquee](https://ryanmulligan.dev/blog/css-marquee/) — Marquee CSS animation -50% translateX technique
- [Lexington Themes Alpine scroll tutorial](https://lexingtonthemes.com/tutorials/how-to-change-background-coloron-scroll-with-tailwind-css-and-alpinejs) — Nav scroll transparency pattern with Alpine
- [Request Metrics: 5 Tips for Google Fonts](https://requestmetrics.com/web-performance/5-tips-to-make-google-fonts-faster/) — preconnect + display=swap optimization
- [MDN: window.location.pathname](https://developer.mozilla.org/en-US/docs/Web/API/Location/pathname) — Active nav link detection

### Project Files Inspected

- `elvora_updated-3.html` [VERIFIED: read directly] — prototype reference; all visual patterns extracted
- `src/input.css` [VERIFIED: read directly] — existing @theme tokens confirmed
- `js/supabase.js` [VERIFIED: read directly] — CDN ESM import, window.__ENV pattern
- `netlify.toml` [VERIFIED: read directly] — Netlify build command, __env.js generation
- `.planning/phases/02-brand-shell-homepage/02-CONTEXT.md` [VERIFIED: read directly] — locked decisions
- `.planning/phases/02-brand-shell-homepage/02-UI-SPEC.md` [VERIFIED: read directly] — component specs, copy, breakpoints

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified on npm registry; already in use from Phase 01
- Tailwind v4 @theme syntax: MEDIUM — verified via official docs; existing `src/input.css` already uses correct v4 syntax
- Alpine.js patterns: MEDIUM — verified via official alpinejs.dev docs; async init() and store() are documented APIs
- Supabase insert + duplicate handling: MEDIUM — verified via official Supabase docs; PostgreSQL error code 23505 is standard
- CSS marquee: LOW — web search pattern, well-established technique
- components.js load order: LOW — ASSUMED based on browser module script spec; validate at implementation time

**Research date:** 2026-06-12
**Valid until:** 2026-07-12 (stable APIs; 30-day validity)
