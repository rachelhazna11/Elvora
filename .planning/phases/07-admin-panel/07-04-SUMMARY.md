---
phase: 07-admin-panel
plan: 07-04
subsystem: admin
status: complete
tags: [admin, products, crud, storage, alpine]
decisions:
  - "Delete+re-insert variant approach for MVP update (simpler than diff-based upsert)"
  - "toSlug exposed on window so Alpine @input handler can call it directly"
tech_stack:
  added: []
  patterns: [supabase-storage-upload, alpine-x-model, alpine-x-for]
key_files:
  created: []
  modified:
    - admin.html
    - js/admin.js
metrics:
  duration: "~12 minutes"
  completed: "2026-06-18"
  tasks_completed: 3
  files_modified: 2
---

# Phase 07 Plan 04: Product Create/Edit Form Summary

Full product create/edit form replacing the 07-01 placeholder. Admin can now create and edit products with name, slug, description, category, price, fabric details, care instructions, is_active toggle, variants (colour/size/hex/stock), and image upload to Supabase Storage.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Replace product form placeholder in admin.html | d90df0b | admin.html |
| 2 | Add product form state and methods to adminApp() | d90df0b | js/admin.js |
| 3 | Implement adminCreateProduct, adminUpdateProduct, toSlug | d90df0b | js/admin.js |

## What Was Built

- **admin.html**: Full form with basic info fields (name/slug/description/category/price/fabric/care), is_active toggle, variants section with add/remove rows (colour/size/hex/stock), existing image display with per-image delete, new image file input with base64 preview, and save/cancel actions with loading state.
- **js/admin.js state**: Added `categories`, `productFormSaving`, and full `productForm` object with all fields.
- **js/admin.js methods**: `openProductForm(product)` (loads categories, pre-populates edit or resets create), `resetProductForm()`, `addVariantRow()`, `removeVariantRow(index)`, `previewImages(event)` (5MB + MIME validation), `removeExistingImage(imageId, index)`, `saveProduct()` (validation + create/update dispatch + list refresh).
- **js/admin.js functions**: `toSlug()` helper, `adminCreateProduct()` (insert product → variants → upload images → insert product_images), `adminUpdateProduct()` (update product → delete+re-insert variants → upload new images).
- **Window exposures**: `window.adminCreateProduct`, `window.adminUpdateProduct`, `window.toSlug`.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- admin.html modified: confirmed (415 line diff)
- js/admin.js modified: confirmed (415 line diff)
- Commit d90df0b: confirmed
