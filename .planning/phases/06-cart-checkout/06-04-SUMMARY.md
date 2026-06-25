---
plan: 06-04
phase: 06-cart-checkout
status: complete
completed_at: "2026-06-16"
duration_minutes: 1
tasks_completed: 1
tasks_total: 1
files_modified: 1
requires: [06-01, 06-02]
provides: [cart-page-ui]
affects: [cart.html]
tech_stack_added: []
tech_stack_patterns: [alpine-store, x-for, x-show, x-data]
key_files_created: []
key_files_modified:
  - cart.html
decisions:
  - "Span style digabung jadi satu atribut (Rule 1 fix: duplicate style attr tidak valid HTML)"
requirements_satisfied: [F-021]
---

# Phase 6 Plan 04: Full Cart Page — cart.html Implementation Summary

## One-liner

Cart page lengkap dengan items list, qty stepper, remove, empty state, dan order summary sidebar — semua terhubung ke `Alpine.store('cart')`.

## What Was Built

`cart.html` diupdate dari stub `<main><!-- Phase 6 fills this --></main>` menjadi markup cart page penuh:

**Empty state** (ditampilkan saat `$store.cart.items.length === 0`):
- SVG bag icon
- Heading "Your bag is empty"
- Deskripsi teks ajakan belanja
- CTA "Shop Now" → `/shop.html`

**Cart layout grid** (ditampilkan saat items ada):
- Kolom kiri: daftar items dengan `x-for`
  - Gambar produk dengan fallback div sage-light jika tidak ada gambar
  - Nama produk, varian (colour / size)
  - Qty stepper: tombol `−` / display `qty` / tombol `+`
  - Tombol "Remove"
  - Line total: `Rp (price × qty).toLocaleString('id-ID')`
- Kolom kanan: order summary sidebar
  - Subtotal → `$store.cart.totalFormatted`
  - Shipping → "Free"
  - Total → `$store.cart.totalFormatted`
  - CTA "Proceed to Checkout" → `/checkout.html`
- Link "Continue Shopping" → `/shop.html`

**Item count badge** di heading h1 (hanya tampil jika `count > 0`).

Semua Alpine expressions membaca dari `$store.cart` — tidak ada local component state.

## Key Files

**Modified:**
- `cart.html` (+130 lines, -1 line) — stub `<main>` diganti markup penuh

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Duplicate `style` attribute pada `<span>` item count**
- **Found during:** Task 1 implementasi
- **Issue:** Plan asal memiliki dua atribut `style` pada elemen `<span>` — browser hanya membaca atribut pertama, Alpine tidak bisa menimpa styling dengan `display:none` yang diperlukan
- **Fix:** Gabungkan kedua value style ke dalam satu atribut, dengan `display:none;` diinclude di dalamnya
- **Files modified:** `cart.html`
- **Commit:** ed4ffcc

## Commits

| Task | Deskripsi | Commit | File |
|------|-----------|--------|------|
| 1 | implementasi cart page penuh di cart.html | ed4ffcc | cart.html |

## Threat Flags

Tidak ada surface baru yang diperkenalkan — ini adalah markup HTML client-side saja, tidak ada endpoint baru, tidak ada auth path baru, tidak ada akses file system.

## Self-Check: PASSED

- [x] `cart.html` `<main>` memiliki `x-data` dan `class="cart-page"`
- [x] Empty state dengan `x-show="$store.cart.items.length === 0"` dan `style="display:none;"`
- [x] Cart grid dengan `x-show="$store.cart.items.length > 0"` dan `style="display:none;"`
- [x] `<template x-for="item in $store.cart.items" :key="item.key">` hadir
- [x] Qty stepper: `setQty(item.key, item.qty - 1)` dan `setQty(item.key, item.qty + 1)`
- [x] Remove button: `@click="$store.cart.remove(item.key)"`
- [x] Line total: `(item.price * item.qty).toLocaleString('id-ID')`
- [x] `$store.cart.totalFormatted` untuk subtotal dan total
- [x] "Proceed to Checkout" → `/checkout.html`
- [x] "Continue Shopping" → `/shop.html`
- [x] Empty state "Shop Now" → `/shop.html`
- [x] Stub comment `<!-- Phase 6 fills this -->` sudah tidak ada
- [x] Commit `ed4ffcc` ada di git log
