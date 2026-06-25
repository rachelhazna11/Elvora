---
plan: 06-02
phase: 06-cart-checkout
status: complete
completed_at: "2026-06-16"
---

# Summary: Plan 06-02 — cart.js + auth.js Extensions

## What Was Built

Three JS files were extended to enable cart drawer state management and Supabase sync:

**`js/cart.js`** — Extended Alpine.store('cart') with:
- `cartDrawerOpen` state (boolean, default false)
- `openDrawer()` / `closeDrawer()` methods
- `loadFromStorage()` exported (was private)
- `mergeGuestCartToSupabase(userId)` — moves localStorage items to Supabase `cart_items` table, deduplicating by product+variant
- `loadCartFromSupabase(userId)` — fetches Supabase cart rows with JOIN to `products` + `product_images` (url, display_order), populates Alpine store items

**`js/auth.js`** — `onAuthChange(callback)` now passes the Supabase event name as second argument to all callbacks: `cb(user, event)` instead of `cb(user)`.

**`js/components.js`** — `initAuth` wiring extended:
- `SIGNED_IN` → trigger `mergeGuestCartToSupabase(user.id)`
- `INITIAL_SESSION` → trigger `loadCartFromSupabase(user.id)`
- Sign-out → `Alpine.store('cart').loadFromStorage()` to restore localStorage cart

## Key Files

- **Modified**: `js/cart.js` (+96 lines), `js/auth.js` (+3 lines), `js/components.js` (+16 lines)

## Deviations

- `loadCartFromSupabase` joins `product_images` on `display_order` to pick primary image URL — not in plan but needed for cart drawer thumbnails.

## Self-Check: PASSED

- ✅ `cartDrawerOpen`, `openDrawer`, `closeDrawer` on Alpine.store('cart')
- ✅ `mergeGuestCartToSupabase`, `loadCartFromSupabase`, `loadFromStorage` exported
- ✅ `onAuthChange` passes event as second arg to callbacks
- ✅ `components.js` wires SIGNED_IN → merge, INITIAL_SESSION → load, sign-out → localStorage
