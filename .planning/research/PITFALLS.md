# Domain Pitfalls

**Project:** Elvora — Premium Women's Activewear E-Commerce
**Domain:** Supabase-backed e-commerce with AI vision integration
**Researched:** 2026-06-10

---

## Critical Pitfalls

Mistakes that cause rewrites, data loss, security incidents, or project failure.

---

### Pitfall 1: Supabase RLS Disabled by Default Exposes All Data

**What goes wrong:** Tables created via the Supabase Table Editor or SQL have Row Level Security disabled by default. Without RLS, any request using the `anon` key — which is embedded in every frontend app — can read and write every row in every table. Product prices, user orders, wishlists, and admin-only content are all publicly readable. CVE-2025-48757 found 10.3% of analyzed Supabase apps were leaking data through this exact vector.

**Why it happens:** Developers assume the `anon` key is read-limited by default, or add RLS later and forget to cover all tables. RLS failures are silent — they return empty results rather than errors, so a misconfiguration looks like a "data loading bug" rather than a security hole.

**Consequences:** Any user can query `products`, `orders`, `users`, or `admin_content` tables directly via the Supabase REST API. Cart and wishlist data of all users is exposed. Admin CRUD operations become accessible from the browser console.

**Prevention:**
- Enable RLS on every table immediately when it is created — never leave it as a post-launch task.
- Write policies before writing application code: enforce `auth.uid() = user_id` for user-scoped tables, and a separate `is_admin` check for admin-writable tables.
- Use the `(select auth.uid())` form (with parentheses) rather than `auth.uid()` directly — this caches the call per statement and avoids the performance trap documented in CVE-2025-48757.
- Never use the `service_role` key in frontend code. It bypasses RLS entirely and has no place in a browser bundle.
- Test RLS by making requests as an anonymous user and as a different authenticated user — verify denied requests return empty sets, not the data.

**Warning signs:**
- You can query `supabase.from('orders').select('*')` in the browser console without being logged in and get data back.
- Any table shows "RLS Disabled" in the Supabase dashboard under Authentication > Policies.
- You added a table days after initial setup and did not revisit RLS.

**Phase to address:** Phase 1 (Foundation / Database schema). RLS policies must be written in the same commit that creates each table — retrofitting is error-prone.

---

### Pitfall 2: AI API Key Exposed on the Client Side

**What goes wrong:** The Claude (or any vision LLM) API key is placed in frontend JavaScript — either hardcoded, in a `.env` file that gets bundled, or in a config object. Anyone viewing page source or network traffic can extract it. An attacker can then run unlimited inference against your account.

**Why it happens:** Student projects often skip backend infrastructure entirely. Without a server, there is no obvious place to proxy the request, so the key ends up in the client. Vite/CRA `.env` files starting with `VITE_` or `REACT_APP_` are intentionally injected into the browser bundle — they are not secrets.

**Consequences:** A leaked Claude API key can generate $82,000+ in charges within 48 hours (documented real-world case). Anthropic can suspend the account, killing the AI Style Match feature mid-assessment. The key cannot be "hidden" once it ships in a browser bundle — it is always recoverable.

**Prevention:**
- Route all AI API calls through a Supabase Edge Function. The key lives in the Edge Function's environment variables (server-side only) and is never sent to the browser.
- The frontend posts the user's image (as base64 or a Supabase Storage URL) to a Supabase Edge Function endpoint, which calls the Claude API and returns the recommendations.
- Set a hard spending cap on the Anthropic account (the last line of defence if the key leaks from the Edge Function environment somehow).
- Never commit the key to git. Use `.env.local` and ensure `.env*.local` is in `.gitignore`.
- For the assessment demo context: if Edge Functions feel complex, at minimum use an environment variable that is only readable server-side and document clearly that production would use a proxy.

**Warning signs:**
- `VITE_ANTHROPIC_KEY` or `REACT_APP_ANTHROPIC_KEY` appears anywhere in code.
- The Anthropic API call is made from a file that runs in the browser (any component or page file).
- You can see the API key value in browser DevTools → Network → Request Headers.

**Phase to address:** Phase 1 (Architecture decisions) and Phase 3 (AI Style Match implementation). The proxy architecture must be decided before writing any AI call — retrofitting is a full rewrite of the feature.

---

### Pitfall 3: Premium Aesthetic Collapses into Generic Sports E-Commerce

**What goes wrong:** The site uses a standard Bootstrap/Tailwind card grid, default blue/red accent colours, generic sans-serif body text, and commodity product card layouts. Despite "quiet luxury" intent, the result looks indistinguishable from a basic WooCommerce store. The brand premium is established entirely in the copy but not in the visual system.

**Why it happens:** UI frameworks provide sensible defaults that are not luxury defaults. Developers reach for familiar components (card grids, navbar with hamburger menu, hero with a single large image and CTA button) without questioning whether those components serve a premium brand. Typography is often the last thing addressed and defaults to system fonts.

**Consequences:** Assessors and users perceive a mismatch between brand claims (Alo Yoga / Varley benchmark) and the delivered experience. The AI Style Match feature — the genuine differentiator — lands in an interface that undercuts its perceived value.

**Prevention:**
- Lock the design system first: define the colour palette (cream, sage, slate, ivory + one accent), typeface pair (a serif display font for headlines + clean sans for body), spacing scale, and border-radius decisions before writing a single component. Refer back to this system on every component.
- Avoid default blue interactive states, generic shadow styles, and pill-shaped buttons — these read as SaaS, not luxury fashion.
- Use generous whitespace as a design element, not an accident of incomplete padding. Luxury brands deliberately leave room.
- Hero sections should use full-bleed editorial imagery with overlaid type — not a split-screen card with a text block on the left.
- Product cards should not show ratings stars, stock count badges, or "Add to Cart" buttons on hover — these are mass-market patterns. Use minimal overlays, clean typography, and a refined hover state.
- Every font-size below 16px in a UI element is a danger sign that the design is shrinking into busyness.

**Warning signs:**
- The homepage looks correct in a screenshot but feels like "a website" not "a brand."
- The primary call-to-action button uses the default framework blue.
- Product cards show more than 4 pieces of information before interaction.
- The typeface is Inter or the OS default.

**Phase to address:** Phase 1 (Design system / CSS foundations). Typography, colour tokens, and spacing scale must be established before building any components. Fixing brand feel after pages are built requires touching every file.

---

### Pitfall 4: Scope Creep Collapses the Project Before Submission

**What goes wrong:** The project starts focused on core e-commerce + AI Style Match, then progressively adds: real-time stock indicators, advanced filtering, a loyalty points system, customer reviews with voting, editorial blog, multiple homepage variants, advanced search with autocomplete, and a comparison tool. None of these reach production quality. The assessment is submitted with 15 half-built features instead of 8 polished ones.

**Why it happens:** E-commerce is a domain with infinite legitimate feature ideas. Every page you reference (Alo Yoga, Varley) has features that seem reasonable to add. Without a hard scope boundary, ideas accumulate into a backlog that is never deferrred — it just grows.

**Consequences:** Core flows (cart, checkout, AI Style Match) are rushed and buggy. The premium aesthetic is compromised because there was no time to polish. Assessment criteria around "clean user flow" and "polished execution" are not met.

**Prevention:**
- Treat the requirements in `PROJECT.md` as a signed contract. Adding a feature requires explicitly removing or deferring another.
- When a new idea surfaces, write it in a "parking lot" list — do not add it to the build backlog during active development.
- After each build phase, audit: does every feature on this phase's list serve the grading criteria directly? If not, defer.
- The three non-negotiable core flows are: product browse → add to cart → checkout, customer auth + wishlist, and AI Style Match photo upload → recommendation. Everything else is decoration. Polish these three to a high standard before touching anything else.
- Set a "feature freeze" date at least two weeks before submission and commit to it.

**Warning signs:**
- The task list grows longer after each work session rather than shorter.
- You find yourself building a feature "just because it would be cool."
- The homepage has more than 8 sections.
- You have started building a feature that is listed in the "Out of Scope" section of `PROJECT.md`.

**Phase to address:** Phase 0 (Project planning) and enforced at every phase boundary via `/gsd-transition`.

---

## Moderate Pitfalls

Mistakes that cause significant rework or degrade quality without being fatal.

---

### Pitfall 5: Cart and Checkout State Management Breaks

**What goes wrong:** Cart state lives only in `localStorage` or a JavaScript variable, causing it to desync from the Supabase `cart` table. Users add items, refresh the page, and their cart is empty or doubled. A promo code can be applied multiple times because the apply logic has no server-side idempotency check. On the checkout confirmation page, the order is created but the cart is not cleared on network failure.

**Why it happens:** Managing distributed state (browser + database) is genuinely difficult. Student projects often start with client-only cart state for simplicity, then add Supabase persistence without fully replacing the local state — resulting in two sources of truth that diverge.

**Consequences:** Users lose cart contents unpredictably. Promo codes apply multiple times. The order confirmation page may show successfully while the order was not actually persisted. These are the most user-visible bugs in the project.

**Prevention:**
- Supabase is the single source of truth for cart state. On every page load, fetch the cart from `cart_items` for the authenticated user. Do not cache cart state in `localStorage` for authenticated users.
- For unauthenticated users (guest cart): use `localStorage` as the only store, and merge it into the database cart on sign-in.
- Promo code application must be idempotent: store the applied code in the order row and check before re-applying. Do not apply discounts purely client-side.
- Model the checkout flow as a state machine: CART → VALIDATED → ORDER_CREATED → CONFIRMED. The cart is only cleared after ORDER_CREATED succeeds. If ORDER_CREATED fails, the user stays in VALIDATED with their cart intact.
- The "payment succeeded but order not created" scenario: since this is a placeholder payment, it is acceptable to create the order before "payment" rather than after — eliminating the race condition entirely.

**Warning signs:**
- Cart count in the nav header does not match the cart page.
- Refreshing the cart page changes the item count.
- You can apply the same promo code twice and get double the discount.
- The checkout confirmation page loads but the order does not appear in the admin panel.

**Phase to address:** Phase 2 (Cart and Checkout implementation). Design the state machine before writing cart code.

---

### Pitfall 6: Admin Panel Has No Server-Side Access Control

**What goes wrong:** The admin panel at `/admin` hides its link in the navigation, but the routes themselves perform no authentication check. Any user who discovers the URL (by reading the JavaScript bundle, trying common paths, or being told the URL) can access full CRUD operations on products, orders, and content.

**Why it happens:** Client-side routing gives a false sense of security. Developers hide the nav link and assume that is sufficient. Supabase RLS policies are written for the customer-facing tables but not audited against admin operations. The pattern of "redirect if not logged in" is implemented as a JavaScript redirect, which can be bypassed by a slow connection, a JavaScript error, or by directly calling the Supabase API.

**Consequences:** Any visitor can delete all products, modify prices, or read all customer orders. Even in an assessment context, a grader who is also a developer may test this and flag it as a security failure.

**Prevention:**
- Every admin route must check authentication server-side (or at minimum in a Supabase RLS policy). For an SPA, this means the first thing an admin page component does is verify `supabase.auth.getUser()` and confirm the user has an `is_admin` flag — before rendering any content.
- RLS policies for admin write operations must require the `is_admin` role: `auth.jwt() ->> 'role' = 'admin'` or a lookup against a `profiles` table with `is_admin = true`.
- Admin routes should not be guessable. Use `/admin` by convention, but protect it with authentication, not obscurity.
- Test admin protection by logging out and navigating directly to `/admin/products` — you must be redirected to login, not shown the product list.
- The `service_role` key must never be used in the admin panel frontend. Use the authenticated user's session + RLS.

**Warning signs:**
- You can navigate to `/admin/products` in an incognito window and see or modify data.
- Admin operations use the `service_role` key in JavaScript.
- The only protection is a `if (!isAdmin) router.push('/login')` check on the client side.
- No RLS policies exist for INSERT/UPDATE/DELETE on the `products` or `collections` tables.

**Phase to address:** Phase 2 (Admin panel implementation). RLS admin policies must be written before the admin panel UI is built.

---

### Pitfall 7: Image-Heavy Pages Perform Poorly and Fail Core Web Vitals

**What goes wrong:** The editorial homepage and product catalog load 20–30 unoptimised JPEG images simultaneously. Hero images are large (2–4 MB), product catalog images use no lazy loading, and no `width`/`height` attributes are set causing Cumulative Layout Shift. The site scores poorly on PageSpeed Insights and feels slow — undercutting the premium experience at first impression.

**Why it happens:** Supabase Storage serves images at their original resolution unless explicitly resized. Without a CDN image transformation step, the browser downloads full-size originals. Developers often upload images during development without thinking about production delivery.

**Consequences:** 70% of e-commerce product pages fail Core Web Vitals benchmarks. A slow first paint on the hero section damages the first impression of a "premium" brand immediately. Images consume 50–70% of average page weight.

**Prevention:**
- Use Supabase Storage's built-in image transformation API (`?width=800&quality=80`) to serve appropriately sized images for each breakpoint. This is available on the free tier.
- Set `loading="lazy"` on all product images below the fold. Do NOT set lazy loading on the hero image — set `fetchpriority="high"` on the hero instead.
- Always include `width` and `height` attributes on `<img>` tags to prevent layout shift.
- Use `srcset` with at least two sizes (mobile ~400px wide, desktop ~800px wide) for product card images.
- Compress images before uploading to Supabase Storage: convert to WebP or JPEG with 80% quality. Target < 150 KB for product cards, < 500 KB for hero images.
- Limit the number of images in the above-the-fold viewport to 3–5 maximum.

**Warning signs:**
- PageSpeed Insights (Lighthouse) mobile score is below 50.
- Network tab shows image requests over 500 KB in product card grid.
- The page visibly reflows as images load (layout shift).
- Hero section takes more than 1.5s to show content on a mid-range connection.

**Phase to address:** Phase 1 (Image pipeline / asset strategy) and Phase 2 (Product catalog pages). Establish the Supabase transform URL convention before seeding the catalog with images.

---

### Pitfall 8: Mobile-First CSS That Breaks on Desktop

**What goes wrong:** The project is built mobile-first on a laptop using browser DevTools device emulation. The mobile layout works. However, on actual desktop widths (1200px+), the layout does not scale: text is too large, single-column grids never switch to multi-column, the hero fills only half the viewport width, and editorial sections that need breathing room are cramped. Alternatively, the inverse: the site is built desktop-first, and on mobile the navigation is unusable, touch targets are too small (below 48px), and `input` font sizes are below 16px causing iOS Safari to zoom in.

**Why it happens:** Mobile-first means writing base styles for mobile and layering `min-width` media queries for larger screens — but developers often forget the `min-width: 1024px` and `min-width: 1280px` breakpoints and only test the mobile emulator. The Safari iOS font-size zoom bug is consistently underestimated.

**Consequences:** Assessors testing on desktop see a broken layout. Safari iOS users (a significant portion of the target demographic: women 20–35) experience involuntary zoom on every form field interaction.

**Prevention:**
- Establish breakpoints at `480px`, `768px`, `1024px`, and `1280px` at the CSS architecture level. Write styles for all four in the design system.
- Test on actual desktop Chrome (1440px viewport) and actual iOS Safari (not just DevTools emulator) at every phase boundary.
- Never set `font-size` below `16px` on any `<input>`, `<select>`, or `<textarea>` element — this triggers the iOS Safari zoom bug.
- All interactive touch targets (buttons, links, nav items) must be at least 48×48px.
- Missing viewport meta tag (`<meta name="viewport" content="width=device-width, initial-scale=1">`) is the most common root cause of the entire responsive layout failing — verify it is present in the HTML `<head>`.
- Use `max-width` containers on wide screens so editorial content does not stretch to 2000px on ultrawide monitors.

**Warning signs:**
- The site looks correct in DevTools mobile emulation but wrong when the DevTools panel is undocked and you view it at full browser width.
- Typing in a search field on iPhone Safari causes the entire page to zoom in.
- Product card grid shows 1 column at 1200px wide.
- Navigation hamburger menu is visible on desktop.

**Phase to address:** Phase 1 (CSS architecture and design system). Breakpoints and type scale must be established globally, not added per-component.

---

### Pitfall 9: Supabase Free Tier Limits Pause the Project Mid-Demo

**What goes wrong:** The project works perfectly during development but the Supabase free project pauses after 7 days of inactivity — including the week before submission when the developer is writing the report rather than running queries. The demo URL returns a connection error during the assessment submission or grading.

**Why it happens:** The 7-day inactivity window is tracked against actual database queries, not dashboard visits. Developers discover this the hard way. Additionally, the 1 GB storage limit can be hit with an image-heavy catalog if images are not compressed, and the 500 MB database limit puts the project in read-only mode if exceeded.

**Consequences:** The deployed URL is down during assessment review. The demo cannot be marked as "working deployment" — a core grading criterion. Recovering a paused project takes 5–15 minutes and requires manual action.

**Prevention:**
- Set up a GitHub Actions scheduled workflow (using `schedule: cron`) to ping the Supabase `/auth/v1/health` endpoint daily. This is a 10-minute setup that prevents the pause entirely.
- Alternatively, set up an Uptime Robot free monitor pointing at the Supabase health endpoint — it pings every 5 minutes and prevents inactivity pauses.
- Compress all images before uploading to stay well under the 1 GB storage limit. With ~60 products at 5 images each (compressed to ~100 KB/image), storage usage is approximately 30 MB — well within limits.
- Monitor free tier usage: Database → Settings → Usage in the Supabase dashboard. Set a calendar reminder to check one week before submission.
- Keep two projects: one active development project and one "submission-ready" project that is kept alive via the ping workflow.

**Warning signs:**
- You have not touched the project for 5+ days.
- The Supabase dashboard shows project status as "Paused."
- `supabase.auth.getUser()` returns a network error in the deployed app.
- Supabase storage dashboard shows > 700 MB used.

**Phase to address:** Phase 1 (Infrastructure setup). Set up the keep-alive ping on day one of deployment, not the day before submission.

---

### Pitfall 10: AI Vision API Calls Are Slow or Expensive

**What goes wrong:** The AI Style Match flow uploads a full-resolution photo (3–8 MB) directly to the Claude API. The API takes 8–20 seconds to respond. Users see a blank spinner with no feedback. Alternatively, the prompt sends the entire product catalog (100+ items) in each request, consuming massive token counts and making each call cost $0.15–0.50. With no rate limiting, a user can spam the upload button and exhaust the API budget within minutes.

**Why it happens:** Sending raw base64 images without resizing is the path of least resistance. Stuffing the full catalog into the prompt seems like the simplest way to get recommendations without a retrieval step. Rate limiting is added "later" and often never is.

**Consequences:** Each analysis call costs significantly more than expected due to image token overhead (width × height / 750 tokens for Claude). Response latency makes the feature feel broken. A determined user — or a bot — can run up significant API costs in minutes.

**Prevention:**
- Resize and compress the uploaded image to a maximum of 800px on the long edge and 80% JPEG quality before sending to the API. This alone reduces image token count by ~70% and cuts upload + processing time proportionally.
- Do not send the full product catalog in the prompt. Send the category taxonomy and a structured description of ~20 curated products per call. Use the API response to recommend category and style tags, then filter the Supabase catalog client-side.
- Implement a per-user rate limit: store the last analysis timestamp in the `profiles` table and reject new requests within 60 seconds of the previous one.
- Use streaming (Claude's streaming API) to show partial results as they arrive — this prevents the UI from appearing frozen during the 5–10 second response window.
- Add a loading state with progressive messaging ("Analysing your style preferences...", "Matching to catalog...") so the wait feels intentional and premium rather than broken.
- Set a hard Anthropic account spending cap to bound worst-case costs.
- For assessment purposes, a per-session limit of 3 analyses is completely reasonable and should be enforced.

**Warning signs:**
- The image being sent to the API is over 1 MB (check in the Edge Function log).
- The prompt includes more than 30 product descriptions.
- There is no timestamp check before allowing a new analysis.
- The UI shows no feedback between button click and result — users click again.
- Your Anthropic usage dashboard shows cost spikes without a corresponding number of expected user sessions.

**Phase to address:** Phase 3 (AI Style Match implementation). Image compression, prompt scoping, and rate limiting must be designed before writing the first API call — not added after the feature "works" in development.

---

## Phase-Specific Warning Summary

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Database schema creation | RLS disabled by default | Write RLS policies in same migration as table creation |
| AI feature architecture | API key on client | Decide Edge Function proxy pattern before writing any AI code |
| Design system setup | Generic aesthetic | Lock colour tokens, typeface, and spacing scale before building components |
| CSS architecture | Mobile/desktop layout breaks | Establish all four breakpoints globally; test on real iOS Safari |
| Infrastructure deployment | Supabase project pauses | Set up keep-alive ping on day one of deployment |
| Cart implementation | State desync between browser and DB | Single source of truth in Supabase; merge guest cart on auth |
| Admin panel routing | Unprotected admin routes | RLS admin policies before building admin UI; test from incognito |
| Product catalog pages | Slow image loading | Use Supabase transform API from first catalog build; never raw originals |
| AI Style Match call | Slow/expensive vision API | Resize image, scope prompt, rate-limit before first real API call |
| Feature planning (all phases) | Scope creep to failure | Treat PROJECT.md requirements as a signed contract; defer aggressively |

---

## Sources

- [Supabase RLS Common Mistakes & CVE-2025-48757 — vibeappscanner.com](https://vibeappscanner.com/supabase-row-level-security)
- [Fixing RLS Misconfigurations in Supabase — prosperasoft.com](https://prosperasoft.com/blog/database/supabase/supabase-rls-issues/)
- [6 Common Supabase Auth Mistakes — startupik.com](https://startupik.com/6-common-supabase-auth-mistakes-and-fixes/)
- [Supabase Security: Exposed Anon Keys, RLS, and Misconfigurations — stingrai.io](https://www.stingrai.io/blog/supabase-powerful-but-one-misconfiguration-away-from-disaster)
- [RLS Performance and Best Practices — Supabase Docs](https://supabase.com/docs/guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv)
- [AI API Key Abuse and Runaway Compute Costs ($82,000 case) — pointguardai.com](https://www.pointguardai.com/blog/when-a-stolen-ai-api-key-becomes-an-82-000-problem)
- [Best Practices for API Key Safety — OpenAI Help Center](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)
- [15 Common UX Pitfalls Luxury Retail E-Commerce Sites Suffer From — Baymard Institute](https://baymard.com/blog/2021-luxury-ecommerce-benchmark)
- [Applying Luxury Principles to Ecommerce Design — Nielsen Norman Group](https://www.nngroup.com/articles/luxury-principles-ecommerce-design/)
- [How I Eliminated Inventory Race Conditions in a Production E-Commerce System — Medium](https://medium.com/@chaturvediinitin/how-i-eliminated-inventory-race-conditions-in-a-production-e-commerce-system-2302ba81846b)
- [E-commerce Business Logic Flaws — CYBRI](https://cybri.com/blog/a-guide-to-e-commerce-business-logic-flaws/)
- [Lab: Unprotected Admin Functionality — PortSwigger Web Security Academy](https://portswigger.net/web-security/access-control/lab-unprotected-admin-functionality)
- [Optimising eCommerce site — Careful with Lazy Loading — Accesto](https://accesto.com/blog/optimizing-ecommerce-site-careful-with-lazy-loading/)
- [How to Optimize Ecommerce Product Images for Core Web Vitals — rewarx.com](https://www.rewarx.com/blogs/optimize-ecommerce-product-images-core-web-vitals-2026)
- [10 Common Responsive Web Design Mistakes — uidesignz.com](https://uidesignz.com/blogs/common-responsive-web-design-mistakes)
- [Mobile CSS consistency best practices — DEV Community](https://dev.to/ohugonnot/mobile-css-consistency-all-best-practices-in-2026-4l5l)
- [Supabase Free Tier Limits in 2026 — aiagencyplus.com](https://aiagencyplus.com/supabase-free-tier-limits/)
- [Prevent Supabase Free Tier Pausing — shadhujan.medium.com](https://shadhujan.medium.com/how-to-keep-supabase-free-tier-projects-active-d60fd4a17263)
- [How to Prevent Supabase Database Pausing Using GitHub Actions — DEV Community](https://dev.to/jps27cse/how-to-prevent-your-supabase-project-database-from-being-paused-using-github-actions-3hel)
- [Claude Vision API Docs — platform.claude.com](https://platform.claude.com/docs/en/build-with-claude/vision)
- [Claude API Pricing — platform.claude.com](https://platform.claude.com/docs/en/about-claude/pricing)
- [How to Handle Latency When Your App Depends on AI APIs — particle41.com](https://particle41.com/insights/handle-latency-ai-api-dependencies/)
- [Optimizing Google Vision API Speed — Medium / Bankify Tech Blog](https://medium.com/bankify-tech-blog/how-to-optimize-the-speed-of-google-vision-api-cdc5e452104b)
- [Storage Access Control — Supabase Docs](https://supabase.com/docs/guides/storage/security/access-control)
