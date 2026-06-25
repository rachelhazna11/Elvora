---
phase: 06-cart-checkout
plan: "05"
subsystem: ui
tags: [alpine.js, supabase, checkout, orders, rls, state-machine]

requires:
  - phase: 06-01
    provides: checkout CSS classes (checkout-page, step-dot, step-connector, payment-card-mock, dll)
  - phase: 06-03
    provides: Alpine.store('cart') dengan items, total, totalFormatted, clear(); Alpine.store('auth')

provides:
  - "checkout.html full 4-step checkout state machine via Alpine.js checkoutData()"
  - "Guest checkout: user_id=null + guest_email (bukan synthetic @elvora.local)"
  - "Auth checkout: user_id=user.id, tanpa guest_email"
  - "Supabase orders + order_items insert dengan snapshot product_name, variant_label, unit_price"
  - "Cart clear setelah order berhasil (Alpine store + localStorage + Supabase cart_items)"
  - "Step indicator dots done/active/pending class bindings 1-indexed"
  - "Order summary sidebar tersembunyi di step 4 (confirmation)"
  - "@keyframes spin untuk loading spinner"

affects: [07-style-match, phase-06-verification]

tech-stack:
  added: []
  patterns:
    - "window.checkoutData() function pattern untuk hindari Alpine x-data escaping complexity"
    - "RLS-safe order insert: guest user_id=null explicit, auth user set user_id, tidak keduanya sekaligus"
    - "Insert orders first (FK), lalu order_items dengan returned order.id"
    - "style='display:none;' + x-show untuk sembunyikan konten sebelum Alpine init (CLS prevention)"

key-files:
  created: []
  modified:
    - checkout.html
    - src/input.css

key-decisions:
  - "window.checkoutData() pattern (bukan inline x-data string) untuk hindari single-quote escaping complexity di HTML attribute"
  - "Guest email TIDAK di-prefill di init() — synthetic @elvora.local dari auth.js tidak boleh masuk guest_email"
  - "user_id=null EKSPLISIT (bukan undefined/omit) untuk guest orders sesuai RLS requirement"
  - "Cart clear urutan: Alpine.store clear dulu → Supabase cart_items delete (auth only) → step=4"
  - "@keyframes spin ditambah di luar @layer di akhir src/input.css, setelah Phase 6 responsive block"

requirements-completed: [F-022, F-023, F-024]

duration: 8min
completed: 2026-06-16
---

# Phase 06 Plan 05: Checkout Page Summary

**Checkout 4-step Alpine.js state machine (Shipping → Review → Payment → Confirmation) dengan Supabase order + order_items insert, RLS-compliant guest/auth payload, dan cart clear on confirmation**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-16T16:24:00Z
- **Completed:** 2026-06-16T16:32:32Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Implementasi `checkout.html` penuh: ganti stub `<!-- Phase 6 fills this -->` dengan full Alpine.js state machine 4 langkah
- `checkoutData()` menangani guest dan auth secara terpisah — RLS rules Supabase dipatuhi ketat (user_id=null eksplisit untuk guest, tidak ada guest_email untuk auth user)
- Insert ke tabel `orders` dulu lalu `order_items` dengan FK `order_id` dari hasil insert pertama; snapshot `product_name`, `variant_label`, `unit_price` di order_items
- Cart di-clear setelah order berhasil: `Alpine.store('cart').clear()` + localStorage + Supabase `cart_items` delete (auth only)
- Step indicator via `x-for` dengan class bindings 1-indexed: `.done` (i+1 < step), `.active` (i+1 === step), `.pending` (i+1 > step)
- Order summary sidebar dengan `x-show="step < 4"` — tersembunyi di step konfirmasi; mini preview 3 item pertama + "+N more"
- Confirmation page menampilkan order reference `orderId.slice(-8).toUpperCase()` dan guest upsell non-blocking

## Task Commits

1. **Task 1: Replace main stub + add checkoutData() function** - `901b184` (feat)

## Files Created/Modified

- `checkout.html` - Full 4-step checkout page: `<main x-data="checkoutData()">`, step indicator, Step 1 shipping form, Step 2 review, Step 3 payment mock, Step 4 confirmation; `checkoutData()` function di `<script>` block
- `src/input.css` - Tambah `@keyframes spin` untuk loading spinner; CSS direbuild

## Decisions Made

- **window.checkoutData() pattern**: Daripada inline `x-data` string raksasa dengan escaping masalah, fungsi `checkoutData()` didefinisikan di `<script>` block dan dipanggil via `x-data="checkoutData()"` — lebih bersih dan mudah dibaca
- **Guest email tidak di-prefill**: `init()` hanya mengisi `firstName`/`lastName` dari auth metadata — email TIDAK diisi karena synthetic `@elvora.local` dari auth.js tidak boleh muncul di `guest_email` Supabase
- **user_id=null eksplisit**: Untuk guest orders, `orderPayload.user_id = null` ditulis eksplisit (bukan undefined/omit) sesuai RLS constraint
- **Cart clear setelah orderId disimpan**: `this.orderId = order.id` disimpan sebelum `Alpine.store('cart').clear()` dipanggil agar confirmation page bisa tampilkan reference

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - tidak ada konfigurasi external service yang diperlukan untuk plan ini. Supabase `orders` dan `order_items` tables sudah ada dari Phase 01 schema migration.

## Next Phase Readiness

- Phase 06 selesai seluruhnya — checkout flow lengkap dari cart drawer (06-03) hingga order confirmation (06-05)
- Phase 07 (AI Style Match) bisa dimulai; tidak ada dependency dari plan ini
- Verifikasi end-to-end checkout flow disarankan sebelum deployment: guest checkout + auth checkout + order tersimpan di Supabase

## Self-Check: PASSED

- checkout.html: FOUND
- src/input.css: FOUND
- 06-05-SUMMARY.md: FOUND
- Commit 901b184: FOUND
- Stub `<!-- Phase 6 fills this -->` tidak ada lagi di checkout.html: OK

---
*Phase: 06-cart-checkout*
*Completed: 2026-06-16*
