---
phase: 04-auth-customer-account
reviewed: 2026-06-14T17:53:34Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - account.html
  - auth.html
  - js/auth.js
  - js/components.js
  - product.html
  - shop.html
  - src/input.css
  - supabase/migrations/003_phase4_user_profiles.sql
findings:
  critical: 3
  warning: 5
  info: 3
  total: 11
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-06-14T17:53:34Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the Phase 4 Auth + Customer Account implementation: authentication flow (`auth.html`, `js/auth.js`), account dashboard (`account.html`), shared navigation/stores (`js/components.js`), product and shop pages updated with wishlist functionality, CSS additions, and a Supabase column migration.

The overall structure is sound and the Supabase RLS posture is correct. Three blockers were found: a sign-out crash on pages that do not include `auth.js` as a `<script>` tag but rely on `window.elvoraSignOut` being set by it, a visual layout break in the auth page left panel caused by a missing CSS class, and the "Forgot password" link pointing to the raw Supabase dashboard rather than a password-reset flow. Five warnings cover double-submit triggers, missing input validation, an unhandled error path, a slug not encoded in URL construction, and an auth subscription that is never cleaned up. Three info items flag the abandoned `productId` parameter, a `console.error` left in production code, and missing database CHECK constraints on the new preference columns.

---

## Critical Issues

### CR-01: Sign-Out Crashes on shop.html and product.html — `window.elvoraSignOut` Not Defined

**File:** `js/components.js:167`

**Issue:** The nav's Sign Out button calls `window.elvoraSignOut()`. That global is set at the bottom of `js/auth.js` (`window.elvoraSignOut = signOut`). On pages where `auth.js` is NOT listed as a `<script type="module">` — specifically `shop.html` and `product.html` — the global is never assigned. The import `import { getUser, onAuthChange } from './auth.js'` inside `components.js` does execute the `auth.js` module, **but** ES module execution happens once per module URL per realm and the side-effects (`window.elvoraSignOut = signOut`) ARE run via that transitive import. However, `components.js` only imports two named exports; the side-effect lines at the bottom of `auth.js` still execute as part of loading the module. This means the global *should* be set — but this is fragile: if the import is ever tree-shaken, or the assignment is moved above the export statements or into a different code path, the sign-out breaks silently in production for any logged-in user on shop/product pages.

More critically: the sign-out handler has **no `.catch()`**. If `elvoraSignOut()` rejects (network error, Supabase timeout), the rejected promise is unhandled. The `$store.auth.user = null` and the redirect to `/index.html` never run, but the user sees no error message either — the button appears to do nothing.

**Fix:**
1. Import and expose `signOut` in `components.js` directly, eliminating the global dependency:
```js
// js/components.js — add to existing import
import { getUser, onAuthChange, signOut } from './auth.js';
```
Then in the nav HTML template, reference `signOut` instead of `window.elvoraSignOut`.

2. Add error handling to the sign-out button:
```html
<button
  @click="signOut().then(() => {
    $store.auth.user = null;
    $store.auth.loggedIn = false;
    window.location.href = '/index.html';
  }).catch(() => {
    /* optionally show toast */
  })"
  class="nav-dropdown-item danger"
>Sign Out</button>
```

---

### CR-02: Auth Left-Panel Tagline Renders at Wrong Position — Missing `.auth-panel-content` CSS Class

**File:** `auth.html:25` / `src/input.css:868`

**Issue:** The left editorial panel in `auth.html` contains:
```html
<div class="auth-panel-content">
  <p class="auth-wordmark">ELVORA</p>
  <p class="auth-tagline">MOVE BEAUTIFULLY</p>
</div>
```
`.auth-wordmark` is styled `position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%)` — it is removed from normal flow. `.auth-tagline` is a normal block element with `display: block; margin-top: 12px`. Since `.auth-panel-content` has **no CSS definition** and therefore no `position: relative`, the tagline does not render below the wordmark at the visual center. Instead it renders in normal flow near the top-left of the panel, visually disconnected from the wordmark. The premium editorial layout is broken.

**Fix:** Add a CSS definition for `.auth-panel-content` that centres its children:
```css
.auth-panel-content {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}
```
Then remove `position: absolute` from `.auth-wordmark` (let the container handle centering):
```css
.auth-wordmark {
  font-family: var(--font-display);
  font-size: 36px; font-weight: 700; font-style: italic;
  color: white; letter-spacing: 6px; white-space: nowrap;
}
```

---

### CR-03: "Forgot Password" Link Points to Raw Supabase Dashboard

**File:** `auth.html:126-129`

**Issue:** The "Forgot password?" link navigates to `https://elvorastudio.supabase.co` — the Supabase project dashboard — in a new tab. This exposes the Supabase project URL to users and provides no password reset functionality. A user who clicks this is sent to a Supabase admin URL they cannot use. This is broken UX that also leaks the hosting provider's project subdomain to users who inspect the link.

**Fix:** Implement a real password reset using Supabase's built-in email reset. Replace the link with a button that calls `supabase.auth.resetPasswordForEmail(email, { redirectTo: ... })`:
```html
<button
  type="button"
  class="auth-forgot"
  @click="if(siEmail) { window.supabase.auth.resetPasswordForEmail(siEmail, { redirectTo: window.location.origin + '/auth.html?tab=reset' }); error = 'Password reset email sent — check your inbox.'; } else { error = 'Enter your email first, then click Forgot password.'; }"
>Forgot password?</button>
```
At minimum, if the full reset flow is out of scope, replace the href with `#` and display a message directing users to contact support.

---

## Warnings

### WR-01: `getUser()` Destructure Throws on Network Error — No Try/Catch

**File:** `js/auth.js:43`

**Issue:** `getUser()` destructures `{ data: { user } }` directly from the Supabase call without any error handling. If the Supabase SDK returns `{ data: { user: undefined }, error: <Error> }` due to a network failure or expired JWT, this still works safely. However, if the SDK itself throws (which can happen on network timeout), the error propagates uncaught to all callers. In `account.html:39`, the call is `await window.supabase.auth.getUser()` (not via `getUser()`), but `components.js:23` calls `await getUser()` without a try/catch — a throw here would crash `initAuth()` silently and leave the nav in an indeterminate state.

**Fix:**
```js
export async function getUser() {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  } catch {
    return null;
  }
}
```

---

### WR-02: `handleSignUp` Does Not Validate Empty First/Last Name Fields

**File:** `auth.html:58-78`

**Issue:** `handleSignUp()` only validates password length and password confirmation match. It does not check whether `suFirst` (first name) or `suLast` (last name) are empty before calling `window.signUp(...)`. While the fields have the `required` HTML attribute, `handleSignUp()` is triggered via `@click.prevent` — bypassing native form validation. A user who submits with empty name fields will create an account, a profile row will be upserted with `first_name: ''`, and the welcome toast will read "Welcome to Elvora, !" with an empty name.

**Fix:** Add client-side validation before the async call:
```js
async handleSignUp() {
  this.error = '';
  if (!this.suFirst.trim() || !this.suLast.trim()) { this.error = 'Please enter your first and last name.'; return; }
  if (this.suPassword.length < 8) { this.error = 'Password must be at least 8 characters.'; return; }
  if (this.suPassword !== this.suConfirm) { this.error = 'Passwords do not match.'; return; }
  // ...
}
```

---

### WR-03: Double-Submit Possible on Profile and Preferences Forms

**File:** `account.html:160,203` and `account.html:259,308`

**Issue:** Both the profile form and the preferences form have a submit handler on the `<form>` element AND a `@click.prevent` handler on the submit `<button>`. For a `type="submit"` button inside a `<form @submit.prevent>`, clicking the button fires the click event first (Alpine handles it, calling `saveProfile()` once), then `preventDefault()` on click stops the form submit event from firing. This prevents double submission for mouse clicks.

However, when the user presses **Enter** in a text input (e.g., the First Name field), the browser fires the form's `submit` event directly — bypassing the button's click handler — and `saveProfile()` is called once via `@submit.prevent`. If the user *also* presses Space/Enter while focused on the button itself, the click handler fires too. The overlap is narrow but the redundant `@click.prevent` on a `type="submit"` button is the underlying confusion: it can cause double invocations in some keyboard navigation paths.

**Fix:** Remove the redundant `@click.prevent="saveProfile()"` from both submit buttons. The `<form @submit.prevent="saveProfile()">` is sufficient:
```html
<!-- profile save button -->
<button type="submit" class="form-submit profile-save-btn" :disabled="profileSaving"
  x-text="profileSaving ? 'Saving…' : 'Save Changes'"></button>

<!-- prefs save button -->
<button type="submit" class="form-submit prefs-save-btn" :disabled="prefsSaving"
  x-text="prefsSaving ? 'Saving…' : 'Save Preferences'"></button>
```

---

### WR-04: `goToProduct(slug)` Does Not Encode the Slug in the URL

**File:** `js/components.js:68`

**Issue:** The nav autosuggest calls `goToProduct(s.slug)` which constructs the URL as:
```js
window.location.href = '/product.html?slug=' + slug;
```
The slug from the database is not passed through `encodeURIComponent`. Slugs in Elvora's schema are typically URL-safe (kebab-case), but if a slug ever contains characters like spaces, `+`, `&`, `=`, or non-ASCII characters, the URL will be malformed. By contrast, `goToSearch()` on the same line correctly uses `encodeURIComponent`. Inconsistency is itself a risk.

**Fix:**
```js
goToProduct(slug) {
  window.location.href = '/product.html?slug=' + encodeURIComponent(slug);
  this.searchOpen = false;
  this.suggestions = [];
  this.searchQuery = '';
},
```

---

### WR-05: Auth State Subscription Leaks — `onAuthChange` Return Value Discarded

**File:** `js/components.js:26-29`

**Issue:** `onAuthChange((user) => { ... })` returns a Supabase `subscription` object that provides an `unsubscribe()` method. This return value is discarded. In a multi-page static site this is acceptable (the page is destroyed on navigation), but within a single page session the subscription accumulates if `initAuth()` is ever called more than once.

There are two paths that call `initAuth()` in `components.js` (lines 33 and 35 — one for `alpine:init`, one for `window.Alpine` already set). On pages where both conditions are true simultaneously, `initAuth()` is called twice, and two auth state subscriptions are created. Each fires separately on sign-in/sign-out events, causing the Alpine store to be updated twice in quick succession.

**Fix:** Guard against double initialization:
```js
let _authInitialized = false;
async function initAuth() {
  if (_authInitialized) return;
  _authInitialized = true;
  const user = await getUser();
  Alpine.store('auth').user = user;
  Alpine.store('auth').loggedIn = !!user;
  onAuthChange((user) => {
    Alpine.store('auth').user = user;
    Alpine.store('auth').loggedIn = !!user;
  });
}
```

---

## Info

### IN-01: Unused `productId` Parameter in `removeFromWishlist`

**File:** `account.html:91`

**Issue:** `removeFromWishlist(wishlistId, productId)` accepts a `productId` parameter that is never used in the function body. The deletion query correctly targets `eq('id', wishlistId)` — the wishlist row's own PK — which is correct. The `productId` parameter is dead code.

**Fix:** Remove the unused parameter:
```js
async removeFromWishlist(wishlistId) {
  // ...
}
```
Update the call site at line 240:
```html
@click.prevent="removeFromWishlist(item.wishlistId)"
```

---

### IN-02: `console.error` Left in Production Code

**File:** `shop.html:129`

**Issue:** `console.error('fetchProducts error:', err)` is left in the production `fetchProducts` error handler. Error detail is exposed in browser devtools.

**Fix:** Remove the `console.error` call and, if logging is needed, route through a proper error reporting path. If this is the only error feedback for the user, consider also showing a toast:
```js
} catch (err) {
  this.products = [];
  // Optionally: show error toast
}
```

---

### IN-03: No Database CHECK Constraints on New Preference Columns in Migration 003

**File:** `supabase/migrations/003_phase4_user_profiles.sql:22-26`

**Issue:** The four new columns (`preferred_activity`, `fit_preference`, `style_aesthetic`, `colour_preference`) are added as unconstrained `text` columns. The schema documentation lists valid values (e.g., `preferred_activity` must be one of `'all', 'padel', 'pilates', 'tennis', 'training', 'running'`) but there are no `CHECK` constraints enforcing this at the database level. A client bug or direct API call could write arbitrary strings, which Phase 5 (AI Style Match) would then read without validation.

**Fix:** Add CHECK constraints in the migration:
```sql
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS preferred_activity text
    CHECK (preferred_activity IN ('all','padel','pilates','tennis','training','running')),
  ADD COLUMN IF NOT EXISTS fit_preference text
    CHECK (fit_preference IN ('fitted','relaxed','longline')),
  ADD COLUMN IF NOT EXISTS style_aesthetic text
    CHECK (style_aesthetic IN ('minimal','sporty','editorial')),
  ADD COLUMN IF NOT EXISTS colour_preference text
    CHECK (colour_preference IN ('neutral','earth','sage','monochrome'));
```

---

_Reviewed: 2026-06-14T17:53:34Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
