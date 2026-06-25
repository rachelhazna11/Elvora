---
phase: 04-auth-customer-account
plan: "03"
subsystem: auth
tags: [alpine, supabase, toastify, auth, forms, split-layout]

requires:
  - phase: 04-02
    provides: window.signIn, window.signUp, window.elvoraSignOut (js/auth.js) + Alpine.store('auth') init in components.js
  - phase: 04-01
    provides: CSS Phase 4 component classes (.auth-page, .auth-panel-left, .auth-panel-right, .auth-form-wrap, .auth-tabs, .auth-tab, .auth-form-title, .auth-form-sub, .auth-name-row, .auth-forgot, .auth-switch-link, .auth-panel-overlay, .auth-wordmark, .auth-tagline, .auth-panel-content) in src/input.css

provides:
  - "auth.html — complete editorial split layout + tabbed Sign In / Create Account form wired to js/auth.js"
  - "handleSignIn() Alpine function: calls window.signIn(), redirects to account.html on success"
  - "handleSignUp() Alpine function: calls window.signUp(), shows personalized Welcome toast, redirects to account.html"
  - "?tab=signup deep-link: URL param sets active tab on load for guest heart redirect (D-11)"
  - "Already-logged-in redirect: init() checks supabase.auth.getUser() and bounces to account.html"

affects: [account.html, nav dropdown, Phase 5 cart checkout, Style Match page]

tech-stack:
  added: [Toastify CDN (toastify-js) added to auth.html head]
  patterns:
    - "Alpine x-data on inner form wrapper (not on <main>) for scoped auth state"
    - "x-show tab toggle with transition-opacity duration-150 for form panels"
    - "Generic error message for sign-in failure (T-04-03-01 mitigation — never discloses email-not-found vs wrong-password)"
    - "style=font-size:16px on all <input> elements prevents iOS Safari auto-zoom"

key-files:
  created: []
  modified:
    - auth.html

key-decisions:
  - "Toastify CDN ditambahkan langsung ke auth.html head (tidak menggangu halaman lain) — pola sama dengan product.html"
  - "Forgot password link mengarah ke Supabase hosted UI (https://elvorastudio.supabase.co) — tidak perlu halaman custom Phase 4"
  - "x-data ditempatkan pada .auth-form-wrap bukan pada <main> — scoping Alpine state lebih ketat, consistent dengan D-01"
  - "Password validation urutan: length check DULU (< 8 chars) baru mismatch check — mengikuti urutan plan task action"

patterns-established:
  - "auth.html: Alpine x-data pada inner wrapper div, bukan elemen semantik luar"
  - "Error display: paragraph dengan x-show='error && tab===<panel>' + role='alert' + display:none initial"
  - "Tab toggle: @click set tab + reset error, x-show on panel div, style=display:none pada panel non-aktif untuk SSR"

requirements-completed:
  - F-025
  - F-026

duration: 12min
completed: 2026-06-15
---

# Phase 04 Plan 03: Auth Page (auth.html) Summary

**Editorial split layout dengan Unsplash lifestyle photo panel kiri + tabbed Alpine form (Sign In / Create Account) terhubung ke window.signIn/signUp dari js/auth.js — auth flow end-to-end fungsional**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-06-15T17:18:00Z
- **Completed:** 2026-06-15T17:30:00Z
- **Tasks:** 1 dari 1
- **Files modified:** 1

## Accomplishments

- Halaman auth.html lengkap: left panel editorial (Unsplash activewear photo, ELVORA wordmark Playfair Display italic, MOVE BEAUTIFULLY tagline) + right panel form pada background --beige
- Tab toggle Sign In / Create Account via Alpine x-show tanpa page reload; ?tab=signup deep-link berfungsi di init()
- Sign In form memanggil window.signIn(), error generic (T-04-03-01), redirect ke account.html on success
- Create Account form memanggil window.signUp() dengan first/last/email/password; success menampilkan Toastify "Welcome to Elvora, [first_name]!" lalu redirect ke account.html
- Inline error messages (bukan toast) dengan role="alert" dan warna var(--rose) untuk semua validation state
- Client-side validation: min 8 chars sebelum submit, mismatch check on blur di confirm field
- Loading state pada kedua submit buttons (Signing In… / Creating Account…, disabled)
- Already-logged-in guard di init() via window.supabase.auth.getUser()

## Task Commits

1. **Task 1: Build auth.html — editorial split layout + tab toggle + sign in/up forms** - `e039f6c` (feat)

**Plan metadata:** _(akan di-commit setelah SUMMARY ini)_

## Files Created/Modified

- `/Users/andika/Desktop/Elvora/auth.html` — Diisi dari shell kosong menjadi halaman auth lengkap: editorial split layout, tabbed Alpine form, CDN Toastify, import auth.js

## Decisions Made

- Toastify CDN ditambahkan ke `auth.html` head (pola identik dengan `product.html`) — CDN sudah ada di project, tidak ada package install baru
- `Forgot password?` link mengarah ke `https://elvorastudio.supabase.co` (Supabase hosted reset flow) sesuai spec — tidak perlu halaman custom untuk Phase 4
- x-data ditempatkan pada `.auth-form-wrap` (inner div) bukan `<main>` — scoping lebih bersih, sesuai dengan plan task action
- Label PASSWORD dan Forgot password diletakkan dalam satu flex row (justify-content: space-between) untuk tampilan yang rapi tanpa float yang mengganggu layout form
- `js/auth.js` diimpor di module script block (sudah expose window.signIn/signUp sebagai side effect)

## Deviations from Plan

Tidak ada — plan dieksekusi tepat seperti yang tertulis.

Satu minor adjustment kosmetik: dalam PLAN.md, `auth-forgot` label menggunakan `float: right` untuk posisi Forgot password. Implementasi menggunakan flexbox row (`display:flex; justify-content:space-between`) pada container label + link karena lebih bersih dan tidak mengganggu layout form-group. Ini bukan perubahan fungsional — hasil visual identik.

## Issues Encountered

Tidak ada — semua window.signIn / window.signUp sudah tersedia dari Plan 04-02, CDN Toastify sudah ada di product.html sebagai referensi, dan CSS auth classes sudah ditambahkan di Plan 04-01.

## User Setup Required

Tidak ada — tidak ada konfigurasi external service tambahan untuk halaman ini.

## Next Phase Readiness

- auth.html siap diakses oleh pengguna; flow registrasi dan login end-to-end fungsional
- Plan 04-04 (account.html) dapat mulai: sidebar + Profile/Wishlist/Preferences panels
- Plan 04-05 (wishlist heart toggle di PLP/PDP) dapat mulai setelah auth siap
- `?tab=signup` deep-link sudah siap untuk D-11 (guest heart redirect dari shop.html/product.html)

---
*Phase: 04-auth-customer-account*
*Completed: 2026-06-15*
