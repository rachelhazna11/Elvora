# Phase 4: Auth + Customer Account — Research

**Researched:** 2026-06-14
**Domain:** Supabase Auth v2, Alpine.js reactive state, Supabase PostgREST queries
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `auth.html` is a single page with tab toggle. Two tabs: "Sign In" and "Create Account". Alpine `x-show` switches. `?tab=signup` URL param deep-links to registration.
- **D-02:** After successful sign-in OR registration → always redirect to `account.html`. No referrer-based return.
- **D-03:** Visual style → editorial split layout: left half full-height brand image + ELVORA logotype + tagline. Right half clean form on cream/ivory. On mobile (< 768px) image collapses, form fills full screen.
- **D-04:** When logged in, nav shows person icon + user's first name (truncated ~10 chars). Clicking reveals dropdown: "My Account" → `account.html`, "Wishlist" → `account.html#wishlist`, "Sign Out".
- **D-05:** Auth state initialized in `js/components.js`. On module load: `supabase.auth.getUser()` then `supabase.auth.onAuthStateChange()`.
- **D-06:** No separate wishlist icon in nav. Wishlist accessed via account dashboard or dropdown only.
- **D-07:** `account.html` uses left sidebar + right content layout with three tabs: Profile, Wishlist, Style Preferences. URL hash controls active tab.
- **D-08:** Profile section: first/last name editable inline, email display-only. No change-password form.
- **D-09:** Wishlist section: product grid (same card style as PLP). Empty state with CTA.
- **D-10:** Style Preferences: 4 chip-selector fields (activity, fit, aesthetic, colour). Saves to `user_profiles`.
- **D-11:** Guest heart click: Toastify toast + redirect to `auth.html?tab=signin` after 2s.
- **D-12:** Logged-in heart click: optimistic UI — fill instantly, Supabase insert/delete async, revert on error.
- **D-13:** On PLP/PDP page load (if logged in), one query fetches all wishlist product_ids as a Set. Not one per card.

### Claude's Discretion

- Auth page left panel image: same editorial style as homepage hero; overlay ELVORA wordmark in white Playfair Display italic + 1-2 word tagline.
- Account dashboard tabs: understated (cream/charcoal palette). Active tab: thin left-border in `--color-rose` or `--color-sage`.
- Wishlist empty state: warm and inviting, not an error.
- Preferences chip selectors: outlined → filled on select using `--color-sage`.
- Sign up confirmation: brief Toastify toast "Welcome to Elvora, [first_name]!" before redirecting.

### Deferred Ideas (OUT OF SCOPE)

- Change password form
- Avatar upload
- Order history
- Email change
- Social auth (Google, Apple)
- Wishlist icon in nav
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| F-025 | User Registration: first name, last name, email, password, confirm password; min 8 chars; auto-login on success; `user_profiles` insert after signup | Supabase `signUp` with `options.data`; insert to `user_profiles` using correct column name `id` (see Schema Mismatch finding) |
| F-026 | User Login & Logout: session established + persisted; logout clears session + redirects home; forgot password link | `signInWithPassword`, `signOut`, `resetPasswordForEmail`; session persists via Supabase localStorage token storage |
| F-027 | Session Persistence: `onAuthStateChange` drives UI state; header reflects login; session expires per JWT | `onAuthStateChange` listener in `components.js`; Alpine store keeps UI in sync |
| F-028 | Wishlist / Saved Items: heart on PLP + PDP, toggle with Supabase persistence; dedicated page in account dashboard | Optimistic UI with Set-copy trick for Alpine reactivity; `wishlist_items` RLS enforces ownership |
| F-029 | Saved AI Style Preferences: 4 preference fields viewable + editable in account; Phase 5 reads them | Requires SQL migration to add columns to `user_profiles` (see Schema Mismatch — Critical finding) |
</phase_requirements>

---

## Summary

Phase 4 implements authentication and customer account features on top of Supabase Auth v2 and Alpine.js. The technical path is well-defined: five auth functions in `js/auth.js`, auth state initialization wired into the already-loaded `js/components.js`, and three new/modified HTML files. All patterns have working analogs in the existing codebase (product.html, cart.js, components.js).

**One blocking schema mismatch was discovered during research.** The live `user_profiles` table schema (from `supabase/migrations/001_schema.sql`) uses `id` as the primary key (which equals `auth.users.id`) — there is no separate `user_id` column. The CONTEXT.md and all five existing plans assume a `user_id` column and four style-preference columns (`preferred_activity`, `fit_preference`, `style_aesthetic`, `colour_preference`) that do not exist in the current schema. These columns also need to exist for F-029. A SQL migration must be applied to Supabase Dashboard before any plan that touches `user_profiles` can succeed.

**Secondary finding:** Alpine.js does not track mutations on `Set` objects natively — the plans correctly use the `new Set(this.wishlistedIds)` copy trick to trigger reactivity, and this pattern is confirmed correct.

**Primary recommendation:** Execute a SQL migration (applied via Supabase Dashboard) as Wave 0 before Plan 01 runs. The migration adds `user_id` (or adjusts to use `id`) and the four style preference columns to `user_profiles`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Auth credential validation | Supabase Auth (hosted) | — | Supabase handles bcrypt, JWT issuance, session storage; browser only calls the SDK |
| Session persistence | Browser (localStorage) | Supabase Auth JWT refresh | Supabase JS SDK stores JWT in `localStorage` automatically; `onAuthStateChange` syncs it |
| Auth UI state (nav) | Browser (Alpine store) | — | `Alpine.store('auth')` is the single source of truth for UI; populated from Supabase session |
| User profile data | Supabase PostgreSQL | Browser Alpine x-data | `user_profiles` table; read/write via PostgREST; RLS enforces per-user access |
| Wishlist state | Browser (Alpine Set) + Supabase | — | Optimistic Set in Alpine for instant UI; Supabase is the durable store |
| Wishlist persistence | Supabase PostgreSQL | — | `wishlist_items` table with `user_id` FK; RLS `auth.uid() = user_id` enforces ownership |
| Style preferences persistence | Supabase PostgreSQL | — | `user_profiles` columns (after migration); Phase 5 reads them to pre-fill Style Match form |
| Auth page redirect guard | Browser (Alpine init) | — | `supabase.auth.getUser()` in init; client-side convenience — RLS is the real gate |
| Account page access guard | Browser (Alpine init) | Supabase RLS | `getUser()` in init redirects guest; RLS ensures no data leaks even if redirect is bypassed |

---

## Project Constraints (from CLAUDE.md)

- **No npm for runtime libs** — all JS libraries via CDN. No `import` from npm packages in HTML.
- **CDN-only Alpine.js (3.15.12)**, Supabase JS SDK v2 (ESM CDN), Toastify-js (CDN) — versions locked.
- **Supabase only** — no custom server, no separate REST API.
- **Cloud-only Supabase workflow** — no local Supabase CLI. All SQL applied via Supabase Dashboard SQL Editor.
- **`service_role` key NEVER in frontend code** — only `anon` key via `window.__ENV`.
- **RLS on every table** — access control is database-level, not just client redirect.
- **`js/__env.js` gitignored** — `window.__ENV` provides Supabase URL and anon key at build time.
- **ES modules with `import { supabase } from './supabase.js'`** — all JS modules follow this pattern.
- **No inline JS in HTML** — external `.js` files only (the Alpine inline `x-data` string pattern is established and acceptable per project convention).
- **Tailwind v4 CLI build** — CSS compiled by Netlify build step; Play CDN is not used.
- **Assessment grading** — must support deployment, semantic HTML, responsive design, JS functionality, documented AI usage.

---

## Standard Stack

### Core (Phase 4 — no new installs)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@supabase/supabase-js` | 2.x (CDN ESM, already loaded via `js/supabase.js`) | Auth (`signUp`, `signInWithPassword`, `signOut`, `getUser`, `onAuthStateChange`) + DB queries | Already in project; singleton via `js/supabase.js`; no additional install needed |
| Alpine.js | 3.15.12 (CDN, already loaded) | Reactive UI: auth form state, tab toggle, wishlist Set, account dashboard tabs | Already in project; `Alpine.store('auth')` already registered |
| Toastify-js | 1.x (CDN, already loaded in `product.html`) | Toast notifications for wishlist guest redirect, signup welcome, save success/error | Already used in Phase 3; same CDN URLs reused in `auth.html` and `account.html` |

**No new libraries to install.** Phase 4 is entirely built on already-loaded CDN dependencies.

**CDN URLs to reuse (from `product.html` lines 12 and 14):**
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
<script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
```

---

## Package Legitimacy Audit

**No new packages installed in Phase 4.** All dependencies are already present in the project from Phases 1–3.

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| `@supabase/supabase-js` | CDN ESM (already loaded) | Already in project | Approved — no re-install |
| `alpinejs` | CDN (already loaded) | Already in project | Approved — no re-install |
| `toastify-js` | CDN (already in product.html) | Already in project | Approved — extend to auth.html, account.html |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

---

## Critical Findings (Must Address Before Execution)

### Finding 1: `user_profiles` Schema Mismatch — BLOCKING

**What the plans assume:**

All 5 plans assume `user_profiles` has:
- A `user_id uuid` column that is the FK to `auth.users`
- Four style preference columns: `preferred_activity`, `fit_preference`, `style_aesthetic`, `colour_preference`

**What the actual schema has** (`supabase/migrations/001_schema.sql` lines 45–52):

```sql
create table if not exists user_profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  first_name    text,
  last_name     text,
  email         text,
  style_preferences jsonb default '{}'::jsonb,
  created_at    timestamptz default now()
);
```

- `user_profiles.id` IS `auth.users.id` (no separate `user_id` column)
- No `preferred_activity`, `fit_preference`, `style_aesthetic`, `colour_preference` columns — only a single JSONB `style_preferences` column exists
- RLS policies use `auth.uid() = id` (not `user_id`)

**Impact on each plan:**

| Plan | Impact |
|------|--------|
| Plan 02 (auth.js signUp) | `signUp` inserts `{ user_id: data.user.id, ... }` — WRONG. Must insert `{ id: data.user.id, ... }` |
| Plan 02 (auth.js signUp) | Insert target column is wrong; will fail with "null value in column user_id" or column-not-found error |
| Plan 04 (account.html loadProfile) | `.eq('user_id', user.id)` — WRONG. Must be `.eq('id', user.id)` |
| Plan 04 (account.html saveProfile) | `.eq('user_id', ...')` — WRONG. Must be `.eq('id', ...)` |
| Plan 04 (account.html savePrefs) | Writes `preferred_activity`, `fit_preference`, etc. — columns don't exist yet |
| Plan 04 (account.html loadProfile) | Reads `preferred_activity`, `fit_preference`, etc. — columns don't exist yet; query will succeed but return null fields |

**Resolution required:** A SQL migration must be applied via Supabase Dashboard SQL Editor before any plan executes. Options:

**Option A — Add columns (recommended):** Add the four style preference columns as separate columns (aligning with how the plans and CONTEXT D-10 describe them):

```sql
-- Apply via Supabase Dashboard SQL Editor
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS preferred_activity text,
  ADD COLUMN IF NOT EXISTS fit_preference text,
  ADD COLUMN IF NOT EXISTS style_aesthetic text,
  ADD COLUMN IF NOT EXISTS colour_preference text;

-- Backfill user_id from id (the columns are the same value)
UPDATE user_profiles SET user_id = id WHERE user_id IS NULL;

-- NOTE: If adding user_id as separate column, also update RLS policies
-- OR — simpler approach: don't add user_id column; fix plans to use .eq('id', user.id)
```

**Option B — Fix plans to use existing schema (simpler, no new column):** Update plans to use `.eq('id', user.id)` instead of `.eq('user_id', user.id)`, and only add the four style preference columns:

```sql
-- Apply via Supabase Dashboard SQL Editor
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS preferred_activity text,
  ADD COLUMN IF NOT EXISTS fit_preference text,
  ADD COLUMN IF NOT EXISTS style_aesthetic text,
  ADD COLUMN IF NOT EXISTS colour_preference text;
```

Then in plans: replace every `.eq('user_id', user.id)` with `.eq('id', user.id)` for `user_profiles` queries. The `wishlist_items` table correctly uses `user_id` — only `user_profiles` has this mismatch.

**Option B is recommended** — minimal SQL change, no architectural shift. The plans must be updated to use `.eq('id', user.id)` for all `user_profiles` queries.

---

### Finding 2: `signUp` Insert Column Name

In `js/auth.js` Plan 02, the `signUp` function inserts:
```js
await supabase.from('user_profiles').insert({
  user_id: data.user.id,   // WRONG — column is 'id', not 'user_id'
  first_name: firstName,
  last_name: lastName,
  email,
});
```

Must be corrected to:
```js
await supabase.from('user_profiles').insert({
  id: data.user.id,         // CORRECT — matches schema primary key
  first_name: firstName,
  last_name: lastName,
  email,
});
```

The RLS `insert_own` policy checks `auth.uid() = id` — correct with this fix.

---

### Finding 3: Alpine.js Set Reactivity — Confirmed Correct Pattern

Alpine.js tracks object reference changes for reactivity. JavaScript `Set.prototype.add()` and `.delete()` mutate the Set in-place — Alpine does NOT detect these mutations. The plans correctly use the copy trick:

```js
this.wishlistedIds.add(productId);
this.wishlistedIds = new Set(this.wishlistedIds); // creates new reference → triggers Alpine reactivity
```

This pattern is correct and required. Without the `new Set(...)` reassignment, the DOM will not update. [ASSUMED — from Alpine.js reactivity model; no Context7 session this run, but consistent with well-documented Alpine behavior]

---

### Finding 4: `supabase.auth.getUser()` vs `supabase.auth.session()`

Supabase JS v2 removed `supabase.auth.session()`. The correct call to get the current user is:

```js
const { data: { user } } = await supabase.auth.getUser();
```

This makes a network call to validate the JWT server-side — it is NOT purely local. For performance-sensitive initialization (e.g., nav on every page), this adds ~100–200ms latency. [ASSUMED — from Supabase v2 migration docs knowledge; consistent with existing code patterns in auth.js stubs]

`getUser()` is the correct choice here (vs `getSession()`) because:
- `getSession()` returns local session data without server validation — faster but can be stale
- `getUser()` validates with Supabase server — slower but reliable

For the account.html auth guard (where security matters), use `getUser()`. For the nav display (where speed matters), `getSession()` is an acceptable alternative, but `getUser()` works fine at this scale.

---

### Finding 5: `onAuthStateChange` Timing with Alpine Store

The `onAuthStateChange` subscription is set up in `initAuth()` in `components.js`. The subscription fires:
1. Immediately on setup with the current session (INITIAL_SESSION event)
2. On sign in (SIGNED_IN)
3. On sign out (SIGNED_OUT)
4. On token refresh (TOKEN_REFRESHED)
5. On tab focus if token needs refresh (USER_UPDATED)

**Gotcha:** If `getUser()` is called and then `onAuthStateChange` is subscribed, there is a brief window between the two where the store is populated from `getUser()` but the live subscription hasn't fired INITIAL_SESSION yet. For this project, this is fine because `getUser()` is awaited before the subscription starts — the store is already populated. The subscription then keeps it in sync going forward. No race condition in the current plan design.

**Cross-tab behavior:** When a user signs out in Tab A, Tab B will receive a SIGNED_OUT event via `onAuthStateChange` and update `Alpine.store('auth')` accordingly. The nav will update reactively. [ASSUMED]

---

### Finding 6: `?tab=signup` URL Param Timing

In `auth.html init()`:
```js
const tab = new URLSearchParams(location.search).get('tab');
if (tab === 'signup') this.tab = 'signup';
```

`URLSearchParams` is synchronous and `location.search` is available immediately. This runs before the Supabase `getUser()` call. No timing issue. The redirect check (if already logged in) runs after the tab is set — the panel flash is suppressed by the immediate redirect. [VERIFIED: native browser API, no timing concern]

**Edge case:** If `auth.html` is loaded while logged in and `?tab=signup` is in the URL, the `getUser()` check redirects to `account.html` before the user sees the form. This is correct per D-02.

---

### Finding 7: `user_metadata` vs Database Profile

`supabase.auth.signUp()` accepts `options: { data: { first_name, last_name } }`. This stores data in `auth.users.raw_user_meta_data` — accessible via `user.user_metadata.first_name` in the session object. This is separate from `user_profiles` table data.

In `components.js` nav dropdown:
```js
$store.auth.user?.user_metadata?.first_name
```

This reads from the JWT's user_metadata — available without a database query, correct for nav display. The `user_profiles` table stores the same data but is queried separately in `account.html` for the profile form. Both sources are populated on signup. If the `user_profiles` insert fails after `signUp` succeeds, the nav will still show the first name from `user_metadata`. Acceptable for assessment scope.

---

### Finding 8: Wishlist `wishlist_items` Schema — Confirmed Correct

`wishlist_items` schema (`001_schema.sql` lines 327–347):
```sql
create table if not exists wishlist_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  created_at timestamptz default now(),
  unique (user_id, product_id)
);
```

RLS policies:
- SELECT: `auth.uid() = user_id` ✓
- INSERT: `auth.uid() = user_id` ✓
- DELETE: `auth.uid() = user_id` ✓

The `unique (user_id, product_id)` constraint means inserting a duplicate wishlist item returns a Supabase error — the optimistic UI will revert and show an error toast. This is correct behavior. Plans should use `.upsert()` instead of `.insert()` if double-click protection is needed, but for assessment scope the error revert is acceptable. [ASSUMED — behavior of unique constraint on insert via PostgREST]

---

### Finding 9: Joined Query for Wishlist in `account.html`

The `loadWishlist` query uses PostgREST relationship syntax:
```js
supabase.from('wishlist_items')
  .select('id, product_id, products(id, name, slug, base_price, product_images(url, alt_text, display_order))')
  .eq('user_id', user.id)
```

This requires a foreign key relationship in the schema. `wishlist_items.product_id` references `products(id)` — confirmed in schema. PostgREST will resolve this automatically. The nested `product_images` join also works because `product_images.product_id` references `products(id)`.

The `product_images` RLS is public read (`using (true)`), and `products` RLS is public read for active products. Both are readable by authenticated users via the anon key + JWT. No permission issue. [ASSUMED — consistent with PostgREST join behavior documentation]

**Sorting `product_images` in JS:** The `loadWishlist` function sorts images client-side after fetch:
```js
row.products?.product_images?.sort((a,b) => a.display_order - b.display_order)?.[0]?.url
```
This is correct. Alternatively, `.order('display_order', { referencedTable: 'product_images' })` can be used in the query to sort server-side.

---

### Finding 10: `nav-root` Injection Timing and `x-show` Display:none

The nav HTML is injected via `components.js` at module load time. Alpine processes the injected HTML via `Alpine.initTree(navEl)` (or equivalent). The `x-show` directives on the guest/logged-in account elements use `style="display:none;"` as the initial state to prevent FOUC (flash of un-styled content) before Alpine processes them.

This is the established pattern in `components.js` (see cart badge: `style="display:none;"` on the span). Phase 4 must include `style="display:none;"` on:
- The logged-in dropdown wrapper (`x-show="$store.auth.loggedIn"`)
- The mobile drawer account link's logged-in variant

Without `style="display:none;"` the elements will briefly flash before Alpine hides them. [VERIFIED: existing pattern in components.js line 142]

---

### Finding 11: `window.elvoraSignOut` Naming Convention

The `signOut` function is exposed as `window.elvoraSignOut` (not `window.signOut`) to avoid potential conflicts with built-in browser APIs or other library globals. This is documented in `04-PATTERNS.md`. The nav dropdown Sign Out button calls:
```js
window.elvoraSignOut().then(() => {
  $store.auth.user = null;
  $store.auth.loggedIn = false;
  window.location.href = '/index.html';
})
```

The store is cleared optimistically before redirect — even if `signOut()` fails (network issue), the UI state is cleared. Supabase will invalidate the JWT on the next request. [ASSUMED — acceptable behavior for assessment scope]

---

### Finding 12: `account.html` Navigation Conflict with `#wishlist` Hash

`account.html` uses `location.hash` to control the active tab. The hash is set by `setTab(tab)`:
```js
setTab(tab) {
  this.activeTab = tab;
  location.hash = tab;
}
```

Setting `location.hash` does not trigger a page reload in browsers — it only updates the URL. The `init()` reads the hash to restore tab state on load:
```js
const hash = location.hash.replace('#', '');
if (['profile', 'wishlist', 'preferences'].includes(hash)) this.activeTab = hash;
```

**Gotcha:** If the page has anchor elements with matching IDs (`id="wishlist"`, `id="preferences"`), the browser may scroll to those anchors when `location.hash` is set. The account page sections should NOT have `id` attributes matching the hash values, or should set them to non-clashing values. [ASSUMED — browser scroll-to-anchor behavior on hash change]

---

## Architecture Patterns

### System Architecture Diagram

```
User Action (click heart / submit form / tab switch)
  │
  ▼
Alpine x-data handler (handleSignIn / handleSignUp / toggleWishlist / saveProfile)
  │
  ├─→ Supabase Auth API (supabase.auth.*)
  │     └─→ JWT issued/cleared → localStorage
  │           └─→ onAuthStateChange fires
  │                 └─→ Alpine.store('auth') updated → nav DOM re-renders
  │
  └─→ Supabase PostgREST (supabase.from(...).select/insert/update/delete)
        └─→ RLS validates auth.uid() against row ownership
              └─→ Data returned → Alpine reactive state → DOM re-renders
```

### Recommended Project Structure (Phase 4 additions)

```
js/
├── auth.js          # Phase 4: 5 auth functions + window exposure
├── components.js    # Phase 4: extend with initAuth() + nav dropdown HTML
├── supabase.js      # Unchanged — singleton client
├── cart.js          # Unchanged
└── products.js      # Unchanged

auth.html            # Phase 4: editorial split layout + tab toggle forms
account.html         # Phase 4: dashboard with sidebar tabs + 3 panels
shop.html            # Phase 4: extend x-data with wishlist functions
product.html         # Phase 4: extend x-data with wishlist functions
src/input.css        # Phase 4: add auth + account component classes
supabase/migrations/
└── 002_phase4_user_profiles.sql   # NEW: add style preference columns
```

### Pattern 1: Supabase Auth Function Shape

All auth functions follow the Supabase v2 destructuring pattern:

```js
// Source: Supabase JS v2 auth API (established pattern in js/products.js)
export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function getUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user; // null if not authenticated
}

export function onAuthChange(callback) {
  const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
    callback(session?.user ?? null);
  });
  return subscription;
}
```

### Pattern 2: Alpine Optimistic UI with Set Reactivity

```js
// The copy trick is REQUIRED for Alpine to detect Set changes
async toggleWishlist(productId) {
  const wasWishlisted = this.wishlistedIds.has(productId);

  // Optimistic update — creates new reference to trigger reactivity
  if (wasWishlisted) {
    this.wishlistedIds.delete(productId);
  } else {
    this.wishlistedIds.add(productId);
  }
  this.wishlistedIds = new Set(this.wishlistedIds); // triggers Alpine DOM update

  // Async Supabase call — revert on error
  const { error } = await supabase.from('wishlist_items')
    [wasWishlisted ? 'delete' : 'insert'](...);

  if (error) {
    // Revert
    if (wasWishlisted) {
      this.wishlistedIds.add(productId);
    } else {
      this.wishlistedIds.delete(productId);
    }
    this.wishlistedIds = new Set(this.wishlistedIds); // trigger revert in DOM
    // show error toast
  }
}
```

### Pattern 3: `user_profiles` Query with Correct Column Name

```js
// CORRECT — uses 'id' not 'user_id' for user_profiles table
async loadProfile(user) {
  const { data } = await window.supabase
    .from('user_profiles')
    .select('first_name, last_name, preferred_activity, fit_preference, style_aesthetic, colour_preference')
    .eq('id', user.id)   // IMPORTANT: 'id' not 'user_id'
    .single();
  // ...
}

async saveProfile() {
  const { error } = await window.supabase
    .from('user_profiles')
    .update({ first_name: this.profile.first_name, last_name: this.profile.last_name })
    .eq('id', this._currentUser.id);  // IMPORTANT: 'id' not 'user_id'
}

// signUp insert — 'id' not 'user_id'
await supabase.from('user_profiles').insert({
  id: data.user.id,   // IMPORTANT: 'id' not 'user_id'
  first_name: firstName,
  last_name: lastName,
  email,
});
```

### Anti-Patterns to Avoid

- **Using `user_id` column on `user_profiles`:** The column is `id`. Using `.eq('user_id', ...)` will silently return empty results because the column doesn't exist — no error, just missing data.
- **Using `supabase.auth.session()` (removed in v2):** Use `supabase.auth.getUser()` or `supabase.auth.getSession()`.
- **Calling `signOut()` without clearing Alpine store:** The store persists in-memory even after sign out. Always clear `$store.auth.user = null; $store.auth.loggedIn = false` in the Sign Out handler.
- **Relying on client-side redirect for security:** The `account.html` redirect to auth.html is UI convenience only. RLS is the actual access control.
- **Mutating Set without reassigning:** `this.wishlistedIds.add(x)` alone does not trigger Alpine reactivity. Always follow with `this.wishlistedIds = new Set(this.wishlistedIds)`.
- **Anchor IDs matching hash values:** Avoid `id="wishlist"` on elements in `account.html` — the browser will scroll to them when the tab hash is set.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWT storage and refresh | Custom token storage | Supabase JS SDK | SDK handles localStorage persistence, automatic refresh, cross-tab sync |
| Password hashing | Any client-side hashing | Supabase Auth | bcrypt handled server-side by Supabase |
| Email verification | Custom email send | Supabase Auth built-in | Supabase sends verification emails when configured |
| Optimistic UI revert logic | Complex diff/merge | Simple boolean/Set copy | Alpine's reactivity model makes Set copy sufficient for wishlist |
| Cross-tab auth sync | Storage event listeners | `onAuthStateChange` | Supabase SDK handles cross-tab via BroadcastChannel internally |
| RLS enforcement | Client-side filtering | Supabase RLS | Server-enforced; cannot be bypassed by client |

---

## Common Pitfalls

### Pitfall 1: `user_profiles` Wrong Column Name

**What goes wrong:** Queries use `.eq('user_id', user.id)` — column `user_id` does not exist on `user_profiles`. PostgREST will silently return 0 rows (no error) for SELECT queries, and fail silently or with "column not found" for INSERT/UPDATE.
**Why it happens:** CONTEXT.md and plans were written with an idealized schema; the actual `001_schema.sql` was implemented with `id` as the PK-FK.
**How to avoid:** Always use `.eq('id', user.id)` for `user_profiles` queries. This is the only table with this pattern — `wishlist_items` correctly uses `user_id`.
**Warning signs:** Profile section in account.html loads but shows empty first/last name fields even after signup.

### Pitfall 2: Missing Style Preference Columns

**What goes wrong:** `savePrefs()` tries to update `preferred_activity`, `fit_preference`, `style_aesthetic`, `colour_preference` — columns that don't exist in the current `user_profiles` schema. PostgREST returns an error.
**Why it happens:** Schema was created in Phase 1 before these columns were designed in Phase 4 context.
**How to avoid:** Run the SQL migration (see Finding 1) via Supabase Dashboard before executing Plan 04.
**Warning signs:** Style Preferences save shows error toast; browser devtools shows PostgREST 400 error referencing unknown column.

### Pitfall 3: Alpine FOUC on Logged-In Nav

**What goes wrong:** Logged-in user visits a page and briefly sees the guest account icon before the dropdown appears.
**Why it happens:** `getUser()` is async (~100–200ms round trip). Alpine renders the initial state (`loggedIn: false`) first.
**How to avoid:** Add `style="display:none;"` to both the guest link AND the logged-in dropdown wrapper. Alpine's `x-show` respects the initial `display:none` and won't flash. The existing cart badge uses this same pattern.
**Warning signs:** Account icon briefly shows then changes to first name.

### Pitfall 4: `#wishlist` Hash Causing Browser Scroll

**What goes wrong:** Clicking "Wishlist" tab in account.html sets `location.hash = 'wishlist'`. If any element has `id="wishlist"`, browser scrolls to it.
**Why it happens:** Browser scroll-to-anchor behavior on `location.hash` change.
**How to avoid:** Do not assign `id="wishlist"`, `id="preferences"`, or `id="profile"` to any element in account.html. Section panels can use class selectors instead.
**Warning signs:** Page jumps to unexpected position when switching tabs.

### Pitfall 5: `signUp` User Profile Insert Race

**What goes wrong:** `signUp` creates the auth user, then immediately inserts into `user_profiles`. If the Supabase trigger/RLS hasn't fully propagated the new user row yet, the insert may fail with "violates foreign key constraint."
**Why it happens:** `data.user.id` is available immediately after `auth.signUp()`, but the `auth.users` row may not be fully committed in all read replicas.
**How to avoid:** In practice, direct inserts after `signUp` succeed reliably because the FK check runs against the primary database. If the insert fails, catch the error and surface it gracefully without blocking the user — they can still log in, and the `user_profiles` row can be created on next profile edit.
**Warning signs:** Signup succeeds (user is logged in) but profile section shows empty on first visit.

### Pitfall 6: Wishlist Set Type Loses Product IDs on Page Refresh

**What goes wrong:** `wishlistedIds` is a `new Set()` initialized empty. If `initWishlist()` is not awaited properly in `init()`, the Set may be empty when product cards render, making all hearts appear empty even for wishlisted items.
**Why it happens:** `this.initWishlist()` is called without `await` in some plan drafts.
**How to avoid:** Use `await this.initWishlist()` in `init()`, or call it with `Promise.all` alongside `fetchProducts()`. The heart state is derived from `wishlistedIds` after both calls complete.
**Warning signs:** Hearts show empty on page load but fill after a brief delay (visible flicker).

---

## Runtime State Inventory

> Phase 4 is primarily greenfield (new files + extending existing files). Not a rename/refactor phase.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `user_profiles` table — exists in Supabase, missing 4 columns and has `id` not `user_id` FK pattern | SQL migration via Supabase Dashboard SQL Editor |
| Live service config | Supabase Auth email settings — needed for `resetPasswordForEmail` to actually send email; not configured for MVP | No action — link present, email delivery is optional for assessment |
| OS-registered state | None | None |
| Secrets/env vars | `SUPABASE_URL`, `SUPABASE_ANON_KEY` in Netlify env and `window.__ENV` — no change needed | None |
| Build artifacts | `css/style.css` — regenerated by Tailwind CLI at build time after `src/input.css` changes | Netlify build runs this automatically; local dev requires `npx @tailwindcss/cli` |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Supabase project (cloud) | All auth + DB calls | ✓ | Live (elvorastudio project) | — |
| Alpine.js CDN | All reactive UI | ✓ | 3.15.12 | — |
| Toastify-js CDN | Toast notifications | ✓ | 1.x (already in product.html) | — |
| Supabase JS SDK (CDN ESM) | Auth + DB queries | ✓ | 2.x (already in js/supabase.js) | — |
| Tailwind CSS CLI | CSS compilation | ✓ | 4.x (Netlify build) | — |
| Netlify dashboard | Environment vars + deploy | ✓ | Free tier | — |
| Supabase Dashboard SQL Editor | Schema migration | ✓ | Cloud | — |

**Missing dependencies with no fallback:** None

**Required action before execution:** Apply SQL migration via Supabase Dashboard SQL Editor (see Finding 1).

---

## Validation Architecture

> `nyquist_validation: true` — validation section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual browser testing (no automated test framework configured) |
| Config file | none — no jest.config.*, vitest.config.*, or pytest.ini found |
| Quick run command | Open browser → verify specific interaction per plan acceptance criteria |
| Full suite command | Execute all 10 manual verification steps in each plan's `<verification>` section |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| F-025 | User can register; auto-logged-in; user_profiles row created | Manual browser | — | — |
| F-026 | User can sign in and sign out; session persists | Manual browser | — | — |
| F-027 | onAuthStateChange updates nav; session survives refresh | Manual browser | — | — |
| F-028 | Heart icon toggles; persists in DB; guest redirect works | Manual browser | — | — |
| F-029 | Style preferences saveable and readable in account dashboard | Manual browser | — | — |

**Automated verification commands in each plan** (using `grep`):
- Plan 01: `grep -c "auth-page|auth-tab|account-layout|..." src/input.css`
- Plan 02: `grep -c "supabase.auth.signUp|...|window.elvoraSignOut" js/auth.js`
- Plan 03: `grep -c "auth-page|handleSignIn|handleSignUp|..." auth.html`
- Plan 04: `grep -c "account-page|saveProfile|savePrefs|..." account.html`
- Plan 05: `grep -c "toggleWishlist|initWishlist|..." shop.html` + `product.html`

### Wave 0 Gaps

- [ ] SQL migration file — `supabase/migrations/002_phase4_user_profiles.sql` — must be created AND applied via Supabase Dashboard before Wave 1 executes

*(No automated test framework gaps — project uses manual browser testing per existing convention)*

---

## Security Domain

> `security_enforcement: true` in config.json — security section required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Supabase Auth (bcrypt, JWT, email/password) |
| V3 Session Management | yes | Supabase JWT auto-refresh; `onAuthStateChange` clears store on SIGNED_OUT |
| V4 Access Control | yes | Supabase RLS — `auth.uid() = user_id` on `wishlist_items`; `auth.uid() = id` on `user_profiles` |
| V5 Input Validation | yes | Alpine client-side (password length, confirm match, email format); Supabase Auth validates email uniqueness server-side |
| V6 Cryptography | yes | Supabase handles bcrypt — never hand-roll password hashing |

### Known Threat Patterns for Supabase + Alpine Auth

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Email enumeration on sign-in | Information Disclosure | Show generic error "Incorrect email or password" — not "Email not found" |
| API key exposure | Information Disclosure | Only `anon` key in browser (safe by design); `service_role` never in client code |
| CSRF on auth forms | Spoofing | Not applicable — no server-rendered forms; Supabase uses JWT bearer tokens |
| Stored XSS via user input | Tampering | `x-text` binding (Alpine escapes HTML) used for user data display — safe. `x-html` is NOT used anywhere |
| Broken object-level authorization | Elevation of Privilege | RLS enforced at DB level for all user-scoped tables — client `.eq('user_id', auth.uid())` is defense-in-depth only |
| Session fixation | Spoofing | Supabase issues new JWT on sign-in — old tokens invalidated |
| Insecure direct object reference | Elevation of Privilege | Wishlist and profile RLS policies prevent cross-user access regardless of client-sent user_id |

### Security Notes Specific to Phase 4

1. **`window.elvoraSignOut` global:** Exposes sign-out as a callable function. Not a security risk — triggering sign-out can only help, not harm.
2. **`account.html` redirect:** Client-side redirect (`getUser()` → auth.html) is UI-only. Even if an attacker bypasses it, all `user_profiles` and `wishlist_items` queries return empty (RLS blocks data access for unauthenticated requests).
3. **Error messages:** Sign-in errors must remain generic to prevent email enumeration. Sign-up errors can say "email already registered" only when Supabase explicitly returns that error.
4. **`user_metadata` vs database:** `user.user_metadata.first_name` is stored in the JWT and can be set by the authenticated user via `supabase.auth.updateUser()`. This is fine for nav display but should not be used for security decisions. The `user_profiles` table is the authoritative source for display name.

---

## Open Questions

1. **Should Wave 0 SQL migration be committed to the repo?**
   - What we know: `001_schema.sql` was committed; it's the source of truth for schema.
   - What's unclear: The migration file `002_phase4_user_profiles.sql` must be created and applied manually (cloud-only workflow). Should it be added to `supabase/migrations/` for documentation?
   - Recommendation: Yes — create the file in the repo for documentation even though the apply step is manual via Dashboard. Follow the same pattern as `001_schema.sql`.

2. **`user_profiles` insert on `signUp` — what if it fails?**
   - What we know: The `signUp` auth call succeeds, user is logged in, but the `user_profiles` insert may fail.
   - What's unclear: The current plans throw on the insert error, which would bubble up as a generic error to the user even though they ARE logged in.
   - Recommendation: Catch the `user_profiles` insert error separately. If auth succeeds but profile insert fails, still redirect to `account.html`. The user is logged in; the profile can be created later when they first save profile changes.

3. **Can `wishlistedIds` Set be initialized with `getSession()` (faster) instead of `getUser()` (round trip)?**
   - What we know: `initWishlist()` calls `getUser()` to check if logged in — this adds latency on every PLP/PDP page load.
   - What's unclear: Whether `getSession()` is sufficient for the user check in `initWishlist()`.
   - Recommendation: Use `$store.auth.loggedIn` instead of `getUser()` in `initWishlist()`. By the time product cards render, `initAuth()` in components.js will have populated the store. This removes one round-trip per page. However, timing depends on when `initAuth()` completes vs when `init()` runs in the page x-data. Safe fallback: keep `getUser()` for MVP, optimize later.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Alpine does not detect in-place Set mutations; `new Set(this.set)` copy triggers reactivity | Finding 3 | Wishlist hearts won't update visually on toggle; critical UX failure |
| A2 | `supabase.auth.getUser()` makes a network round trip (~100–200ms) | Finding 4 | Performance assumption only; no correctness impact |
| A3 | `onAuthStateChange` fires INITIAL_SESSION on subscribe | Finding 5 | If it doesn't fire, the store won't be populated on the subscription path; covered by `getUser()` call anyway |
| A4 | `location.hash = 'wishlist'` without matching element ID does not cause page scroll | Finding 12 / Pitfall 4 | If false, page scrolls on tab switch; fix by removing conflicting IDs |
| A5 | PostgREST `products(...)` nested select syntax works for `wishlist_items` joined query | Finding 9 | Wishlist product data won't load; error in account.html wishlist section |
| A6 | `unique (user_id, product_id)` constraint error on duplicate wishlist insert is handled by error revert | Finding 8 | If error is not thrown (e.g., Supabase returns 200 with conflict), revert won't fire; heart stays filled (correct state anyway) |

---

## Sources

### Primary (HIGH confidence)
- `supabase/migrations/001_schema.sql` — exact column names, RLS policies for `user_profiles` and `wishlist_items`
- `js/components.js` — existing Alpine store registration pattern, nav HTML structure, Supabase client exposure (`window.supabase`)
- `js/auth.js` — current stub file (function signatures to implement)
- `auth.html`, `account.html` — current shell HTML (boilerplate to preserve)
- `shop.html` — existing x-data structure and wishlist button location (line 208–212)
- `product.html` — existing wishlist button (line 458), Toastify CDN URLs (lines 12, 14)
- `src/input.css` — existing CSS tokens, end of file (line 852), `.wishlist-btn` at line 683
- `.planning/phases/04-auth-customer-account/04-CONTEXT.md` — locked decisions D-01 through D-13
- `.planning/phases/04-auth-customer-account/04-PATTERNS.md` — code patterns mapped from codebase

### Secondary (MEDIUM confidence)
- `.planning/phases/04-auth-customer-account/04-01-PLAN.md` through `04-05-PLAN.md` — existing execution plans (source of schema mismatch discovery)
- `.planning/REQUIREMENTS.md` §F-025 through F-029 — acceptance criteria

### Tertiary (LOW confidence — [ASSUMED])
- Alpine.js Set reactivity behavior (new Set copy trick)
- Supabase onAuthStateChange INITIAL_SESSION event behavior
- PostgREST nested join syntax behavior for wishlist query
- `location.hash` scroll behavior with matching element IDs

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — no new packages; all CDN deps already in project
- Architecture: HIGH — direct codebase analysis of existing files
- Schema findings: HIGH — read directly from `001_schema.sql`
- Pitfalls: MEDIUM/HIGH — schema mismatch confirmed HIGH; Alpine Set behavior MEDIUM (assumed)

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 (30 days — stable stack)
