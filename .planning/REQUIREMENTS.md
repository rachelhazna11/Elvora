# Elvora — v1 Requirements

**Project:** Elvora — Premium Women's Activewear E-Commerce
**Version:** 1.0
**Last updated:** 2026-06-10
**Status:** Approved for roadmap

---

## Table of Contents

- [Functional Requirements](#functional-requirements)
  - [Homepage](#homepage)
  - [Product Catalog (PLP)](#product-catalog-plp)
  - [Product Detail Page (PDP)](#product-detail-page-pdp)
  - [Cart & Checkout](#cart--checkout)
  - [Customer Account](#customer-account)
  - [AI Style Match](#ai-style-match)
  - [Admin Panel](#admin-panel)
  - [Brand & Content Pages](#brand--content-pages)
  - [Data Layer & Infrastructure](#data-layer--infrastructure)
- [Non-Functional Requirements](#non-functional-requirements)
- [Deferred to v2](#deferred-to-v2)
- [Traceability Matrix](#traceability-matrix)

---

## Functional Requirements

### Homepage

---

**F-001 — Editorial Hero Section**

Description:
The homepage must open with a full-screen editorial hero section that communicates the Elvora brand identity and drives users into the catalog.

Acceptance Criteria:
- Full-screen or near-full-screen hero image/video with overlay text
- Headline, subheadline, and at least one primary CTA button (e.g., "Shop the Collection")
- CTA links to the product listing page or a featured collection
- Hero is visually consistent with the quiet luxury aesthetic (no bright colours, no generic sports imagery)
- Renders correctly on mobile, tablet, and desktop

Module: Homepage
Priority: Must

---

**F-002 — Featured Activity Collections**

Description:
The homepage must display the four core activity collection cards so users can navigate directly to sport-specific product listings.

Acceptance Criteria:
- Four collection cards displayed: Padel, Pilates, Tennis, Training
- Each card shows a lifestyle image and collection label
- Clicking a card navigates to the filtered PLP for that activity
- Cards are responsive (grid collapses appropriately on mobile)

Module: Homepage / Product Catalog
Priority: Must

---

**F-003 — Best Sellers Section**

Description:
The homepage must feature a curated row of best-selling or featured products to drive product discovery.

Acceptance Criteria:
- Displays at least 4 product cards pulled from the Supabase products table
- Each card shows product image, name, price, and color swatches
- Clicking a card navigates to the product detail page
- Section header is editable via the admin panel (F-041)

Module: Homepage / Product Catalog
Priority: Must

---

**F-004 — Lifestyle / Lookbook Grid**

Description:
The homepage must include a curated editorial grid ("As Styled" or equivalent) that showcases outfit combinations and reinforces the brand aesthetic.

Acceptance Criteria:
- Grid of at least 4–6 editorial images
- Optional: each image links to a product or collection
- Layout reads as fashion editorial, not generic product grid
- Responsive (2-column on mobile, wider grid on desktop)

Module: Homepage
Priority: Must

---

**F-005 — Brand Story Section**

Description:
The homepage must include a concise brand story section that communicates Elvora's values and positioning.

Acceptance Criteria:
- Short editorial text block (tagline + 2–3 sentences)
- Optional supporting image
- Links to the full About page (F-044)
- Tone is premium, minimalist — no bullet points or generic copy

Module: Homepage / Brand Content
Priority: Must

---

**F-006 — Testimonials Section**

Description:
The homepage must display customer testimonials to build social proof.

Acceptance Criteria:
- Displays at least 3 testimonials (quote, customer name, optional activity label)
- Testimonials are stored in Supabase and manageable via admin panel (F-042)
- Layout is clean and brand-appropriate (no star ratings on the homepage — save those for PDP)

Module: Homepage / Admin
Priority: Must

---

**F-007 — Newsletter Signup**

Description:
The homepage must include an email newsletter signup form.

Acceptance Criteria:
- Email input field and submit button
- On submit: shows a confirmation message ("You're on the list")
- Email is stored in a `newsletter_subscribers` Supabase table
- No third-party email delivery required for v1 (UI-functional only)
- Form validates email format before submission

Module: Homepage
Priority: Must

---

### Product Catalog (PLP)

---

**F-008 — Product Listing Page**

Description:
Users must be able to browse all Elvora products on a dedicated listing page with premium product cards.

Acceptance Criteria:
- Displays all active products from the Supabase catalog
- Each card shows: product image, name, price, color swatches
- Cards link to the respective product detail page
- Empty state handled gracefully (no broken layout when no results)
- Page is paginated or uses load-more if product count exceeds 12

Module: Product Catalog
Priority: Must

---

**F-009 — Activity Category Filtering**

Description:
Users must be able to filter the product listing by activity category as the primary navigation axis.

Acceptance Criteria:
- Filter options: All, Padel, Pilates, Tennis, Training, Running
- Active filter is visually highlighted
- Filtering updates the product grid without a full page reload (Alpine.js or similar)
- Filter state is reflected in the URL (e.g., `?category=padel`) for shareable links
- Accessible via keyboard navigation

Module: Product Catalog
Priority: Must

---

**F-010 — Color Swatches on Product Cards**

Description:
Product cards must display color variant swatches so users can see available colors without opening the product page.

Acceptance Criteria:
- Up to 4 color swatches shown per card (overflow hidden with indicator if more)
- Hovering/tapping a swatch updates the card image to the corresponding color variant
- Active swatch is visually indicated
- Swatch colours match the actual product variant colours

Module: Product Catalog
Priority: Must

---

**F-011 — Product Search with Autosuggest**

Description:
Users must be able to search for products by name with live suggestions as they type.

Acceptance Criteria:
- Search input in the site header (accessible from all pages)
- Typing shows a dropdown of matching product names (min 2 characters to trigger)
- Selecting a suggestion navigates to that product's detail page
- Pressing Enter navigates to PLP filtered by search query
- No results state handled gracefully

Module: Product Catalog
Priority: Must

---

**F-012 — Sort Options**

Description:
Users must be able to sort the product listing to control the order of results.

Acceptance Criteria:
- Sort options: New Arrivals, Price Low–High, Price High–Low, Best Sellers
- Default sort is New Arrivals
- Changing sort re-orders the visible grid without full page reload
- Sort state is reflected in URL for shareable links

Module: Product Catalog
Priority: Must

---

### Product Detail Page (PDP)

---

**F-013 — Multi-Image Product Gallery**

Description:
Each product detail page must display multiple product images to support confident purchase decisions.

Acceptance Criteria:
- At least 3 images per product: model shot, lifestyle shot, fabric detail shot
- Main image is large; thumbnails are clickable/swipeable to change main image
- Touch/swipe gesture supported on mobile
- Images load via Supabase Storage with optimised transform parameters (`?width=1200&quality=80`)

Module: Product Detail Page
Priority: Must

---

**F-014 — Sticky Add to Cart Bar**

Description:
A sticky Add to Cart bar must remain visible as the user scrolls down the product detail page.

Acceptance Criteria:
- Sticky bar appears after user scrolls past the main ATC button
- Bar displays: product name, selected size, selected colour, price, and Add to Cart button
- Clicking Add to Cart in the sticky bar adds the item with the currently selected options
- Bar is dismissed/hidden when the main ATC button is in viewport

Module: Product Detail Page
Priority: Must

---

**F-015 — Size Guide Modal**

Description:
Users must be able to access a size guide on the product detail page without leaving the page.

Acceptance Criteria:
- "Size Guide" link opens a modal overlay
- Modal contains a size chart with body measurements (bust, waist, hips) mapped to XS/S/M/L/XL
- Includes a brief how-to-measure instruction
- Modal is closeable via button, Escape key, or clicking outside
- Accessible (focus trap inside modal when open)

Module: Product Detail Page
Priority: Must

---

**F-016 — Fabric & Material Details**

Description:
Each product must display fabric composition and care instructions to support premium purchase confidence.

Acceptance Criteria:
- Fabric details displayed in an accordion or dedicated section (e.g., "82% Nylon, 18% Elastane")
- Care instructions included (machine wash cold, do not tumble dry, etc.)
- Details are stored as structured fields in Supabase (not free-text blob)

Module: Product Detail Page
Priority: Must

---

**F-017 — Complete the Look — Outfit Pairing**

Description:
Each product detail page must suggest complementary items to encourage outfit building and increase average order value.

Acceptance Criteria:
- Displays 2–3 product cards styled as "Complete the Look" or "Style It With"
- Pairing suggestions are activity-context-relevant (e.g., a padel skirt pairs with padel top, not running shoes)
- Pairing data is manageable via the admin panel (F-038)
- Each suggestion links to its own PDP

Module: Product Detail Page
Priority: Must

---

**F-018 — Related Products Grid**

Description:
Product detail pages must display a grid of related products from the same category or activity.

Acceptance Criteria:
- Displays at least 4 related products below the main product content
- Related products are from the same activity category by default
- Each card links to the respective PDP

Module: Product Detail Page
Priority: Must

---

**F-019 — Customer Reviews on PDP**

Description:
Users must be able to read customer reviews on each product detail page to support confident purchasing.

Acceptance Criteria:
- Displays aggregate star rating (1–5) and total review count
- Individual reviews show: star rating, written review, reviewer name, date, and fit feedback (Runs Small / True to Size / Runs Large)
- Reviews are paginated or load-more if count exceeds 5
- Reviews are stored in Supabase and associated with the product
- Review submission is not required for v1 (display only, admin-seedable)

Module: Product Detail Page
Priority: Must

---

### Cart & Checkout

---

**F-020 — Slide-out Mini Cart**

Description:
Adding a product to the cart must open a slide-out mini cart drawer without navigating away from the current page.

Acceptance Criteria:
- Mini cart opens from the right side of the screen on add-to-cart
- Displays all cart items: image, name, variant (colour/size), price, quantity controls
- Shows order subtotal
- "View Cart" and "Checkout" CTAs at the bottom
- Item count badge updates on the cart icon in the header
- Guest cart persists in `localStorage`; authenticated cart persists in Supabase `cart_items`
- Mini cart closes via click-outside or explicit close button

Module: Cart & Checkout
Priority: Must

---

**F-021 — Full Cart Page**

Description:
Users must be able to view and manage their full cart on a dedicated cart page.

Acceptance Criteria:
- Displays all cart items with image, name, variant, unit price, quantity selector, and remove button
- Order summary shows subtotal, estimated shipping placeholder, and total
- "Continue Shopping" link returns to PLP
- "Proceed to Checkout" CTA advances to checkout flow
- Empty cart state handled gracefully with CTA to browse

Module: Cart & Checkout
Priority: Must

---

**F-022 — Guest Checkout**

Description:
Users must be able to complete checkout without creating an account.

Acceptance Criteria:
- No forced account creation at any step of checkout
- Guest provides email address for order confirmation
- Guest checkout completes the same order flow as authenticated checkout
- Optional prompt to create an account shown on order confirmation page (not blocking)

Module: Cart & Checkout
Priority: Must

---

**F-023 — Multi-Step Checkout Flow**

Description:
The checkout experience must be a simplified multi-step flow that feels premium and reduces friction.

Acceptance Criteria:
- Step 1 — Shipping: first name, last name, email, address, city, postcode, country
- Step 2 — Review: summary of items, shipping address, and total before confirming
- Step 3 — Payment: payment section placeholder (message: "Secure payment powered by [placeholder]" with card field UI — non-functional for v1)
- Step 4 — Confirmation: order confirmed message, order ID, items summary, and delivery estimate text
- Progress indicator shows current step
- Form validates all required fields before advancing

Module: Cart & Checkout
Priority: Must

---

**F-024 — Order Record Creation**

Description:
On checkout completion, an order record must be persisted in Supabase with a price snapshot.

Acceptance Criteria:
- Order record created in Supabase `orders` table on confirmation
- `order_items` rows snapshot `unit_price`, `product_name`, `variant_label` at insertion (not joined to live product)
- Order is associated with the user account if authenticated, or stored with guest email if not
- Order status defaults to "confirmed"
- Cart is cleared after successful order creation

Module: Cart & Checkout
Priority: Must

---

### Customer Account

---

**F-025 — User Registration**

Description:
Users must be able to create an Elvora account using their email address and a password.

Acceptance Criteria:
- Registration form: first name, last name, email, password, confirm password
- Password minimum 8 characters
- Email uniqueness enforced (Supabase Auth handles)
- On success: user is logged in and redirected to their account dashboard
- Error states displayed for duplicate email, weak password, or form validation failures

Module: Customer Account
Priority: Must

---

**F-026 — User Login & Logout**

Description:
Registered users must be able to log in to and out of their account.

Acceptance Criteria:
- Login form: email and password
- On success: session is established and persisted across page loads
- Logout clears the session and redirects to homepage
- Incorrect credentials show a clear error message
- "Forgot password" link present (reset flow via Supabase email; functional if Supabase email is configured)

Module: Customer Account
Priority: Must

---

**F-027 — Session Persistence**

Description:
Authenticated user sessions must persist across page navigation and browser refresh.

Acceptance Criteria:
- Supabase `onAuthStateChange` listener updates UI state across all pages
- Header updates to show account name / account icon when logged in
- Cart icon badge reflects persisted cart count
- Session expires per Supabase Auth default (JWT expiry); user is redirected to login on expiry

Module: Customer Account
Priority: Must

---

**F-028 — Wishlist / Saved Items**

Description:
Authenticated users must be able to save products to a wishlist for later viewing.

Acceptance Criteria:
- Heart / save icon on product cards (PLP) and PDP adds the item to the user's wishlist
- Wishlist icon toggles on/off (saved state persists in Supabase `wishlist_items`)
- Dedicated wishlist page in the account section lists all saved products
- Removing an item from the wishlist updates both the page and the saved state
- Wishlist is user-scoped (RLS enforced — users cannot see each other's wishlists)

Module: Customer Account
Priority: Must

---

**F-029 — Saved AI Style Preferences**

Description:
Users must be able to save their style preferences from the AI Style Match session to their account for future use.

Acceptance Criteria:
- After completing a Style Match session (F-034), users are prompted to save their preferences
- Saved preferences include: activity, fit preference, style aesthetic, colour preference
- Preferences are viewable and editable in the account preferences section
- Saved preferences pre-fill the Style Match form on next visit (if logged in)
- Preferences stored in Supabase `user_profiles` as structured fields

Module: Customer Account / AI Style Match
Priority: Must

---

### AI Style Match

---

**F-030 — Style Match Landing Page**

Description:
Elvora must have a dedicated landing page for the AI Style Match experience that explains the feature and invites users to try it.

Acceptance Criteria:
- Page describes what Style Match does in 2–3 steps (e.g., Upload → Preferences → Discover)
- Editorial imagery that reinforces the premium personal-stylist framing
- Primary CTA: "Find My Style" / "Get Started" — advances to the Style Match form
- Page is linked from the main navigation

Module: AI Style Match
Priority: Must

---

**F-031 — Photo Upload**

Description:
Users must be able to upload a photo of themselves as input to the AI Style Match recommendation engine.

Acceptance Criteria:
- File input accepts JPEG and PNG formats
- Client-side image resizing to max 800px before upload (reduces API cost and latency)
- Photo is uploaded to Supabase Storage `user-uploads` bucket under `{user_id}/{session_id}/` path
- Upload progress is indicated
- Uploaded image is not stored permanently — can be deleted after session is complete (or after 24h)
- Photo upload is optional if the user prefers to proceed with preferences only

Module: AI Style Match
Priority: Must

---

**F-032 — Style Preference Input Form**

Description:
Users must be able to provide optional style preferences that guide the AI recommendations.

Acceptance Criteria:
- Preference inputs: Activity (multi-select: padel, pilates, tennis, gym, running), Fit (fitted / balanced / relaxed), Style Aesthetic (minimal / elegant / sporty-luxury), Colour Preference (neutral / warm / cool / bold)
- All inputs are optional
- Preferences are presented as visual selector chips, not plain dropdowns
- Form is usable without uploading a photo (preferences-only mode)

Module: AI Style Match
Priority: Must

---

**F-033 — AI Outfit Combination Recommendations**

Description:
The AI Style Match engine must return 2–3 complete outfit combinations from the Elvora catalog based on the user's uploaded photo and/or preferences.

Acceptance Criteria:
- Recommendations are generated by Gemini Vision API via Supabase Edge Function (never direct browser call)
- Each recommendation is a named outfit (e.g., "Padel Court Look") comprising 2–3 products
- Products in recommendations exist in the Supabase catalog and are returned as product IDs
- Recommendations are rendered as product cards linking to the respective PDPs
- Loading state shown during API call (spinner or progress message: "Finding your style…")
- Error state handled gracefully if the API call fails

Module: AI Style Match
Priority: Must

---

**F-034 — Complementary Colour Guidance**

Description:
The AI Style Match must include a colour guidance component that explains which colour families suit the user based on their appearance or stated preference.

Acceptance Criteria:
- Returns 1–2 sentences of colour guidance (e.g., "Warm neutrals like ivory, camel, and sage work well with your warm undertones")
- Guidance is displayed alongside outfit recommendations
- Derived from the uploaded photo appearance analysis and/or stated colour preference
- Guidance references Elvora's actual colour palette (cream, sage, slate, ivory, black, neutral tones)

Module: AI Style Match
Priority: Must

---

**F-035 — Style Match Session Persistence**

Description:
Style Match sessions must be saved to Supabase so users can review past recommendations.

Acceptance Criteria:
- Each completed session is stored in Supabase `ai_style_sessions` table
- Session record includes: user_id (if authenticated), preferences used, recommended product IDs, colour guidance text, timestamp
- Authenticated users can view past sessions in their account
- Sessions are user-scoped (RLS enforced)
- Guest sessions are stored with a session token but not linked to a user account

Module: AI Style Match / Customer Account
Priority: Should

---

### Admin Panel

---

**F-036 — Admin Authentication & Access Control**

Description:
The admin panel must be accessible only to users with the admin role, enforced at both the UI and database level.

Acceptance Criteria:
- Admin routes (`/admin/*`) redirect non-admin users to homepage
- Admin role is stored in Supabase `auth.users.raw_app_meta_data` (not `raw_user_meta_data`)
- All admin data operations are protected by RLS `is_admin()` policies — client-side redirect alone is not sufficient
- Admin role is assigned via Supabase dashboard (service role key) — no in-app role promotion
- Accessing `/admin/products` in an unauthenticated or non-admin session returns no data

Module: Admin Panel
Priority: Must

---

**F-037 — Product CRUD**

Description:
Admins must be able to create, read, update, and delete products from the Elvora catalog.

Acceptance Criteria:
- Product form fields: name, description, category, price, fabric details, care instructions, styling suggestions, active/inactive status
- Creating a product also creates at least one product variant (colour + size combination)
- Editing a product updates all associated fields in Supabase
- Deleting a product soft-deletes (sets `is_active = false`) rather than hard-deletes
- Product list view shows all products with name, category, price, and status

Module: Admin Panel
Priority: Must

---

**F-038 — Product Image Upload**

Description:
Admins must be able to upload product images and associate them with products via the admin panel.

Acceptance Criteria:
- Image upload input in the product form accepts JPEG and PNG
- Images are uploaded to Supabase Storage `product-images` bucket
- Multiple images can be associated with one product (model, lifestyle, detail)
- Image order can be set (first image = primary card image)
- Images are served via Supabase Storage CDN with transform parameters for optimised delivery

Module: Admin Panel
Priority: Must

---

**F-039 — Category & Collection Management**

Description:
Admins must be able to create, edit, and delete product categories and curated collections.

Acceptance Criteria:
- Category management: create/edit/delete activity categories (Padel, Pilates, Tennis, Training, Running)
- Collection management: create/edit/delete named collections (e.g., "New Arrivals", "Best Sellers", "Summer Edit")
- Products can be assigned to collections from the product edit screen
- Collections can be featured on the homepage (linked to F-041)

Module: Admin Panel
Priority: Must

---

**F-040 — Homepage Content Management**

Description:
Admins must be able to update key homepage sections without modifying code.

Acceptance Criteria:
- Featured collections section: admin can select which 4 collections appear in the homepage grid
- Best sellers section: admin can select which products appear as featured/best sellers
- Hero section: admin can update hero headline, subheadline, and CTA text (image updated via code deploy or Storage)
- Changes are reflected on the homepage immediately after save

Module: Admin Panel
Priority: Must

---

**F-041 — Testimonials Management**

Description:
Admins must be able to create, edit, and delete customer testimonials displayed on the homepage.

Acceptance Criteria:
- Testimonial form fields: customer name, quote text, activity label (optional), display order
- Testimonials are stored in Supabase and retrieved for homepage display (F-006)
- Admin can toggle testimonial visibility (active/inactive)

Module: Admin Panel
Priority: Must

---

**F-042 — Order Read View**

Description:
Admins must be able to view submitted orders in the admin panel for reference.

Acceptance Criteria:
- Order list shows: order ID, customer email, order date, total, item count, and status
- Order detail view shows all line items with product name, variant, quantity, and unit price
- Orders are read-only (no fulfillment management in v1)
- Sorted by most recent first

Module: Admin Panel
Priority: Must

---

### Brand & Content Pages

---

**F-043 — About / Brand Story Page**

Description:
Elvora must have a dedicated brand story page that communicates the brand's origin, values, and wellness philosophy.

Acceptance Criteria:
- Editorial long-form page with headline, brand narrative, and supporting imagery
- References the Elvora design aesthetic (quiet luxury, fashion meets wellness)
- Links to the product catalog and/or Style Match feature
- Content is hardcoded HTML for v1 (not CMS-managed)

Module: Brand Content
Priority: Must

---

**F-044 — Lifestyle Editorial Content**

Description:
Sport-context editorial content blocks must appear on the homepage or supporting pages to reinforce the wellness lifestyle brand positioning.

Acceptance Criteria:
- At least 2 lifestyle content blocks (e.g., "Pilates Studio", "Padel Life") woven into the homepage or as standalone editorial sections
- Each block includes an editorial image, a short headline, and a CTA linking to the relevant activity collection
- Visual treatment is consistent with the overall quiet luxury aesthetic

Module: Brand Content
Priority: Must

---

**F-045 — Contact / FAQ Page**

Description:
Elvora must provide a Contact and FAQ page covering common customer questions.

Acceptance Criteria:
- FAQ section covers: sizing guidance, returns policy, shipping information (placeholder), fabric care
- Contact section includes an email address or simple contact form
- Page is accessible from the footer navigation
- Content is hardcoded HTML for v1

Module: Brand Content
Priority: Must

---

### Data Layer & Infrastructure

---

**F-046 — Supabase Database Schema**

Description:
All application data must be persisted in a Supabase PostgreSQL database with a well-structured schema.

Acceptance Criteria:
- Tables created: `user_profiles`, `products`, `product_variants`, `product_images`, `categories`, `collections`, `collection_products`, `cart_items`, `wishlist_items`, `orders`, `order_items`, `reviews`, `testimonials`, `newsletter_subscribers`, `ai_style_sessions`, `promo_codes` (stub)
- All tables have Row Level Security enabled
- RLS policies written for each table at creation time (not deferred)
- `product_variants` uses separate rows (not JSON) for per-variant colour/size tracking
- `order_items` snapshots `unit_price`, `product_name`, and `variant_label` at insertion

Module: Data Layer
Priority: Must

---

**F-047 — Supabase Auth Integration**

Description:
All user authentication must be handled by Supabase Auth with email/password.

Acceptance Criteria:
- Signup and login via Supabase Auth email/password provider
- JWT session persists across page loads via `supabase.auth.onAuthStateChange`
- Protected routes redirect unauthenticated users to login
- Admin role stored in `raw_app_meta_data` and checked via `is_admin()` RLS function
- Password reset flow is wired (functional if Supabase email configured; UI-present for v1)

Module: Data Layer
Priority: Must

---

**F-048 — Supabase Storage Integration**

Description:
All file storage (product images and user-uploaded style photos) must use Supabase Storage.

Acceptance Criteria:
- `product-images` bucket: public, CDN-served, admin-write only via RLS
- `user-uploads` bucket: private, user-scoped paths (`{uid}/{session_id}/`), 60-second signed URLs
- Product images served with Supabase transform parameters (`?width=800&quality=80` minimum)
- User-uploaded style photos deleted or expired after session completes (or within 24h)

Module: Data Layer
Priority: Must

---

**F-049 — AI Proxy Edge Function**

Description:
All calls to the Gemini Vision API must be proxied through a Supabase Edge Function to protect the API key.

Acceptance Criteria:
- Edge Function `style-match` deployed to Supabase
- `GEMINI_API_KEY` stored as Edge Function secret — never in any frontend file
- Function verifies user JWT before processing (rate-limit check via `ai_style_sessions`)
- Function accepts: signed photo URL + user preferences + compact catalog context
- Function calls Gemini Vision API, receives structured JSON response, saves session, and returns product IDs + colour guidance
- CORS headers locked to production domain
- API key is never present in any HTML, JS, or `.env` file committed to the repository

Module: AI Style Match / Data Layer
Priority: Must

---

**F-050 — Seeded Product Catalog**

Description:
The Supabase database must be pre-populated with a realistic sample catalog to support all storefront features.

Acceptance Criteria:
- Minimum 20 products across 6 types: sports bras, leggings, tennis skirts, jackets, padel sets, pilates sets
- Each product has: name, category, price, colour variants (min 2), size options (XS–XL), materials, description, styling suggestions, at least 2 images
- Seed data is written as a repeatable SQL seed script committed to the repository
- Products are realistic for a premium activewear brand (premium pricing, considered naming, real fabric details)

Module: Data Layer
Priority: Must

---

**F-051 — Deployment Pipeline**

Description:
Elvora must be deployable to a public URL accessible for assessment review and demonstration.

Acceptance Criteria:
- Deployed to Netlify (or Vercel) with a stable public URL
- Environment variables (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) configured in deployment platform — never hardcoded
- Build step runs Tailwind CSS v4 CLI to produce production CSS
- Edge Function is deployed to Supabase and accessible from the production domain
- A GitHub Actions (or equivalent) scheduled workflow pings Supabase `/auth/v1/health` daily to prevent free-tier project pause

Module: Infrastructure
Priority: Must

---

## Non-Functional Requirements

---

**NF-001 — Responsive Mobile-First Design**

Description:
The entire website must be designed mobile-first and function correctly across all common device sizes.

Acceptance Criteria:
- All pages render correctly at: 375px (mobile), 768px (tablet), 1024px (laptop), 1280px+ (desktop)
- Navigation collapses to a hamburger menu on mobile
- No horizontal scrolling on any page at any breakpoint
- Touch targets (buttons, links) are minimum 44×44px
- No form input has `font-size` below 16px (prevents iOS Safari auto-zoom)
- Tested in Chrome DevTools responsive mode at all four breakpoints

Module: UI/UX
Priority: Must

---

**NF-002 — Page Load Performance**

Description:
Key pages must load quickly to support the premium user experience and pass Core Web Vitals.

Acceptance Criteria:
- Homepage LCP (Largest Contentful Paint) under 3.0 seconds on a simulated 4G connection
- All product images served with Supabase Storage transform (`?width=800&quality=80` or better)
- Hero image uses `fetchpriority="high"`; all below-fold images use `loading="lazy"`
- `width` and `height` attributes set on all `<img>` tags to prevent layout shift
- No render-blocking scripts in `<head>` (defer or async where appropriate)
- Tailwind CSS compiled to production build (not Play CDN in production)

Module: UI/UX / Infrastructure
Priority: Must

---

**NF-003 — Accessibility Baseline**

Description:
The website must meet basic WCAG 2.1 Level AA accessibility requirements.

Acceptance Criteria:
- All images have meaningful `alt` attributes (decorative images use `alt=""`)
- Colour contrast ratio ≥ 4.5:1 for body text, ≥ 3:1 for large text and UI components
- All interactive elements (buttons, links, form inputs) are reachable and operable via keyboard
- Focus styles are visible (not removed with `outline: none` without a replacement)
- Form inputs have associated `<label>` elements
- Modal dialogs implement focus trap while open (F-015)
- Page has a logical heading hierarchy (`h1` → `h2` → `h3`)

Module: UI/UX
Priority: Must

---

**NF-004 — Brand Aesthetic Consistency**

Description:
The entire website must maintain the quiet luxury brand identity consistently across all pages and components.

Acceptance Criteria:
- Design tokens defined in Tailwind config: colour palette (cream `#F5F0E8`, sage `#8A9E8E`, slate `#6B7280`, ivory `#FAFAF7`, charcoal `#2D2D2D`), typeface pair (display serif + body sans-serif), spacing scale
- No default framework colours (e.g., Tailwind blue-500, Bootstrap primary) appear in the UI
- Typography system uses a premium display serif for headlines and a clean sans-serif for body text
- Buttons, cards, and form elements follow the defined component library — no ad-hoc styling
- The experience visually reads closer to Alo Yoga / Varley than a generic sports e-commerce store

Module: UI/UX
Priority: Must

---

**NF-005 — Security**

Description:
The application must not expose sensitive data or credentials at any point.

Acceptance Criteria:
- Supabase `ANON_KEY` is the only key present in frontend code (this is safe by design — RLS enforces access control)
- `ANTHROPIC_API_KEY` is stored only in Supabase Edge Function secrets — never in HTML, JS, `.env`, or git history
- `SERVICE_ROLE_KEY` is never present in any frontend file or committed to the repository
- All Supabase tables have RLS enabled and policies written
- Admin write operations fail at the database level for non-admin users (not just redirected client-side)
- User-uploaded photos are stored in a private bucket with user-scoped paths

Module: Infrastructure / Data Layer
Priority: Must

---

**NF-006 — Code Maintainability**

Description:
The codebase must be structured for readability and maintainability appropriate to a student-scope project.

Acceptance Criteria:
- Files organised by page/feature (e.g., `js/cart.js`, `js/auth.js`, `js/style-match.js`)
- Supabase client initialised in a single shared module (`js/supabase.js`) — not re-initialised per page
- No inline JavaScript in HTML files (external `.js` files only)
- CSS uses Tailwind utility classes with custom design tokens; no duplicate or conflicting style blocks
- Database queries use parameterised Supabase JS SDK calls — no raw SQL string concatenation in frontend code
- SQL seed scripts and migrations stored in a `/supabase/` directory in the repository
- `README.md` documents: project setup, environment variable configuration, deployment steps

Module: Infrastructure
Priority: Must

---

**NF-007 — AI Usage Documentation**

Description:
The project must include clear documentation of how AI is used within Elvora, as required by the university assessment.

Acceptance Criteria:
- `AI-USAGE.md` (or equivalent section in `README.md`) documents: which AI tools were used, what they were used for, how the Style Match feature works technically
- Claude Vision API integration is documented with example input/output
- Edge Function proxy pattern is explained (why the API key is not in the browser)
- Any AI-assisted code generation is disclosed
- Documentation is clear enough for a non-technical assessor to understand what the AI does and why

Module: Infrastructure
Priority: Must

---

**NF-008 — Deployment Readiness**

Description:
The project must be deployable to a public URL without manual intervention beyond initial configuration.

Acceptance Criteria:
- All environment variables documented in `.env.example` with descriptions
- No hardcoded localhost URLs in production code
- Build process is documented and reproducible (`npm run build` or equivalent)
- Supabase project URL and anon key can be swapped via environment variables without code changes
- Project remains accessible after 7 days without activity (F-051 keep-alive ping)

Module: Infrastructure
Priority: Must

---

## Deferred to v2

The following features were considered and explicitly deferred from v1 scope:

| Feature | Reason for Deferral |
|---------|-------------------|
| Order history in customer account | Deprioritised for student scope; orders are stored but not surfaced in account UI |
| Promo code validation logic | UI placeholder only in v1; validation logic deferred |
| Newsletter email delivery | Form UI is functional; third-party email sending (Resend/Mailgun) deferred |
| Review submission by customers | Reviews are seeded/admin-managed in v1; user-submitted reviews deferred |
| Virtual try-on | Out of scope — no generative imagery |
| Real payment processing | Placeholder architecture only; live payment provider integration deferred |
| Live inventory management | Seeded static data only |
| Multi-currency support | Single currency (USD/IDR) only |
| Mobile app (iOS/Android) | Web-only for v1 |
| Advanced analytics dashboard | Not required for assessment scope |
| Social login (Google/Apple) | Email/password only for v1 |
| Post-purchase email confirmations | Deferred with newsletter email delivery |

---

## Traceability Matrix

| Requirement ID | Feature Area | Phase | Status |
|----------------|--------------|-------|--------|
| F-046 | Supabase Database Schema | Phase 1 | Pending |
| F-047 | Supabase Auth Integration | Phase 1 | Pending |
| F-048 | Supabase Storage Integration | Phase 1 | Pending |
| F-049 | AI Proxy Edge Function | Phase 1 | Pending |
| F-050 | Seeded Product Catalog | Phase 1 | Pending |
| F-051 | Deployment Pipeline | Phase 1 | Complete |
| NF-005 | Security | Phase 1 | Complete |
| NF-006 | Code Maintainability | Phase 1 | Pending |
| NF-008 | Deployment Readiness | Phase 1 | Complete |
| F-001 | Editorial Hero Section | Phase 2 | Pending |
| F-002 | Featured Activity Collections | Phase 2 | Pending |
| F-003 | Best Sellers Section | Phase 2 | Pending |
| F-004 | Lifestyle / Lookbook Grid | Phase 2 | Pending |
| F-005 | Brand Story Section | Phase 2 | Pending |
| F-006 | Testimonials Section | Phase 2 | Pending |
| F-007 | Newsletter Signup | Phase 2 | Pending |
| F-043 | About / Brand Story Page | Phase 2 | Pending |
| F-044 | Lifestyle Editorial Content | Phase 2 | Pending |
| F-045 | Contact / FAQ Page | Phase 2 | Pending |
| NF-001 | Responsive Mobile-First Design | Phase 2 | Pending |
| NF-002 | Page Load Performance | Phase 2 | Pending |
| NF-003 | Accessibility Baseline | Phase 2 | Pending |
| NF-004 | Brand Aesthetic Consistency | Phase 2 | Pending |
| F-008 | Product Listing Page | Phase 3 | Pending |
| F-009 | Activity Category Filtering | Phase 3 | Pending |
| F-010 | Color Swatches on Product Cards | Phase 3 | Pending |
| F-011 | Product Search with Autosuggest | Phase 3 | Pending |
| F-012 | Sort Options | Phase 3 | Pending |
| F-013 | Multi-Image Product Gallery | Phase 3 | Pending |
| F-014 | Sticky Add to Cart Bar | Phase 3 | Pending |
| F-015 | Size Guide Modal | Phase 3 | Pending |
| F-016 | Fabric & Material Details | Phase 3 | Pending |
| F-017 | Complete the Look — Outfit Pairing | Phase 3 | Pending |
| F-018 | Related Products Grid | Phase 3 | Pending |
| F-019 | Customer Reviews on PDP | Phase 3 | Pending |
| F-025 | User Registration | Phase 4 | Pending |
| F-026 | User Login & Logout | Phase 4 | Pending |
| F-027 | Session Persistence | Phase 4 | Pending |
| F-028 | Wishlist / Saved Items | Phase 4 | Pending |
| F-029 | Saved AI Style Preferences | Phase 4 | Pending |
| F-030 | Style Match Landing Page | Phase 5 | Pending |
| F-031 | Photo Upload | Phase 5 | Pending |
| F-032 | Style Preference Input Form | Phase 5 | Pending |
| F-033 | AI Outfit Combination Recommendations | Phase 5 | Pending |
| F-034 | Complementary Colour Guidance | Phase 5 | Pending |
| F-035 | Style Match Session Persistence | Phase 5 | Pending |
| NF-007 | AI Usage Documentation | Phase 5 | Pending |
| F-020 | Slide-out Mini Cart | Phase 6 | Pending |
| F-021 | Full Cart Page | Phase 6 | Pending |
| F-022 | Guest Checkout | Phase 6 | Pending |
| F-023 | Multi-Step Checkout Flow | Phase 6 | Pending |
| F-024 | Order Record Creation | Phase 6 | Pending |
| F-036 | Admin Authentication & Access Control | Phase 7 | Pending |
| F-037 | Product CRUD | Phase 7 | Pending |
| F-038 | Product Image Upload | Phase 7 | Pending |
| F-039 | Category & Collection Management | Phase 7 | Pending |
| F-040 | Homepage Content Management | Phase 7 | Pending |
| F-041 | Testimonials Management | Phase 7 | Pending |
| F-042 | Order Read View | Phase 7 | Pending |
