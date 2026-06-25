---
phase: 07-admin-panel
plan: 07-01
subsystem: admin
tags: [admin, css, spa, guard, alpine]
status: complete
requires: []
provides: [admin-css-classes, admin-spa-shell, admin-guard]
affects: [src/input.css, admin.html, js/admin.js]
tech-stack:
  added: [Toastify JS CDN]
  patterns: [Alpine x-data SPA, hash routing, admin guard via getUser()]
key-files:
  created: []
  modified:
    - src/input.css
    - admin.html
    - js/admin.js
decisions:
  - Admin guard uses supabase.auth.getUser() (server-validated JWT) not getSession()
  - Loading screen fixed overlay prevents flash-of-admin-content before guard resolves
  - Hash routing delegates hashchange events to a single listener registered in init()
  - Data functions are stubs (return []) — plan 07-03 to 07-06 will replace
metrics:
  duration: ~8 minutes
  completed: 2026-06-18
  tasks_completed: 3
  files_modified: 3
---

# Phase 7 Plan 01: CSS + Admin Shell + Guard Summary

**One-liner:** Admin SPA shell with loading-screen guard using server-validated JWT, hash-based section routing, and full admin CSS token layer.

## What Was Built

Three files were fully implemented to form the foundation of the admin panel:

1. **`src/input.css`** — 168 lines of admin CSS appended inside the existing `@layer components {}` block after Phase 6 cart/checkout styles. Covers the complete admin design token surface: shell layout, sidebar, nav items, table styles, badges, button variants (primary/secondary/danger), form controls, toggle switch, variant rows, image previews, order items, and a responsive breakpoint at 768px.

2. **`admin.html`** — Full SPA shell replacing the previous stub. Includes a fixed loading screen overlay (`#admin-loading-screen`) that persists until the guard resolves. The Alpine `x-data="adminApp()"` div is hidden via `style="display:none"` and only revealed when `adminReady = true`. Four section panels (Products, Orders, Content, Testimonials) use `x-show` for client-side routing. The Products section includes a product form modal stub. Sidebar has 4 nav buttons with SVG icons and active-state binding. No `#nav-root` or `#footer-root` — admin does not use the standard nav/footer.

3. **`js/admin.js`** — Complete Alpine component function `adminApp()` with:
   - Guard using `supabase.auth.getUser()` (server-validated, not localStorage-only `getSession()`)
   - Role check: `user.app_metadata?.role === 'admin'`
   - `setSection()` / `loadSection()` hash-based dispatcher
   - `doSignOut()`, `openProductForm()`, `openTestimonialForm()`, `toggleOrderItems()`
   - Stub data functions (`adminGetProducts`, `adminGetOrders`, `adminGetOrderItems`, `adminGetTestimonials`, `adminGetCollections`) returning `[]`
   - `showToast()` Toastify helper
   - All functions exposed on `window.*`

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | `3367451` | feat(admin): admin CSS classes in src/input.css |
| 2 | `1396577` | feat(admin): admin.html SPA shell with guard and section routing |
| 3 | `be3ae4e` | feat(admin): js/admin.js guard + dispatcher + window exposure |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

The following stubs are intentional — they will be replaced in plans 07-03 to 07-06:

| Stub | File | Reason |
|------|------|--------|
| `adminGetProducts()` returns `[]` | js/admin.js | Plan 07-03 implements full Supabase query |
| `adminGetOrders()` returns `[]` | js/admin.js | Plan 07-06 implements orders query |
| `adminGetOrderItems()` returns `[]` | js/admin.js | Plan 07-06 implements order items query |
| `adminGetTestimonials()` returns `[]` | js/admin.js | Plan 07-05 implements testimonials CRUD |
| `adminGetCollections()` returns `[]` | js/admin.js | Plan 07-05 implements collections query |
| Product form modal body | admin.html | Plan 07-04 implements full product form |
| Content section body | admin.html | Plan 07-05 implements best sellers toggles |
| Testimonials section body | admin.html | Plan 07-05 implements testimonials table |

These stubs do not prevent the plan's goal (shell + guard + routing) from being achieved.

## Threat Flags

None — no new network endpoints or auth paths introduced beyond the existing `supabase.auth.getUser()` call, which is the recommended secure pattern.

## Self-Check: PASSED

- [x] `src/input.css` modified — confirmed (commit 3367451)
- [x] `admin.html` modified — confirmed (commit 1396577)
- [x] `js/admin.js` modified — confirmed (commit be3ae4e)
- [x] All 3 commits exist in git log
- [x] `@layer components {}` not duplicated — admin CSS appended inside existing block
- [x] No `#nav-root` in admin.html
- [x] Guard uses `getUser()` not `getSession()`
