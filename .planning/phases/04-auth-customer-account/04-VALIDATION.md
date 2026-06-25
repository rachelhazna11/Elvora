---
phase: 4
slug: auth-customer-account
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-15
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — browser + Supabase Dashboard manual verification (no test runner; Alpine.js CDN project) |
| **Config file** | none |
| **Quick run command** | Open browser DevTools → Console, run snippet per task (see Per-Task map below) |
| **Full suite command** | Full user flow walkthrough per Wave (see Manual-Only Verifications below) |
| **Estimated runtime** | ~5–10 min manual per wave |

---

## Sampling Rate

- **After every task commit:** Check browser console for JS errors on the affected page; confirm no `TypeError` or `ReferenceError` from the modified file
- **After every plan wave:** Run the full Wave verification flow in browser (see Manual-Only Verifications)
- **Before `/gsd-verify-work`:** All manual verifications must be completed with ✅

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | F-025–029 | — | N/A — CSS only | manual | Open shop.html in browser → DevTools console: no CSS errors | ✅ | ⬜ pending |
| 04-02-01 | 02 | 1 | F-025, F-026 | T-04-01 | signUp/signIn never expose passwords in console or window; auth token stored in localStorage by Supabase SDK only | manual | DevTools → Application → Local Storage: confirm `sb-*-auth-token` key present after login | ✅ | ⬜ pending |
| 04-02-02 | 02 | 1 | F-027 | T-04-02 | `Alpine.store('auth')` reflects real session state; no stale data after signOut | manual | Console: `Alpine.store('auth')` → `{ loggedIn: true, user: { ... } }` after sign-in; `{ loggedIn: false, user: null }` after sign-out | ✅ | ⬜ pending |
| 04-03-01 | 03 | 2 | F-025, F-026 | T-04-01 | Form submit: password field value never logged or visible in network payload beyond Supabase HTTPS call | manual | auth.html: sign up with test credentials → redirect to account.html; Supabase Dashboard → Auth → Users: new user appears | ✅ | ⬜ pending |
| 04-04-01 | 04 | 2 | F-028, F-029 | — | Profile save only writes to authenticated user's own row (RLS enforced) | manual | account.html logged in → edit first name → Save → refresh → name persists | ✅ | ⬜ pending |
| 04-04-02 | 04 | 2 | F-029 | — | Style preferences stored as discrete columns, not mixed with other user data | manual | account.html → Style Preferences → select options → Save Preferences → Supabase Dashboard → Table Editor → user_profiles → confirm columns populated | ✅ | ⬜ pending |
| 04-05-01 | 05 | 3 | F-028 | T-04-03 | Wishlist RLS: user cannot see/modify another user's wishlist_items | manual | shop.html logged in → click heart → confirm fill; Supabase Dashboard → Table Editor → wishlist_items → row with correct user_id appears | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

**Pre-execution SQL migration (manual — Supabase Dashboard):**

- [ ] Apply via Supabase Dashboard → SQL Editor:
  ```sql
  ALTER TABLE user_profiles
    ADD COLUMN IF NOT EXISTS preferred_activity text,
    ADD COLUMN IF NOT EXISTS fit_preference text,
    ADD COLUMN IF NOT EXISTS style_aesthetic text,
    ADD COLUMN IF NOT EXISTS colour_preference text;
  ```
- [ ] Verify: Supabase Dashboard → Table Editor → user_profiles → confirm 4 new columns visible

This is Wave 0 because Plan 04 (Style Preferences section) cannot write preferences without these columns existing in production.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sign up creates account + user_profiles row | F-025 | No test runner; requires live Supabase | auth.html → Create Account tab → fill form → submit → check Supabase Dashboard: Auth > Users + Table Editor > user_profiles |
| Sign in persists session across page reload | F-026, F-027 | Requires browser localStorage + Supabase JWT | Sign in → navigate to shop.html → hard refresh → nav still shows user name |
| Sign out clears session | F-026 | Requires browser state | Click Sign Out in nav dropdown → nav reverts to guest state → Supabase localStorage key cleared |
| Wishlist heart: guest redirect | F-028 | Requires browser + routing | Open shop.html not logged in → click heart → Toastify toast appears → after 2s redirects to auth.html?tab=signin |
| Wishlist heart: optimistic toggle (logged in) | F-028 | Requires live Supabase + browser UI | Logged in → click heart on product → heart fills immediately → Supabase Dashboard wishlist_items row appears |
| Wishlist remove: optimistic card fade | F-028 | Requires browser animation + Supabase | account.html → Wishlist tab → click × → card fades out → row deleted in Supabase |
| Style preferences pre-fill | F-029 | Requires saved data + Alpine init timing | Save preferences → refresh account.html → chips pre-selected correctly |
| Mobile: auth page image panel hides | F-025 | Requires browser resize | auth.html at 375px → left image panel hidden; only form visible; no horizontal scroll |
| Mobile: account sidebar becomes horizontal scroll | F-027 | Requires browser resize | account.html at 375px → sidebar tabs display as horizontal scrollable row |

---

## Validation Sign-Off

- [ ] All tasks have manual verification steps
- [ ] Wave 0 SQL migration applied before Plan 04 execution
- [ ] Session limit is no longer a concern (planner rerun covers schema fix)
- [ ] `nyquist_compliant: true` set in frontmatter when all tasks pass

**Approval:** pending
