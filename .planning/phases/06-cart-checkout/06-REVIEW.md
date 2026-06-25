---
phase: 06
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - src/input.css
  - js/cart.js
  - js/auth.js
  - js/components.js
  - product.html
  - shop.html
  - cart.html
  - checkout.html
status: fixed
critical: 2
warning: 4
info: 3
---

# Phase 06: Cart + Checkout — Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Phase 6 adds a cart drawer (Alpine store + localStorage), a full cart page, and a 4-step checkout flow with Supabase order creation. The overall architecture is sound and the guest/auth order separation logic is correctly implemented. Two critical bugs were found: nav search crashes on cart and checkout pages because `products.js` is not loaded there, and items added from `product.html` are silently dropped during Supabase cart sync because `variantId` is never passed to `cart.add()`. Four warnings cover a redundant import pattern, a missing sign-out error handler, a stale auth-state race at checkout, and missing empty-cart guard at order placement.

---

## Critical Issues

### CR-01: Nav search crashes on cart.html and checkout.html — `window.searchProducts` is undefined

**File:** `js/components.js:75` (injected via `cart.html` and `checkout.html`)
**Issue:** The nav HTML injected by `components.js` calls `window.searchProducts(this.searchQuery)` inside `onSearchInput()`. `window.searchProducts` is only assigned by `js/products.js` (line 138). Neither `cart.html` nor `checkout.html` loads `products.js`. When a user on either page types two or more characters into the search bar, the call throws `TypeError: window.searchProducts is not a function`, crashing the async handler and leaving the search dropdown permanently broken. The `searchQuery.length < 2` guard fires first, so zero-input is safe, but any real search attempt on these pages throws.

**Fix:** Add a null-guard before calling `window.searchProducts`, or load `products.js` on all pages. The null-guard is the simpler fix that avoids bundle bloat on non-shop pages:

```js
// js/components.js — onSearchInput()
async onSearchInput() {
  if (this.searchQuery.length < 2) { this.suggestions = []; return; }
  if (typeof window.searchProducts !== 'function') return;  // products.js not loaded on this page
  clearTimeout(this._searchTimer);
  this._searchTimer = setTimeout(async () => {
    const { data } = await window.searchProducts(this.searchQuery);
    this.suggestions = data || [];
  }, 300);
},
```

---

### CR-02: Items added from product.html are silently dropped from Supabase sync

**File:** `js/cart.js:84` / `product.html:225-234`
**Issue:** `mergeGuestCartToSupabase` filters out any cart item where `item.variantId` is falsy (line 84: `.filter(item => item.variantId)`). The `addToBag()` function in `product.html` (lines 227–234) never passes a `variantId` to `cart.add()`. Since `variantId` defaults to `null`, every item added from the product detail page has `variantId === null`. When the user logs in after a guest session, all items added via the PDP are silently discarded during the merge — they are saved to localStorage and shown in the cart UI, but never written to `cart_items` in Supabase.

Additionally, the shop page's "Add to Bag" button (shop.html line 289) also omits `variantId` and `image`, so every shop-page cart add has the same sync problem and will render without a thumbnail in the drawer.

**Fix (two parts):**

Part 1 — `product.html`: resolve the correct variant ID from `selectedColour` + `selectedSize` and pass it to `add()`:

```js
// product.html — addToBag()
addToBag() {
  if (!this.selectedSize) { alert('Please select a size'); return; }
  const variant = this.product.product_variants?.find(
    v => v.colour === this.selectedColour && v.size === this.selectedSize
  );
  const images = [...(this.product.product_images || [])]
    .sort((a, b) => a.display_order - b.display_order);
  const image = images[0]?.url || '';
  Alpine.store('cart').add({
    productId: this.product.id,
    variantId: variant?.id || null,   // <-- was missing
    name: this.product.name,
    slug: this.product.slug,
    colour: this.selectedColour,
    size: this.selectedSize,
    price: this.product.base_price,
    image,                            // <-- was missing
  });
  Alpine.store('cart').openDrawer();
},
```

Part 2 — `shop.html` line 289: the quick-add from the grid also needs `variantId`. At minimum pass `image` so the thumbnail renders:

```js
Alpine.store('cart').add({
  productId: p.id,
  name: p.name,
  slug: p.slug,
  price: p.base_price,
  image: p.activeImage || '',    // <-- was missing
  colour: p.activeColour || '',  // <-- was missing
});
```

---

## Warnings

### WR-01: Sign-out error is silently swallowed in nav dropdown

**File:** `js/components.js:184`
**Issue:** The sign-out button calls `window.elvoraSignOut().then(...)` with no `.catch()`. If `supabase.auth.signOut()` returns an error (e.g., network failure), the promise rejects, the nav state is still cleared (`$store.auth.user = null`), and the redirect fires — but the underlying error is never surfaced to the user. The user believes they are signed out but the Supabase session may still be active server-side.

**Fix:**
```html
<button @click="window.elvoraSignOut()
  .then(() => {
    $store.auth.user = null;
    $store.auth.loggedIn = false;
    window.location.href = '/index.html';
  })
  .catch(err => {
    console.error('Sign out failed', err);
    alert('Sign out failed — please try again.');
  })"
  class="nav-dropdown-item danger">Sign Out</button>
```

---

### WR-02: `placeOrder()` reads auth state from Alpine store instead of Supabase session

**File:** `checkout.html:456`
**Issue:** `placeOrder()` determines whether the order is guest or authenticated via `Alpine.store('auth')?.user`. The Alpine auth store is populated asynchronously by `components.js → initAuth()`. On a cold page load with a slow session round-trip, `initAuth()` may not have completed by the time the user reaches step 3 and clicks "Place Order". If the store still shows `user: null`, an authenticated user's order is recorded as a guest order (`user_id: null`, `guest_email` from the form) — meaning the order is never linkable to their account.

**Fix:** Verify the session directly at the time of order placement rather than relying solely on the store:

```js
async placeOrder() {
  this.loading = true;
  this.errorMsg = '';
  try {
    // Verify live session, not just cached store value
    const { data: { user } } = await window.supabase.auth.getUser();
    const cartItems = Alpine.store('cart').items;
    // ... rest of function uses `user` from live check
  }
}
```

---

### WR-03: `cart.js` redundant dynamic imports shadow the static import

**File:** `js/cart.js:6,75,118`
**Issue:** `cart.js` statically imports `supabase` at the top (line 6: `import { supabase } from './supabase.js'`). Inside `mergeGuestCartToSupabase` (line 75) and `loadCartFromSupabase` (line 118), it then performs `const { supabase } = await import('./supabase.js')`. This redundant dynamic import creates a local `supabase` binding that shadows the top-level static import. While ES module caching means the same module instance is returned both times, the local `const { supabase }` inside each function shadow the module-level `supabase` silently. The top-level import at line 6 is never used — it is dead code. If a future refactor removes the dynamic imports without noticing the dead top-level import, `supabase` will be undefined in those function scopes.

**Fix:** Remove the redundant dynamic imports and use the top-level static import:

```js
// js/cart.js — remove lines 75 and 118 (the dynamic imports)
// The static import at line 6 is sufficient; use that binding throughout.
export async function mergeGuestCartToSupabase(user) {
  // const { supabase } = await import('./supabase.js');  <-- remove
  const localItems = loadFromStorage();
  // ... rest unchanged, supabase from module scope works fine
}
```

---

### WR-04: `initAuth()` can run twice if both `alpine:init` and direct-path conditions are true

**File:** `js/components.js:49-52`
**Issue:** `components.js` registers the `alpine:init` listener and also calls `registerStores(); initAuth()` directly if `window.Alpine` is truthy. If Alpine is already initialized when the module runs, both the listener and the direct call execute — the listener fires synchronously from an already-dispatched event replay that does not occur for `alpine:init`, so in practice only the direct path runs. However `cart.js` has the same dual pattern (lines 169–170), and since both modules are loaded on all cart/checkout pages, the interaction between `cart.js` calling `initCartStore()` and `components.js` calling `registerStores()` (which guards with `if (!Alpine.store('cart'))`) is load-order-sensitive. If `cart.js` runs first and registers the full cart store, `registerStores()` in `components.js` correctly skips the stub. But if `components.js` runs first, it registers a stub `{ count: 0, items: [] }` without the computed getters and methods, and the guard prevents `initCartStore()` from replacing it with the real store.

**Fix:** Remove the stub store registration from `registerStores()` and always let `cart.js` own the cart store definition:

```js
// js/components.js — registerStores()
function registerStores() {
  // Do not register stub cart store — cart.js owns it
  if (!Alpine.store('auth')) Alpine.store('auth', { user: null, loggedIn: false });
}
```

---

## Info

### IN-01: `alert()` used for size validation UX in `product.html`

**File:** `product.html:226`
**Issue:** `addToBag()` uses a native `alert('Please select a size')` when no size is selected. The page already has Toastify loaded for other notifications. A native `alert` blocks the thread, cannot be styled, and breaks the premium UX.

**Fix:** Replace with a Toastify notification consistent with the rest of the page:

```js
if (!this.selectedSize) {
  Toastify({
    text: 'Please select a size',
    duration: 2500,
    gravity: 'bottom', position: 'right',
    style: { background: 'var(--charcoal)', borderRadius: '50px', fontSize: '12px', letterSpacing: '2px' }
  }).showToast();
  return;
}
```

---

### IN-02: Color token duplication between `@theme` and `:root` in `src/input.css`

**File:** `src/input.css:3-27`
**Issue:** Every color token is defined twice — once in `@theme { }` for Tailwind v4 (lines 3–15) and once in `:root { }` as CSS custom properties (lines 17–27). The values are identical. Components that use `var(--rose)` (CSS custom property) and components that use Tailwind's `text-rose` class reference two separate token definitions. If a color is updated in one block, the other must be updated manually or the two sources of truth diverge.

**Fix:** In Tailwind v4, `@theme` variables are automatically exposed as CSS custom properties. Remove the duplicate `:root` block and use `var(--color-rose)`, `var(--color-sage)` etc. everywhere. Alternatively, keep the `:root` block as the single source and `@theme` should reference them — but pick one pattern.

---

### IN-03: Checkout order summary sidebar shows `step < 4` but sidebar is never visible at step 4 anyway

**File:** `checkout.html:338`
**Issue:** Minor dead condition — the aside sidebar uses `x-show="step < 4"` but step 4 shows a full-width confirmation card. At step 4, the grid still has `grid-template-columns: 1fr 340px`, so the aside takes up space even when `x-show` hides it (Alpine uses `display:none` so the space actually collapses). This is not a rendering bug but the grid column definition could be simplified for clarity.

**Fix:** Apply `x-show="step < 4"` with `x-cloak` or restructure the layout so that step 4 uses a full-width layout class. Low priority.

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
