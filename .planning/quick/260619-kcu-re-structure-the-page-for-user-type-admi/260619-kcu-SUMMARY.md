---
phase: quick
plan: 260619-kcu
subsystem: auth
tags: [admin, redirect, security, alpine]
dependency_graph:
  requires: [supabase.js]
  provides: [admin-redirect.js]
  affects: [index.html, shop.html, product.html, cart.html, checkout.html, account.html, about.html, contact.html, lookbook.html, style-match.html, setup-profile.html]
tech_stack:
  added: []
  patterns: [early-redirect, module-import-singleton]
key_files:
  created:
    - js/admin-redirect.js
  modified:
    - index.html
    - shop.html
    - product.html
    - cart.html
    - checkout.html
    - account.html
    - about.html
    - contact.html
    - lookbook.html
    - style-match.html
    - setup-profile.html
decisions:
  - "admin-redirect.js imports supabase.js directly (not components.js/auth.js) to avoid triggering Alpine store registration and cart loading on the redirect path"
  - "window.location.replace() used (not href assignment) so storefront page is removed from browser history — admin cannot press Back"
  - "Script tag placed immediately after supabase.js in each page so getUser() starts as soon as the module resolves from cache"
  - "admin.html and auth.html excluded to prevent redirect loop and allow admin login respectively"
metrics:
  duration: 4m
  completed: 2026-06-19
status: complete
---

# Phase quick Plan 260619-kcu: Admin Redirect Summary

Early admin role check module + script tag on all 11 storefront pages — admins are redirected to admin.html before Alpine initializes, shoppers and guests unaffected.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create js/admin-redirect.js | ff933fc | js/admin-redirect.js |
| 2 | Add script tag to all 11 storefront pages | 98af3c3 | index.html, shop.html, product.html, cart.html, checkout.html, account.html, about.html, contact.html, lookbook.html, style-match.html, setup-profile.html |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- js/admin-redirect.js: EXISTS, contains getUser(), app_metadata check, location.replace()
- All 11 storefront pages: contain admin-redirect.js script tag after supabase.js line
- admin.html: does NOT contain admin-redirect.js (no redirect loop)
- auth.html: does NOT contain admin-redirect.js (admin can log in)
- Commits ff933fc and 98af3c3: verified in git log
