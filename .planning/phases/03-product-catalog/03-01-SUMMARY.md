---
phase: 03-product-catalog
plan: 01
subsystem: database
tags: [supabase, postgresql, rls, product-catalog, data-layer, alpine]

requires:
  - phase: 02-auth
    provides: Supabase client singleton (js/supabase.js), RLS policies pattern, seed.sql product/collection UUIDs

provides:
  - product_pairings table in Supabase with RLS (public read, admin write)
  - collection_products gap fill for Tennis, Training, Running sub-collections (21 collections fully populated)
  - js/products.js — getProducts(), getProduct(), getCategories(), searchProducts() — all implemented and window-exposed
  - ACTIVITY_TOP_SLUGS constant mapping 5 activity tabs to collection slugs

affects:
  - 03-02 (PLP — calls getProducts with category/sub/sort/search)
  - 03-03 (search — calls searchProducts)
  - 03-04 (PDP core — calls getProduct by slug)
  - 03-05 (social proof — calls getProduct for pairings)
  - 06 (cart — products data feeds cart operations)

tech-stack:
  added: []
  patterns:
    - "ACTIVITY_TOP_SLUGS inlined constant: avoids circular import from subcategory-styles.js"
    - "Two-step collection filter: collections.select(id).in(slug) → collection_products.select(product_id).in(collection_id) → Set dedup → products.in(id)"
    - "window.* exposure bridge: ES module functions exposed on window for Alpine x-data string access"
    - "Guard-return pattern: searchProducts returns { data: [] } for query < 2 chars without hitting Supabase"

key-files:
  created:
    - supabase/migrations/002_product_pairings.sql
  modified:
    - js/products.js

key-decisions:
  - "Inline ACTIVITY_TOP_SLUGS in products.js rather than import from subcategory-styles.js to prevent circular dependency"
  - "product_pairings uses composite primary key (product_id, paired_product_id) — no surrogate ID needed"
  - "Migration Sections A/B/C in single file: DDL + collection gap fill + pairing seed applied atomically via SQL Editor"
  - "getProducts returns raw Supabase query result (not awaited) — callers destructure { data, error }"
  - "getProduct returns null on any error rather than propagating error object — callers check null for 404 redirect"

patterns-established:
  - "Pattern: window.getProducts = getProducts — Alpine x-data global scope bridge for ES module functions"
  - "Pattern: two-phase collection filter via collections → collection_products join tables (no Supabase nested filter needed)"
  - "Pattern: Phase 7 comment in getProduct() documents Unsplash vs Supabase Storage URL param difference (?w= vs ?width=)"

requirements-completed: [F-008, F-009, F-010, F-011, F-012, F-017, F-018]

duration: ~35min (across 2 sessions — Task 1 + Task 3)
completed: 2026-06-14
---

# Phase 03 Plan 01: Data Foundation Summary

**Supabase product_pairings table + collection gap fill for all 5 activity tabs + js/products.js fully implemented with 4 window-exposed functions**

## Performance

- **Duration:** ~35 min across 2 sessions
- **Started:** 2026-06-14T07:00:00Z (Task 1), 2026-06-14T07:30:00Z (Task 3)
- **Completed:** 2026-06-14T08:07:45Z
- **Tasks:** 3 (Task 1: migration write, Task 2: human-apply, Task 3: products.js implement)
- **Files modified:** 2 (supabase/migrations/002_product_pairings.sql created, js/products.js replaced)

## Accomplishments

- `product_pairings` table created in live Supabase with RLS enabled (public SELECT, is_admin() write) and 66 seed rows covering all 22 products
- collection_products gap fill applied: all 21 collections (including Tennis, Training, Running sub-collections that had 0 assignments) now have products — activity filter tabs return non-empty grids
- `js/products.js` fully implemented: `getProducts` with category/sub/sort/search filters, `getProduct` with full nested joins, `getCategories`, `searchProducts` with 2-char guard; all four exposed on `window.*` for Alpine access

## Task Commits

Each task was committed atomically:

1. **Task 1: Write 002_product_pairings.sql migration** - `e3f19ad` (feat) — initial migration; patched in `51bbad0` and `fba96fb` to fix missing sub-collection inserts
2. **Task 2: Apply migration to live Supabase** — human checkpoint (no commit — user confirmed: product_pairings has 66 rows, 21 collections in DB)
3. **Task 3: Implement js/products.js** - `db8bc5c` (feat)

## Files Created/Modified

- `supabase/migrations/002_product_pairings.sql` — product_pairings DDL, RLS policies, collection_products gap fill (all 21 collections), 66 pairing seed rows
- `js/products.js` — ACTIVITY_TOP_SLUGS const + getProducts/getProduct/getCategories/searchProducts functions with window exposure

## Decisions Made

- Inlined `ACTIVITY_TOP_SLUGS` in `products.js` rather than importing from `subcategory-styles.js` — avoids circular dependency risk and keeps the data layer self-contained
- `getProduct` returns `null` on error (not `{ data, error }`) — callers use `if (!data) redirect('/shop.html')` pattern; cleaner for PDP
- `getProducts` returns the raw Supabase query chain (unawaited) — callers destructure `{ data, error }` uniformly
- Two-step collection filter query (collections → collection_products → products.in) chosen over Supabase nested filter — explicit and debuggable

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Migration patched twice to include all 21 collections**
- **Found during:** Task 1 review / Task 2 human verification
- **Issue:** Initial migration only inserted sub-collection rows without first ensuring the 21 parent/top-level collections existed — gap fill INSERT FK violations
- **Fix:** Two patch commits (`51bbad0`, `fba96fb`) extended the migration to first insert all 21 collection rows (including top-level Padel Edit, Studio Essentials) with ON CONFLICT DO NOTHING before the gap fill
- **Files modified:** supabase/migrations/002_product_pairings.sql
- **Committed in:** 51bbad0, fba96fb

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug in migration INSERT ordering)
**Impact on plan:** Fix was necessary for the migration to execute cleanly. No scope creep.

## Issues Encountered

Migration required two patch commits because initial version assumed all 21 collections already existed in the `collections` table. The seed.sql inserts them, but the migration needed to be self-sufficient (idempotent) with its own `ON CONFLICT DO NOTHING` inserts for collections before referencing them in collection_products. Resolved via two sequential patches applied in same migration file.

## User Setup Required

None — no new external service configuration required. Supabase migration was applied manually by user via SQL Editor (Task 2 human checkpoint).

## Next Phase Readiness

- `getProducts()` ready for Plan 03-02 (PLP) — accepts `{ category, sub, sort, search }`, returns active products with images + variants
- `getProduct(slug)` ready for Plan 03-04 (PDP core) — returns full product with nested images/variants/categories or null
- `searchProducts(query)` ready for Plan 03-03 (search) — returns up to 6 name+slug matches
- All activity tabs (Padel, Pilates, Tennis, Training, Running) will return non-empty grids — collection_products fully populated
- No known blockers for subsequent plans in Phase 3

## Known Stubs

None — js/products.js implements real Supabase queries. No hardcoded or empty data stubs.

## Threat Flags

No new threat surface beyond plan's threat model. All four functions use Supabase SDK parameterized calls (no raw SQL concatenation). RLS enabled on product_pairings. searchProducts 2-char guard implemented per T-03-02.

## Self-Check: PASSED

- `js/products.js` exists: FOUND
- `supabase/migrations/002_product_pairings.sql` exists: FOUND
- Task 3 commit db8bc5c: FOUND (confirmed via git log)
- Task 1 commit e3f19ad: FOUND (confirmed via git log)
- All 16 acceptance criteria checks: PASS (verified via node -e verification script)

---
*Phase: 03-product-catalog*
*Completed: 2026-06-14*
