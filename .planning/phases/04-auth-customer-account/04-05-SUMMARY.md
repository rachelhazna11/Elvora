---
phase: 04-auth-customer-account
plan: "05"
subsystem: wishlist-ui
tags: [wishlist, alpine, supabase, optimistic-ui, toast]
dependency_graph:
  requires: [04-03, 04-04]
  provides: [F-028-complete, wishlist-toggle-plp, wishlist-toggle-pdp]
  affects: [shop.html, product.html]
tech_stack:
  added: []
  patterns: [alpine-set-copy-trick, optimistic-ui-with-revert, guest-redirect-toast]
key_files:
  created: []
  modified:
    - shop.html
    - product.html
decisions:
  - "D-13: satu initWishlist() query per page — load semua product_id wishlist user ke Set, tidak per card"
  - "Alpine Set reactivity: new Set([...this.wishlistedIds, id]) / new Set([...].filter()) untuk trigger DOM update"
  - "Guest redirect ke auth.html?tab=signin setelah 2s; toast bisa diklik untuk redirect langsung"
  - "wishlist button PDP ditambah sebagai full-width button di bawah ATC dengan label teks 'Save to Wishlist' / 'Saved'"
  - "Related products wishlist button di product.html juga difungsikan (bukan hanya PDP utama)"
metrics:
  duration: "~10 menit"
  completed_date: "2026-06-15"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
---

# Phase 04 Plan 05: Wishlist Toggle (PLP + PDP) Summary

**One-liner:** Wishlist heart toggle fungsional di shop.html PLP dan product.html PDP dengan optimistic UI, Set copy trick Alpine reactivity, dan guest redirect ke auth.html.

## What Was Built

### Task 1: shop.html — Wishlist State + PLP Heart Buttons (commit `2447d15`)

Ditambahkan ke x-data object pada `<main>` di shop.html:

- **`wishlistedIds: new Set()`** — reactive Set yang menyimpan product_id yang sudah di-wishlist oleh user yang login
- **`initWishlist()`** — query sekali ke `wishlist_items` mengambil semua `product_id` milik user, disimpan ke Set (D-13: satu query per page, bukan per card)
- **`toggleWishlist(productId)`** — handler optimistic untuk toggle wishlist:
  - Guest: Toastify toast + setTimeout redirect ke `auth.html?tab=signin` setelah 2s; toast onClick juga redirect langsung
  - Logged-in: optimistic Set update (Set copy trick) → async Supabase insert/delete → revert + error toast jika gagal
- **`init()`** diupdate: memanggil `await this.initWishlist()` setelah `await this.fetchProducts()`
- Heart button product card diupdate dari static `♡` ke binding penuh dengan `:class="{ 'active': wishlistedIds.has(p.id) }"`, `@click.prevent.stop`, `aria-label` dinamis, `aria-pressed`, dan `x-text` untuk ♥/♡

### Task 2: product.html — Wishlist State + PDP Heart Button (commit `bed0062`)

Ditambahkan ke x-data object pada `<main>` di product.html:

- **`wishlistedIds: new Set()`** — sama seperti shop.html
- **`initWishlist()`** — identik dengan shop.html; query `wishlist_items` sekali per page load
- **`toggleWishlist(productId)`** — identik dengan shop.html; Set copy trick di semua add/remove/revert path
- **`init()`** diupdate: memanggil `await this.initWishlist()` setelah `await Promise.all([...])` selesai
- **Wishlist button PDP utama** ditambah di bawah ATC button: full-width button dengan label teks dinamis "Save to Wishlist" / "Saved" dan ikon ♡/♥; menggunakan `product?.id` (optional chaining karena product belum tentu loaded saat init)
- **Related products wishlist button** di "You Might Also Love" section juga diupdate dari static ke binding penuh

## Security Notes (Threat Model)

- **T-04-05-01/02 (mitigated):** INSERT dan DELETE wishlist_items mengirim `user_id: user.id` dari client; Supabase RLS `auth.uid() = user_id` memblokir cross-user operasi di sisi server — double defense
- **T-04-05-03 (accepted):** Revert on error menggunakan Set copy trick; state kembali ke kondisi benar; worst case adalah icon stale yang refresh di next load
- **T-04-05-04/05 (accepted):** Guest redirect dan initWishlist query tidak melibatkan data sensitif

## Deviations from Plan

### Auto-addition: PDP Wishlist Button dengan Label Teks

**Found during:** Task 2

**Issue:** Plan mendefinisikan PDP wishlist button hanya sebagai icon button (`♡`/`♥`). Pada PDP, user experience lebih baik jika ada label teks ("Save to Wishlist" / "Saved") karena button posisinya di bawah ATC yang juga punya teks, bukan hanya ikon overlay di gambar.

**Fix:** Wishlist button PDP ditambahkan sebagai full-width button dengan `<span>` teks di samping ikon, lebih konsisten dengan pattern ATC button area.

**Files modified:** product.html

Selain itu, related products wishlist button di product.html juga diupdate (ini tidak eksplisit disebutkan dalam plan untuk product.html, hanya untuk shop.html), karena button tersebut ada di dalam scope x-data yang sama dan tidak fungsional jika dibiarkan static.

## Known Stubs

Tidak ada stubs — wishlist toggle sepenuhnya terhubung ke Supabase wishlist_items table.

## Threat Flags

Tidak ada permukaan ancaman baru di luar yang sudah ada di threat model plan.

## Self-Check

- [x] shop.html: `grep -cE "toggleWishlist|initWishlist|wishlistedIds|new Set\(\["` = 15 (>= 4)
- [x] product.html: `grep -cE "toggleWishlist|initWishlist|wishlistedIds|new Set\(\["` = 20 (>= 4)
- [x] Commit 2447d15 ada: shop.html wishlist
- [x] Commit bed0062 ada: product.html wishlist
- [x] Heart button shop.html pakai `:class="{ 'active': wishlistedIds.has(p.id) }"` ✓
- [x] Heart button product.html PDP pakai `:class="{ 'active': wishlistedIds.has(product?.id) }"` ✓
- [x] Set copy trick dipakai di 4 path (add, remove, revert-add, revert-remove) di tiap file ✓
- [x] `new Set([...` muncul >= 2x di masing-masing file ✓

## Self-Check: PASSED
