---
phase: 07-admin-panel
status: complete
plans_total: 6
plans_completed: 6
completed_at: 2026-06-18
commits:
  - cbd5c2b  # migration 007 RLS policies
  - 3367451  # admin CSS classes
  - 1396577  # admin.html SPA shell
  - be3ae4e  # js/admin.js guard + dispatcher
  - f018f02  # homepage best sellers fix
  - af7e399  # adminGetProducts + adminDeleteProduct
  - 07ff217  # testimonials CRUD + best sellers toggle
  - 5924f58  # adminGetOrders + adminGetOrderItems
  - d90df0b  # adminCreateProduct + adminUpdateProduct + product form
---

# Phase 7 Summary: Admin Panel

## What Was Built

A fully protected admin panel at `admin.html` with hash-based SPA routing, secure server-side auth guard, and complete CRUD operations across four sections.

### Files Modified / Created

| File | Change |
|------|--------|
| `admin.html` | Complete SPA: loading overlay, sidebar nav (4 sections), Products/Orders/Content/Testimonials panels, product create/edit form with variant rows + image upload, order expand rows |
| `js/admin.js` | `adminApp()` Alpine component with full state + methods; `adminGetProducts`, `adminDeleteProduct`, `adminCreateProduct`, `adminUpdateProduct`, `adminGetOrders`, `adminGetOrderItems`, `adminGetTestimonials`, `adminSaveTestimonial`, `adminDeleteTestimonial`, `adminToggleTestimonial`, `adminGetCollections`, `adminSetBestSeller`, `toSlug`, `showToast` |
| `src/input.css` | 168 lines of admin CSS: `.admin-shell`, `.admin-sidebar`, `.admin-nav-*`, `.admin-table`, `.admin-badge-*`, `.admin-btn-*`, `.admin-form-*`, `.admin-toggle`, `.admin-variant-row`, `.admin-image-*`, `.admin-order-*` |
| `index.html` | Fixed best sellers query — added `.eq('is_best_seller', true)` + `.eq('is_active', true)`, correct column names, href uses product.slug |
| `supabase/migrations/007_admin_policies.sql` | RLS policies: `orders_admin_select` + `products_admin_select` (USING is_admin()); apply manually via Supabase SQL Editor |

### Capabilities Delivered

**Products (F-036, F-037)**
- List all products (including is_active=false drafts) in sortable table
- Create new product: name, auto-slug, description, category, price, fabric/care details, is_active toggle
- Edit existing product: pre-populated form with all fields, existing images displayed
- Dynamic variant rows: add/remove with colour, colour_hex, size, stock quantity (SKU auto-generated)
- Image upload: multi-file with 5MB + MIME validation, base64 preview, existing image per-image delete
- Delete product: confirm dialog + cascading delete (Storage files → product_images → product_variants → product)

**Orders (F-040, F-041)**
- List all orders sorted newest first (limit 50) with order ref, customer email, subtotal in Rupiah, status badge, localized date
- Expand any order inline to show line items using snapshot columns (product_name, variant_label, unit_price, quantity)
- Graceful empty state with migration hint if 007 not applied

**Content / Best Sellers (F-042)**
- Best sellers toggle grid: flip is_best_seller on any product instantly; reflects on homepage without redeploy

**Testimonials (F-038, F-039)**
- List all testimonials (including hidden) in table
- Create/edit via modal form: name, role, content, rating, photo URL, is_active
- Toggle visibility per testimonial
- Delete with confirm dialog

### Security

- Auth guard: `supabase.auth.getUser()` (server-validated JWT) — unauthenticated or non-admin redirected to `/`
- `adminReady: false` + loading overlay prevents flash-of-content before guard resolves
- RLS policies in migration 007 enforce DB-level access independent of client guard

### Manual Action Required

Migration `007_admin_policies.sql` must be applied to live Supabase before Orders and full Products admin queries work.

Path: `supabase/migrations/007_admin_policies.sql`
Apply via: Supabase Dashboard → SQL Editor → paste and run

## Phase Success Criteria Check

| Criterion | Status |
|-----------|--------|
| 1. Unauthenticated visitor redirected, no data returned | getUser() guard + adminReady gate |
| 2. Admin can create product with variants + images, appears live on PLP | adminCreateProduct, Storage upload |
| 3. Admin can update featured collections + best sellers on homepage | Content section + adminSetBestSeller |
| 4. Admin can CRUD testimonials, homepage reflects changes | Full testimonials CRUD |
| 5. Admin can view order list + drill into line items | adminGetOrders + expand row |
