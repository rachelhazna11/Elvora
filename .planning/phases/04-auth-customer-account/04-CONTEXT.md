# Phase 4: Auth + Customer Account - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Authentication and personal account management. This phase delivers:
- **`auth.html`:** Single-page sign in / create account with tab toggle (Alpine `x-show`), editorial split layout, and redirect to `account.html` on success
- **`account.html`:** 3-section account dashboard (Profile, Wishlist, Style Preferences) with left sidebar tab navigation
- **`js/auth.js`:** All 5 stub functions implemented (signUp, signIn, signOut, getUser, onAuthChange)
- **`js/components.js`:** Auth state initialization (getUser + onAuthStateChange → drives Alpine.store('auth')); nav updated to show first name + dropdown when logged in
- **Wishlist interactions:** Heart icon on PLP and PDP — optimistic toggle for logged-in users, toast + redirect for guests

**Phase 4 does NOT include:** Real payment processing (Phase 6), admin panel (Phase 7), AI Style Match session saving (Phase 5 triggers the session — Phase 4 only builds the preferences form in account.html), order history (deferred to v2).

</domain>

<decisions>
## Implementation Decisions

### Auth Page Layout (auth.html)

- **D-01:** `auth.html` is a **single page with tab toggle**. Two tabs: "Sign In" and "Create Account". Alpine `x-show` switches between the two form panels. `?tab=signup` URL param deep-links to the registration tab on arrival (e.g., guest clicks heart icon → redirected with `?tab=signin`).
- **D-02:** After successful sign-in OR registration → **always redirect to `account.html`**. No referrer-based return; simple and predictable.
- **D-03:** Visual style → **editorial split layout**: left half is a full-height brand image (Unsplash editorial activewear photo, same aesthetic as homepage hero) with the ELVORA logotype and a short brand tagline overlaid. Right half is the clean sign in/up form on cream/ivory background. On mobile (< 768px), the image collapses and only the form shows.

### Nav: Logged-In State

- **D-04:** When logged in, the nav account area shows the **person icon + user's first name** (truncated to ~10 chars if long). Clicking the name/icon reveals a **small dropdown** with three items: "My Account" → `account.html`, "Wishlist" → `account.html#wishlist`, "Sign Out" (calls signOut() and updates store). Both desktop and mobile nav must reflect this state.
- **D-05:** Auth state is **initialized in `js/components.js`** (not per-page). On module load: call `supabase.auth.getUser()` to populate `Alpine.store('auth')` immediately, then subscribe `supabase.auth.onAuthStateChange()` to keep the store in sync across tab changes and token refreshes. This runs on every page automatically since components.js is loaded everywhere.
- **D-06:** No separate wishlist icon in the nav. Wishlist is accessed exclusively via the account dashboard or the dropdown ("Wishlist" link → `account.html#wishlist`).

### Account Dashboard (account.html)

- **D-07:** `account.html` uses a **left sidebar + right content** layout with three tabs: "Profile", "Wishlist", "Style Preferences". Active tab state managed by Alpine `x-data`. URL hash can reflect active tab (`#wishlist`, `#preferences`) for direct linking from the nav dropdown.
- **D-08:** **Profile section:** displays user's first name, last name (editable inline, saves to `user_profiles` on submit), and email address (display-only — email changes are out of scope). No change-password form. Simple "Save Changes" button.
- **D-09:** **Wishlist section:** product grid (same card style as PLP — image, name, price, remove button). Fetches `wishlist_items` joined with `products` for the logged-in user. Empty state: illustration + "You haven't saved any items yet. Start browsing →" linking to `shop.html`.
- **D-10:** **Style Preferences section:** editable form with 4 chip-selector fields matching the Style Match input UI:
  - Preferred activity (All, Padel, Pilates, Tennis, Training, Running)
  - Fit preference (Fitted, Relaxed, Longline)
  - Style aesthetic (Minimal, Sporty, Editorial)
  - Colour preference (Neutral, Earth, Sage, Monochrome)
  
  Saves to `user_profiles` columns: `preferred_activity`, `fit_preference`, `style_aesthetic`, `colour_preference`. "Save Preferences" button. Phase 5 reads these fields to pre-fill the Style Match form.

### Wishlist Heart Icon (PLP + PDP)

- **D-11:** **Guest behavior:** clicking the heart icon shows a **Toastify toast** ("Sign in to save items to your wishlist") and navigates to `auth.html?tab=signin` after 2 seconds (or immediately on toast click). The toast uses Toastify.js (already in the project from Phase 3).
- **D-12:** **Logged-in toggle behavior:** **optimistic UI** — heart fills instantly (Alpine reactive `wishlisted` state). Background Supabase `insert` (add) or `delete` (remove) fires asynchronously. On Supabase error: revert the icon state + show an error toast ("Couldn't save item — try again").
- **D-13:** **Initial wishlist state on PLP/PDP:** on page load (if user is logged in), fire a single query `supabase.from('wishlist_items').select('product_id').eq('user_id', user.id)` and store the result as a Set in Alpine data (`wishlistedIds`). Each product card checks `wishlistedIds.has(product.id)` to render the heart as filled or empty. One query per page, not one per card.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements (Phase 4 scope)
- `.planning/REQUIREMENTS.md` §F-025 — User Registration: form fields (first name, last name, email, password, confirm password), password min 8 chars, auto-login on success, `user_profiles` insert after signup
- `.planning/REQUIREMENTS.md` §F-026 — User Login & Logout: email + password form, session established + persisted, logout clears session + redirects to homepage
- `.planning/REQUIREMENTS.md` §F-027 — Session Persistence: `onAuthStateChange` drives UI state across all pages, header reflects login state
- `.planning/REQUIREMENTS.md` §F-028 — Wishlist / Saved Items: heart icon on PLP + PDP, toggle with persistence in `wishlist_items`, dedicated wishlist page in account dashboard
- `.planning/REQUIREMENTS.md` §F-029 — Saved AI Style Preferences: preferences (activity, fit, aesthetic, colour) viewable + editable in account; Phase 5 triggers saves after sessions

### Database
- `supabase/migrations/001_schema.sql` — Phase 4 writes to: `user_profiles` (id, user_id, first_name, last_name, email, preferred_activity, fit_preference, style_aesthetic, colour_preference, avatar_url), `wishlist_items` (id, user_id, product_id). RLS policies already written — user can only see/mutate their own rows.

### Existing Code (reuse + extend)
- `js/components.js` — **Phase 4 extends this file** to add auth state initialization (getUser + onAuthStateChange) and update the nav HTML template to show first name + dropdown when `Alpine.store('auth').loggedIn` is true.
- `js/auth.js` — All 5 stub functions (signUp, signIn, signOut, getUser, onAuthChange) implemented in Phase 4. Planner must implement all stubs.
- `js/supabase.js` — Singleton Supabase client — all auth and DB calls import `{ supabase }` from here.
- `src/input.css` — All design tokens (cream, sage, slate, ivory, charcoal, rose). Account dashboard and auth form use only these tokens.

### Prior Phase Decisions
- `.planning/phases/03-product-catalog/03-CONTEXT.md` §D-04 — Wishlist heart icon on PLP/PDP cards was deferred: "Phase 3 renders the icon as a static UI element without persistence." Phase 4 makes it functional.
- `.planning/phases/01-foundation/01-CONTEXT.md` §D-08 — Cloud-only Supabase workflow: no local CLI. Any new SQL must be applied via the Supabase SQL Editor dashboard.

### Project Decisions
- `.planning/PROJECT.md` §Key Decisions — aesthetic benchmark: Alo Yoga / Varley quiet luxury. Auth page and account dashboard must match this standard.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Alpine.store('auth')` — already registered in `components.js` as `{ user: null, loggedIn: false }`. Phase 4 populates `user.id`, `user.email`, `user.user_metadata.first_name` etc. from the Supabase session.
- `Alpine.store('cart')` — established pattern for reactive global state. Auth store should follow the same registration pattern.
- `Toastify.js` — already used in Phase 3 for cart actions. Use the same Toastify call pattern for wishlist guest toast + wishlist error toast.
- `js/products.js` — `getProducts()` is a model for Supabase query patterns. Wishlist queries follow the same `supabase.from(...).select(...).eq(...)` shape.
- Unsplash editorial lifestyle photos — same source for the auth page left-panel image. Use `?w=1200&q=80` for full-height panel.

### Established Patterns
- **CDN-only loading** — no npm for Alpine, Supabase, Toastify. All via `<script>` CDN tags.
- **Alpine.js `x-data` + `init()` async** — established in Phase 2 (best sellers), used in Phase 3 (products, reviews). Phase 4 account dashboard tabs follow the same pattern.
- **`window.__ENV` injection** — Supabase URL and anon key from `js/__env.js`. Already loaded on all pages.
- **ES module imports** — all JS modules use `import { supabase } from './supabase.js'`. auth.js follows this pattern.
- **`x-show` for conditional UI** — used for cart badge, search expand, nav drawer. Auth tab toggle and dropdown menu use the same pattern.

### Integration Points
- `auth.html` ← Phase 4 fills `<main>` with editorial split layout + tabbed sign in/up form
- `account.html` ← Phase 4 fills `<main>` with sidebar tabs + Profile/Wishlist/Preferences panels
- `js/auth.js` ← Phase 4 implements all 5 stubs
- `js/components.js` ← Phase 4 extends: (1) adds auth initialization, (2) updates nav HTML template for logged-in dropdown state
- `shop.html` ← Phase 4 makes heart icons on product cards functional (was static in Phase 3)
- `product.html` ← Phase 4 makes PDP heart icon functional (was static in Phase 3)
- `user_profiles` table ← Phase 4 inserts on signup, reads on account load, updates on profile/preferences save
- `wishlist_items` table ← Phase 4 inserts/deletes on heart toggle, queries on PLP/PDP/account load

</code_context>

<specifics>
## Specific Ideas

- **Auth page left panel image** — Use the same editorial style as the homepage hero. Overlay the ELVORA wordmark in white Playfair Display italic + a 1-2 word tagline (e.g., "Move Beautifully" or "Dress the Part"). Image should feel aspirational not functional.
- **Account dashboard tabs** — Each tab label in the sidebar should be understated (cream/charcoal palette, no aggressive active states). Active tab: thin left-border accent in `--color-rose` or `--color-sage`.
- **Wishlist empty state** — Should feel warm and inviting, not like an error. Example copy: "Your wishlist is waiting. Save pieces you love as you explore." with a subtle heart illustration or icon.
- **Preferences chip selectors** — Same visual style as planned for the Style Match page. Chip pills: outlined → filled on select, using `--color-sage` as the selected fill. Multiple chips can't be selected in the same field (single-select per category).
- **Sign up confirmation** — On successful registration, before redirecting to `account.html`, show a brief success toast: "Welcome to Elvora, [first_name]!" (personalized using the submitted name). Reinforces the premium feeling of the onboarding moment.

</specifics>

<deferred>
## Deferred Ideas

- **Change password form** — Out of scope for Phase 4. Supabase `updateUser()` handles it; add in v2 or as a post-assessment polish step.
- **Avatar upload** — `user_profiles.avatar_url` column exists but avatar upload is not in Phase 4 scope. Phase 7 (admin panel) or v2.
- **Order history** — Already deferred to v2 in STATE.md. Not in Phase 4 account dashboard. No "Orders" tab.
- **Email change** — Requires Supabase email verification flow; out of scope for assessment. Email is display-only.
- **Social auth (Google, Apple)** — Not in ROADMAP; email/password only for assessment scope.
- **Wishlist icon in nav** — Decided against nav wishlist icon (D-06). Accessible via account dropdown instead.

</deferred>

---

*Phase: 4-Auth + Customer Account*
*Context gathered: 2026-06-14*
