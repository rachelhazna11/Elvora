# Feature Landscape

**Domain:** Premium women's activewear e-commerce (quiet luxury, padel/pilates/tennis/gym/running)
**Project:** Elvora
**Researched:** 2026-06-10
**Research basis:** Alo Yoga, Lululemon, Varley, Baymard Institute UX research (170+ sites, 21,000+ parameters), Vervaunt luxury e-commerce analysis, industry UX practitioner sources

---

## Table Stakes

Features users expect. Missing = product feels incomplete, trust collapses, or users leave.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Full-screen editorial hero with CTA | Premium activewear brands (Alo Yoga, Adanola, Varley) all lead with cinematic hero imagery + one clear action. Text-over-lifestyle-photo is the genre convention. | Low | Use a single full-bleed image or short video loop. CTA = "Shop [Collection]" or "Discover Elvora." No generic "Welcome." |
| Activity-based collection navigation | Users browse by sport context (Padel, Pilates, Tennis, Training, Running), not generic "tops/bottoms." Alo Yoga, Lululemon, and Varley all lead with activity categories. | Low | Top nav + homepage collection grid. This is how the target audience mentally organizes her wardrobe. |
| Color swatch display on product listing page | Users must see color variants without clicking into the PDP. 42% of sites still fail this (Baymard 2025). Without swatches, users miss options and bounce. | Low | Show clickable swatches beneath product thumbnail. Clicking swatch updates thumbnail image. Min hit area 7mm x 7mm per Baymard. |
| Multiple product images per listing card (3+ views) | 80% of sites show only 1 image on listing pages (Baymard 2025). Users who see 3+ images have dramatically higher purchase confidence. Fashion requires lifestyle + flat + detail shots. | Low | On hover (desktop) or swipe (mobile): show 2nd image, typically a worn/lifestyle view. |
| Exposed size button selectors (not dropdown) | Dropdowns cause users to overlook size selectors entirely and miss sold-out signals. 70% of apparel sites still use dropdowns (Baymard). Button layout shows availability at a glance. | Low | Greyed-out/crossed buttons for unavailable sizes. Critical for mobile. |
| Size guide with body measurements (not just S/M/L) | 82% of apparel sites fail to provide adequate sizing info (Baymard). Activewear fit is critical — wrong sizing = returns and lost trust. Must include cm/inches and how-to-measure instructions. | Low-Medium | Modal or accordion on PDP. Include notes like "runs small" or "high-waist sits above navel." |
| Products displayed on human models | Users cannot assess drape, length, or fit from flat-lay or ghost images. Baymard: 21% of sites still omit this. Activewear especially needs to show waistband placement, coverage, range of motion. | Low (seeded catalog) | Every catalog product needs at least one on-model photo. Commission or source accordingly during catalog seeding. |
| Fabric and material details on PDP | Premium activewear buyers want fabric composition (e.g., "78% Nylon, 22% Elastane"), stretch direction, moisture-wicking or compression properties. This is a trust signal and differentiator from fast fashion. | Low | Accordion section on PDP: "Fabric & Care." Include fabric weight if known, key performance properties, care instructions. |
| Slide-out mini cart (not page redirect on add) | Interrupting browse flow by redirecting to a full cart page on every add-to-cart kills conversion. Mini-cart confirms the action, shows subtotal, and keeps user in browsing mode. | Medium | Slide-in panel from right. Show item thumbnail, name, size, color, quantity, subtotal. Two CTAs: "Continue Shopping" (close) and "View Cart / Checkout." |
| Sticky "Add to Cart" bar on PDP scroll | When users scroll through long PDPs (images, description, size guide, reviews), the add-to-cart must remain accessible. Glossier, Alo Yoga, and Lululemon all implement this. Without it, users must scroll back up to buy. | Low-Medium | After scrolling past the primary ATC button, show a condensed sticky bar at bottom of viewport with product name, selected size/color, and ATC button. |
| Guest checkout | Forced account creation causes 26% of cart abandonments (Baymard/industry data). For a premium brand, it also feels presumptuous at a first visit. | Medium | Allow email-only checkout. Offer account creation post-purchase ("Save your order details — create an account"). |
| Shipping cost transparency before checkout | 48% of cart abandonments are caused by unexpected shipping costs (industry data). Showing "Free shipping over X" or a cost estimate in the mini cart / cart page is now expected behavior. | Low | Show shipping threshold banner ("Free shipping on orders over $X") in mini cart and cart page. Placeholder values for the assessment context. |
| Order confirmation page + email | Fundamental trust signal after any purchase. Users expect an immediate on-screen confirmation and an email summary. | Low-Medium | Confirmation page: order number, item summary, shipping address. Email template: same content. Supabase can trigger via edge function or client-side for assessment. |
| Customer account: order history | Users expect to review past purchases. Without this, the account section feels empty and the registration incentive disappears. | Medium | List of orders with status, date, item thumbnails, and total. |
| Wishlist / heart / save for later | 44% of shoppers want wishlist functionality (industry data). Wishlist users are 3x more likely to convert and spend 16% more per order. In premium fashion, saving items is a browsing behavior, not just a convenience. | Medium | Heart icon on every product card and PDP. Requires account or pre-auth save-to-local-storage for guests. Show saved items in account section. |
| Customer reviews with aggregate rating on PDP | 90% of consumers read reviews before purchasing. Products with 5+ reviews are 270% more likely to sell. In activewear, reviews validate fit, comfort during activity, and fabric quality. | Medium | Star rating aggregate at top of PDP. Review cards with: rating, title, body, reviewer name, date. Display reviewer-submitted photos in carousel (not per-review — Baymard recommends cross-review navigation). |
| Aggregate "fit" subscore in reviews | Baymard: only 24% of sites offer this, yet it's one of the highest-value signals for apparel. A "tight vs. loose" or "runs small / true to size / runs large" scale saves users from reading 30 reviews to determine fit. | Low-Medium | Add a fit rating scale to the review submission form. Show aggregate as a visual scale on PDP alongside star rating. |
| Search with autosuggest | Users who can't find products via search bounce. Autosuggest showing product names, categories, and activity tags reduces friction and increases discovery. | Medium | Real-time search suggestions on keystroke. Show product thumbnails + name in dropdown. Supabase full-text search is sufficient for a seeded catalog. |
| Activity category filtering on PLP | Since products span padel, pilates, tennis, gym, running — filtering by activity is the primary discovery axis for this catalog. | Low | Left sidebar or top filter bar (mobile: horizontal scroll filter pills). Filter by: Activity, Color, Size, Price Range. Sort by: Featured, Newest, Price Low-High, Price High-Low. |
| Mobile-responsive navigation with hamburger menu | 68% of e-commerce traffic is mobile. Premium activewear target audience (women 20-35) will predominantly use phones. A cluttered or broken mobile nav is immediately disqualifying. | Low-Medium | Off-canvas slide-in menu on mobile. Category links with activity icons. Search accessible in one tap from nav. |
| Brand story / About page | Premium brands are identity purchases. Buyers want to know the ethos, values, and origin story. Alo Yoga's "About" and "Community" pages are integral to their conversion funnel. | Low | Single page with brand narrative, aesthetic imagery, and values statement. Links to from footer and nav. |
| Newsletter signup (email capture) | Standard for premium DTC fashion. Typically gated with a discount or "early access" incentive. Builds the re-engagement channel. | Low | Footer section + optional modal on first visit (delayed 10+ seconds or on exit intent). No aggressive popups on landing — inconsistent with quiet luxury positioning. |

---

## Differentiators

Features that set Elvora apart. Not universally expected, but create competitive advantage and assessment distinctiveness.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AI Style Match (photo upload → outfit recommendation) | The core differentiator. No equivalent in the assessment context. User uploads a photo → Claude Vision analyzes appearance, body proportions, coloring → returns a curated outfit from the Elvora catalog with reasoning. Feels like a personal stylist, not a quiz. Competitors (Stylitics, Daydream) are enterprise tools; this is brand-native and intimate. | High | Vision-capable LLM (Claude API). Input: user photo + activity preference. Output: 3-4 catalog products with styling rationale. Store preference results in Supabase for logged-in users. No image generation, no virtual try-on. |
| Activity-specific outfit pairings on PDP | "Complete the Look" built around the sport context, not generic "you may also like." A padel dress PDP shows the matching padel bag, court shoes (if in catalog), and a matching sports bra — styled as a complete court outfit. This is how premium brands like Alo Yoga and Varley merchandise. | Medium | Manual editorial curation during catalog seeding. Each hero product tagged with 2-3 complementary items. Displayed as styled "Shop the Look" section at bottom of PDP. |
| Saved AI style preferences in account | After running AI Style Match, users can save their preference profile (photo, activity type, style notes from the AI's analysis). On return visits, the AI can use the saved profile to deliver faster, better recommendations. Feels like the platform "knows" you. | Medium | Supabase table: user_style_preferences (user_id, uploaded_photo_url, activity, ai_style_notes). Link recommendations to saved profile. Allow re-upload to refresh preferences. |
| Quiet luxury editorial homepage rhythm | Not just a hero + grid. A structured editorial flow: Hero → Featured Collections → Bestsellers → AI Style Match CTA → Lifestyle Inspiration / Lookbook → Brand Story Teaser → Testimonials → Newsletter. This creates a brand narrative experience, not a product list. Alo Yoga and Varley do this; generic stores don't. | Medium | Requires thoughtful content architecture and section-by-section visual design. Not technically complex — complexity is editorial, not engineering. |
| Complementary color suggestions from AI | When recommending outfits, the AI notes color relationships ("This sage green top pairs with your neutral coloring" or "The ivory and slate combination suits your warm undertone"). Competitors offer generic "complete the look" — this is personalized to the user's appearance. | Medium (bundled with AI Style Match) | Part of the AI prompt output, not a separate feature. Include in the AI Style Match output rendering: a "Why this works for you" section. |
| Activity-context storytelling (lifestyle pages) | Beyond the product catalog, editorial pages for each activity (Padel Life, Pilates Studio, On the Court) that blend lifestyle photography with shoppable product recommendations. Serves SEO and brand positioning simultaneously. Premium brands use this as a content moat. | Medium | 4-5 editorial content pages. Static content + a curated product grid pulled from the catalog. Supabase-managed or hardcoded for assessment. |
| Lookbook-style "As Styled" section on homepage | User-generated styling inspiration (or editorially curated) showing real outfits assembled from Elvora pieces. Alo Yoga calls this "Styled By You." Creates social proof, cross-sells, and reinforces the quiet luxury aesthetic. | Medium | Curated grid (seeded/editorial for assessment). Each image links to tagged products. Does not require real UGC infrastructure — can be seeded editorial imagery. |

---

## Anti-Features

Features to explicitly NOT build. Building these would waste time, undercut the brand aesthetic, or exceed realistic scope.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Virtual try-on or AR clothing overlay | Technically complex (needs body detection, garment fitting, generative ML), out of assessment scope, and the AI Style Match already provides the personalization story. No premium activewear brand in this tier does this natively without an enterprise vendor. | Use AI Style Match (recommendation only) as the personalization differentiator. |
| Aggressive promotional popups on landing | Destroys quiet luxury positioning. Discount popups on landing communicate "fast fashion" energy — the opposite of Alo Yoga / Varley. Target audience (women 20-35, premium) reads this as cheap. | Use delayed or exit-intent newsletter signup. Or skip the popup entirely and rely on footer capture. |
| Real-time inventory / live stock counters | Requires live inventory system, webhooks, and backend complexity not realistic for seeded catalog. "Only 2 left!" on seeded demo data is dishonest and adds implementation overhead with no assessment value. | Show static sold-out state for specific seeded variants. Sufficient for demonstrating the pattern. |
| Live chat / chatbot | Real-time communication infrastructure is out of scope. A chatbot that can't actually respond damages trust more than having none. | Static "Contact Us" page or email address in footer. Optionally: FAQ accordion section. |
| Multi-currency / international shipping calculator | Adds complexity (currency conversion APIs, localization logic) with no assessment value. Elvora is a portfolio project, not a live transactional store. | Single currency. Static "Shipping info" page with placeholder policy text. |
| Product comparison feature | Activewear is not a spec-comparison purchase category. Users don't compare leggings feature-by-feature. This pattern belongs in electronics/appliances. Would clutter the UI without serving the target audience. | Let the size guide, fabric details, and reviews do the comparison work. |
| Flash sale / countdown timer mechanics | FOMO countdowns conflict with quiet luxury brand identity. Lululemon, Alo Yoga, and Varley do not use countdown timers. This aesthetic reads as Shein, not premium wellness. | Use "New Arrival" and "Bestseller" badges instead for attention without urgency pressure. |
| Loyalty points / gamified rewards program | Alo Access (Alo Yoga's loyalty program) works because it has 10M+ users and ecosystem depth. For a seeded demo store, a points system has no real value, no history, and creates implementation overhead. | Wishlist + saved style preferences create retention incentive without a points backend. |
| Social media feed embed (live Instagram / TikTok) | Live social feed embeds require API credentials, rate limits, and third-party dependencies. They break, go stale, or flash policy errors in demo environments. | Use editorially curated "As Styled" image grid (seeded, static) that looks exactly like a social feed without the infrastructure. |
| Size recommendation ML model | Building a custom fit recommendation ML model is well beyond scope. Enterprise solutions like True Fit and Fit Analytics exist for this. The AI Style Match serves a different (higher-value) personalization angle. | Size guide + aggregate fit review scale gives users the information they need. |
| Real payment processing (Stripe, PayPal live integration) | Out of scope per PROJECT.md. No transactional store needed for assessment. A live Stripe integration requires PCI compliance awareness, webhook handling, and refund flows. | Payment form with placeholder architecture: UI accepts card fields, shows "Order confirmed" without real charge. State that this is a UI/UX prototype. |
| Blog / CMS content publishing system | Full editorial CMS (author management, drafts, publishing workflow, SEO metadata editor) is overkill. Static editorial pages serve the brand story need without content management infrastructure. | Hardcode or Supabase-manage 4-5 editorial pages (About, Activity Guides, Brand Story). Admin can update product/collection content without a blog engine. |
| Product Q&A section | Requires moderation, admin responses, and an additional content surface. Adds low value when a good size guide + reviews already answer the common questions. | Redirect sizing questions to the size guide via a prominent link on PDP. |

---

## Feature Dependencies

```
Account (auth) → Wishlist (requires user_id)
Account (auth) → Order History (requires user_id)
Account (auth) → Saved AI Style Preferences (requires user_id)
Guest Checkout → Order Confirmation (no account required, but email required)

Product Catalog (seeded) → All PDP Features
Product Catalog (seeded) → Activity-Specific Outfit Pairings (curation requires catalog to exist)
Product Catalog (seeded) → AI Style Match Recommendations (AI maps to catalog items)

AI Style Match → Complementary Color Suggestions (bundled in same feature)
AI Style Match → Saved AI Style Preferences (saving the output requires account)

Customer Reviews (submission) → Account (auth recommended, not required)
Customer Reviews (display) → Product Catalog

Admin: Product CRUD → Product Catalog (admin populates it)
Admin: Collection / Category CRUD → Activity Navigation
Admin: Homepage Content CRUD → Editorial Homepage Sections
Admin: Testimonials CRUD → Homepage Testimonials Section

Mini Cart → Cart Page (mini cart is the entry point; cart page is the full review)
Cart Page → Checkout Flow
Checkout Flow → Order Confirmation
```

---

## MVP Recommendation

Given the assessment context (university project, prioritize polished execution over breadth), build in this priority order:

**Must ship (assessment pass):**
1. Editorial homepage with hero, activity collections, bestsellers, brand story, testimonials, newsletter
2. Product catalog: activity filtering, color swatches, size selectors, 3+ images per product
3. Product detail page: full imagery, size guide, fabric details, outfit pairing ("Complete the Look"), sticky ATC, customer reviews
4. Mini cart + cart page + guest checkout flow + order confirmation
5. Customer account: signup/login, order history, wishlist
6. AI Style Match MVP: photo upload → Claude Vision analysis → catalog product recommendations
7. Admin panel: product CRUD, collection CRUD, homepage content management

**Ship second (differentiates assessment quality):**
8. Saved AI style preferences in account
9. Fit rating scale in reviews
10. Activity-specific lifestyle editorial pages (Padel Life, Pilates Studio, etc.)
11. "As Styled" curated lookbook section

**Defer / cut if time-constrained:**
- Newsletter backend (form UI without actual email delivery is fine for assessment)
- Advanced search with product-image autosuggest (basic text search sufficient)
- Cross-review photo carousel navigation (single review photos acceptable for MVP)

---

## Phase-Specific Notes for Roadmap

| Phase Topic | Feature Density | Key Complexity | Notes |
|-------------|----------------|----------------|-------|
| Homepage | Medium | Editorial rhythm, section ordering | 7-8 sections. Most complexity is visual/design, not technical. |
| Product Catalog / PLP | Medium | Filtering logic, swatch-updates-thumbnail | Supabase queries for filters. Color swatch → image swap is JavaScript. |
| Product Detail Page | High | Sticky ATC, "Complete the Look" curation, review system | Most features are on this page. Most build time lands here. |
| Cart + Checkout | Medium-High | Mini cart state management, multi-step checkout flow | State management across components. Guest vs. auth flow branch. |
| Account + Wishlist | Medium | Supabase auth integration, wishlist persistence | Supabase auth handles most complexity. Wishlist is a join table. |
| AI Style Match | High | Claude Vision API, prompt engineering, result mapping | Highest technical novelty. Needs prompt iteration. Photo upload → Supabase Storage → API call → response rendering. |
| Admin Panel | Medium | CRUD operations, image upload, auth-gated access | Standard CRUD. Admin auth is a protected route check. Image upload to Supabase Storage. |

---

## Sources

- [Baymard Institute — 5 Apparel UX Best Practices](https://baymard.com/blog/apparel-5-best-practices)
- [Baymard Institute — Product List UX Best Practices 2025](https://baymard.com/blog/current-state-product-list-and-filtering)
- [Commerce UI — 21 Fashion PDP Examples 2025](https://commerce-ui.com/insights/best-21-fashion-pdp-examples-in-2024)
- [Brain & Code — 13 UX Best Practices for Apparel E-commerce](https://brainandcode.com/13-ux-best-practices-to-boost-apparel-ecommerce-conversions/)
- [Vervaunt — Luxury Brand-Led eCommerce Examples](https://vervaunt.com/examples-of-luxury-brand-led-ecommerce-websites-premium-ecommerce-ux-technology)
- [xLook — Best AI Fashion Apps Comparison Guide 2025](https://xlook.app/blog/best-ai-fashion-apps-comparison-guide-2025/)
- [Alo Yoga Omnichannel Marketing Strategy — AppBrew](https://www.appbrew.com/blogs/alo-yoga-omnichannel-marketing-strategy)
- [BelVG — Shopping Cart UX Best Practices 2026](https://belvg.com/blog/best-practices-for-ecommerce-shopping-carts.html)
- [Drip — E-commerce Wishlist Examples](https://www.drip.com/blog/e-commerce-wishlist-examples)
- [Seclgroup — E-commerce Admin Panel Features](https://seclgroup.com/top-ecommerce-website-features-part-2/)
- [Baymard Institute — Mobile UX Ecommerce](https://baymard.com/blog/mobile-ux-ecommerce)
- [Wisernotify — Social Proof Statistics 2026](https://wisernotify.com/blog/social-proof-statistics/)
