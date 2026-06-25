# Phase 2: Brand Shell + Homepage — Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 11 (3 filled, 8 placeholder-updated)
**Analogs found:** 7 / 11 (stubs only for placeholder updates; primary analogs from prototype + existing JS)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `js/components.js` | utility/provider | event-driven (alpine:init) | `js/auth.js` + `js/supabase.js` | role-match (module structure) |
| `index.html` | page/component | CRUD (Supabase reads) + request-response | `elvora_updated-3.html` | exact (prototype reference) |
| `about.html` | page/component | static (no data flow) | `elvora_updated-3.html` | role-match |
| `contact.html` | page/component | event-driven (Alpine accordion) | `elvora_updated-3.html` | role-match |
| `src/input.css` | config | transform (CSS compilation) | `src/input.css` itself (extend only) | exact |
| `shop.html` | page stub | — | `index.html` (placeholder structure) | exact |
| `product.html` | page stub | — | `index.html` (placeholder structure) | exact |
| `cart.html` | page stub | — | `index.html` (placeholder structure) | exact |
| `checkout.html` | page stub | — | `index.html` (placeholder structure) | exact |
| `auth.html` | page stub | — | `index.html` (placeholder structure) | exact |
| `account.html` | page stub | — | `index.html` (placeholder structure) | exact |
| `style-match.html` | page stub | — | `index.html` (placeholder structure) | exact |
| `admin.html` | page stub (no footer) | — | `index.html` (placeholder structure) | partial |

---

## Pattern Assignments

### `js/components.js` (utility/provider, event-driven)

**Analog:** `js/supabase.js` (lines 1–10) for ES module structure + import pattern; `js/auth.js` (lines 1–24) for stub module shape.

**Imports pattern** — copy from `js/supabase.js` lines 1–10:
```javascript
// js/components.js
import { supabase } from './supabase.js';
```

**Alpine store registration pattern** — use `alpine:init` event, must come before Alpine processes x-data:
```javascript
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

**Nav HTML injection pattern** — inject synchronously before Alpine deferred script runs:
```javascript
const navRoot = document.getElementById('nav-root');
const footerRoot = document.getElementById('footer-root');
if (navRoot) navRoot.innerHTML = navHTML;
if (footerRoot) footerRoot.innerHTML = footerHTML;

// Call Alpine.initTree so Alpine processes injected x-data directives
if (window.Alpine) Alpine.initTree(navRoot);
```

**Active nav link detection pattern** — use `data-page` attribute on anchor tags:
```javascript
const currentPath = window.location.pathname;
document.querySelectorAll('[data-page]').forEach(link => {
  const href = link.getAttribute('href');
  const isHome = href === '/index.html' && (currentPath === '/' || currentPath === '/index.html');
  const isActive = isHome || href === currentPath;
  if (isActive) link.classList.add('text-rose');
});
```

**Nav x-data Alpine pattern** — inline in the nav HTML string (prototype `elvora_updated-3.html` lines 33–41 translated to Alpine):
```javascript
// Nav Alpine x-data — embedded in navHTML string
const navHTML = `
<nav
  x-data="{
    navOpen: false,
    scrolled: false,
    init() {
      window.addEventListener('scroll', () => {
        this.scrolled = window.scrollY > 80;
      }, { passive: true });
    }
  }"
  :class="scrolled ? 'bg-beige/90 backdrop-blur-md border-b border-sage/20' : 'bg-transparent'"
  class="fixed top-0 left-0 right-0 z-[100] flex items-center justify-between px-12 py-5 transition-all duration-300"
>
  ...
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
  ...
  </div>
  <div x-show="navOpen" @click="navOpen = false" class="fixed inset-0 bg-charcoal/50 z-[150]" style="display:none;"></div>
</nav>`;
```

---

### `index.html` (page, CRUD + request-response)

**Primary analog:** `elvora_updated-3.html` — port faithfully; all section layouts, copy, and visual hierarchy are defined there.

**HTML shell pattern** — update from current `index.html` (lines 1–15):
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ELVORA — Women Activewear</title>
  <!-- Correct font weights only (Playfair 700/700i + Poppins 400/600) -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;1,700&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js"></script>
</head>
<body>
  <div id="nav-root"></div>
  <main>
    <!-- 8 sections filled here -->
  </main>
  <div id="footer-root"></div>
  <!-- Load order: __env.js FIRST (plain script, runs synchronously) -->
  <script src="/js/__env.js"></script>
  <script type="module" src="/js/supabase.js"></script>
  <script type="module" src="/js/components.js"></script>
</body>
</html>
```

**Hero section pattern** — two-column grid from `elvora_updated-3.html` lines 98–203 (`.hero`, `.hero-content`, `.hero-visual`):
```html
<section class="min-h-screen grid grid-cols-1 md:grid-cols-2 pt-20">
  <!-- Left: content -->
  <div class="flex flex-col justify-center px-16 py-20">
    <span class="section-label mb-6">New Season · SS 2025</span>
    <h1 class="font-display font-bold text-[clamp(48px,5vw,72px)] leading-[1.1] text-charcoal mb-7">
      Move with <em class="italic text-rose">Grace</em>,<br>Train with Purpose
    </h1>
    <p class="text-[15px] leading-[1.8] text-text-muted max-w-[400px] mb-12 font-light">
      Premium activewear for the woman who demands elegance as much as performance.
    </p>
    <div class="flex gap-4 items-center">
      <a href="/shop.html" class="btn-primary">Discover the Collection</a>
      <a href="/style-match.html" class="btn-secondary">Find My Style</a>
    </div>
  </div>
  <!-- Right: hero image -->
  <div class="relative overflow-hidden bg-sage-light">
    <img
      src="https://images.unsplash.com/photo-{ID}?w=1200&q=80"
      alt="Woman in premium activewear"
      class="w-full h-full object-cover"
      fetchpriority="high"
      width="800" height="1067"
    />
  </div>
</section>
```

**Marquee strip pattern** — from `elvora_updated-3.html` lines 205–226 (`.marquee-section`, `.marquee-track`); translate to Tailwind + CSS in `src/input.css`:
```html
<div class="bg-charcoal py-[18px] overflow-hidden" aria-hidden="true">
  <div class="marquee-track flex gap-[60px] w-max">
    <div class="flex gap-[60px] flex-shrink-0">
      <span class="marquee-item">New Arrivals <span class="w-1 h-1 rounded-full bg-rose flex-shrink-0 inline-block"></span></span>
      <!-- repeat 6 keywords -->
    </div>
    <!-- Exact duplicate for seamless loop -->
    <div class="flex gap-[60px] flex-shrink-0" aria-hidden="true">
      <!-- same items -->
    </div>
  </div>
</div>
```

**Collections grid pattern** — from `elvora_updated-3.html` lines 262–318 (`.categories-grid`, `.cat-card`):
```html
<div class="grid gap-4" style="grid-template-columns: 2fr 1fr 1fr;">
  <a href="/shop.html?category=padel"
     class="rounded-[20px] overflow-hidden relative cursor-pointer transition-transform duration-400 hover:scale-[1.02]"
     style="grid-row: span 2; min-height: 520px;">
    <div class="absolute inset-0 bg-gradient-to-br from-sage to-[#7A9E75]"></div>
    <div class="absolute inset-0 bg-charcoal/15 opacity-0 hover:opacity-100 transition-opacity duration-300"></div>
    <div class="absolute bottom-7 left-7 right-7">
      <p class="font-display text-[22px] font-semibold text-white mb-1">Padel</p>
      <p class="text-[11px] tracking-[2px] uppercase text-white/80">24 Styles</p>
    </div>
  </a>
  <!-- Cards 2–4: medium, min-height: 248px -->
</div>
```

**Best sellers Alpine async pattern** — x-data with async init(), loading skeleton, x-for render:
```html
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
      } finally {
        this.loading = false;
      }
    }
  }"
  class="bg-beige py-[100px] px-16"
>
  <div x-show="loading" class="grid grid-cols-4 gap-6">
    <template x-for="i in 4" :key="i">
      <div class="bg-sage-light animate-pulse rounded-[20px] aspect-[3/4]"></div>
    </template>
  </div>
  <div x-show="!loading && !error" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
    <template x-for="product in products" :key="product.id">
      <div class="bg-white rounded-[20px] overflow-hidden hover:-translate-y-1.5 hover:shadow-[0_20px_48px_rgba(0,0,0,0.08)] transition-all duration-300">
        <div class="aspect-[3/4] overflow-hidden">
          <img
            :src="product.product_images?.[0]?.image_url"
            :alt="product.name"
            class="w-full h-full object-cover transition-transform duration-[600ms] hover:scale-[1.08]"
            loading="lazy"
            width="400" height="533"
          />
        </div>
        <div class="p-5">
          <h3 x-text="product.name" class="font-display text-base font-semibold text-charcoal mb-1.5"></h3>
          <span x-text="'$' + product.price" class="font-body text-base font-semibold text-charcoal"></span>
        </div>
      </div>
    </template>
  </div>
</section>
```

**Testimonials Alpine async pattern** — same shape as best sellers, different Supabase query:
```html
x-data="{
  testimonials: [],
  loading: true,
  async init() {
    try {
      const { data, error } = await supabase
        .from('testimonials')
        .select('*')
        .eq('is_active', true)
        .limit(3);
      if (error) throw error;
      this.testimonials = data || [];
    } catch (e) { /* silent fail */ }
    finally { this.loading = false; }
  }
}"
```

**Newsletter form pattern** — Alpine form with Supabase insert + duplicate key handling (error.code '23505'):
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
          this.errorMsg = error.code === '23505'
            ? 'You\'re already part of the inner circle.'
            : 'Something went wrong — please try again.';
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
>
  <form @submit.prevent="submitNewsletter">
    <input type="email" x-model="email" required style="font-size: 16px;" aria-label="Email address" />
    <button type="submit" :disabled="loading">
      <span x-show="!loading">Join the Circle</span>
      <span x-show="loading">…</span>
    </button>
  </form>
  <p x-show="errorMsg" x-text="errorMsg"></p>
  <div x-show="submitted">You're on the list. Welcome to Elvora.</div>
</section>
```

---

### `about.html` (page, static)

**Analog:** `index.html` (current stub, lines 1–15) for shell structure; `elvora_updated-3.html` brand story section for editorial layout.

**Shell pattern** — identical to `index.html` shell with title change + no hero fetchpriority needed:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>About — ELVORA</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;1,700&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js"></script>
</head>
<body>
  <div id="nav-root"></div>
  <main><!-- editorial content --></main>
  <div id="footer-root"></div>
  <script src="/js/__env.js"></script>
  <script type="module" src="/js/supabase.js"></script>
  <script type="module" src="/js/components.js"></script>
</body>
</html>
```

**Brand story editorial pattern** — from `elvora_updated-3.html` brand story section; pure HTML/CSS, no Alpine data fetch:
```html
<!-- Page hero: full-width editorial image + headline overlay -->
<section class="relative min-h-[60vh] flex items-end bg-charcoal">
  <img src="https://images.unsplash.com/photo-{ID}?w=1600&q=80" alt=""
       class="absolute inset-0 w-full h-full object-cover opacity-60"
       loading="eager" fetchpriority="high" width="1600" height="900" />
  <div class="relative z-10 px-16 pb-20">
    <span class="section-label text-sage/80">Our Story</span>
    <h1 class="font-display font-bold text-[clamp(40px,5vw,64px)] text-white leading-[1.1] mt-4">
      Designed for the <em class="italic text-rose">Woman</em><br>Who Moves with Intent
    </h1>
  </div>
</section>
<!-- Editorial copy: 2-col text + image -->
<section class="bg-beige py-[100px] px-16">
  <div class="max-w-[1100px] mx-auto grid md:grid-cols-2 gap-20 items-center">
    <div>
      <p class="font-body text-[17px] leading-[1.9] text-charcoal/80 mb-6">...</p>
      <a href="/shop.html" class="btn-primary">Shop the Collection</a>
    </div>
    <img src="https://images.unsplash.com/photo-{ID}?w=800&q=80" alt=""
         class="rounded-[20px] w-full aspect-[4/5] object-cover"
         loading="lazy" width="800" height="1000" />
  </div>
</section>
```

---

### `contact.html` (page, event-driven Alpine accordion)

**Analog:** `index.html` stub shell + `elvora_updated-3.html` for design tokens.

**FAQ accordion Alpine pattern** — activeIndex pattern (only one item open at a time):
```html
<section
  x-data="{
    activeIndex: null,
    faqs: [
      { q: 'What is your return policy?', a: 'We offer 30-day returns on all unworn items...' },
      { q: 'How do I find my size?', a: 'Our size guide covers XS–XL with measurements...' },
      { q: 'Do you ship internationally?', a: 'Yes — we ship to 40+ countries...' },
      { q: 'What materials do you use?', a: 'We use sustainable fabrics including...' },
      { q: 'How long does shipping take?', a: '3–5 business days domestically...' },
      { q: 'Is Elvora sustainable?', a: 'Sustainability is core to our mission...' }
    ]
  }"
  class="bg-beige py-[100px] px-16"
>
  <div class="max-w-2xl mx-auto">
    <template x-for="(faq, i) in faqs" :key="i">
      <div class="border-b border-sage/20">
        <button
          @click="activeIndex = activeIndex === i ? null : i"
          :aria-expanded="activeIndex === i"
          class="flex items-center justify-between w-full py-5 text-left font-body text-[15px] font-medium text-charcoal"
        >
          <span x-text="faq.q"></span>
          <svg :class="activeIndex === i ? 'rotate-180' : ''"
               class="w-5 h-5 transition-transform duration-200 flex-shrink-0" ...></svg>
        </button>
        <div
          x-show="activeIndex === i"
          x-transition:enter="transition ease-out duration-200"
          x-transition:enter-start="opacity-0 -translate-y-2"
          x-transition:enter-end="opacity-100 translate-y-0"
          class="pb-5 text-[15px] leading-[1.8] font-light text-text-muted"
        >
          <p x-text="faq.a"></p>
        </div>
      </div>
    </template>
  </div>
</section>
```

---

### `src/input.css` (config, transform)

**Analog:** `src/input.css` itself — extend only, never redefine tokens.

**Do NOT touch** `@theme` block (lines 1–15) — all color and font tokens already defined.

**Add to `@layer components`** for patterns used 4+ times across pages:
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
    text-decoration: none;
    display: inline-block;
    border: none;
    cursor: pointer;
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
    text-decoration: none;
    display: inline-block;
    cursor: pointer;
  }

  .btn-secondary:hover {
    border-color: var(--color-rose);
    color: var(--color-rose);
  }
}
```

**Add marquee keyframes** to `src/input.css` (after `@layer components`):
```css
@keyframes marquee {
  from { transform: translateX(0); }
  to   { transform: translateX(-50%); }
}

.marquee-track {
  animation: marquee 20s linear infinite;
}

@media (prefers-reduced-motion: reduce) {
  .marquee-track { animation: none; }
}
```

**Add scroll animation** (hero scroll indicator from `elvora_updated-3.html` lines 198–203):
```css
@keyframes scrollAnim {
  0%   { transform: scaleY(0); transform-origin: top; }
  50%  { transform: scaleY(1); transform-origin: top; }
  51%  { transform: scaleY(1); transform-origin: bottom; }
  100% { transform: scaleY(0); transform-origin: bottom; }
}
```

---

### Placeholder HTML stubs (shop, product, cart, checkout, auth, account, style-match)

**Analog:** `index.html` lines 1–15 (current structure) — add nav-root, footer-root, Alpine CDN, components.js script.

**Pattern to apply to ALL 7 stub pages** (currently missing nav-root/footer-root divs and Alpine/components.js script tags):
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PAGE TITLE — ELVORA</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;1,700&family=Poppins:wght@400;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js"></script>
</head>
<body>
  <div id="nav-root"></div>
  <main><!-- Phase N fills this --></main>
  <div id="footer-root"></div>
  <script src="/js/__env.js"></script>
  <script type="module" src="/js/supabase.js"></script>
  <script type="module" src="/js/components.js"></script>
</body>
</html>
```

**Exception — `admin.html`:** Omit `<div id="footer-root"></div>`. The admin panel has no public footer.

---

## Shared Patterns

### Supabase Client Import
**Source:** `js/supabase.js` lines 1–10
**Apply to:** `js/components.js` (the only new JS module in Phase 2)
```javascript
import { supabase } from './supabase.js';
// supabase reads from window.__ENV.SUPABASE_URL and window.__ENV.SUPABASE_ANON_KEY
// __env.js must be the FIRST <script> tag in <body> on every HTML page
```

### Design Tokens (Tailwind classes)
**Source:** `src/input.css` lines 3–15
**Apply to:** All HTML files — use generated utility classes, never raw hex values
```
Colors:   bg-sage, bg-rose, bg-beige, bg-charcoal, bg-lavender, bg-sage-light, bg-rose-light, text-text-muted
Opacity:  bg-beige/90, bg-charcoal/50, text-charcoal/65  (slash syntax)
Fonts:    font-display (Playfair Display), font-body (Poppins)
```

### Prototype CSS → Tailwind Translation Key
**Source:** `elvora_updated-3.html` inline `<style>` block
**Apply to:** All sections in `index.html`, `about.html`, `contact.html`

| Prototype CSS | Tailwind v4 Equivalent |
|---------------|------------------------|
| `padding: 100px 64px` | `py-[100px] px-16` |
| `font-size: clamp(32px, 4vw, 52px)` | `text-[clamp(32px,4vw,52px)]` |
| `border-radius: 20px` | `rounded-[20px]` |
| `letter-spacing: 4px` | `tracking-[4px]` |
| `grid-template-columns: 2fr 1fr 1fr` | `style="grid-template-columns: 2fr 1fr 1fr;"` (inline style — safer than arbitrary class for fr units) |
| `z-index: 100` | `z-[100]` |
| `backdrop-filter: blur(16px)` | `backdrop-blur-md` (12px) or `backdrop-blur-xl` (24px) |
| `transition: all 0.3s ease` | `transition-all duration-300` |

### Script Load Order (All HTML Pages)
**Source:** `index.html` lines 12–14 + RESEARCH.md Pattern 8
**Apply to:** Every HTML page
```html
<!-- In <body>, after all content: -->
<script src="/js/__env.js"></script>              <!-- 1st: plain script, synchronous -->
<script type="module" src="/js/supabase.js"></script>  <!-- 2nd: module, deferred -->
<script type="module" src="/js/components.js"></script> <!-- 3rd: module, deferred -->
<!-- Alpine CDN with defer is in <head> — runs after DOM parse, after modules queue -->
```

### Accessibility Baseline
**Source:** RESEARCH.md NF-003 + WCAG AA
**Apply to:** All interactive elements in nav, FAQ, forms
- `aria-label` on all icon-only buttons (search, user, bag, hamburger, close)
- `aria-expanded` on FAQ accordion triggers
- `alt` text on all `<img>` tags (empty `alt=""` for decorative images)
- Heading hierarchy: h1 on each page, h2 for section titles, h3 for card titles
- `role="navigation"` on `<nav>` (implicit but explicit for clarity)

---

## No Analog Found

| File | Role | Reason |
|------|------|--------|
| `js/components.js` (nav/footer HTML string pattern) | utility/provider | No existing shared component injection module in codebase — pattern established fresh from RESEARCH.md Pattern 1 |
| `index.html` (8-section homepage) | page | Existing `index.html` is a minimal 15-line stub with `<!-- Phase 2 fills this -->` — prototype is the reference, not any existing page |

---

## Metadata

**Analog search scope:** `/Users/andika/Desktop/Elvora/` — all `.html` and `.js` files excluding `.planning/`, `node_modules/`, `.git/`
**Files scanned:** 12 source files read directly
**Prototype reference:** `elvora_updated-3.html` (lines 1–319 read) — primary design source of truth for all visual patterns
**Pattern extraction date:** 2026-06-12
