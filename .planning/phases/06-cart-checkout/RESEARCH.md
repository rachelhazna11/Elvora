# Phase 06: Cart + Checkout — Research

**Researched:** 2026-06-16
**Domain:** Alpine.js store patterns, Supabase RLS insert sequences, multi-step checkout state machines
**Confidence:** HIGH

---

## Summary

Phase 06 wires up the existing `Alpine.store('cart')` (localStorage-backed) into a complete shopping experience: a slide-out mini-cart drawer injected via `components.js`, a full cart page (`cart.html`), a 4-step checkout flow on `checkout.html`, Supabase order creation, and a guest-to-auth cart merge on login.

The existing codebase gives an excellent foundation. The mobile nav drawer in `components.js` establishes the exact injection pattern to follow for the mini-cart drawer. The `addToBag()` function in `product.html` already calls `Alpine.store('cart').add(...)` and shows a Toastify notification — Phase 6 extends that to also open the cart drawer. The schema (`001_schema.sql`) already has `orders`, `order_items`, and `cart_items` with correct RLS policies.

The key architectural decisions are: (1) mini-cart drawer is a second injected HTML block appended to `nav-root`'s parent in `components.js`, controlled by a new `Alpine.store('cartUI')` boolean; (2) Supabase cart sync is login-triggered only (not on every add/remove), which is simpler and sufficient for MVP; (3) checkout is a single-page Alpine step machine (no page reload) on `checkout.html`.

**Primary recommendation:** Follow the existing mobile-nav-drawer pattern precisely. Keep `Alpine.store('cart')` as the single source of truth; add `Alpine.store('cartUI')` only for drawer open/close state. Do not add a second state management layer.

---

## Project Constraints (from CLAUDE.md)

- No React, no Svelte, no Vue. Alpine.js 3.15.12 + Vanilla ES Modules only.
- No build step except Tailwind CSS CLI. No Vite unless explicitly added.
- `supabase-js` loaded from CDN ESM (`https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm`).
- Alpine loaded via `<script defer>` CDN tag — all stores must be initialized before Alpine processes the DOM.
- `service_role` key must never appear in browser code.
- RLS must be enabled on every table (already done in schema).
- Aesthetic: premium quiet luxury — no generic e-commerce look.
- Payment: placeholder only, no real payment processing.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Mini-cart drawer (open/close, item list) | Browser / Client | — | Pure client state; `Alpine.store('cart')` already owns items |
| Cart page (qty stepper, remove, totals) | Browser / Client | — | All reactive reads from `Alpine.store('cart')` |
| Checkout step machine (4 steps) | Browser / Client | — | No SSR; form state lives in `x-data` on `checkout.html` |
| Guest order creation | Browser → Supabase | — | Anonymous Supabase client INSERT allowed by RLS policy `orders_insert_authenticated` |
| Authenticated order creation | Browser → Supabase | — | Same INSERT; `auth.uid() = user_id` branch of the same RLS policy |
| Cart persistence (auth users) | Browser → Supabase | — | `cart_items` table; sync triggered on login event |
| Guest-to-auth cart merge | Browser / Client | Supabase | `onAuthStateChange` triggers merge; upsert handles conflict |
| Price snapshot | Browser / Client | — | Price taken from `Alpine.store('cart').items[].price` at checkout submit time |

---

## Research Findings by Question

### Q1 — Mini Cart Drawer: Alpine.store + components.js injection pattern

**Pattern:** Add a second HTML block to the `components.js` injection. The mobile nav drawer in `components.js` is the reference implementation — follow it exactly.

The drawer needs its own store because it must be reachable from `product.html` (which calls `addToBag()`) and from the nav cart icon. A boolean on an existing store works fine — no need for a new store.

**Recommended approach:** Add `cartDrawerOpen` boolean directly to `Alpine.store('cart')` in `cart.js`. This avoids creating a second store and keeps all cart state co-located.

```js
// In cart.js — extend the existing store definition
Alpine.store('cart', {
  items: savedItems,
  cartDrawerOpen: false,          // NEW

  openDrawer()  { this.cartDrawerOpen = true; },
  closeDrawer() { this.cartDrawerOpen = false; },

  get count() { ... },
  // ... rest unchanged
});
```

**Drawer HTML block (inject in components.js alongside navHTML):**

```html
<!-- Cart drawer — inject via components.js, placed after nav-root -->
<div id="cart-drawer-root">
  <!-- Backdrop -->
  <div
    x-show="$store.cart.cartDrawerOpen"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0"
    @click="$store.cart.closeDrawer()"
    class="fixed inset-0 z-[180] bg-charcoal/40 backdrop-blur-sm"
    style="display:none;"
    aria-hidden="true"
  ></div>

  <!-- Drawer panel -->
  <div
    x-show="$store.cart.cartDrawerOpen"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="translate-x-full"
    x-transition:enter-end="translate-x-0"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="translate-x-0"
    x-transition:leave-end="translate-x-full"
    @keydown.escape.window="$store.cart.closeDrawer()"
    role="dialog"
    aria-modal="true"
    aria-label="Shopping bag"
    x-ref="cartDrawer"
    class="fixed inset-y-0 right-0 w-[400px] max-w-full z-[190] flex flex-col bg-beige shadow-2xl"
    style="display:none;"
  >
    <!-- Drawer header -->
    <div class="flex items-center justify-between px-8 py-6 border-b border-sage/20">
      <p class="font-display text-lg font-bold text-charcoal tracking-wide">
        Your Bag
        <span x-show="$store.cart.count > 0" class="ml-2 text-[13px] font-body font-normal text-text-muted"
              x-text="'(' + $store.cart.count + ' items)'"></span>
      </p>
      <button
        @click="$store.cart.closeDrawer()"
        aria-label="Close cart"
        class="w-9 h-9 flex items-center justify-center rounded-full hover:bg-rose/10 transition-colors text-charcoal"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
          <line x1="18" y1="6" x2="6" y2="18" stroke-linecap="round"/>
          <line x1="6" y1="6" x2="18" y2="18" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <!-- Items list -->
    <div class="flex-1 overflow-y-auto px-8 py-6">
      <!-- Empty state -->
      <div x-show="$store.cart.items.length === 0" class="flex flex-col items-center justify-center h-full gap-4 text-center">
        <svg class="w-12 h-12 text-sage/40" fill="none" stroke="currentColor" stroke-width="1" viewBox="0 0 24 24">
          <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/>
          <path d="M16 10a4 4 0 01-8 0"/>
        </svg>
        <p class="font-display text-charcoal text-lg">Your bag is empty</p>
        <p class="text-sm text-text-muted">Add something beautiful to begin.</p>
        <a href="/shop.html" @click="$store.cart.closeDrawer()"
           class="btn-primary mt-4">Shop Now</a>
      </div>

      <!-- Items -->
      <template x-for="item in $store.cart.items" :key="item.key">
        <div class="flex gap-4 py-5 border-b border-sage/15 last:border-0">
          <!-- Item image placeholder / actual image -->
          <div class="w-20 h-24 rounded-xl bg-sage-light flex-shrink-0 overflow-hidden">
            <img x-show="item.image" :src="item.image" :alt="item.name"
                 class="w-full h-full object-cover" loading="lazy">
            <div x-show="!item.image" class="w-full h-full bg-sage-light"></div>
          </div>

          <!-- Item details -->
          <div class="flex-1 min-w-0">
            <p class="font-display text-[14px] font-semibold text-charcoal leading-tight truncate"
               x-text="item.name"></p>
            <p class="text-[11px] text-text-muted mt-0.5 tracking-wide uppercase"
               x-text="[item.colour, item.size].filter(Boolean).join(' · ')"></p>
            <p class="text-[13px] font-semibold text-charcoal mt-2"
               x-text="'Rp ' + (item.price * item.qty).toLocaleString('id-ID')"></p>

            <!-- Qty stepper + remove -->
            <div class="flex items-center gap-3 mt-3">
              <div class="flex items-center border border-sage/30 rounded-full overflow-hidden">
                <button
                  @click="$store.cart.setQty(item.key, item.qty - 1)"
                  class="w-8 h-7 flex items-center justify-center text-charcoal hover:bg-sage/10 transition-colors text-lg leading-none"
                  :aria-label="'Decrease quantity of ' + item.name"
                >−</button>
                <span class="w-8 text-center text-[13px] font-medium" x-text="item.qty"></span>
                <button
                  @click="$store.cart.setQty(item.key, item.qty + 1)"
                  class="w-8 h-7 flex items-center justify-center text-charcoal hover:bg-sage/10 transition-colors text-lg leading-none"
                  :aria-label="'Increase quantity of ' + item.name"
                >+</button>
              </div>
              <button
                @click="$store.cart.remove(item.key)"
                class="text-[11px] text-text-muted hover:text-rose transition-colors tracking-wide uppercase underline underline-offset-2"
                :aria-label="'Remove ' + item.name + ' from bag'"
              >Remove</button>
            </div>
          </div>
        </div>
      </template>
    </div>

    <!-- Footer: subtotal + CTA -->
    <div x-show="$store.cart.items.length > 0" class="px-8 py-6 border-t border-sage/20 bg-white">
      <div class="flex justify-between items-center mb-4">
        <span class="text-[12px] tracking-widest uppercase text-text-muted">Subtotal</span>
        <span class="font-display text-lg font-bold text-charcoal"
              x-text="$store.cart.totalFormatted"></span>
      </div>
      <a href="/checkout.html"
         @click="$store.cart.closeDrawer()"
         class="btn-primary w-full text-center block">
        Proceed to Checkout
      </a>
      <button @click="$store.cart.closeDrawer()"
              class="w-full mt-3 text-[11px] tracking-widest uppercase text-text-muted hover:text-charcoal transition-colors">
        Continue Shopping
      </button>
    </div>
  </div>
</div>
```

**Injection in components.js:**

```js
// After injecting navHTML into #nav-root, inject drawer into body
const cartDrawerRoot = document.createElement('div');
cartDrawerRoot.id = 'cart-drawer-root';
cartDrawerRoot.innerHTML = cartDrawerHTML;
document.body.appendChild(cartDrawerRoot);
if (window.Alpine) Alpine.initTree(cartDrawerRoot);
```

**Focus trap:** Alpine's `x-trap` directive (available via the `@alpinejs/focus` plugin) is the cleanest solution. Alternatively, implement manually with `@keydown.tab` on the drawer panel — the existing size-guide modal in `product.html` shows the manual pattern (lines 213–223 of product.html). The manual approach is preferred to avoid adding another CDN dependency.

**Pitfall — `initTree` called before store is registered:** `cart.js` and `components.js` are both `type="module"` scripts. Module execution order is deterministic (DOM order), but `Alpine.store('cart')` is set up in `cart.js`, which loads before `components.js`. The cart drawer HTML uses `$store.cart`, which is already initialized by the time `Alpine.initTree(cartDrawerRoot)` runs. No timing issue. [VERIFIED: existing mobile nav drawer uses the same pattern in components.js and works correctly]

**Update `addToBag()` in product.html** to open the drawer after adding:

```js
addToBag() {
  if (!this.selectedSize) { alert('Please select a size'); return; }
  Alpine.store('cart').add({
    productId: this.product.id,
    variantId: this.selectedVariant?.id || null,
    name: this.product.name,
    slug: this.product.slug,
    colour: this.selectedColour,
    size: this.selectedSize,
    price: this.product.base_price,
    image: this.product.product_images?.[0]?.url || '',
  });
  Alpine.store('cart').openDrawer();
  // Remove the old Toastify notification — drawer replaces it
},
```

**Update nav cart icon** to also open the drawer instead of navigating to cart.html (or keep both: click opens drawer, drawer has "View Full Cart" link).

---

### Q2 — Cart Page (cart.html)

The cart page is a full-page view with the same data as the drawer but more space. It reads directly from `Alpine.store('cart')`.

**Page structure:**

```html
<main x-data class="pt-[80px] min-h-screen bg-beige">
  <!-- Two-column layout on desktop: items left, order summary right -->
  <div class="max-w-[1200px] mx-auto px-6 lg:px-16 py-16">
    <h1 class="font-display text-4xl font-bold text-charcoal mb-12">Your Bag</h1>

    <!-- Empty state -->
    <div x-show="$store.cart.items.length === 0" class="...">
      ...
    </div>

    <!-- Cart content: 2-column grid -->
    <div x-show="$store.cart.items.length > 0"
         class="grid grid-cols-1 lg:grid-cols-[1fr_360px] gap-16">

      <!-- Left: items list -->
      <div>
        <template x-for="item in $store.cart.items" :key="item.key">
          <!-- Cart item row — wider than drawer, shows full name, qty stepper, line total -->
        </template>
      </div>

      <!-- Right: sticky order summary -->
      <div class="lg:sticky lg:top-[104px] self-start">
        <!-- Subtotal, shipping note, checkout CTA -->
      </div>
    </div>
  </div>
</main>
```

**Key component classes needed for cart.html:**

```css
/* src/input.css — @layer components */
.cart-item-row { ... }           /* flex row with image, details, stepper, price */
.cart-qty-stepper { ... }        /* the +/- control with border */
.order-summary-card { ... }      /* sticky white card for totals */
.cart-empty-state { ... }        /* centered illustration + CTA */
```

**Qty stepper in cart page:** Same pattern as drawer — `$store.cart.setQty(item.key, newQty)`. When qty drops to 0, `setQty` calls `remove(key)` internally (already implemented in cart.js).

---

### Q3 — Guest-to-Auth Cart Merge

**When to trigger:** On `supabase.auth.onAuthStateChange` when `event === 'SIGNED_IN'`. This fires both on explicit login and on page load when an existing session is restored. To avoid merging on every page load, check if there are localStorage items and if the user is freshly signed in (use `event` parameter).

**Merge strategy:** Supabase cart wins on variant conflict. Reasoning: if a user logged in on a different device and added items to their Supabase cart, those should be preserved. The localStorage items are merged as additions, not replacements.

```js
// js/cart.js — add after the store definition

async function mergeGuestCartToSupabase(user) {
  const localItems = loadFromStorage();
  if (!localItems.length) return;

  // Build upsert payload — one row per variant
  const rows = localItems
    .filter(item => item.variantId)   // skip items without a variant ID
    .map(item => ({
      user_id: user.id,
      product_id: item.productId,
      variant_id: item.variantId,
      quantity: item.qty,
    }));

  if (!rows.length) return;

  // upsert: ON CONFLICT (user_id, variant_id) DO UPDATE — add quantities
  // Supabase upsert with ignoreDuplicates:false replaces the row; we want to add.
  // Strategy: fetch existing Supabase cart first, then sum quantities, then upsert.
  const { data: existing } = await supabase
    .from('cart_items')
    .select('variant_id, quantity')
    .eq('user_id', user.id);

  const existingMap = {};
  (existing || []).forEach(r => { existingMap[r.variant_id] = r.quantity; });

  const mergedRows = rows.map(row => ({
    ...row,
    quantity: (existingMap[row.variant_id] || 0) + row.quantity,
  }));

  await supabase
    .from('cart_items')
    .upsert(mergedRows, { onConflict: 'user_id,variant_id' });

  // After successful merge, reload Supabase cart into Alpine store
  await loadCartFromSupabase(user.id);

  // Clear localStorage — Supabase is now the source of truth
  saveToStorage([]);
}

async function loadCartFromSupabase(userId) {
  const { data } = await supabase
    .from('cart_items')
    .select(`
      id, quantity, variant_id,
      product_variants!inner(colour, size, product_id,
        products!inner(id, name, slug, base_price,
          product_images(url, display_order)
        )
      )
    `)
    .eq('user_id', userId);

  if (!data) return;

  const items = data.map(row => {
    const v = row.product_variants;
    const p = v.products;
    const images = p.product_images || [];
    images.sort((a, b) => a.display_order - b.display_order);
    const key = `${p.id}|${row.variant_id}|${v.size}`;
    return {
      key,
      productId: p.id,
      variantId: row.variant_id,
      name: p.name,
      slug: p.slug,
      price: p.base_price,
      image: images[0]?.url || '',
      colour: v.colour,
      size: v.size,
      qty: row.quantity,
    };
  });

  Alpine.store('cart').items = items;
  saveToStorage(items);
}
```

**Triggering merge from `components.js`:**

```js
// In components.js — extend the onAuthChange callback
import { mergeGuestCartToSupabase, loadCartFromSupabase } from './cart.js'; // add exports

onAuthChange(async (user, event) => {
  Alpine.store('auth').user = user;
  Alpine.store('auth').loggedIn = !!user;
  if (user && event === 'SIGNED_IN') {
    await mergeGuestCartToSupabase(user);
  } else if (user && event === 'INITIAL_SESSION') {
    // Restore Supabase cart on page load (no localStorage merge)
    await loadCartFromSupabase(user.id);
  } else if (!user) {
    // On sign-out, reload from localStorage
    Alpine.store('cart').items = loadFromStorage();
  }
});
```

**Note:** `supabase.auth.onAuthStateChange` callback receives `(event, session)`. The `event` string is `'SIGNED_IN'`, `'SIGNED_OUT'`, `'INITIAL_SESSION'`, `'TOKEN_REFRESHED'`. Currently `auth.js`'s `onAuthChange` wrapper only passes `session?.user` — it needs to be extended to also pass `event`. [ASSUMED: event parameter is present in supabase-js v2 onAuthStateChange; this is the documented API]

---

### Q4 — Supabase Cart Sync Strategy

**Decision: Login-triggered sync only (not on every add/remove).**

Reasoning:
- The project scope is MVP for a university assessment. Real-time two-way sync would require retry logic, error handling for network failures mid-add, and conflict resolution on every operation.
- guest localStorage cart already works reliably.
- At checkout, the Alpine store has the ground truth; order items are snapshotted from there.
- The Supabase `cart_items` table is most useful for: (1) letting users resume their cart across devices, and (2) an admin view of abandoned carts.

**Implementation:** On login → `mergeGuestCartToSupabase`. On page load while authenticated → `loadCartFromSupabase`. No sync on individual add/remove — those stay localStorage-only until next page load.

**Trade-off accepted:** If a logged-in user adds items and then navigates away without the page triggering another load, the cart_items table may be stale by the count of new items. For MVP this is acceptable.

---

### Q5 — Multi-Step Checkout Flow (checkout.html)

**Architecture:** Single `x-data` object on `<main>` — a step machine. No page reloads.

```js
x-data="{
  step: 1,                     // 1=Shipping, 2=Review, 3=Payment, 4=Confirmation
  loading: false,
  orderId: null,
  errorMsg: '',

  // Step 1 form fields
  email: '',
  firstName: '',
  lastName: '',
  address: '',
  city: '',
  province: '',
  postalCode: '',
  phone: '',

  // Validation
  errors: {},

  validateStep1() {
    this.errors = {};
    if (!this.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email))
      this.errors.email = 'Valid email required';
    if (!this.firstName.trim()) this.errors.firstName = 'First name required';
    if (!this.lastName.trim()) this.errors.lastName = 'Last name required';
    if (!this.address.trim()) this.errors.address = 'Address required';
    if (!this.city.trim()) this.errors.city = 'City required';
    return Object.keys(this.errors).length === 0;
  },

  nextStep() {
    if (this.step === 1 && !this.validateStep1()) return;
    this.step++;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  },

  prevStep() {
    if (this.step > 1) { this.step--; window.scrollTo({ top: 0, behavior: 'smooth' }); }
  },

  async placeOrder() {
    this.loading = true;
    this.errorMsg = '';
    try {
      const user = $store.auth.user;
      const cartItems = $store.cart.items;
      const subtotal = $store.cart.total;

      // Insert order header
      const orderPayload = {
        status: 'confirmed',
        subtotal,
        shipping_address: {
          firstName: this.firstName,
          lastName: this.lastName,
          address: this.address,
          city: this.city,
          province: this.province,
          postalCode: this.postalCode,
          phone: this.phone,
        },
      };
      if (user) {
        orderPayload.user_id = user.id;
      } else {
        orderPayload.guest_email = this.email;
        orderPayload.user_id = null;
      }

      const { data: order, error: orderErr } = await window.supabase
        .from('orders')
        .insert(orderPayload)
        .select('id')
        .single();

      if (orderErr) throw orderErr;

      // Insert order_items (snapshotted)
      const lineItems = cartItems.map(item => ({
        order_id: order.id,
        product_id: item.productId,
        variant_id: item.variantId,
        product_name: item.name,
        variant_label: [item.colour, item.size].filter(Boolean).join(' / '),
        unit_price: item.price,
        quantity: item.qty,
      }));

      const { error: itemsErr } = await window.supabase
        .from('order_items')
        .insert(lineItems);

      if (itemsErr) throw itemsErr;

      // Success: clear cart, show confirmation
      this.orderId = order.id;
      $store.cart.clear();

      // If auth user: also clear Supabase cart_items
      if (user) {
        await window.supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id);
      }

      this.step = 4;
      window.scrollTo({ top: 0, behavior: 'smooth' });

    } catch (err) {
      this.errorMsg = 'Something went wrong. Please try again.';
      console.error('Order creation failed:', err);
    } finally {
      this.loading = false;
    }
  }
}"
```

**Step visibility pattern:**

```html
<!-- Step 1: Shipping info -->
<div x-show="step === 1" x-transition:enter="transition ease-out duration-200"
     x-transition:enter-start="opacity-0 translate-x-4" x-transition:enter-end="opacity-100 translate-x-0">
  ...
</div>

<!-- Step 2: Order Review -->
<div x-show="step === 2" style="display:none;" ...>
  <!-- Render $store.cart.items read-only, show subtotal -->
</div>

<!-- Step 3: Payment (placeholder) -->
<div x-show="step === 3" style="display:none;" ...>
  <!-- Static copy: "Payment processed securely" + card number mockup -->
  <!-- One button: "Place Order" → calls placeOrder() -->
</div>

<!-- Step 4: Confirmation -->
<div x-show="step === 4" style="display:none;" ...>
  <p>Order ID: <span x-text="orderId?.slice(0, 8).toUpperCase()"></span></p>
</div>
```

**Step indicator:**

```html
<div class="flex items-center gap-0 mb-12" role="list" aria-label="Checkout steps">
  <template x-for="(label, i) in ['Shipping', 'Review', 'Payment', 'Confirmation']" :key="i">
    <div class="flex items-center" role="listitem">
      <div class="flex items-center gap-2"
           :class="step >= i+1 ? 'text-charcoal' : 'text-text-muted'">
        <div class="w-7 h-7 rounded-full flex items-center justify-center text-[11px] font-semibold border transition-colors"
             :class="step > i+1 ? 'bg-sage border-sage text-white' :
                     step === i+1 ? 'bg-charcoal border-charcoal text-white' :
                     'border-sage/30 text-text-muted'">
          <template x-if="step > i+1">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </template>
          <template x-if="step <= i+1">
            <span x-text="i+1"></span>
          </template>
        </div>
        <span class="text-[11px] tracking-widest uppercase hidden sm:block" x-text="label"></span>
      </div>
      <div x-show="i < 3" class="w-12 lg:w-20 h-px mx-3 transition-colors"
           :class="step > i+1 ? 'bg-sage' : 'bg-sage/20'"></div>
    </div>
  </template>
</div>
```

**Pitfall — `x-show` vs `style="display:none"` on steps:** Alpine requires `style="display:none"` on all `x-show` elements that should be hidden on initial render, otherwise they flash briefly before Alpine initializes. This is already the established pattern in this project (see nav drawer in components.js). All non-first steps must have `style="display:none;"`.

---

### Q6 — Order Creation: Insertion Sequence

**Critical:** Insert `orders` first, get the `id`, then insert `order_items`. This is the only safe sequence because `order_items.order_id` is a foreign key to `orders.id`.

The RLS policy `order_items_insert_allowed` verifies that the `order_id` references an order owned by the current user (or a guest order with non-null `guest_email`). This means the `orders` row **must exist** before the `order_items` INSERT is attempted.

**Error handling:** If `order_items` INSERT fails after `orders` INSERT succeeds, the order header exists but has no line items. For MVP, show an error and ask the user to contact support. A full production system would use a database transaction or Supabase RPC function. For this scope, a simple try/catch is sufficient.

**Sequence:**

```
1. Build orderPayload (with user_id or guest_email)
2. INSERT INTO orders → receive order.id
3. Build lineItems[] with order.id
4. INSERT INTO order_items (all rows in one call — Supabase accepts an array)
5. On success: call $store.cart.clear(), set this.step = 4, store this.orderId
6. On failure at step 4: surface errorMsg, do NOT advance step
```

---

### Q7 — Guest Checkout and RLS

**RLS policy already exists and is correct** (from `001_schema.sql`):

```sql
-- orders_insert_authenticated allows:
-- authenticated insert where auth.uid() = user_id
-- OR anonymous insert where user_id IS NULL AND guest_email IS NOT NULL
WITH CHECK (
  auth.uid() = user_id
  OR (user_id is null and guest_email is not null)
)
```

This means the anonymous Supabase client (no session) can insert an order as long as:
- `user_id` is explicitly set to `null` (not omitted — the column must be null, not missing)
- `guest_email` is provided

**Guest checkout flow:**
- Step 1 form collects `email` field (required for guests, pre-filled for auth users)
- At `placeOrder()`, check `$store.auth.user`:
  - If user exists: set `user_id = user.id`, `guest_email = null`
  - If no user: set `user_id = null`, `guest_email = this.email`

**Important:** For authenticated users, `guest_email` should be `null`, not the user's email — the constraint `orders_user_or_guest` requires EITHER `user_id` OR `guest_email` to be non-null, not both. If both are set, the Supabase policy check `auth.uid() = user_id` passes but setting `guest_email` is redundant and potentially confusing. Set only the applicable field.

**For auth users, pre-fill the email field:**

```html
<input type="email" x-model="email" @x-init="email = $store.auth.user?.email || ''">
```

Actually for the synthetic email system in auth.js (`{username}@elvora.local`), do NOT pre-fill the email from auth user metadata for the order guest_email. For auth users, the order gets `user_id` and no `guest_email`. Display the contact info as their username instead.

---

### Q8 — Price Snapshot Integrity

**Current state:** `cart.js` stores `price` as `item.price` which is set at `add()` time from `product.base_price` (fetched from Supabase catalog). The price is snapshotted the moment the user clicks "Add to Bag".

**At checkout:** `placeOrder()` reads `item.price` from `$store.cart.items` — this is the price at add-to-cart time, not re-fetched from Supabase. This is the correct MVP approach.

**Risk:** If the user's localStorage cart was set 30 days ago and the price changed, the snapshotted price is stale. For a university assessment, this is acceptable. A production system would re-validate prices server-side.

**`unit_price` in `order_items`:** Must be set from `item.price` (the cart snapshot), not from a catalog join. The schema comment confirms this: "unit_price, product_name, and variant_label are snapshotted — NOT joined to live catalog."

**`variant_label`:** Construct as `[item.colour, item.size].filter(Boolean).join(' / ')`. Example: `"Sage Green / S"`.

---

### Q9 — CSS Classes Needed for Phase 6

Add to `src/input.css` under `@layer components`:

```css
/* ─── Cart Drawer ─────────────────────────────────────────────────────────── */
.cart-drawer-item {
  display: flex; gap: 16px; padding: 20px 0;
  border-bottom: 1px solid rgba(168,191,163,0.15);
}
.cart-drawer-item:last-child { border-bottom: none; }
.cart-drawer-thumb {
  width: 80px; height: 96px; border-radius: 12px;
  overflow: hidden; flex-shrink: 0;
  background: var(--sage-light);
}
.cart-qty-stepper {
  display: inline-flex; align-items: center;
  border: 1px solid rgba(168,191,163,0.3); border-radius: 50px; overflow: hidden;
}
.cart-qty-stepper button {
  width: 32px; height: 28px; display: flex; align-items: center; justify-content: center;
  background: none; border: none; cursor: pointer; font-size: 18px; line-height: 1;
  color: var(--charcoal); transition: background 0.15s;
}
.cart-qty-stepper button:hover { background: rgba(168,191,163,0.15); }
.cart-qty-stepper span { width: 32px; text-align: center; font-size: 13px; font-weight: 500; }

/* ─── Cart Page ───────────────────────────────────────────────────────────── */
.cart-page { background: var(--beige); min-height: 100vh; padding-top: 80px; }
.cart-layout {
  max-width: 1200px; margin: 0 auto; padding: 64px;
  display: grid; grid-template-columns: 1fr 360px; gap: 64px; align-items: start;
}
.cart-item-row {
  display: flex; gap: 24px; padding: 28px 0;
  border-bottom: 1px solid rgba(168,191,163,0.2);
}
.cart-item-row:last-child { border-bottom: none; }
.cart-item-image {
  width: 96px; height: 120px; border-radius: 14px;
  overflow: hidden; flex-shrink: 0; background: var(--sage-light);
}
.order-summary {
  background: white; border-radius: 20px; padding: 32px;
  position: sticky; top: 104px;
}
.order-summary-row {
  display: flex; justify-content: space-between; align-items: center;
  padding: 12px 0; border-bottom: 1px solid rgba(168,191,163,0.15);
}
.order-summary-row:last-of-type { border-bottom: none; }
.cart-empty {
  min-height: 60vh; display: flex; flex-direction: column;
  align-items: center; justify-content: center; text-align: center; gap: 16px;
}

/* ─── Checkout Page ───────────────────────────────────────────────────────── */
.checkout-page { background: var(--beige); min-height: 100vh; padding-top: 80px; }
.checkout-layout {
  max-width: 1100px; margin: 0 auto; padding: 64px;
  display: grid; grid-template-columns: 1fr 340px; gap: 56px; align-items: start;
}
.checkout-card {
  background: white; border-radius: 20px; padding: 40px;
}
.checkout-step-indicator {
  display: flex; align-items: center; margin-bottom: 48px;
}
.step-dot {
  width: 28px; height: 28px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 600; border: 1.5px solid;
  transition: all 0.3s;
}
.step-dot.done { background: var(--sage); border-color: var(--sage); color: white; }
.step-dot.active { background: var(--charcoal); border-color: var(--charcoal); color: white; }
.step-dot.pending { background: transparent; border-color: rgba(168,191,163,0.3); color: var(--text-muted); }
.step-connector {
  flex: 1; height: 1px; margin: 0 12px; transition: background 0.3s;
}
.step-connector.done { background: var(--sage); }
.step-connector.pending { background: rgba(168,191,163,0.2); }
.checkout-form-group { margin-bottom: 20px; }
.checkout-form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.checkout-field-error {
  font-size: 11px; color: var(--rose); margin-top: 4px; letter-spacing: 0.5px;
}
.checkout-summary-item {
  display: flex; gap: 12px; padding: 12px 0;
  border-bottom: 1px solid rgba(168,191,163,0.15);
  font-size: 13px;
}
.checkout-confirm-icon {
  width: 80px; height: 80px; border-radius: 50%;
  background: var(--sage-light); display: flex; align-items: center;
  justify-content: center; margin: 0 auto 24px;
}

/* ─── Checkout responsive ─────────────────────────────────────────────────── */
@media (max-width: 900px) {
  .cart-layout { grid-template-columns: 1fr; padding: 32px 24px; gap: 32px; }
  .order-summary { position: static; }
  .checkout-layout { grid-template-columns: 1fr; padding: 32px 24px; gap: 32px; }
}
```

---

### Q10 — Alpine Patterns: Store Watchers and Auth Effects

**`Alpine.effect` for reacting to store changes:**

`Alpine.effect` is Alpine 3's reactive effect primitive — it runs immediately and re-runs whenever any reactive data it reads changes. It is available globally when Alpine is initialized.

```js
// Run this after Alpine initializes (in cart.js or components.js)
document.addEventListener('alpine:init', () => {
  // Example: sync cart count to page title
  Alpine.effect(() => {
    const count = Alpine.store('cart').count;
    document.title = count > 0
      ? `(${count}) ${document.title.replace(/^\(\d+\) /, '')}`
      : document.title.replace(/^\(\d+\) /, '');
  });
});
```

`Alpine.effect` can watch auth changes too, but `onAuthChange` from `auth.js` (which wraps `supabase.auth.onAuthStateChange`) is the correct tool for auth — it fires even before Alpine initializes if the session restores early. Use `onAuthChange` for auth-triggered side effects, `Alpine.effect` for DOM/store reactions.

**Reactive multi-step form in x-data:** The step machine (Q5) is all in `x-data` on `<main>`. Alpine's `x-data` object methods have `this` bound to the Alpine component instance. All `$store` accesses inside `x-data` methods must be through `Alpine.store('cart')` (JS), not `$store.cart` (template shorthand — `$store` only works in HTML templates, not in JS methods within `x-data`).

```js
// CORRECT in x-data method
async placeOrder() {
  const cartItems = Alpine.store('cart').items;
  const subtotal = Alpine.store('cart').total;
  const user = Alpine.store('auth').user;
  // ...
}

// WRONG — $store is a template magic, not available in JS method scope
async placeOrder() {
  const cartItems = $store.cart.items; // ReferenceError
}
```

**`$nextTick` in methods:** Use `this.$nextTick(callback)` inside `x-data` methods when you need to wait for DOM updates after a reactive change. This is the same as Vue's `$nextTick`. Available in all `x-data` method contexts.

---

## Standard Stack

### Core (already in use — no new installs)

| Library | Version | Purpose | Source |
|---|---|---|---|
| Alpine.js | 3.15.12 | Store, reactivity, drawer, step machine | CDN, already in all HTML files |
| Supabase JS | 2.x (≥2.79) | Order insert, cart sync | CDN ESM, already in supabase.js |
| Tailwind CSS v4 | 4.x | Styling, responsive | CLI build, already configured |
| Toastify-js | 1.x | Already in product.html for cart feedback | CDN, already in product.html |

### No New Packages Required

Phase 6 does not require installing any new npm packages. All needed functionality is handled by the existing stack:
- Drawer: Alpine.js `x-show` + CSS transitions (same as mobile nav)
- Validation: hand-written (simple required fields, email regex)
- Order creation: Supabase JS SDK
- Notifications: Toastify (already in product.html; add to cart.html + checkout.html)

---

## Package Legitimacy Audit

No new packages are installed in Phase 6. All libraries are already in the project. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
User action (Add to Bag)
        │
        ▼
  product.html addToBag()
        │
        ├─► Alpine.store('cart').add(item)   ──► localStorage.setItem
        │
        └─► Alpine.store('cart').openDrawer()
                  │
                  ▼
           Cart Drawer (in DOM, injected by components.js)
           reads $store.cart.items reactively
                  │
           [Proceed to Checkout]
                  │
                  ▼
           checkout.html (x-data step machine)
           Step 1: Shipping form → validate
           Step 2: Review (reads $store.cart.items)
           Step 3: Payment placeholder
           Step 4: placeOrder()
                  │
        ┌─────────┴──────────┐
        ▼                    ▼
   Auth user             Guest user
   user_id = uid         user_id = null
   guest_email = null    guest_email = email
        │                    │
        └─────────┬──────────┘
                  ▼
         Supabase INSERT orders
                  │
                  ▼
         Supabase INSERT order_items[]
                  │
                  ▼
         $store.cart.clear()
         step = 4 (Confirmation)


Login event (onAuthStateChange SIGNED_IN)
        │
        ▼
   mergeGuestCartToSupabase(user)
        │
        ├─► Fetch existing cart_items for user
        ├─► Sum quantities from localStorage cart
        ├─► Upsert merged rows to cart_items
        └─► loadCartFromSupabase() → update $store.cart.items
```

### Recommended Project Structure (Phase 6 additions)

```
js/
├── cart.js            # Extend: add cartDrawerOpen, openDrawer, closeDrawer,
│                      #         mergeGuestCartToSupabase, loadCartFromSupabase
├── checkout.js        # NEW: export submitOrder() if complexity grows
│                      #      (optional — can live in x-data if it stays small)
├── components.js      # Extend: inject cartDrawerHTML, update onAuthChange call
│                      #         to pass event name for merge trigger
└── [others unchanged]

src/
└── input.css          # Extend: add Phase 6 component classes

cart.html              # Fill <main> stub with cart page markup
checkout.html          # Fill <main> stub with 4-step checkout markup
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Form validation | Custom validation library | Inline JS (simple required + email regex) | 4 fields — a library is overkill |
| Step machine | Custom router/history API | Alpine `x-data` with `step` integer | No page reload needed, Alpine handles it |
| Cart state | Second state store (Zustand-like) | `Alpine.store('cart')` already exists | Adding a layer adds complexity for no gain |
| Focus trap | Hand-rolled trap logic | Manual Tab key handler (already in product.html size guide) | Copy the existing pattern from product.html lines 213–223 |
| Price re-validation | Re-fetch catalog at checkout | Snapshot from store at submit time | MVP scope; Supabase RLS does not prevent client price injection at this scale |
| Cart item IDs | UUID generation | Composite key `${productId}|${variantId}|${size}` | Already done in cart.js — don't change it |

---

## Common Pitfalls

### Pitfall 1: `$store` shorthand not available in JS methods

**What goes wrong:** Developer writes `const items = $store.cart.items` inside an `async placeOrder()` method in `x-data`. This throws `ReferenceError: $store is not defined`.

**Why it happens:** `$store` is a template magic property injected by Alpine into HTML attribute evaluation contexts. Inside regular JavaScript functions (even those defined in `x-data`), it is not in scope.

**How to avoid:** Use `Alpine.store('cart')` in JavaScript contexts. `$store.cart` only works in HTML attributes like `x-bind`, `x-text`, `x-show`, `@click`.

### Pitfall 2: `style="display:none"` missing on hidden steps

**What goes wrong:** Steps 2, 3, and 4 flash visible for a frame when the page loads before Alpine initializes, causing FOUC.

**Why it happens:** `x-show` toggles `display` after Alpine processes the DOM. Without an initial `style="display:none"`, the element renders visible until Alpine hides it.

**How to avoid:** All `x-show` elements that should be hidden initially must have `style="display:none;"`. This is the established project convention (visible throughout components.js).

### Pitfall 3: Cart drawer `initTree` timing with store

**What goes wrong:** `Alpine.initTree(cartDrawerRoot)` is called before `Alpine.store('cart')` is registered, causing `$store.cart` to reference an undefined store.

**Why it happens:** If `components.js` is loaded before `cart.js` in the module graph, the store doesn't exist when the drawer HTML is processed.

**How to avoid:** The current `<script type="module">` order in all HTML files is: `supabase.js → cart.js → components.js`. Module scripts execute in document order. This order is safe. The cart drawer injection in `components.js` happens after both scripts run. Do not change the script loading order.

**Warning sign:** Console error `Cannot read properties of undefined (reading 'items')` on the cart drawer elements.

### Pitfall 4: Guest order RLS — `user_id` must be explicitly `null`

**What goes wrong:** Guest order INSERT fails with RLS policy violation even though `guest_email` is provided.

**Why it happens:** If `user_id` is omitted from the INSERT payload (not included in the object), Postgres uses the column default (`null`). BUT the RLS `WITH CHECK` evaluates `user_id is null` — which is true for the absent column. Normally this works. The pitfall is if the developer accidentally sets `user_id: undefined` (JavaScript) — this may serialize differently than a true `null` in the JSON body.

**How to avoid:** Always explicitly set `user_id: null` in the INSERT payload for guest orders, not `user_id: undefined` and not omitting the key.

```js
// CORRECT
const payload = { user_id: null, guest_email: this.email, ... };

// RISKY — undefined may serialize to missing key or 'null' depending on JSON.stringify
const payload = { user_id: undefined, guest_email: this.email, ... };
```

### Pitfall 5: Order items INSERT fails silently if `order_id` is wrong

**What goes wrong:** `order_items` INSERT returns no error but no rows are inserted.

**Why it happens:** The RLS policy `order_items_insert_allowed` checks that `order_id` references an order owned by the current user. If the `order_id` is from a different user's order, the INSERT is silently rejected by RLS (Supabase returns empty data, not an error, for RLS-blocked inserts by default).

**How to avoid:** Always use the `order.id` returned from the `orders` INSERT in the same call chain. Do not use a hardcoded or cached order ID. Verify with `.select()` chained to the `orders` INSERT to confirm the row was created.

### Pitfall 6: `loadCartFromSupabase` join query column naming

**What goes wrong:** The nested select query `product_variants!inner(...)` returns columns that may conflict with the outer row's columns.

**Why it happens:** Supabase PostgREST returns nested selects as nested objects. If the developer tries to access `.url` instead of `.product_variants.products.product_images[0].url`, it fails silently.

**How to avoid:** Always destructure the Supabase response by following the nesting: `row.product_variants.products.product_images[0].url`. Test with `console.log(data)` first.

### Pitfall 7: Alpine step transition direction — only enter, not leave

**What goes wrong:** Step transitions feel jerky because only enter transitions are defined, not leave transitions. Or both are defined and they conflict — step 2 enters right while step 1 leaves right, causing both panels to fly off in the same direction.

**How to avoid:** For the step machine, use simple `opacity` transitions only (no translate) to avoid direction confusion. Or use `x-transition` only on enter and let the leave be instant.

```html
<div x-show="step === 2"
     x-transition:enter="transition ease-out duration-200"
     x-transition:enter-start="opacity-0"
     x-transition:enter-end="opacity-100"
     style="display:none;">
```

### Pitfall 8: `mergeGuestCartToSupabase` called on every page load for auth users

**What goes wrong:** On every page load, the auth state change fires `'INITIAL_SESSION'` and the developer calls merge on that event too. This double-writes the localStorage cart to Supabase on every page load, potentially bloating `cart_items` or causing incorrect quantity sums.

**How to avoid:** Only call `mergeGuestCartToSupabase` on `'SIGNED_IN'` event. On `'INITIAL_SESSION'`, call `loadCartFromSupabase` instead (read only, no localStorage merge).

---

## Validation Architecture

### Test Framework

Phase 6 has no automated test framework in scope (no pytest, jest, or vitest configured in this project). Validation is manual + visual.

| Property | Value |
|---|---|
| Framework | None configured |
| Quick run command | Open cart.html in browser |
| Full suite command | Manual walkthrough of 4 checkout steps |

### Phase Requirements → Test Map

| Req | Behavior | Test Type | How to Verify |
|---|---|---|---|
| REQ-6.1 | Mini cart drawer opens when item added | Manual | Add item from product.html, confirm drawer slides in |
| REQ-6.2 | Cart badge updates immediately | Manual | Check nav badge count after add |
| REQ-6.3 | Guest checkout 4 steps complete | Manual | Complete checkout as guest, verify order ID shown |
| REQ-6.4 | Auth user order in Supabase | Manual | Login, add item, checkout, query orders table in Supabase dashboard |
| REQ-6.5 | Cart cleared after order | Manual | Confirm badge shows 0 after step 4 |
| REQ-6.6 | Auth cart merge on login | Manual | Add item as guest, login, confirm item still in cart |
| REQ-6.7 | order_items rows have snapshotted price | Manual | Query order_items in Supabase, verify unit_price matches product page |

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Control |
|---|---|---|
| V4 Access Control | Yes | RLS policies on `orders` and `order_items` — already in schema |
| V5 Input Validation | Yes | Client-side: required fields + email regex; server-side: Supabase `check` constraints on `subtotal >= 0`, `quantity > 0` |
| V6 Cryptography | No | No crypto operations in this phase |
| V2 Authentication | Partial | Guest email is not verified — acceptable for MVP |

### Threat Patterns for this phase

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Client-side price injection | Tampering | MVP: snapshotted from catalog at add-to-cart time; acceptable for assessment. Production: Supabase RPC function with server-side price lookup. |
| Guest order spam | DoS | Acceptable for MVP demo. Production: rate limiting on Netlify Functions or Supabase Edge. |
| Accessing another user's orders | Info Disclosure | RLS `orders_select_own` limits SELECT to `auth.uid() = user_id` — guests cannot read other guests' orders. |
| XSS in order confirmation | Tampering | Order ID is a UUID from Supabase (`order.id`) — safe to render with `x-text`. No `innerHTML`. |

**Security note for auth users and synthetic email:** The `auth.js` module uses `{username}@elvora.local` as a synthetic email for Supabase Auth. At checkout for auth users, use `user_id = user.id` and `guest_email = null`. Do NOT put the synthetic `@elvora.local` address into `guest_email` — it would look like a real email address to order confirmation logic.

---

## Open Questions

1. **Should the nav cart icon open the drawer or navigate to cart.html?**
   - What we know: Currently it's an `<a href="/cart.html">` link
   - What's unclear: UX convention — some premium sites open drawers, others link to cart page
   - Recommendation: Change the nav icon to open the drawer (`@click.prevent="$store.cart.openDrawer()"`); keep `/cart.html` accessible from the drawer's "View Full Cart" link. This follows the premium e-commerce pattern (Alo Yoga, Net-a-Porter).

2. **Should `variant_id` be required in the cart for Supabase sync?**
   - What we know: `cart_items` has `variant_id NOT NULL`. If a product was added from the shop grid (no variant selected), `variantId` may be null in the Alpine store item.
   - What's unclear: Do any "Add to Bag" paths skip variant selection?
   - Recommendation: The PDP `addToBag()` always requires `selectedSize` before proceeding. The shop grid "Add to Cart" quick-add (if any) should also require variant selection. Filter out items without `variantId` in `mergeGuestCartToSupabase` with a log warning.

3. **Shipping cost calculation?**
   - What we know: The schema has no shipping cost column on orders.
   - What's unclear: Should a flat shipping fee be applied?
   - Recommendation: For MVP, display "Free Shipping" on all orders. `subtotal` in `orders` reflects the cart total only. No shipping line item needed.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Multi-page checkout (separate URLs) | Single-page step machine (Alpine state) | No full page reloads; URL stays at /checkout.html |
| Page-level cart persistence | Store-level `Alpine.store` | Cart accessible from any component on the same page |
| Separate cart sync on every mutation | Login-triggered bulk sync | Simpler code, fewer Supabase calls |

---

## Sources

### Primary (HIGH confidence)

- Codebase: `/Users/andika/Desktop/Elvora/js/cart.js` — confirmed store API, localStorage pattern [VERIFIED: codebase]
- Codebase: `/Users/andika/Desktop/Elvora/js/components.js` — confirmed injection pattern, `Alpine.initTree` usage [VERIFIED: codebase]
- Codebase: `/Users/andika/Desktop/Elvora/product.html` — confirmed `addToBag()`, `Alpine.store('cart').add()`, Toastify usage [VERIFIED: codebase]
- Codebase: `/Users/andika/Desktop/Elvora/supabase/migrations/001_schema.sql` — confirmed `orders`, `order_items`, `cart_items` table shapes and RLS policies [VERIFIED: codebase]
- Codebase: `/Users/andika/Desktop/Elvora/src/input.css` — confirmed design tokens, existing component class patterns [VERIFIED: codebase]
- Codebase: `/Users/andika/Desktop/Elvora/js/auth.js` — confirmed `onAuthChange` wrapper API and synthetic email pattern [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- Alpine.js docs — `x-show`, `x-transition`, `Alpine.store`, `Alpine.effect`, `$nextTick` [CITED: https://alpinejs.dev/globals/alpine-store]
- Supabase JS v2 docs — `onAuthStateChange` event names (`SIGNED_IN`, `INITIAL_SESSION`) [CITED: https://supabase.com/docs/reference/javascript/auth-onsessionchanged]
- Supabase JS v2 docs — `upsert` with `onConflict` option [CITED: https://supabase.com/docs/reference/javascript/upsert]

### Tertiary (LOW confidence / ASSUMED)

- `Alpine.effect` availability in Alpine 3.15.12 — documented in Alpine 3 changelog [ASSUMED]
- `onAuthStateChange` `event` parameter values (`'SIGNED_IN'`, `'INITIAL_SESSION'`, `'SIGNED_OUT'`) — based on Supabase JS v2 API surface [ASSUMED: verify against actual SDK behavior if auth events don't fire as expected]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `onAuthStateChange` passes `event` as first argument; current `onAuthChange` wrapper in auth.js discards it and must be updated | Q3, Q10 | Merge logic could trigger on every page load instead of only on sign-in; double-merge |
| A2 | `Alpine.effect` is available globally in Alpine 3.15.12 as a global function (not just in `x-data` context) | Q10 | Effect-based cart count title sync would fail; minor feature, skip if broken |
| A3 | Supabase JS upsert with `onConflict: 'user_id,variant_id'` (composite conflict target) works with PostgREST endpoint | Q3 | Merge would need to be done manually (delete + insert) instead of upsert |

---

## Metadata

**Confidence breakdown:**

- Mini cart drawer pattern: HIGH — identical to existing mobile nav drawer in components.js
- Order creation sequence: HIGH — schema confirms foreign key constraint; RLS policies confirmed in SQL
- Guest-to-auth merge: HIGH — onAuthStateChange is documented Supabase JS v2 API
- CSS classes: HIGH — follows established patterns from existing input.css
- Price snapshot integrity: HIGH — confirmed by schema comment in 001_schema.sql
- `Alpine.effect` global availability: MEDIUM — documented but not verified against 3.15.12 specifically

**Research date:** 2026-06-16
**Valid until:** 2026-07-16 (Alpine and Supabase JS are stable; Tailwind v4 is stable)
