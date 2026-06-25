---
phase: 06-cart-checkout
plan: 06-07
subsystem: auth-cart
tags: [google-oauth, cart-merge, supabase-trigger, guest-cart]
dependency_graph:
  requires: [06-06]
  provides: [google-oauth-profile-persistence, guest-cart-oauth-merge]
  affects: [js/components.js, supabase/migrations/]
tech_stack:
  added: []
  patterns: [supabase-db-trigger, auth-event-cart-merge]
key_files:
  created:
    - supabase/migrations/006_handle_new_user.sql
  modified:
    - js/components.js
decisions:
  - Migration named 006 (not 005) — 005_style_sessions.sql already occupied; renaming auto-fixed to avoid collision
  - handle_new_user uses ON CONFLICT (id) DO NOTHING for idempotency — safe to re-run in SQL Editor
  - INITIAL_SESSION merge uses existing mergeGuestCartToSupabase(user) — no new logic needed, only branch routing
metrics:
  duration_minutes: 8
  completed_date: "2026-06-17T15:55:38Z"
  tasks_completed: 2
  files_changed: 2
---

# Phase 06 Plan 07: Google OAuth Profile Persistence + Guest Cart Merge on Redirect Summary

DB trigger auto-creates user_profiles for Google OAuth users; INITIAL_SESSION handler now merges guest cart items instead of overwriting on OAuth redirect return.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create handle_new_user DB trigger migration | 28c9a7c | supabase/migrations/006_handle_new_user.sql |
| 2 | Fix INITIAL_SESSION to merge guest cart | 44ea412 | js/components.js |

## What Was Built

**Task 1 — Migration 006:** `public.handle_new_user()` trigger function fires `AFTER INSERT ON auth.users`. Reads `raw_user_meta_data` from Google (`given_name`, `family_name`, `preferred_username`) and falls back to email prefix when metadata is absent. `ON CONFLICT (id) DO NOTHING` makes it idempotent. Trigger name `on_auth_user_created` replaces any prior definition via `DROP TRIGGER IF EXISTS`.

**Manual step required:** User must run `006_handle_new_user.sql` in Supabase Dashboard → SQL Editor. The project has no migration runner configured.

**Task 2 — INITIAL_SESSION cart merge:** In `onAuthChange`, the `INITIAL_SESSION` branch now calls `loadFromStorage()` first. If local items exist (guest items added before OAuth redirect), it routes to `mergeGuestCartToSupabase(user)`. If no local items, it falls back to `loadCartFromSupabase(user.id)` (existing session restore path unchanged). This closes UAT Gap 1 (guest cart lost after Google sign-in).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Migration file renamed 006 (plan said 005)**
- **Found during:** Task 1
- **Issue:** `supabase/migrations/005_style_sessions.sql` already exists; creating `005_handle_new_user.sql` would have collided or overwritten context
- **Fix:** Named file `006_handle_new_user.sql` — next available sequential number
- **Files modified:** supabase/migrations/006_handle_new_user.sql
- **Commit:** 28c9a7c

## UAT Gap Closures

| Gap | Description | Resolution |
|-----|-------------|------------|
| Gap 1 | Guest cart lost after Google sign-in | INITIAL_SESSION now merges via mergeGuestCartToSupabase |
| Gap 2 | Google OAuth profile not saved to Supabase | handle_new_user trigger creates user_profiles row on auth.users insert |

## Known Stubs

None — no placeholder or hardcoded empty values introduced.

## Threat Flags

None — no new network endpoints or auth paths introduced. Trigger uses SECURITY DEFINER with `SET search_path = public` (safe pattern per Supabase docs).

## Self-Check: PASSED

- [x] supabase/migrations/006_handle_new_user.sql exists
- [x] SUMMARY notes user must run it in Supabase SQL Editor
- [x] INITIAL_SESSION merges local cart when localItems.length > 0
- [x] INITIAL_SESSION loads Supabase cart when no local items
- [x] Commit 28c9a7c verified in git log
- [x] Commit 44ea412 verified in git log
