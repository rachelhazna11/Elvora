---
status: resolved
phase: 07-admin-panel
source:
  - .planning/phases/07-admin-panel/07-SUMMARY.md
  - .planning/phases/07-admin-panel/07-07-SUMMARY.md
started: 2026-06-18T12:00:00.000Z
updated: 2026-06-18T16:00:00.000Z
---

## Current Test

## Current Test

[testing complete]

## Tests

### 1. Admin Guard — Unauthenticated Redirect
expected: Open admin.html in an incognito window (not logged in). Loading screen flashes briefly, then page redirects to homepage (/). No product data or admin UI visible.
result: pass

### 2. Admin Shell Loads
expected: Log in as an admin user, then open admin.html. Loading overlay appears briefly, then the full admin shell renders — sidebar with Products, Orders, Content, Testimonials nav buttons, and the Products section panel is visible by default.
result: pass

### 3. Products List
expected: In the Products section, a table shows all products including inactive ones (is_active=false). Each row shows product name, price (Rp format), Active/Inactive badge, Edit and Delete buttons. (Requires migration 007_admin_policies.sql applied to Supabase.)
result: pass

### 4. Product Form — Open for Create
expected: Click the "Add Product" button. A product form appears with empty fields: name, slug (auto-generated), description, category dropdown, base price, fabric details, care instructions, is_active toggle, a variants section, and an image upload area.
result: issue
reported: "Yes, but can't upload image, the input missing"
severity: major

### 5. Product Form — Variant Rows
expected: In the product form, click "Add Variant". A new row appears with fields for colour name, hex code, size, and stock quantity. Click it again — a second row appears. Click the × on one row — it disappears.
result: pass

### 6. Product Save (Create)
expected: Fill in the product form (name, description, category, price, one variant row), click Save. A success toast appears and the new product appears in the products table.
result: pass

### 7. Product Delete
expected: Click Delete on any product. Browser confirm dialog appears with the product name. Click Cancel — nothing changes. Click Delete again then OK — product disappears from list and success toast appears.
result: pass

### 8. Orders Section
expected: Click "Orders" in the sidebar. Orders table loads sorted newest first. Each row shows: 8-char uppercase monospace order ref, customer email (or "—"), subtotal in Rupiah, status badge, localized date. (Requires migration 007.)
result: pass

### 9. Order Items Expand
expected: Click "Details" on any order. An expand row appears below showing line items: product_name, variant_label, quantity, unit_price. Click "Details" again — row collapses.
result: issue
reported: "the Details button dont show anything"
severity: major

### 10. Content — Best Sellers Toggle
expected: Click "Content" in the sidebar. A grid of product cards appears each with a toggle switch. Flip a toggle — toast confirms. Navigate to homepage — best sellers section reflects the change.
result: issue
reported: "Ya, tapi section Best sellers di Home-page tidak menampilkan apa apa walaupun sudah active"
severity: major

### 11. Testimonials List
expected: Click "Testimonials" in the sidebar. Table shows all testimonials including hidden (is_active=false). Each row has: name, content preview, rating, Active/Inactive badge, Edit/Delete/Toggle buttons.
result: issue
reported: "Error loading testimonials, the console: [Error] Failed to load resource: the server responded with a status of 404 () (c46e56684ecdb0e7d6ad18928ad5340abc882a37fefbb22d9b289b02328c6c7f.map, line 0)"
severity: major

### 12. Testimonial Create
expected: Click "Add Testimonial". Modal form appears with name, role, content, rating (1–5), photo URL, is_active fields. Fill name + content + rating, click Save. Modal closes, toast confirms, new testimonial appears in table.
result: issue
reported: "[Error] ReferenceError: Can't find variable: saveTestimonial — (anonymous function) (cdn.min.js:5)"
severity: major

### 13. Testimonial Toggle Visibility
expected: Click the visibility toggle on an active testimonial. Badge changes from Active to Inactive immediately. Navigate to homepage — testimonials section reflects the change.
result: blocked
blocked_by: prior-phase
reason: "blank, tidak ada yang tampil 'No Testimonials yet' — blocked by Test 11 testimonials load failure"

## Summary

total: 13
passed: 7
issues: 5
pending: 0
skipped: 0
blocked: 1
skipped: 0

## Gaps

- truth: "Product form includes a working image upload area with a file input"
  status: resolved
  reason: "Fixed: admin.html file input wrapped in <label> with class=admin-form-input (commit ebf53d4)"
  severity: major
  test: 4
  root_cause: "admin.html:197-203 file input has no CSS class — Tailwind v4 Preflight strips border/background/padding from bare inputs, making it invisible. Other form inputs use .admin-form-input which restores these styles, but the file input was the only one left unstyled."
  artifacts:
    - path: "admin.html"
      issue: "Line 197-203: <input type=\"file\"> has no CSS class, only inline font-size/color/width — no border, no background"
    - path: "css/style.css"
      issue: "Lines 67-72, 149-157: Tailwind v4 Preflight removes padding, border, background-color from all bare inputs"
  missing:
    - "Style the file input with .admin-form-input class or a custom styled upload zone wrapper (<label> + hidden input)"
  debug_session: ".planning/debug/product-image-upload-missing.md"

- truth: "Clicking Details on an order row expands inline line items below it"
  status: resolved
  reason: "Fixed: 008_order_items_admin_policy.sql created (commit ebf53d4) — apply via Supabase Dashboard SQL Editor to activate"
  severity: major
  test: 9
  root_cause: "Missing order_items_admin_select RLS policy in 007_admin_policies.sql. The only existing policy (order_items_select_own from 001_schema.sql) grants SELECT only where the order belongs to auth.uid(). Admin viewing other users' orders fails this check — Supabase silently returns [] with no error. Alpine toggle and JS logic are correct."
  artifacts:
    - path: "supabase/migrations/007_admin_policies.sql"
      issue: "Adds orders_admin_select and products_admin_select but omits order_items_admin_select"
    - path: "supabase/migrations/001_schema.sql"
      issue: "order_items_select_own policy restricts SELECT to auth.uid() owner only — blocks admin reads"
  missing:
    - "Add CREATE POLICY order_items_admin_select ON order_items FOR SELECT USING (is_admin()) to 007 or new migration 008"
  debug_session: ".planning/debug/order-details-expand-broken.md"

- truth: "Homepage Best Sellers section displays products toggled active in admin Content panel"
  status: resolved
  reason: "Fixed: toggleBestSeller() + adminSetBestSeller() added to adminApp() (commit 882be00)"
  severity: major
  test: 10
  root_cause: "toggleBestSeller() is entirely absent from adminApp() in js/admin.js. admin.html:316 binds @change=\"toggleBestSeller(p.id, $event.target.checked, p)\" but the function was never implemented. Toggle fires Alpine ReferenceError silently — no Supabase UPDATE sent, is_best_seller stays false for all products. Homepage query (.eq('is_best_seller', true)) correctly returns zero rows."
  artifacts:
    - path: "js/admin.js"
      issue: "toggleBestSeller() missing from adminApp() return object"
    - path: "admin.html"
      issue: "Line 316: @change=\"toggleBestSeller(...)\" calls missing function"
  missing:
    - "Add async toggleBestSeller(id, checked, product) to adminApp() — Supabase UPDATE is_best_seller + local mutation + toast"
    - "Verify seed.sql was applied to live Supabase instance (4 products have is_best_seller=true in seed)"
  debug_session: ".planning/debug/best-sellers-empty-homepage.md"

- truth: "Testimonials section loads and shows all rows including inactive ones"
  status: resolved
  reason: "Fixed: adminGetTestimonials() stub replaced with real Supabase query (commit 882be00)"
  severity: major
  test: 11
  root_cause: "adminGetTestimonials() in js/admin.js (lines 603-605) is an unimplemented stub: entire body is 'return [];' — never queries Supabase. UI shows empty state, user interprets as error. The 404 .map error is unrelated CDN sourcemap noise (Toastify or similar). RLS policy testimonials_admin_all (using is_admin()) exists in 001_schema.sql and would permit the query."
  artifacts:
    - path: "js/admin.js"
      issue: "Lines 603-605: adminGetTestimonials() stub returns [] without any Supabase query"
  missing:
    - "Replace stub body with real query: .from('testimonials').select('id, customer_name, quote, activity_label, display_order, is_active, created_at').order('display_order', { ascending: true })"
  debug_session: ".planning/debug/testimonials-load-failure.md"

- truth: "Clicking Save in Add Testimonial modal creates a new testimonial record"
  status: resolved
  reason: "Fixed: saveTestimonial(), resetTestimonialForm(), deleteTestimonial(), toggleTestimonialVisibility() all added to adminApp() (commit 882be00)"
  severity: major
  test: 12
  root_cause: "saveTestimonial(), resetTestimonialForm(), and deleteTestimonial() are all absent from adminApp() in js/admin.js. Commit 7179d20 added testimonialForm/testimonialFormSaving state properties but omitted the action methods. Only openTestimonialForm() was implemented. admin.html calls all 4 methods — 3 of which don't exist."
  artifacts:
    - path: "js/admin.js"
      issue: "Lines 291-295: only openTestimonialForm() in testimonial block; saveTestimonial, resetTestimonialForm, deleteTestimonial absent from adminApp() return object"
    - path: "admin.html"
      issue: "Lines 362-363, 404-405: @click calls saveTestimonial(), resetTestimonialForm(), deleteTestimonial() — all undefined"
  missing:
    - "Add resetTestimonialForm() to adminApp() — resets testimonialForm fields, clears editingTestimonial"
    - "Add async saveTestimonial() to adminApp() — insert/update Supabase, refresh list, toast, close form"
    - "Add async deleteTestimonial(id, name) to adminApp() — confirm, Supabase delete, refresh list, toast"
    - "Add adminCreateTestimonial/adminUpdateTestimonial/adminDeleteTestimonial helpers below adminApp() (parallel to adminCreateProduct pattern)"
  debug_session: ".planning/debug/save-testimonial-reference-error.md"
