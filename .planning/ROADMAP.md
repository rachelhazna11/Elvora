# Roadmap: Elvora

## Overview

Elvora is built in seven dependency-ordered phases. The schema and seed data land first because every other phase reads from them. The design system comes second because every page component inherits from it. The product catalog follows as a read-only surface that can be verified immediately against real data. Auth unlocks session persistence and enables the AI feature. The AI Style Match — the project's core differentiator — ships in Phase 5 while scope is still manageable and the catalog is in place to source recommendations. Cart and checkout ship in Phase 6, completing the purchase flow. The admin panel closes out the build as an isolated CRUD layer that validates against the fully working storefront.

## Phases

- [x] **Phase 1: Foundation** - Setup repository, Supabase schema (all tables + RLS), seed catalog (20+ products), storage buckets, deployment pipeline, keep-alive ping
- [x] **Phase 2: Brand Shell + Homepage** - Quiet luxury Tailwind v4 design system, component library, full 8-section homepage, About page, Contact/FAQ page (completed 2026-06-12)
- [x] **Phase 3: Product Catalog** - PLP with filtering/search/sort, PDP with gallery, sticky ATC, size guide, fabric details, Complete the Look, recommendations, reviews (completed 2026-06-14)
- [x] **Phase 4: Auth + Customer Account** - Signup/login/session persistence, wishlist, saved AI style preferences, account dashboard (completed 2026-06-15)
- [x] **Phase 5: AI Style Match** - Gemini Vision photo upload → outfit recommendations → colour guidance → session persistence (completed 2026-06-16)
- [x] **Phase 6: Cart + Checkout** - Mini cart drawer, full cart page, guest checkout, multi-step checkout, order creation with price snapshot (completed 2026-06-16)
- [x] **Phase 7: Admin Panel** - Protected admin routes, product CRUD + image upload, category/collection management, homepage content, testimonials, order read view

## Phase Details

### Phase 1: Foundation

**Goal**: The repository, Supabase project, database schema, seed data, and deployment pipeline are fully in place — every subsequent phase builds on a stable, secured, publicly accessible backend
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: F-046, F-047, F-048, F-049, F-050, F-051, NF-005, NF-006, NF-008
**Success Criteria** (what must be TRUE):

  1. A visitor can open the deployed public URL and receive a response — the app is live on Netlify with Supabase connected
  2. All 16 database tables exist with Row Level Security enabled and policies written — an anonymous query to any table returns only what RLS permits
  3. The product catalog contains 20+ seeded products (sports bras, leggings, tennis skirts, jackets, padel sets, pilates sets) readable via the Supabase JS SDK
  4. The `GEMINI_API_KEY` is stored only in Edge Function secrets and is absent from every HTML, JS, and committed file — verifiable by grep
  5. A GitHub Actions scheduled workflow pings Supabase daily so the free-tier project never pauses during assessment review

**Plans**: 9 plans (7 original + 2 gap-closure)

**Wave 1**

- [x] 01-01-PLAN.md — Supabase schema DDL: 16 tables + RLS + is_admin() + storage buckets
- [x] 01-04-PLAN.md — Repository scaffold: 11 HTML shells, 6 JS modules, Tailwind CSS source, .env.example
- [x] 01-05-PLAN.md — style-match Supabase Edge Function stub (Deno, auth-validated, mock response)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — [BLOCKING] Apply 001_schema.sql to Supabase via SQL Editor
- [x] 01-03-PLAN.md — Seed catalog: 22+ products, variants, images, categories, collections, testimonials

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-06-PLAN.md — Deployment pipeline: netlify.toml, README.md, GitHub Actions keep-alive
- [x] 01-07-PLAN.md — [BLOCKING] Apply seed.sql to Supabase via SQL Editor

**Wave 4** *(gap-closure — blocked on Wave 3 + UAT)*

- [x] 01-08-PLAN.md — [GAP] Netlify env injection: window.__ENV for Supabase client init + HTML script tags
- [x] 01-09-PLAN.md — [GAP] keepalive cron: weekly → daily (0 8 * * *)

### Phase 2: Brand Shell + Homepage

**Goal**: A visitor landing on Elvora encounters a complete premium editorial homepage with all eight sections and can navigate to the brand content pages — the quiet luxury visual identity is fully established and inherited by all future pages
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: F-001, F-002, F-003, F-004, F-005, F-006, F-007, F-043, F-044, F-045, NF-001, NF-002, NF-003, NF-004
**Success Criteria** (what must be TRUE):

  1. The homepage renders all eight sections — hero, featured collections, best sellers, lookbook grid, lifestyle editorial blocks, brand story, testimonials, and newsletter signup — at all four breakpoints (375px, 768px, 1024px, 1280px+) with no horizontal scroll
  2. The design system tokens (cream, sage, slate, ivory, charcoal palette; display serif + body sans-serif typefaces) are defined in Tailwind config and used consistently — no default framework colours appear anywhere in the UI
  3. A visitor can navigate to the About/Brand Story and Contact/FAQ pages and back to the homepage without broken links, and all pages read as premium editorial content
  4. Clicking a featured collection card on the homepage navigates to the activity-filtered product listing page
  5. Submitting the newsletter form shows a confirmation message and stores the email in the `newsletter_subscribers` table

**Plans**: 4 plans

**Wave 1**

- [x] 02-01-PLAN.md — Design system (src/input.css component utilities + marquee keyframes), js/components.js (nav + footer injection, Alpine stores), update all 9 HTML placeholder stubs

**Wave 2** *(blocked on Wave 1 completion — runs in parallel)*

- [x] 02-02-PLAN.md — index.html static sections: hero, marquee strip, featured collections grid, lookbook grid, brand story
- [x] 02-03-PLAN.md — about.html editorial layout + contact.html FAQ accordion and contact info

**Wave 3** *(blocked on Wave 2 — 02-02 specifically)*

- [x] 02-04-PLAN.md — index.html live-data sections: best sellers (Supabase), testimonials (Supabase), newsletter signup (Supabase insert)

**UI hint**: yes

### Phase 3: Product Catalog

**Goal**: A visitor can browse all products, filter by activity, search by name, and view full product detail pages with imagery, size guidance, fabric information, outfit pairings, and customer reviews — the core shopping discovery experience is complete
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: F-008, F-009, F-010, F-011, F-012, F-013, F-014, F-015, F-016, F-017, F-018, F-019
**Success Criteria** (what must be TRUE):

  1. A visitor can filter the product listing by activity category (All, Padel, Pilates, Tennis, Training, Running) and sort by New Arrivals, Price Low–High, Price High–Low, and Best Sellers — filter and sort state are reflected in the URL
  2. Typing in the search bar shows a live autosuggest dropdown of matching product names; pressing Enter or selecting a suggestion navigates to the correct result
  3. On a product detail page, a visitor can swipe through at least three product images, select a colour swatch (updating the main image), select a size, open the size guide modal (closeable by Escape key), and read fabric composition and care instructions
  4. A visitor scrolling down a PDP sees the sticky Add to Cart bar appear after passing the main ATC button, reflecting the currently selected size and colour
  5. A visitor can see 2–3 "Complete the Look" product cards and at least 4 related products on every PDP, and can read seeded customer reviews with star ratings and fit feedback

**Plans**: 5 plans

**Wave 1** *(data foundation — blocking)*

- [x] 03-01-PLAN.md — Data foundation: 002_product_pairings.sql migration + collection gap fill seed (Tennis/Training/Running), js/products.js full implementation + window exposure [HAS CHECKPOINT]

**Wave 2** *(blocked on Wave 1 — plans run in parallel)*

- [x] 03-02-PLAN.md — PLP (shop.html): Supabase-backed product grid, activity tabs + sub-category pills, colour swatch hover, sort select, URL state sync, empty state, Toastify ATC stub + PLP CSS classes
- [x] 03-03-PLAN.md — Nav search (js/components.js): click-to-expand search input, debounced autosuggest dropdown, Enter → PLP, click → PDP

**Wave 3** *(blocked on Wave 2 — plans run in parallel)*

- [x] 03-04-PLAN.md — PDP core (product.html): Swiper gallery + thumbnails, colour swatch → gallery sync, size selector, sticky ATC (IntersectionObserver), size guide modal (focus trap), fabric accordion + PDP CSS classes
- [x] 03-05-PLAN.md — PDP social proof (product.html): Complete the Look pairings, related products grid, customer reviews with aggregate rating + fit badges + load-more

**UI hint**: yes

### Phase 4: Auth + Customer Account

**Goal**: A user can create an account, log in, maintain their session across page loads, save products to a wishlist, and store AI style preferences — authenticated state is reflected consistently across the entire site
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: F-025, F-026, F-027, F-028, F-029
**Success Criteria** (what must be TRUE):

  1. A new user can register with first name, last name, email, and password; on success they are automatically logged in and redirected to their account dashboard
  2. A returning user can log in, navigate across multiple pages, and remain logged in after a full browser refresh — the header shows their account name and cart badge throughout
  3. A logged-in user can add products to their wishlist from both the PLP and PDP, view all saved items on their wishlist page, and remove items — wishlist state persists in Supabase and is user-scoped
  4. After completing an AI Style Match session, a logged-in user is prompted to save their preferences (activity, fit, aesthetic, colour); those preferences pre-fill the Style Match form on next visit

**Plans**: 5 plans

**Wave 1** *(no dependencies — run in parallel)*

- [x] 04-01-PLAN.md — Phase 4 CSS: all auth + account + wishlist + preferences + nav dropdown component classes added to src/input.css
- [x] 04-02-PLAN.md — Auth service + nav state: js/auth.js 5 functions implemented + js/components.js extended with initAuth() + logged-in nav dropdown

**Wave 2** *(blocked on Wave 1 — plans run in parallel)*

- [x] 04-03-PLAN.md — auth.html: editorial split layout + tab toggle (sign in / create account) + Supabase auth wiring
- [x] 04-04-PLAN.md — account.html: sidebar dashboard + Profile section + Style Preferences chip selectors + Wishlist section (with remove)

**Wave 3** *(blocked on Wave 2)*

- [x] 04-05-PLAN.md — Wishlist heart toggle: shop.html + product.html hearts wired to wishlist_items (optimistic UI, guest redirect, error revert)

**UI hint**: yes

### Phase 5: AI Style Match

**Goal**: A visitor can upload a photo and/or specify style preferences, receive 2–3 named outfit recommendations from the Elvora catalog with complementary colour guidance via Gemini Vision, and — if logged in — save and revisit past sessions
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: F-030, F-031, F-032, F-033, F-034, F-035, NF-007
**Success Criteria** (what must be TRUE):

  1. A visitor on the Style Match landing page understands the three-step flow (Upload → Preferences → Discover) and can click "Find My Style" to reach the Style Match form — the page is accessible from the main navigation
  2. A visitor can upload a JPEG or PNG photo (resized client-side to max 800px), select preferences via visual chip selectors (activity, fit, aesthetic, colour), submit the form, and see a loading state ("Finding your style…") while the Edge Function processes the request
  3. The Style Match returns 2–3 named outfit combinations, each comprising 2–3 product cards linking to real PDPs, alongside 1–2 sentences of colour guidance referencing Elvora's palette — the `GEMINI_API_KEY` is not present in any client-side file or network request headers
  4. A logged-in user's completed Style Match session is saved to `ai_style_sessions` in Supabase with preferences, recommended product IDs, colour guidance, and timestamp — they can view past sessions from their account
  5. An `AI-USAGE.md` document exists in the repository explaining what AI tools were used, how the Style Match feature works, the Edge Function proxy pattern, and is clear enough for a non-technical assessor

**Plans**: TBD
**UI hint**: yes

### Phase 6: Cart + Checkout

**Plans**: 5 plans (3 waves)

**Goal**: A visitor — guest or authenticated — can add products to the cart, review and adjust the order, complete a multi-step checkout, and receive an order confirmation with a persisted order record
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: F-020, F-021, F-022, F-023, F-024
**Success Criteria** (what must be TRUE):

  1. Adding a product to the cart from any page opens the slide-out mini cart drawer showing the item with correct variant (colour/size), price, and a running subtotal — the cart icon badge in the header updates immediately
  2. A guest visitor can proceed through all four checkout steps (Shipping, Review, Payment placeholder, Confirmation) without creating an account, providing only an email address, and receives a confirmation page with an order ID
  3. An authenticated user's cart persists in Supabase across sessions; a guest cart stored in localStorage is merged into the authenticated cart upon login
  4. On checkout confirmation, an order record exists in the Supabase `orders` table with snapshotted `unit_price`, `product_name`, and `variant_label` on each order item — the cart is cleared

**Plans**: 5 plans executed

**Wave 1** *(CSS + store foundation)*

- [x] 06-01-PLAN.md — Cart CSS: .cart-drawer, .cart-drawer-*, .cart-qty-* classes in src/input.css
- [x] 06-02-PLAN.md — Cart JS store: Alpine.store('cart') full implementation, cartDrawerOpen/openDrawer/closeDrawer, Supabase sync

**Wave 2** *(UI injection + wiring)*

- [x] 06-03-PLAN.md — Mini cart drawer: cartDrawerHTML injected via components.js, nav icons wired, product+shop addToBag openDrawer
- [x] 06-04-PLAN.md — Cart page (cart.html): full cart page with item list, qty steppers, subtotal, proceed to checkout
- [x] 06-05-PLAN.md — Checkout (checkout.html): multi-step form, order creation, confirmation

**UI hint**: yes

### Phase 7: Admin Panel

**Goal**: An admin user can manage the entire product catalog, categories, collections, homepage content, testimonials, and view orders through a protected admin section — all changes are immediately reflected on the storefront
**Mode:** mvp
**Depends on**: Phase 6
**Requirements**: F-036, F-037, F-038, F-039, F-040, F-041, F-042
**Success Criteria** (what must be TRUE):

  1. An unauthenticated visitor or non-admin user navigating to any `/admin/*` route is redirected to the homepage and receives no data from Supabase — verified from an incognito session
  2. An admin can create a new product (with name, description, category, price, fabric details, and at least one variant), upload product images to Supabase Storage, and see the product appear live on the PLP without a code deploy
  3. An admin can update which four collections appear in the homepage featured grid and which products appear as best sellers — changes are visible on the homepage immediately after save
  4. An admin can create, edit, toggle visibility of, and delete testimonials, and the homepage testimonials section reflects those changes without a redeploy
  5. An admin can view the order list (sorted by most recent) and drill into any order to see all line items with product name, variant, quantity, and unit price

**Plans**: 6/7 plans executed

- [x] 07-07-PLAN.md

**Wave 1** *(berjalan paralel — tidak ada dependensi)*

- [x] 07-01-PLAN.md — CSS admin + Admin SPA shell (admin.html) + admin guard (js/admin.js)
- [x] 07-02-PLAN.md — Migration 007_admin_policies.sql (orders + products admin SELECT RLS) + fix best sellers query di index.html

**Wave 2** *(blocked on Wave 1 — berjalan paralel satu sama lain)*

- [x] 07-03-PLAN.md — Products list + delete (adminGetProducts, adminDeleteProduct)
- [x] 07-05-PLAN.md — Testimonials CRUD + best sellers toggle (adminGetTestimonials, adminSetBestSeller)
- [x] 07-06-PLAN.md — Orders read view + order items expand (adminGetOrders, adminGetOrderItems)

**Wave 3** *(blocked on Wave 2 — 07-03 specifically)*

- [x] 07-04-PLAN.md — Product create/edit form + image upload (adminCreateProduct, adminUpdateProduct)

**UI hint**: yes

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 9/9 | Complete   | 2026-06-11 |
| 2. Brand Shell + Homepage | 4/4 | Complete   | 2026-06-12 |
| 3. Product Catalog | 5/5 | Complete   | 2026-06-14 |
| 4. Auth + Customer Account | 5/5 | Complete   | 2026-06-14 |
| 5. AI Style Match | 5/4 | Complete    | 2026-06-16 |
| 6. Cart + Checkout | 5/5 | Complete    | 2026-06-16 |
| 7. Admin Panel | 6/7 | In Progress|  |
