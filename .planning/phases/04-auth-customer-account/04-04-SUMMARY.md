---
phase: 04-auth-customer-account
plan: "04"
subsystem: auth
tags: [alpine, supabase, wishlist, user-profiles, account-dashboard]

requires:
  - phase: 04-01
    provides: CSS classes Phase 4 (account-page, account-layout, account-sidebar, account-nav, prefs-chip, wishlist-grid, dll.)
  - phase: 04-02
    provides: js/auth.js (window.elvoraSignOut, window.supabase), Alpine.store auth, schema user_profiles dengan PK 'id'
  - phase: 04-03
    provides: auth.html selesai; pattern Toastify CDN di head; pattern module script block

provides:
  - account.html: dashboard 3-section dengan sidebar tab navigation
  - init() auth guard: redirect ke auth.html?tab=signin jika tidak login
  - loadProfile(user): baca user_profiles via .eq('id', user.id)
  - saveProfile(): update first_name/last_name via .eq('id', user.id)
  - loadWishlist(user): baca wishlist_items JOIN products
  - removeFromWishlist(wishlistId): optimistic delete wishlist item
  - savePrefs(): update preferred_activity/fit_preference/style_aesthetic/colour_preference
  - supabase/migrations/003_phase4_user_profiles.sql: DDL migration 4 kolom preference

affects: [05-cart-checkout, 07-ai-style-match]

tech-stack:
  added: []
  patterns:
    - "Promise.all([loadProfile, loadWishlist]) di init() — parallel data load pattern"
    - "Optimistic UI remove: simpan prev array, filter optimistically, revert jika error"
    - "Hash-driven tab navigation: location.hash.replace('#','') dibaca di init(), location.hash = tab di setTab()"
    - "Chip single-select toggle: prefs.activity === val ? null : val — deselect jika sama"

key-files:
  created: []
  modified:
    - account.html
    - supabase/migrations/003_phase4_user_profiles.sql

key-decisions:
  - "Tidak ada id='profile/wishlist/preferences' pada panel section — mencegah browser scroll-to-anchor saat tab switch (RESEARCH Pitfall 4)"
  - "loadWishlist menggunakan .eq('user_id', user.id) — wishlist_items pakai kolom user_id; user_profiles pakai PK 'id'"
  - "Fallback loadProfile: jika row user_profiles belum ada, isi dari user.user_metadata (user baru yang belum diproses trigger)"
  - "Migration file bernama 003 (bukan 002) karena 002 sudah dipakai Phase 03 — developer apply via Supabase Dashboard SQL Editor"

patterns-established:
  - "account.html x-data: init() auth guard + hash tab + Promise.all parallel load"
  - "Chip selector pattern: type=button, :class selected, @click toggle null"

requirements-completed:
  - F-027
  - F-028
  - F-029

duration: ~15min
completed: "2026-06-15"
---

# Phase 04 Plan 04: Account Dashboard Summary

**Account dashboard Alpine.js dengan sidebar 3-tab (Profile/Wishlist/Style Preferences), optimistic wishlist remove, dan chip selector preferences yang menulis ke 4 kolom Supabase user_profiles.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-15T17:30:00Z
- **Completed:** 2026-06-15T17:41:00Z
- **Tasks:** 2 (Task 1 selesai di sesi sebelumnya; Task 2 di sesi ini)
- **Files modified:** 1 (account.html — migration file dari Task 1 sudah ada)

## Accomplishments

- account.html dibangun penuh dari shell kosong menjadi dashboard 3-section lengkap
- Auth guard aktif: init() cek getUser() → redirect ke auth.html?tab=signin jika null
- Profile section: form editable first/last name + email read-only, saveProfile() via .eq('id')
- Wishlist section: grid 3-kolom dengan optimistic remove (array revert on error) + empty state
- Style Preferences section: 4 chip-selector rows (activity/fit/aesthetic/colour), single-select toggle, savePrefs()
- Semua user_profiles queries menggunakan .eq('id', user.id) — schema correction F-027/F-028/F-029

## Task Commits

1. **Task 1: Create SQL migration file** - `dbbc211` (chore) — sesi sebelumnya
2. **Task 0: Apply migration via Supabase Dashboard** — manual step, dikonfirmasi developer "migration applied"
3. **Task 2: Build account.html dashboard** - `f408806` (feat)

## Files Created/Modified

- `account.html` — dashboard lengkap: sidebar nav, Profile, Wishlist, Style Preferences panels; 306 baris ditambahkan
- `supabase/migrations/003_phase4_user_profiles.sql` — DDL: ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS (preferred_activity, fit_preference, style_aesthetic, colour_preference) — sudah applied ke Supabase live

## Decisions Made

- **Migration file 003 bukan 002**: File bernama `003_phase4_user_profiles.sql` karena `002` sudah digunakan oleh Phase 03. Tidak mempengaruhi fungsionalitas — file ini adalah referensi DDL, bukan auto-run migration runner.
- **Fallback loadProfile**: Jika baris user_profiles belum ada (user baru yang trigger belum dibuat), profile diisi dari `user.user_metadata` — mencegah profile kosong untuk user baru.
- **Tidak ada id panel**: Panel section tidak menggunakan id="profile/wishlist/preferences" — menghindari browser scroll-to-anchor saat tab switch (temuan RESEARCH Pitfall 4 / Finding 12).
- **wishlist_items pakai user_id, user_profiles pakai id**: Dua tabel berbeda, kolom filter berbeda — konsisten dengan schema yang sudah ada.

## Deviations from Plan

None — plan dieksekusi sesuai spesifikasi. Semua query pattern, Toastify calls, dan chip toggle logic mengikuti 04-04-PLAN.md dan 04-PATTERNS.md verbatim.

## Issues Encountered

None. Migration sudah dikonfirmasi applied oleh developer sebelum Task 2 dieksekusi.

## User Setup Required

Sudah selesai — developer telah menerapkan migrasi SQL melalui Supabase Dashboard SQL Editor dan mengkonfirmasi 4 kolom tersedia:
- `preferred_activity` (text)
- `fit_preference` (text)
- `style_aesthetic` (text)
- `colour_preference` (text)

## Known Stubs

Tidak ada stub. Semua data diambil langsung dari Supabase live (user_profiles, wishlist_items JOIN products). Wishlist kosong jika user belum menyimpan item — ini adalah empty state yang valid, bukan stub.

## Threat Flags

Tidak ada surface baru di luar threat model. Semua mitigasi T-04-04-01 hingga T-04-04-06 sudah diterapkan:
- T-04-04-01: auth guard aktif di init()
- T-04-04-02: user_profiles queries pakai .eq('id', user.id) + RLS
- T-04-04-03: wishlist_items pakai .eq('user_id', user.id) + RLS
- T-04-04-04: Alpine x-text digunakan untuk nama user (auto-escaped)

## Next Phase Readiness

- account.html siap digunakan oleh authenticated user
- Style preference columns tersedia di Supabase — Phase 7 (AI Style Match) bisa membaca `preferred_activity`, `fit_preference`, `style_aesthetic`, `colour_preference` untuk pre-fill form
- Phase 05 (Cart + Checkout) tidak memerlukan account.html changes

---
*Phase: 04-auth-customer-account*
*Completed: 2026-06-15*
