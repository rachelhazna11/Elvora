---
phase: 06-cart-checkout
plan: "06"
subsystem: ui
tags: [alpine, cart, auth, components]

requires:
  - phase: 06-cart-checkout
    provides: cart store, auth store, components.js

provides:
  - One-shot guard preventing dual Alpine init registration
  - Removal of eager loadCartFromSupabase race condition in initAuth

affects:
  - cart-checkout
  - auth

tech-stack:
  added: []
  patterns:
    - "_componentsInitDone guard pattern for idempotent Alpine init across defer/module timing"

key-files:
  created: []
  modified:
    - js/components.js

key-decisions:
  - "Use module-level boolean flag _componentsInitDone instead of removing one of the two init branches — preserves flexibility for script order changes while eliminating double execution"
  - "Remove eager loadCartFromSupabase from initAuth — INITIAL_SESSION event handler is the single correct place for initial cart load; eager call raced against in-flight user adds"

patterns-established:
  - "_componentsInit() one-shot wrapper: always wrap dual-path Alpine init (alpine:init event + window.Alpine check) with a boolean guard to prevent double registration"

requirements-completed: []

duration: 5min
completed: 2026-06-17
---

# Phase 06 Plan 06: Fix Dual Alpine Registration + Eager Cart Overwrite Summary

**One-shot `_componentsInitDone` guard eliminates double `onAuthStateChange` subscription; eager `loadCartFromSupabase` race removed from `initAuth` so cart items survive login**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-17T15:48:00Z
- **Completed:** 2026-06-17T15:53:10Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `_componentsInitDone` boolean guard so `registerStores()` and `initAuth()` run exactly once regardless of whether Alpine fires `alpine:init` before or after the ES module loads
- Removed eager `loadCartFromSupabase(user.id)` call from inside `initAuth()` — this call raced against items the user added between page load and async resolution, causing a wholesale `items =` replace that wiped the cart
- `INITIAL_SESSION` event handler remains as the single correct load point for returning authenticated users

## Task Commits

1. **Task 1 + 2: One-shot guard + remove eager cart load** - `85b5d79` (fix)

## Files Created/Modified

- `js/components.js` — Added `_componentsInitDone` guard around dual init path; removed eager `loadCartFromSupabase` call from `initAuth()`

## Decisions Made

- Combined both tasks in a single commit — they touch the same file and are tightly coupled (both fix compounding bugs in the same init flow)
- Retained the `loadCartFromSupabase` import since it is still used in the `INITIAL_SESSION` handler inside `onAuthChange`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- UAT Gaps 3 and 4 are now addressed: cart items no longer disappear after login, and the product page no longer shows raw JS code for authenticated users
- Ready for Phase 07 (AI Style Match) or any remaining UAT verification

## Self-Check

- [x] `_componentsInitDone` guard present in `js/components.js` (lines 48-56)
- [x] No eager `loadCartFromSupabase` call inside `initAuth()`
- [x] `INITIAL_SESSION` handler still loads cart for returning auth users (line 37)
- [x] `SIGNED_IN` handler still merges guest cart on login (line 35)
- [x] Commit `85b5d79` exists in git log

## Self-Check: PASSED

---
*Phase: 06-cart-checkout*
*Completed: 2026-06-17*
