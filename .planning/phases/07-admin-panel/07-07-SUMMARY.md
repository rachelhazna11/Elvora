---
phase: "07-admin-panel"
plan: "07-07"
subsystem: "admin"
tags: [admin, rls, testimonials, best-sellers, gap-closure]
dependency_graph:
  requires: ["07-05", "07-06"]
  provides: ["order_items RLS admin policy", "toggleBestSeller", "saveTestimonial", "resetTestimonialForm", "deleteTestimonial", "real testimonials query"]
  affects: ["admin.html", "js/admin.js", "supabase/migrations/"]
tech_stack:
  added: []
  patterns: ["Alpine method binding", "Supabase RLS policy", "admin helper functions"]
key_files:
  created:
    - supabase/migrations/008_order_items_admin_policy.sql
  modified:
    - admin.html
    - js/admin.js
decisions:
  - "File input wrapped in label element to make it a visible click target; admin-form-input class restores border/padding stripped by Tailwind v4 Preflight"
  - "Migration 008 is idempotent (DROP IF EXISTS + CREATE) — safe to re-run in Supabase SQL Editor"
  - "adminGetCollections() stub also replaced with real Supabase query as defensive measure"
metrics:
  duration: "~2 minutes"
  completed: "2026-06-18"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 3
status: complete
---

# Phase 07 Plan 07: Gap Closure — 5 UAT Failures Summary

Closed 5 UAT gaps in the admin panel: invisible file input, empty order details due to missing RLS policy, best-seller toggle ReferenceError, testimonials list stub, and testimonial save/delete/reset methods missing from adminApp().

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Fix file input visibility + add order_items RLS migration | ebf53d4 | admin.html, supabase/migrations/008_order_items_admin_policy.sql |
| 2 | Add toggleBestSeller and complete testimonial methods | 882be00 | js/admin.js |

## What Was Built

### Task 1 — File Input Styling (Gap 1 — Test 4)

The bare `<input type="file">` in the product form was stripped of visible borders and padding by Tailwind v4 Preflight CSS reset. Fixed by wrapping the input in a `<label style="display:block;cursor:pointer;">` and adding `class="admin-form-input"` to the input. The `.admin-form-input` class provides `width:100%; padding:12px 16px; border:1.5px solid rgba(168,191,163,0.3); border-radius:10px; background:white;`.

### Task 1 — Order Items RLS Migration (Gap 2 — Test 9)

Created `supabase/migrations/008_order_items_admin_policy.sql` with an `order_items_admin_select` policy that uses `is_admin()` — the same pattern as `orders_admin_select` in migration 007. Without this policy, the existing `order_items_select_own` policy blocked admin reads of other users' order items, causing `adminGetOrderItems()` to silently return [].

**MANUAL STEP REQUIRED:** This migration must be applied to the live Supabase instance via Dashboard → SQL Editor before Test 9 will pass in UAT.

### Task 2 — toggleBestSeller (Gap 3 — Test 10)

Added `async toggleBestSeller(productId, isBestSeller, product)` to `adminApp()`. The Content section HTML already had `@change="toggleBestSeller(p.id, $event.target.checked, p)"` wired — the method was just missing, causing ReferenceError on toggle click.

### Task 2 — Real testimonials query (Gap 4 — Test 11)

Replaced `adminGetTestimonials()` stub (returning `[]`) with a real Supabase query selecting all testimonials ordered by `display_order`. No `is_active` filter — admin needs to see all rows including inactive ones. Also replaced `adminGetCollections()` stub with a real collections query.

### Task 2 — Testimonial CRUD methods (Gap 5 — Test 12)

Added to `adminApp()`:
- `resetTestimonialForm()` — resets form state and `testimonialFormSaving` flag
- `saveTestimonial()` — validates name/quote, calls `adminSaveTestimonial()`, refreshes list
- `toggleTestimonialVisibility(id, isActive)` — optimistic update, falls back to full reload on error
- `deleteTestimonial(id, name)` — confirm dialog, then hard delete

Added helper functions (outside Alpine, exposed on `window`):
- `adminSaveTestimonial(testimonialData)` — upsert (UPDATE if id present, INSERT if not)
- `adminToggleTestimonial(id, isActive)` — UPDATE `is_active`
- `adminDeleteTestimonial(id)` — hard DELETE
- `adminSetBestSeller(productId, isBestSeller)` — UPDATE `is_best_seller` on products

Also updated `openTestimonialForm(testimonial)` to properly populate `testimonialForm` fields when editing an existing testimonial (previously only set `editingTestimonial` but did not populate form state).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Functionality] openTestimonialForm() did not populate testimonialForm fields on edit**

- **Found during:** Task 2 implementation
- **Issue:** Original `openTestimonialForm(testimonial)` set `this.editingTestimonial = testimonial` but did not populate `this.testimonialForm` with the existing testimonial data, so the Edit form would appear blank.
- **Fix:** Added form population logic in the `if (testimonial)` branch (same pattern as `openProductForm`).
- **Files modified:** js/admin.js
- **Commit:** 882be00

**2. [Rule 2 - Missing Functionality] adminGetCollections() stub also replaced**

- **Found during:** Task 2 implementation
- **Issue:** Plan only required replacing `adminGetTestimonials()` stub, but `adminGetCollections()` was also returning `[]`. Content section collections list would be perpetually empty.
- **Fix:** Replaced stub with real Supabase query ordered by `display_order`.
- **Files modified:** js/admin.js
- **Commit:** 882be00

## Manual Steps Required

| Step | Location | When |
|------|----------|------|
| Apply 008_order_items_admin_policy.sql | Supabase Dashboard → SQL Editor | Before UAT Test 9 re-run |

## UAT Tests Addressed

| Test | Gap | Status After This Plan |
|------|-----|----------------------|
| Test 4 | File input invisible | Fixed — admin-form-input class applied |
| Test 9 | Order details expand shows empty | Fixed — migration 008 adds RLS policy (requires manual apply) |
| Test 10 | Best-seller toggle ReferenceError | Fixed — toggleBestSeller() added to adminApp() |
| Test 11 | Testimonials list always empty | Fixed — adminGetTestimonials() now queries Supabase |
| Test 12 | Testimonial save/delete ReferenceError | Fixed — saveTestimonial(), resetTestimonialForm(), deleteTestimonial() added |

## Threat Surface Scan

No new network endpoints or auth paths introduced. All mutations use `is_admin()` RLS (enforced server-side). Threat model T-07-07-01, T-07-07-02, T-07-07-03 are addressed as planned:
- T-07-07-01 mitigated: `order_items_admin_select` policy uses `is_admin()` — non-admins cannot read other users' order items
- T-07-07-02 mitigated: existing `testimonials_admin_all` policy already restricts writes to `is_admin()`; client validation (name/quote required) is defence-in-depth
- T-07-07-03 accepted: admin-only view of all testimonials including inactive; `is_admin()` RLS enforced

## Self-Check: PASSED

- [x] admin.html — file input has `class="admin-form-input"` — FOUND
- [x] supabase/migrations/008_order_items_admin_policy.sql — contains `order_items_admin_select` — FOUND
- [x] js/admin.js — `toggleBestSeller` method present — FOUND
- [x] js/admin.js — `saveTestimonial` method present — FOUND
- [x] js/admin.js — `resetTestimonialForm` method present — FOUND
- [x] js/admin.js — `deleteTestimonial` method present — FOUND
- [x] js/admin.js — `.from('testimonials')` real query present — FOUND
- [x] Commit ebf53d4 exists — FOUND
- [x] Commit 882be00 exists — FOUND
