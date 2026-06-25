---
phase: 04-auth-customer-account
plan: "02"
subsystem: auth-service
tags: [auth, alpine-store, nav-dropdown, supabase-auth, FOUC-prevention]
dependency_graph:
  requires:
    - 04-01 (CSS classes nav-user-trigger, nav-dropdown, nav-dropdown-item, nav-dropdown-divider)
    - js/supabase.js (singleton Supabase client)
  provides:
    - js/auth.js (5 auth functions: signUp, signIn, signOut, getUser, onAuthChange)
    - window.signIn, window.signUp, window.elvoraSignOut
    - components.js initAuth() (auth state on every page)
    - Alpine.store('auth').user + loggedIn (populated from live session)
    - Nav logged-in dropdown (desktop + mobile)
  affects:
    - Semua halaman (initAuth() jalan via components.js)
    - auth.html (Plan 04-03 menggunakan window.signIn + window.signUp)
    - account.html (Plan 04-04 menggunakan Alpine.store('auth').user)
    - shop.html + product.html (Plan 04-05 wishlist menggunakan $store.auth.loggedIn)
tech_stack:
  added: []
  patterns:
    - "Supabase Auth: signUp/signInWithPassword/signOut/getUser/onAuthStateChange"
    - "user_profiles upsert dengan PK 'id' (bukan user_id) + onConflict:'id'"
    - "Alpine.store reactivity: mutasi langsung .user + .loggedIn"
    - "FOUC prevention: style='display:none;' pada logged-in wrapper + dropdown"
    - "window exposure pattern: window.elvoraSignOut = signOut (hindari naming conflict)"
key_files:
  created: []
  modified:
    - js/auth.js
    - js/components.js
decisions:
  - "Schema correction: user_profiles PK adalah 'id' bukan 'user_id' (per PLAN must_haves)"
  - "Profile upsert error dicatch secara terpisah — auth succeed tidak diblock oleh profile failure"
  - "window.elvoraSignOut (bukan window.signOut) untuk hindari konflik dengan nama global"
  - "initAuth() dipanggil di kedua jalur (alpine:init event dan direct window.Alpine check)"
  - "x-text digunakan untuk first_name (bukan x-html) — mencegah XSS per threat T-04-02-02"
metrics:
  duration: "~12 menit"
  completed_date: "2026-06-15"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
---

# Phase 04 Plan 02: Auth Service + Nav Dropdown Summary

**One-liner:** Implementasi 5 fungsi Supabase Auth di `js/auth.js` dengan schema correction PK `id` + nav logged-in dropdown via `initAuth()` di `components.js`.

## What Was Built

### Task 1: js/auth.js — 5 Auth Functions (commit `7d142c9`)

Semua stub diganti dengan implementasi lengkap:

| Fungsi | Supabase Call | Behavior |
|--------|--------------|---------|
| `signUp(email, password, firstName, lastName)` | `auth.signUp()` | Auth user dibuat + upsert `user_profiles` (PK: `id`) |
| `signIn(email, password)` | `auth.signInWithPassword()` | Throws on error |
| `signOut()` | `auth.signOut()` | Throws on error; exposed sebagai `window.elvoraSignOut` |
| `getUser()` | `auth.getUser()` | Returns user atau null |
| `onAuthChange(callback)` | `auth.onAuthStateChange()` | Returns subscription handle |

**Schema correction diterapkan:** `user_profiles` diisi dengan `{ id: data.user.id }` (bukan `user_id`) sesuai PLAN must_haves. Profile upsert menggunakan `onConflict: 'id'` untuk idempotency.

**Window exposure:** `window.signIn`, `window.signUp`, `window.elvoraSignOut` — untuk Alpine inline x-data di halaman manapun.

### Task 2: js/components.js — initAuth() + Nav Dropdown (commit `594d623`)

**Perubahan 1 — Import + initAuth():**
- Import `{ getUser, onAuthChange }` dari `./auth.js` ditambah di atas file
- `initAuth()`: populate `Alpine.store('auth').user` dan `.loggedIn` dari session live, subscribe perubahan via `onAuthChange`
- Event listener diupdate: `document.addEventListener('alpine:init', () => { registerStores(); initAuth(); })`
- Direct path: `if (window.Alpine) { registerStores(); initAuth(); }`

**Perubahan 2 — Desktop nav account area:**
- Guest state: `<a x-show="!$store.auth.loggedIn" href="/auth.html">` (visible default)
- Logged-in wrapper: `x-show="$store.auth.loggedIn" style="display:none;"` (FOUC prevention)
- Trigger button: person SVG + `x-text` first name + `userDropOpen` toggle
- Dropdown: My Account → `/account.html`, Wishlist → `/account.html#wishlist`, Sign Out → `window.elvoraSignOut()`
- Nav x-data: `userDropOpen: false` ditambah

**Perubahan 3 — Mobile drawer account area:**
- Guest: plain `<a href="/auth.html">` dengan SVG
- Logged-in (`style="display:none;"`): link langsung ke `/account.html` + first name text (tanpa dropdown di mobile)

## Deviations from Plan

None — plan dieksekusi persis sesuai spesifikasi.

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|-----------|
| T-04-02-01 | Error Supabase di-throw as-is dari signIn; auth.html (Plan 03) yang mapping ke pesan generik |
| T-04-02-02 | `x-text` (bukan `x-html`) untuk first_name di nav — Alpine auto-escape HTML, tidak ada XSS |
| T-04-02-05 | Profile upsert error dicatch secara terpisah; auth tidak diblock jika profile upsert gagal |

## Known Stubs

None — semua fungsi auth diimplementasi penuh. Tidak ada placeholder atau hardcoded empty values.

## Self-Check: PASSED

- js/auth.js: FOUND
- js/components.js: FOUND
- 04-02-SUMMARY.md: FOUND
- commit 7d142c9: FOUND
- commit 594d623: FOUND
