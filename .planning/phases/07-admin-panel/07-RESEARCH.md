# Phase 7: Admin Panel — Research

**Researched:** 2026-06-18
**Domain:** Alpine.js + Supabase JS SDK — admin CRUD, image upload, RLS-gated multi-page admin
**Confidence:** HIGH

---

## Summary

Phase 7 adds a protected admin section to Elvora. The codebase is already nearly
"admin-ready": every writable table already has admin INSERT/UPDATE/DELETE RLS
policies gated by `is_admin()`. The two concrete gaps are (1) `orders` has no admin
SELECT policy (admin cannot read orders at all), and (2) `orders` has no admin SELECT
policy for `order_items` either — the existing `order_items_admin_all` covers it but
relies on `orders` being readable first via the `order_id in (…)` sub-query. A new
migration (`007_admin_policies.sql`) must add `orders_admin_select` before the order
view feature can work.

The admin section can be built as a **single-page Alpine.js application inside
`admin.html`** using URL hash routing (`#products`, `#content`, `#orders`). This
avoids spinning up new HTML pages, fits the no-build-step constraint, and matches the
existing pattern of large inline `x-data` objects seen in `index.html`,
`account.html`, and `checkout.html`. A separate `js/admin.js` module provides the
data-access functions; `admin.html` inlines the view logic as Alpine `x-data`.

The admin guard fires in `admin.html`'s inline Alpine `x-data init()`: check session,
verify `app_metadata.role === 'admin'` from the JWT, redirect to `/index.html` if
not. RLS is the actual security boundary — the client-side redirect is just UX.

**Primary recommendation:** Single `admin.html` with hash-based section switching, a
dedicated `js/admin.js` data module, and one new migration file adding the missing
orders admin SELECT policy.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Admin route guard | Browser (client JS) | Supabase RLS | Client redirect is UX; RLS is actual security — both layers required |
| Product CRUD (read/write) | Supabase (RLS + PostgREST) | Browser Alpine UI | All writes blocked at RLS for non-admin; client is just a form layer |
| Image upload | Supabase Storage (product-images bucket) | Browser (FileReader resize) | Bucket already has admin-only INSERT policy; anon key is safe by design |
| Homepage content management | Supabase DB (products.is_best_seller, collections.is_featured) | Browser Alpine UI | Single column flip via `.update()` — no new tables needed |
| Testimonials CRUD | Supabase DB (testimonials table) | Browser Alpine UI | Full admin_all policy already exists |
| Order read view | Supabase DB (orders + order_items SELECT) | Browser Alpine UI | Requires new `orders_admin_select` migration |
| Admin CSS | Browser (Tailwind CSS v4 utilities) | — | No separate CSS file; use existing utility classes + minimal new @layer admin utilities |

---

## Standard Stack

### Core (already in project — no new installs)

| Library | Version | Purpose | Source |
|---|---|---|---|
| Alpine.js | 3.15.12 (CDN) | Admin UI reactivity, section routing, form state | `[VERIFIED: admin.html CDN link]` |
| @supabase/supabase-js | 2.x (CDN ESM) | All Supabase CRUD, storage, auth | `[VERIFIED: js/supabase.js import]` |
| Tailwind CSS v4 | 4.x (CLI build) | Styling via utility classes | `[VERIFIED: package.json devDep]` |
| Toastify-js | 1.x (CDN) | Toast notifications for save/delete confirmations | `[ASSUMED — already used in product.html; confirm CDN tag is present in admin.html head]` |

### Supporting (no new installs required)

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Native `<input type="file">` + FileReader | Browser built-in | Image file selection and preview before upload | Product image upload form |
| URL hash routing | Browser built-in | Switch between admin sections without page reload | `window.location.hash` + `hashchange` event |

**No new npm packages are needed for Phase 7.** [VERIFIED: existing stack covers all requirements]

**Installation:** None — all dependencies already loaded via CDN in existing HTML files.

---

## Package Legitimacy Audit

No new external packages are introduced in this phase.

| Package | Verdict | Disposition |
|---|---|---|
| (none) | — | No new packages to audit |

---

## Architecture Patterns

### System Architecture Diagram

```
Browser (admin.html)
        │
        ├─ init() ──► supabase.auth.getUser()
        │              └─► check app_metadata.role === 'admin'
        │                  └─► NOT ADMIN → redirect /index.html
        │                  └─► ADMIN → render admin shell
        │
        ├─ #products section ──► js/admin.js: adminGetProducts()
        │                        adminCreateProduct() / adminUpdateProduct() / adminDeleteProduct()
        │                        adminUploadImage() → Storage: product-images bucket
        │                        adminSaveVariants() → product_variants INSERT
        │
        ├─ #content section ──► js/admin.js: adminGetBestSellers()
        │                       adminSetBestSeller(id, bool) → products.is_best_seller UPDATE
        │                       adminGetCollections()
        │                       adminSetCollectionFeatured(id, bool) → collections.is_featured UPDATE
        │
        ├─ #testimonials section ──► js/admin.js: adminGetTestimonials() (ALL, not filtered by is_active)
        │                            adminSaveTestimonial() / adminDeleteTestimonial()
        │                            adminToggleTestimonial(id, bool)
        │
        └─ #orders section ──► js/admin.js: adminGetOrders()
                               adminGetOrderItems(orderId)
                               ↕
                               Supabase DB (requires migration 007: orders_admin_select)
```

### Recommended Project Structure

```
/
├── admin.html               ← single admin SPA shell (hash-routed sections)
├── js/
│   ├── admin.js             ← all admin data functions (replace stub)
│   ├── supabase.js          ← shared (unchanged)
│   ├── components.js        ← shared (unchanged)
│   └── auth.js              ← shared (unchanged)
└── supabase/
    └── migrations/
        └── 007_admin_policies.sql  ← adds orders_admin_select
```

### Pattern 1: Admin Guard in Alpine `init()`

**What:** On page load, check auth session + JWT `app_metadata.role`. Redirect
non-admins before Alpine renders any admin UI.

**When to use:** Every admin page (currently just `admin.html`).

**Critical detail:** `supabase.auth.getUser()` makes a network round-trip to verify
the JWT signature server-side. `supabase.auth.getSession()` only reads local storage
and can be spoofed. Always use `getUser()` for the admin guard. [ASSUMED — consistent
with Supabase docs pattern; getUser() is the authoritative check]

```javascript
// Inside admin.html x-data init() — runs before Alpine renders children
async init() {
  const { data: { user }, error } = await window.supabase.auth.getUser();
  if (error || !user) {
    window.location.href = '/index.html';
    return;
  }
  // app_metadata is injected into the JWT by Supabase and readable client-side
  // but can only be WRITTEN by the service_role key — safe to read here.
  const role = user.app_metadata?.role;
  if (role !== 'admin') {
    window.location.href = '/index.html';
    return;
  }
  this.adminReady = true;
  this.activeSection = window.location.hash.replace('#', '') || 'products';
  await this.loadSection(this.activeSection);
}
```

**Source:** `is_admin()` reads `auth.jwt() -> 'app_metadata' ->> 'role'` (confirmed
in `001_schema.sql` line 27). The client-side check mirrors this exact field.
[VERIFIED: 001_schema.sql]

### Pattern 2: URL Hash Section Routing

**What:** Use `window.location.hash` to switch between admin views without a page
reload. `hashchange` event updates `this.activeSection`.

**Why not separate HTML pages:** Avoids repeating the auth guard on every page and
keeps the admin section self-contained. Matches the `account.html` pattern which uses
hash anchors for panel switching (Phase 4 precedent). [VERIFIED: account.html lines
84 context from STATE.md]

```javascript
// In admin.html x-data
init() {
  window.addEventListener('hashchange', () => {
    this.activeSection = window.location.hash.replace('#', '') || 'products';
    this.loadSection(this.activeSection);
  });
},
setSection(name) {
  window.location.hash = name;
}
```

```html
<!-- Section toggle buttons -->
<button @click="setSection('products')" :class="activeSection === 'products' ? 'admin-nav-active' : ''">Products</button>
<button @click="setSection('content')" :class="activeSection === 'content' ? 'admin-nav-active' : ''">Content</button>
<button @click="setSection('testimonials')" :class="activeSection === 'testimonials' ? 'admin-nav-active' : ''">Testimonials</button>
<button @click="setSection('orders')" :class="activeSection === 'orders' ? 'admin-nav-active' : ''">Orders</button>

<!-- Section panels — Alpine x-show for instant toggle -->
<div x-show="activeSection === 'products'">...</div>
<div x-show="activeSection === 'content'">...</div>
<div x-show="activeSection === 'testimonials'">...</div>
<div x-show="activeSection === 'orders'">...</div>
```

### Pattern 3: Product CRUD with Variants

**What:** Create product → insert to `products` → insert N rows to
`product_variants` → upload images to Storage → insert rows to `product_images`.

**Order matters:** product row must exist before variants (FK constraint). Images can
be uploaded in parallel after the product row exists.

```javascript
// js/admin.js — createProduct with variants
export async function adminCreateProduct(productData, variants, imageFiles) {
  // 1. Insert product
  const { data: product, error: productErr } = await supabase
    .from('products')
    .insert({
      name: productData.name,
      slug: productData.slug,        // derive from name: name.toLowerCase().replace(/\s+/g, '-')
      description: productData.description,
      category_id: productData.category_id,
      base_price: productData.base_price,
      fabric_details: productData.fabric_details,
      care_instructions: productData.care_instructions,
      is_active: true,
    })
    .select('id')
    .single();

  if (productErr) throw productErr;
  const productId = product.id;

  // 2. Insert variants (each colour × size combo)
  if (variants.length > 0) {
    const variantRows = variants.map((v, i) => ({
      product_id: productId,
      colour: v.colour,
      colour_hex: v.colour_hex || '#888888',
      size: v.size,
      stock_quantity: v.stock_quantity ?? 10,
      sku: `${productData.slug}-${v.colour.toLowerCase()}-${v.size.toLowerCase()}-${i}`,
    }));
    const { error: varErr } = await supabase.from('product_variants').insert(variantRows);
    if (varErr) throw varErr;
  }

  // 3. Upload images and insert product_images rows
  for (let i = 0; i < imageFiles.length; i++) {
    const file = imageFiles[i];
    const path = `products/${productId}/${Date.now()}-${i}.${file.name.split('.').pop()}`;
    const { error: upErr } = await supabase.storage
      .from('product-images')
      .upload(path, file, { cacheControl: '3600', upsert: false });
    if (upErr) throw upErr;

    const { data: { publicUrl } } = supabase.storage
      .from('product-images')
      .getPublicUrl(path);

    await supabase.from('product_images').insert({
      product_id: productId,
      url: publicUrl,
      alt_text: productData.name,
      display_order: i,
    });
  }

  return productId;
}
```

**Source:** Supabase Storage JS SDK pattern [ASSUMED — consistent with SDK docs;
verify `getPublicUrl` return shape before implementation]

### Pattern 4: Supabase Storage Upload from Browser

**What:** `supabase.storage.from(bucket).upload(path, file)` — file is a browser
`File` object from `<input type="file">`.

**Key details:**

- `product-images` bucket is `public: true` — `getPublicUrl()` returns a stable CDN
  URL immediately (no signed URL needed).
- Storage RLS `product_images_admin_insert` policy requires `is_admin()` — the anon
  key + admin JWT satisfies this.
- File path must be unique; convention: `products/{productId}/{timestamp}-{index}.{ext}`
- Max file size: 5 MB (set in `001_schema.sql` line 664). Client-side validation
  required — alert if `file.size > 5 * 1024 * 1024`.
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `image/gif`
  (set in `001_schema.sql` line 665). Validate `file.type` before upload.

```javascript
// Storage upload + get public URL
const { data, error } = await supabase.storage
  .from('product-images')
  .upload(path, file, { cacheControl: '3600', upsert: false });

const { data: { publicUrl } } = supabase.storage
  .from('product-images')
  .getPublicUrl(path);
// publicUrl is the stable CDN URL to store in product_images.url
```

[VERIFIED: 001_schema.sql bucket config; storage pattern ASSUMED from SDK docs]

### Pattern 5: Homepage Content Management

**What the homepage currently queries:**

- **Best Sellers** (`index.html` line 141–147): `supabase.from('products').select(...).order('created_at', { ascending: false }).limit(4)` — NOTE: this query does NOT filter by `is_best_seller`. It just takes the 4 newest products. [VERIFIED: index.html]
- **Featured Collections** (categories grid in `index.html`): **Hardcoded static HTML** — not pulled from `collections` table. [VERIFIED: index.html lines 68–130]
- **Testimonials** (`index.html` line 244–252): `supabase.from('testimonials').select('*').eq('is_active', true).limit(3)` — this IS live from Supabase. [VERIFIED: index.html]

**Implication for admin:** The "best sellers" section requires a real query change to
respect `is_best_seller = true`. The `index.html` best sellers query must be updated
(as part of Phase 7 plan) to filter `eq('is_best_seller', true)` and order by
`display_order` or `created_at`.

The "featured collections" grid is static HTML — the admin can control the
`collections.is_featured` flag but the homepage won't reflect it until `index.html`
is updated to query featured collections dynamically. This is a scope-expanding
dependency. **Recommendation:** Update `index.html` best sellers query to use
`is_best_seller = true` as part of Wave 1 (data layer). For featured collections, add
a dynamic query replacing the static categories grid — or simplify by having admin
set `is_best_seller` on individual products, which is immediately reflected if the
homepage query is fixed.

```javascript
// Admin: toggle is_best_seller on a product
export async function adminSetBestSeller(productId, isBestSeller) {
  const { error } = await supabase
    .from('products')
    .update({ is_best_seller: isBestSeller })
    .eq('id', productId);
  if (error) throw error;
}

// Admin: toggle is_featured on a collection
export async function adminSetCollectionFeatured(collectionId, isFeatured) {
  const { error } = await supabase
    .from('collections')
    .update({ is_featured: isFeatured })
    .eq('id', collectionId);
  if (error) throw error;
}

// Read all collections for admin (public read policy exists)
export async function adminGetCollections() {
  const { data, error } = await supabase
    .from('collections')
    .select('id, name, slug, is_featured, display_order')
    .order('display_order', { ascending: true });
  if (error) throw error;
  return data;
}
```

[VERIFIED schema: collections.is_featured column in 001_schema.sql line 228; products.is_best_seller in line 121]

### Pattern 6: Testimonials CRUD

**Schema** (from `001_schema.sql`):
```sql
testimonials (
  id            uuid PK,
  customer_name text NOT NULL,
  quote         text NOT NULL,      -- NOTE: homepage uses t.content || t.quote (both supported)
  activity_label text,
  display_order  integer DEFAULT 0,
  is_active      boolean DEFAULT true,
  created_at     timestamptz
)
```

**RLS:** `testimonials_admin_all` policy covers all operations for admin.
`testimonials_public_read` filters `is_active = true` — so admin UI must query
**without** the `is_active` filter to see inactive testimonials too.

```javascript
// Admin: fetch ALL testimonials (no is_active filter)
export async function adminGetTestimonials() {
  const { data, error } = await supabase
    .from('testimonials')
    .select('*')
    .order('display_order', { ascending: true });
  if (error) throw error;
  return data;
}

// The admin_all policy allows this despite public_read filtering inactive ones
// because RLS evaluates the most permissive matching policy.

export async function adminToggleTestimonial(id, isActive) {
  const { error } = await supabase
    .from('testimonials')
    .update({ is_active: isActive })
    .eq('id', id);
  if (error) throw error;
}

export async function adminSaveTestimonial(testimonial) {
  if (testimonial.id) {
    // Update
    const { error } = await supabase
      .from('testimonials')
      .update({
        customer_name: testimonial.customer_name,
        quote: testimonial.quote,
        activity_label: testimonial.activity_label,
        display_order: testimonial.display_order ?? 0,
        is_active: testimonial.is_active ?? true,
      })
      .eq('id', testimonial.id);
    if (error) throw error;
  } else {
    // Create
    const { error } = await supabase
      .from('testimonials')
      .insert({
        customer_name: testimonial.customer_name,
        quote: testimonial.quote,
        activity_label: testimonial.activity_label,
        display_order: testimonial.display_order ?? 0,
        is_active: testimonial.is_active ?? true,
      });
    if (error) throw error;
  }
}

export async function adminDeleteTestimonial(id) {
  const { error } = await supabase.from('testimonials').delete().eq('id', id);
  if (error) throw error;
}
```

[VERIFIED: 001_schema.sql testimonials table and RLS policies]

### Pattern 7: Orders Read View with Join

**RLS gap:** `orders` has `orders_admin_update` and `orders_admin_delete` but NO
`orders_admin_select`. Without this policy, `supabase.from('orders').select(...)` returns
an empty result for the admin user — RLS silently filters it out (no error, just
empty data). [VERIFIED: 001_schema.sql lines 387–394 — admin select policy absent]

`order_items` has `order_items_admin_all` which covers SELECT — but its public policy
uses `order_id in (select id from orders where ...)`. If the admin cannot see orders,
this sub-query returns nothing for non-admin-owned orders. The `admin_all` policy
overrides this but **only if the admin can get past the orders policy**. Since
`order_items_admin_all` is an unconditional `using (is_admin())`, it should still
work for direct `order_items` queries — but joining through `orders` requires the
orders policy fix.

**Migration 007 required:**

```sql
-- supabase/migrations/007_admin_policies.sql
create policy "orders_admin_select"
  on orders for select
  using (is_admin());
```

**Orders query pattern (after migration):**

```javascript
// Admin: fetch all orders, most recent first
export async function adminGetOrders(limit = 50) {
  const { data, error } = await supabase
    .from('orders')
    .select(`
      id,
      created_at,
      status,
      subtotal,
      guest_email,
      shipping_address,
      user_id
    `)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data;
}

// Admin: fetch line items for one order
export async function adminGetOrderItems(orderId) {
  const { data, error } = await supabase
    .from('order_items')
    .select(`
      id,
      product_name,
      variant_label,
      unit_price,
      quantity
    `)
    .eq('order_id', orderId)
    .order('created_at', { ascending: true });
  if (error) throw error;
  return data;
}
```

[VERIFIED: 001_schema.sql table schema; RLS gap confirmed by policy audit]

### Anti-Patterns to Avoid

- **Using `supabase.auth.getSession()` for the admin guard:** `getSession()` reads
  local storage and can be tampered with. Use `getUser()` which validates server-side.
- **Blocking render on admin check:** Show a loading spinner while `getUser()` resolves;
  don't flash the admin UI before the check completes. Use `adminReady: false` in Alpine
  state and `x-show="adminReady"` on the admin shell.
- **Not slugifying on the client before insert:** `products.slug` has a UNIQUE
  constraint. Generate slug from name: `name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')`.
  Check for collision before submitting.
- **Forgetting to add `is_active: true` on product insert:** The PLP query filters
  `eq('is_active', true)` so a product without this flag won't appear in the storefront.
- **Uploading images before the product row exists:** FK constraint on
  `product_images.product_id` requires the `products` row to exist first.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Rich text editor for product description | Custom textarea with formatting | Plain `<textarea>` (Phase 7 is MVP) | Scope constraint; description renders as text in PDP, not HTML |
| Image resize before upload | Canvas-based resize logic | Accept raw file up to 5 MB limit (already enforced by Storage bucket) | Phase 7 MVP; resize already done by Supabase image transform on read |
| Slug uniqueness check | Custom debounced query on every keystroke | Derive slug, attempt insert, catch unique violation error, show user feedback | Keep it simple; uniqueness enforced by DB constraint |
| Pagination for orders list | Cursor-based pagination | `.limit(50)` on first implementation; add pagination only if needed | Assessment demo load is tiny |
| Drag-and-drop image reorder | sortable.js or custom DnD | Numeric `display_order` field updated by arrow buttons | Simpler and sufficient for MVP |

---

## Runtime State Inventory

> Phase 7 adds new data management UI over existing tables. No renames or migrations
> of live data are involved.

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | Supabase `testimonials`: 5 seeded rows with `is_active=true` | No migration needed; admin UI will manage these |
| Stored data | Supabase `products`: 22 seeded rows, none have `is_best_seller=true` based on seed.sql pattern | Admin toggles best sellers via UI; index.html query must be updated to filter by is_best_seller |
| Live service config | Supabase `orders_admin_select` RLS policy: MISSING | Migration 007 required before orders read view works |
| OS-registered state | None | None |
| Secrets/env vars | `SUPABASE_URL` + `SUPABASE_ANON_KEY` in Netlify env — already set for Phase 1–6 | No changes needed |
| Build artifacts | `css/style.css` is gitignored and generated at build | Admin CSS classes must be added to `src/input.css` |

---

## Common Pitfalls

### Pitfall 1: Admin Guard Race Condition

**What goes wrong:** Alpine renders the admin UI before `getUser()` resolves. Admin
content flashes briefly to unauthenticated users before redirect fires.

**Why it happens:** Alpine `init()` is async; the DOM is already rendered by the time
the auth check completes.

**How to avoid:** Initialize Alpine state with `adminReady: false`. Wrap all admin
content in `<div x-show="adminReady">`. Set `adminReady = true` only after the
`is_admin()` check passes. Show a full-screen loading spinner during the check.

**Warning signs:** Admin sidebar flashes then disappears in incognito test.

### Pitfall 2: RLS Silent Empty Result on Orders

**What goes wrong:** `adminGetOrders()` returns `[]` with no error. Developer assumes
there are no orders.

**Why it happens:** Missing `orders_admin_select` policy — RLS silently filters all
rows for users who don't match any SELECT policy.

**How to avoid:** Apply migration 007 before building the orders view. Verify by
checking `.count` on the response: if 0 and seed orders exist, RLS is blocking.

**Warning signs:** Order list shows empty state even after confirmed checkout.

### Pitfall 3: Storage Upload Path Collision

**What goes wrong:** Two products with the same slug get images uploaded to the same
Storage path; `upsert: false` throws an error.

**Why it happens:** Using just the slug in the path without a timestamp or index.

**How to avoid:** Always include `Date.now()` and a loop index: `products/{productId}/{timestamp}-{i}.ext`.

**Warning signs:** Upload error on second image for same product.

### Pitfall 4: Testimonials Admin Query Returns Only Active Rows

**What goes wrong:** Admin hits "edit" on a deactivated testimonial but it doesn't
appear in the list.

**Why it happens:** Developer added `.eq('is_active', true)` to the admin query
(copy-pasted from the homepage query).

**How to avoid:** Admin query must have NO `is_active` filter — the `admin_all`
policy on Supabase returns all rows for admin users. Only the public policy filters by
`is_active`.

### Pitfall 5: Homepage Best Sellers Section Not Respecting `is_best_seller` Flag

**What goes wrong:** Admin marks products as best sellers but homepage still shows
the same 4 newest products.

**Why it happens:** `index.html` best sellers query currently does NOT filter by
`is_best_seller = true` — it just orders by `created_at DESC, LIMIT 4`. [VERIFIED:
index.html lines 141–147]

**How to avoid:** As part of Phase 7 Wave 1, update the `index.html` best sellers
inline query to `.eq('is_best_seller', true).order('created_at', { ascending: false }).limit(4)`.

### Pitfall 6: Product Admin Select Not Showing Inactive Products

**What goes wrong:** Admin creates a product with `is_active: false` for drafting
but it doesn't appear in the admin product list.

**Why it happens:** `products_public_read` policy filters `is_active = true`. Admin
reads through this policy unless a separate admin-read policy exists.

**How to avoid:** The existing schema has `products_admin_update` and
`products_admin_delete` but no `products_admin_select` policy. Add to migration 007:

```sql
create policy "products_admin_select"
  on products for select
  using (is_admin());
```

This overrides the public read policy so admin can see ALL products including
inactive drafts.

---

## Missing RLS Policies — Complete Gap Audit

These policies are absent from `001_schema.sql` and must be added in `007_admin_policies.sql`:

| Table | Operation | Gap | Impact |
|---|---|---|---|
| `orders` | SELECT | `orders_admin_select` missing | Admin cannot read any orders |
| `products` | SELECT | `products_admin_select` missing | Admin sees only `is_active=true` products; cannot list drafts |

Policies that ARE already correct:
- `product_variants_admin_insert/update/delete` — present [VERIFIED: 001_schema.sql line 167–179]
- `product_images_admin_insert/update/delete` — present [VERIFIED: 001_schema.sql line 199–215]
- `testimonials_admin_all` — present [VERIFIED: 001_schema.sql line 506–509]
- `order_items_admin_all` — present [VERIFIED: 001_schema.sql line 439–443]
- `storage.objects` admin policies for `product-images` — present [VERIFIED: 001_schema.sql lines 692–717]
- `collections_admin_insert/update/delete` — present [VERIFIED: 001_schema.sql line 239–251]

---

## Code Examples

### Admin Guard (complete init function)

```javascript
// Inside admin.html main x-data object
async init() {
  // Must use getUser() not getSession() — server-side JWT verification
  const { data: { user }, error } = await window.supabase.auth.getUser();
  if (error || !user) {
    window.location.replace('/index.html');
    return;
  }
  const role = user.app_metadata?.role;
  if (role !== 'admin') {
    window.location.replace('/index.html');
    return;
  }
  this.adminReady = true;
  // Set initial section from hash
  const hash = window.location.hash.replace('#', '');
  this.activeSection = ['products', 'content', 'testimonials', 'orders'].includes(hash)
    ? hash
    : 'products';
  await this.loadSection(this.activeSection);
  // Listen for hash changes (back/forward nav)
  window.addEventListener('hashchange', async () => {
    const h = window.location.hash.replace('#', '');
    this.activeSection = h || 'products';
    await this.loadSection(this.activeSection);
  });
}
```

### Slug Generation Helper

```javascript
// js/admin.js
export function toSlug(name) {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}
```

### Product Image Preview (client-side, no upload yet)

```html
<!-- Image file input with preview -->
<input
  type="file"
  accept="image/jpeg,image/png,image/webp"
  multiple
  @change="previewImages($event)"
>

<script>
// In admin x-data
imageFiles: [],
imagePreviews: [],
previewImages(event) {
  const files = Array.from(event.target.files);
  const oversized = files.filter(f => f.size > 5 * 1024 * 1024);
  if (oversized.length > 0) {
    alert('One or more files exceed 5 MB limit');
    return;
  }
  this.imageFiles = files;
  this.imagePreviews = [];
  files.forEach(file => {
    const reader = new FileReader();
    reader.onload = e => { this.imagePreviews.push(e.target.result); };
    reader.readAsDataURL(file);
  });
}
</script>
```

### Order Detail Drill-Down

```javascript
// In admin.html x-data orders section
async openOrder(orderId) {
  this.selectedOrderId = orderId;
  this.orderItems = [];
  this.loadingItems = true;
  try {
    this.orderItems = await window.adminGetOrderItems(orderId);
  } finally {
    this.loadingItems = false;
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Separate admin HTML pages per section | Single admin.html with hash routing | Phase 7 design decision | Fewer files; guard runs once; no nav between admin pages |
| Service role key in admin client | Anon key + RLS `is_admin()` | Phase 1 design decision | Safe to deploy; admin credentials managed server-side via Supabase dashboard |

---

## Open Questions

1. **Does the admin need to see inactive products in the product list?**
   - What we know: `products_public_read` filters `is_active = true`; no admin SELECT policy exists
   - What's unclear: Whether the planner should add `products_admin_select` to migration 007
   - Recommendation: Yes — add it. An admin editing drafts needs to see them.

2. **Should featured collections drive the homepage grid dynamically?**
   - What we know: `index.html` categories grid is hardcoded static HTML; `collections.is_featured` flag exists but is not currently queried by the homepage
   - What's unclear: Whether Phase 7 should update `index.html` to query `collections.is_featured = true` or leave the grid static
   - Recommendation: Update `index.html` best sellers to use `is_best_seller = true` (this is clearly needed). For collections, a simpler MVP scope is to leave the categories grid static but let admin set `is_featured` on collections for future use — this avoids a significant homepage refactor in the final phase.

3. **Toastify in admin.html — is the CDN tag missing?**
   - What we know: Current `admin.html` stub does not include the Toastify CDN link
   - What's unclear: Whether it was omitted intentionally
   - Recommendation: Add it to `admin.html` head in Wave 1 CSS plan, consistent with `product.html` and `checkout.html`.

---

## Environment Availability

> Phase 7 is code-only with no new external tools.

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Supabase project (live) | All admin operations | Checked via anon key in existing env | 2.x SDK | — |
| Netlify build | CSS compilation | Confirmed working (Phases 1–6 deployed) | — | — |
| Node.js (local dev) | Tailwind CLI watch | Available (used in all prior phases) | — | — |

**No missing dependencies.**

---

## Validation Architecture

> `workflow.nyquist_validation` not found in `.planning/config.json` (no config.json
> present) — treating as enabled.

Phase 7 success criteria are best verified through manual incognito testing (auth
guard) and live Supabase queries (data changes reflected on storefront). No automated
test framework is configured in the project. Formal test infrastructure is out of
scope for an assessment-grade build.

**Manual verification checklist (replaces automated test map):**
| Req | Behavior | Verification Method |
|---|---|---|
| F-036 | Non-admin redirect | Incognito → /admin.html → lands on /index.html |
| F-037 | Product create appears on PLP | Create product → open /shop.html in new tab |
| F-038 | Best sellers update | Toggle is_best_seller → reload /index.html |
| F-039 | Testimonials toggle | Deactivate testimonial → reload /index.html → not shown |
| F-040 | Order list loads | Open admin orders section → orders from checkout visible |
| F-041 | Order drill-down | Click order → line items (name/variant/qty/price) visible |
| F-042 | Image upload | Upload image → verify URL appears in product_images table |

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | YES — admin check | `supabase.auth.getUser()` (server-validated JWT) |
| V3 Session Management | YES | Supabase auto-refresh JWT |
| V4 Access Control | YES — critical | `is_admin()` RLS on every admin write + read; client redirect is UX only |
| V5 Input Validation | YES | Client-side: file type/size check; slug sanitization; required field validation before insert |
| V6 Cryptography | NO | No crypto operations in admin panel |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Non-admin user calls admin Supabase operations directly (bypass client redirect) | Elevation of Privilege | RLS `is_admin()` on ALL admin tables blocks server-side — client redirect alone is insufficient |
| Admin uploads malicious file via Storage | Tampering | Bucket MIME type allowlist (`image/jpeg,image/png,image/webp,image/gif`) enforced by Supabase Storage — verified in `001_schema.sql` |
| XSS via unsanitized product description stored in DB | Information Disclosure | Alpine `x-text` (not `x-html`) used for display in PLP/PDP — text content only, no HTML injection |
| Slug collision causes 409 on product insert | DoS (minor) | Catch unique constraint error, surface friendly message to admin |
| `service_role` key exposed via admin UI | Information Disclosure | Admin panel uses anon key only; service_role key is never used in any client file (confirmed by grep) |

---

## Sources

### Primary (HIGH confidence — verified against codebase)

- `/Users/andika/Desktop/Elvora/supabase/migrations/001_schema.sql` — Full schema, all RLS policies, storage bucket config, `is_admin()` function definition
- `/Users/andika/Desktop/Elvora/js/auth.js` — Auth patterns, `getUser()` usage
- `/Users/andika/Desktop/Elvora/js/supabase.js` — Supabase client setup, CDN ESM import
- `/Users/andika/Desktop/Elvora/js/components.js` — Alpine store registration, `initAuth()`, nav HTML pattern
- `/Users/andika/Desktop/Elvora/js/admin.js` — Existing stub (confirms file location)
- `/Users/andika/Desktop/Elvora/admin.html` — Existing admin shell (confirms boilerplate pattern)
- `/Users/andika/Desktop/Elvora/index.html` — Confirmed: best sellers query has no `is_best_seller` filter; categories grid is static HTML; testimonials use `is_active` filter

### Secondary (MEDIUM confidence)

- `/Users/andika/Desktop/Elvora/.planning/STATE.md` — Confirmed admin role in `raw_app_meta_data`; `is_admin()` live in Supabase
- `/Users/andika/Desktop/Elvora/.planning/ROADMAP.md` — Phase 7 requirements scope

### Tertiary (LOW confidence — ASSUMED from training knowledge)

- Supabase Storage `getPublicUrl()` return shape `{ data: { publicUrl } }` — consistent with SDK docs but not verified against live CDN in this session
- Alpine `x-show` vs `x-if` behavior for section switching — based on known Alpine behavior; `x-show` preferred for fast toggle (keeps DOM)

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Toastify CDN absent from admin.html stub | Standard Stack | Low — easy to add in Wave 1 |
| A2 | `supabase.storage.from('product-images').getPublicUrl(path)` returns `{ data: { publicUrl } }` | Pattern 4 | Medium — would need to adjust return destructuring in admin.js |
| A3 | Alpine `x-show` sections initialize lazily enough that admin check fires before content renders | Pattern 1 pitfall | Low — mitigated by `adminReady: false` guard |
| A4 | Seed data: `is_best_seller = false` on all 22 products | Runtime State Inventory | Low — admin can toggle after panel is built |

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies already in codebase, no new packages
- RLS policy audit: HIGH — read directly from migration file
- Architecture patterns: HIGH — grounded in existing codebase patterns (components.js, account.html, checkout.html)
- Code examples: MEDIUM — schema verified, SDK call shapes assumed from training knowledge
- Homepage best sellers gap: HIGH — confirmed by direct index.html read

**Research date:** 2026-06-18
**Valid until:** 2026-08-18 (stable stack, 60-day horizon)
