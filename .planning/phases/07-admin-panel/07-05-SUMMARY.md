---
phase: 07-admin-panel
plan: 07-05
subsystem: admin-panel
tags: [testimonials, best-sellers, crud, admin, alpine, supabase]
dependency_graph:
  requires: [07-01, 07-02]
  provides: [testimonials-crud, best-sellers-toggle]
  affects: [admin.html, js/admin.js, homepage-testimonials, homepage-best-sellers]
tech_stack:
  added: []
  patterns: [alpine-x-show, optimistic-local-state-update, supabase-rls-admin-policy]
key_files:
  created: []
  modified:
    - admin.html
    - js/admin.js
decisions:
  - "x-show without conflicting style=display:none on testimonial modal — Alpine manages visibility exclusively"
  - "adminGetTestimonials() has NO is_active filter so admin sees all testimonials including inactive"
  - "toggleTestimonialVisibility updates local array state optimistically then falls back to server refresh on error"
  - "toggleBestSeller updates product.is_best_seller in-place then spreads array to trigger Alpine reactivity"
  - "adminGetCollections() is now fully implemented fetching from collections table (was stub)"
metrics:
  duration: 120s
  completed: "2026-06-18"
  tasks_completed: 3
  files_modified: 2
status: complete
requirements:
  - F-038
  - F-039
---

# Phase 7 Plan 05: Testimonials + Homepage Content Management Summary

## One-liner

Testimonials CRUD with visibility toggle and best sellers checkbox grid wired to Supabase, replacing both admin.html placeholders from plan 07-01.

## What was built

### Task 1: Testimonials Section (admin.html)

Replaced `<!-- TESTIMONIALS SECTION — plan 07-05 akan mengisi ini -->` placeholder with:
- Table showing all testimonials (author, activity, quote preview, visible toggle, edit/delete buttons)
- `x-for="t in testimonials"` iterating over Alpine state
- Inline toggle switch bound to `toggleTestimonialVisibility(t.id, $event.target.checked)`
- Form modal controlled by `x-show="showTestimonialForm"` — NO conflicting `style="display:none;"` on the outer div (Alpine manages visibility exclusively)
- Form fields: customer_name, activity_label, quote (textarea), display_order (number), is_active (toggle)
- Save/Cancel buttons with `testimonialFormSaving` loading state

### Task 2: Content Section (admin.html)

Replaced `<!-- CONTENT SECTION — plan 07-05 akan mengisi ini -->` placeholder with:
- Best Sellers card listing all products with toggle per row
- Product thumbnail (48x48 from product_images[0]), name, base_price in each row
- `@change="toggleBestSeller(p.id, $event.target.checked, p)"` per toggle
- Empty state shown while `bestSellers.length === 0`

### Task 3: JS Functions (js/admin.js)

**State added to adminApp():**
- `testimonialFormSaving: false`
- `testimonialForm: { customer_name, quote, activity_label, display_order, is_active }`

**Methods added to adminApp():**
- `openTestimonialForm(testimonial)` — pre-populates form with existing data or resets for new
- `resetTestimonialForm()` — clears form fields, resets saving flag
- `saveTestimonial()` — validates required fields, calls adminSaveTestimonial(), refreshes list
- `toggleTestimonialVisibility(id, isActive)` — optimistic local update, falls back to server refresh on error
- `deleteTestimonial(id, name)` — confirm dialog, calls adminDeleteTestimonial(), refreshes list
- `toggleBestSeller(productId, isBestSeller, product)` — optimistic local update via array spread

**Data functions replaced/added:**
- `adminGetTestimonials()` — full Supabase query with NO is_active filter, ordered by display_order
- `adminSaveTestimonial(testimonialData)` — upsert via id presence: update if id exists, insert if not
- `adminToggleTestimonial(id, isActive)` — single-field update on is_active
- `adminDeleteTestimonial(id)` — delete by id
- `adminGetCollections()` — was stub, now fetches from collections table ordered by display_order
- `adminSetBestSeller(productId, isBestSeller)` — updates products.is_best_seller column

All new functions exposed on window alongside existing ones.

## Deviations from Plan

None — plan executed exactly as written.

Note: `js/admin.js` had already been significantly updated by plan 07-03 (the file in context at plan start was a prior snapshot). The actual file had `loadSection` with try/catch/finally already in place and `adminGetProducts()` / `adminDeleteProduct()` fully implemented. The implementation proceeded correctly against the actual file state.

## Self-Check

- [x] `admin.html` modified — testimonials and content sections fully replaced
- [x] `js/admin.js` modified — all new functions and state added
- [x] Commit 07ff217 exists
- [x] No placeholder text remaining in either section
- [x] `x-show="showTestimonialForm"` on modal without conflicting `style="display:none;"`
- [x] `adminGetTestimonials()` has no `is_active` filter
- [x] All 6 new data functions exposed on window

## Self-Check: PASSED
