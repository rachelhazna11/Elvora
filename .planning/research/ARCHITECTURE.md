# Architecture Patterns

**Project:** Elvora — Premium Women's Activewear E-Commerce
**Domain:** Static frontend + Supabase backend + Claude AI integration
**Researched:** 2026-06-10

---

## Recommended Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     BROWSER (Client)                        │
│  HTML/CSS/JS  ─── Supabase JS SDK ─── Supabase Anon Key    │
│                         │                                   │
│         calls Edge Function for AI (no direct API key)     │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
        ┌────────────────┴─────────────────┐
        │           SUPABASE               │
        │  ┌────────────────────────────┐  │
        │  │  PostgreSQL (Database)     │  │
        │  │  - Products / Variants     │  │
        │  │  - Categories              │  │
        │  │  - Cart / Wishlist         │  │
        │  │  - Orders / Order Items    │  │
        │  │  - User Profiles           │  │
        │  │  - Reviews                 │  │
        │  │  - AI Style Preferences    │  │
        │  └────────────────────────────┘  │
        │  ┌────────────────────────────┐  │
        │  │  Auth (JWT sessions)       │  │
        │  │  - Email/password signup   │  │
        │  │  - Session refresh tokens  │  │
        │  │  - app_metadata role claim │  │
        │  └────────────────────────────┘  │
        │  ┌────────────────────────────┐  │
        │  │  Storage (Cloudflare CDN)  │  │
        │  │  - product-images (public) │  │
        │  │  - user-uploads (private)  │  │
        │  └────────────────────────────┘  │
        │  ┌────────────────────────────┐  │
        │  │  Edge Functions (Deno)     │  │
        │  │  - style-match (AI proxy)  │  │
        │  └────────────────────────────┘  │
        └──────────────────────────────────┘
                         │
                  calls Anthropic API
                  (Claude vision)
                         │
                 ┌───────┴────────┐
                 │  Anthropic API  │
                 │  claude-sonnet  │
                 └────────────────┘

Frontend hosted: Netlify / Vercel (static files via CDN)
Backend hosted: Supabase cloud (managed)
```

---

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| Frontend JS | UI rendering, routing, form handling, cart state | Supabase JS SDK, Edge Functions |
| Supabase Auth | User identity, JWT tokens, session management | Frontend SDK |
| Supabase DB (PostgreSQL) | All persistent data with RLS enforcement | Frontend SDK (read/write via RLS), Edge Functions |
| Supabase Storage | File hosting for product images and user uploads | Frontend SDK (upload/read), Edge Function (read URL) |
| Edge Function: `style-match` | Receives uploaded image URL + user preferences, calls Claude API, returns product IDs | Frontend (HTTP POST), Anthropic API, Supabase DB (product query) |
| Anthropic Claude API | Image analysis, style profiling, recommendation text generation | Edge Function only — never frontend directly |
| Netlify/Vercel | Serves static HTML/CSS/JS files globally via CDN | Browser only |

---

## 1. Database Schema

### Design Principles
- Products are read by everyone (public). Cart, wishlist, orders are user-scoped. Admin writes apply to catalog tables.
- Variants (size + color) are separate rows in `product_variants`, not JSON columns — enables per-variant inventory stubs and future stock tracking.
- Orders snapshot price at time of purchase — never join back to live product price.
- `user_profiles` extends `auth.users` via a trigger — do not store auth data redundantly.

### Core Tables

```sql
-- Categories (activity: padel, pilates, tennis, training, etc.)
create table categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  slug        text not null unique,
  description text,
  image_url   text,
  sort_order  int default 0
);

-- Products
create table products (
  id              uuid primary key default gen_random_uuid(),
  category_id     uuid references categories(id),
  name            text not null,
  slug            text not null unique,
  description     text,
  materials       text,                   -- fabric/care details
  styling_notes   text,                   -- editorial suggestions
  base_price      numeric(10,2) not null,
  is_published    boolean default false,
  created_at      timestamptz default now()
);

-- Product variants (one row per size+color combination)
create table product_variants (
  id           uuid primary key default gen_random_uuid(),
  product_id   uuid references products(id) on delete cascade,
  color_name   text not null,
  color_hex    text,                      -- "#A8B5A3" for swatch rendering
  size         text not null,             -- XS/S/M/L/XL
  price        numeric(10,2),             -- null = inherits base_price
  sku          text unique,
  in_stock     boolean default true
);

-- Product images (ordered, supports multiple per variant or product)
create table product_images (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid references products(id) on delete cascade,
  variant_id  uuid references product_variants(id),  -- null = product-level image
  storage_path text not null,            -- path in Supabase Storage
  alt_text    text,
  sort_order  int default 0,
  is_primary  boolean default false
);

-- User profiles (extends auth.users)
create table user_profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  full_name      text,
  avatar_url     text,
  preferred_sizes jsonb,                 -- {"tops": "S", "bottoms": "M"}
  style_notes    text,
  created_at     timestamptz default now()
);

-- Wishlist
create table wishlist_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade,
  product_id uuid references products(id) on delete cascade,
  added_at   timestamptz default now(),
  unique(user_id, product_id)
);

-- Cart
create table cart_items (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  variant_id  uuid references product_variants(id) on delete cascade,
  quantity    int not null default 1 check (quantity > 0),
  added_at    timestamptz default now(),
  unique(user_id, variant_id)
);

-- Orders (price snapshot at checkout)
create table orders (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references auth.users(id),
  status          text default 'pending',   -- pending, confirmed, shipped, delivered, cancelled
  subtotal        numeric(10,2) not null,
  discount_amount numeric(10,2) default 0,
  total           numeric(10,2) not null,
  shipping_name   text,
  shipping_address jsonb,
  promo_code      text,
  created_at      timestamptz default now()
);

-- Order items (snapshot: store price + names at time of order)
create table order_items (
  id              uuid primary key default gen_random_uuid(),
  order_id        uuid references orders(id) on delete cascade,
  variant_id      uuid references product_variants(id),
  product_name    text not null,         -- snapshot
  variant_label   text not null,         -- "Sage Green / M" snapshot
  unit_price      numeric(10,2) not null, -- snapshot
  quantity        int not null
);

-- Reviews
create table reviews (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid references products(id) on delete cascade,
  user_id     uuid references auth.users(id),
  rating      int not null check (rating between 1 and 5),
  body        text,
  is_approved boolean default false,
  created_at  timestamptz default now()
);

-- AI Style preferences (saved after each Style Match session)
create table ai_style_sessions (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid references auth.users(id) on delete cascade,
  photo_storage_path text,              -- path in user-uploads bucket
  activity_context  text,               -- "padel", "pilates", etc.
  style_summary     text,               -- Claude's analysis text
  recommended_ids   uuid[],             -- product IDs returned
  created_at        timestamptz default now()
);

-- Homepage / content (admin-editable)
create table testimonials (
  id          uuid primary key default gen_random_uuid(),
  author_name text not null,
  body        text not null,
  rating      int,
  is_active   boolean default true,
  sort_order  int default 0
);

-- Trigger: auto-create user_profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.user_profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

### Data Flow: Catalog Read
```
Browser → Supabase JS SDK → PostgreSQL (RLS: anon allowed on products)
           ← product rows + joined variant/image data ←
```

### Data Flow: Order Creation
```
Browser (checkout form)
  → POST cart_items (user-scoped)
  → INSERT orders + order_items (price copied at time of insert)
  → DELETE cart_items for user
  ← order confirmation ←
```

---

## 2. Row Level Security (RLS)

### Principle
Enable RLS on every table. Default-deny unless a policy explicitly allows. Never rely on application-layer checks alone — RLS enforces at the database level regardless of how the table is accessed.

```sql
-- Enable RLS on all tables
alter table products enable row level security;
alter table product_variants enable row level security;
alter table product_images enable row level security;
alter table categories enable row level security;
alter table cart_items enable row level security;
alter table wishlist_items enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table reviews enable row level security;
alter table user_profiles enable row level security;
alter table ai_style_sessions enable row level security;
alter table testimonials enable row level security;
```

### Public Read Policies (catalog)

```sql
-- Anyone (anon + authenticated) can read published products
create policy "Public: read published products"
  on products for select
  to anon, authenticated
  using (is_published = true);

create policy "Public: read product variants"
  on product_variants for select
  to anon, authenticated
  using (exists (
    select 1 from products p
    where p.id = product_id and p.is_published = true
  ));

create policy "Public: read product images"
  on product_images for select
  to anon, authenticated
  using (true);

create policy "Public: read categories"
  on categories for select
  to anon, authenticated
  using (true);

create policy "Public: read approved reviews"
  on reviews for select
  to anon, authenticated
  using (is_approved = true);

create policy "Public: read active testimonials"
  on testimonials for select
  to anon, authenticated
  using (is_active = true);
```

### User-Owned Data Policies

```sql
-- Cart: user can only see and manage their own items
create policy "User: own cart select"
  on cart_items for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "User: own cart insert"
  on cart_items for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "User: own cart update"
  on cart_items for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "User: own cart delete"
  on cart_items for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- Wishlist: same pattern as cart
create policy "User: own wishlist"
  on wishlist_items for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Orders: user can view their own orders only
create policy "User: own orders select"
  on orders for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "User: insert own order"
  on orders for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- Order items: accessible if user owns the order
create policy "User: own order items"
  on order_items for select
  to authenticated
  using (exists (
    select 1 from orders o
    where o.id = order_id
    and (select auth.uid()) = o.user_id
  ));

-- User profile: own profile only
create policy "User: own profile"
  on user_profiles for all
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- AI sessions: own sessions only
create policy "User: own AI sessions"
  on ai_style_sessions for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Reviews: users can insert and manage their own
create policy "User: insert own review"
  on reviews for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "User: update own review"
  on reviews for update
  to authenticated
  using ((select auth.uid()) = user_id);
```

### Admin Policies

Admin role is stored in `auth.users.raw_app_meta_data->>'role'`. This field is only writable via the Supabase service role key (server-side), not by users themselves — making it safe for authorization.

```sql
-- Helper function for cleaner policies
create or replace function is_admin()
returns boolean language sql security definer as $$
  select coalesce(
    (select auth.jwt()->'app_metadata'->>'role') = 'admin',
    false
  );
$$;

-- Admin: full access to products
create policy "Admin: manage products"
  on products for all
  to authenticated
  using (is_admin())
  with check (is_admin());

-- Admin: manage variants, images, categories, testimonials
create policy "Admin: manage product_variants"
  on product_variants for all
  to authenticated
  using (is_admin()) with check (is_admin());

create policy "Admin: manage product_images"
  on product_images for all
  to authenticated
  using (is_admin()) with check (is_admin());

create policy "Admin: manage categories"
  on categories for all
  to authenticated
  using (is_admin()) with check (is_admin());

create policy "Admin: manage reviews"
  on reviews for all
  to authenticated
  using (is_admin()) with check (is_admin());

create policy "Admin: manage testimonials"
  on testimonials for all
  to authenticated
  using (is_admin()) with check (is_admin());

-- Admin: read all orders
create policy "Admin: read all orders"
  on orders for select
  to authenticated
  using (is_admin());
```

### Assigning Admin Role
Admin role is set via service role key only — never from the client:

```sql
-- Run server-side or via Supabase dashboard SQL editor
update auth.users
  set raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
  where email = 'admin@elvora.com';
```

---

## 3. Auth Patterns

### Session Lifecycle
- Supabase Auth issues a short-lived access token (JWT, 1-hour default) and a long-lived refresh token.
- The JS SDK (`@supabase/supabase-js`) auto-refreshes sessions every ~50 minutes in the background.
- Session is persisted in `localStorage` automatically.
- On page load: call `supabase.auth.getSession()` to restore session without a network round-trip.

### Signup / Login

```javascript
// Signup
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure-password',
  options: {
    data: { full_name: 'Amara Sari' }   // goes into raw_user_meta_data
  }
});

// Login
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'secure-password'
});

// Logout
await supabase.auth.signOut();
```

### Protected Route Guard (vanilla JS)

```javascript
// On any protected page (account, checkout, wishlist, admin)
async function requireAuth(redirectTo = '/login.html') {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.href = redirectTo;
    return null;
  }
  return session;
}

// Admin route guard
async function requireAdmin() {
  const session = await requireAuth('/login.html');
  if (!session) return;
  const role = session.user?.app_metadata?.role;
  if (role !== 'admin') {
    window.location.href = '/';
  }
}
```

### Auth State Listener

```javascript
// Place in main app init — reacts to login/logout across tabs
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_IN') {
    mergePendingCart(session.user.id);   // merge localStorage cart on login
    updateNavUI(session);
  }
  if (event === 'SIGNED_OUT') {
    clearCartUI();
    updateNavUI(null);
  }
});
```

---

## 4. Storage Patterns

### Bucket Design

| Bucket | Type | Purpose | RLS |
|--------|------|---------|-----|
| `product-images` | Public | Product photography served via CDN | Read: anyone; Write: admin only |
| `user-uploads` | Private | User photos for AI Style Match | Read/Write: owning user only |

### Why Public for Product Images
Public buckets bypass auth on reads — the CDN can aggressively cache without per-request authorization checks. This is the correct choice for product photography: lower latency, better cache hit rates, no token required in the URL.

### Why Private for User Photos
User-uploaded style photos are personal. Signed URLs (time-limited, ~60 seconds) are generated only when needed (e.g., when the Edge Function processes them). Do not expose these URLs permanently.

### Creating Buckets

```sql
-- Create via Supabase dashboard or API
-- product-images: public = true
-- user-uploads: public = false

-- Storage RLS for user-uploads (set in Supabase Storage policies UI)
-- Allow authenticated users to upload to their own folder:
-- Bucket: user-uploads
-- Allowed path: {auth.uid()}/*

-- Policy: users can read their own uploads
create policy "User: read own uploads"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'user-uploads' and (select auth.uid())::text = (storage.foldername(name))[1]);

create policy "User: insert own uploads"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'user-uploads' and (select auth.uid())::text = (storage.foldername(name))[1]);
```

### Upload Pattern (user photo for AI match)

```javascript
async function uploadStylePhoto(file, userId) {
  const ext = file.name.split('.').pop();
  const path = `${userId}/${Date.now()}.${ext}`;

  // Resize before upload: keep under 1568px long edge to control token costs
  const resized = await resizeImage(file, 1568);

  const { data, error } = await supabase.storage
    .from('user-uploads')
    .upload(path, resized, { contentType: file.type, upsert: false });

  if (error) throw error;
  return path;  // store path, not full URL
}
```

### Product Image Upload (admin)

```javascript
async function uploadProductImage(file, productId) {
  const path = `products/${productId}/${Date.now()}-${file.name}`;
  const { data, error } = await supabase.storage
    .from('product-images')
    .upload(path, file, { contentType: file.type });
  if (error) throw error;
  // Public URL — no expiry needed
  const { data: { publicUrl } } = supabase.storage
    .from('product-images')
    .getPublicUrl(path);
  return publicUrl;
}
```

---

## 5. Admin Panel Architecture

### Design Decision
Admin panel lives at `/admin/*` routes within the same HTML/JS application. Not a separate app or server. Protected by client-side route guard + database-level RLS. The service role key is never shipped to the browser — admin writes go through the standard Supabase anon key but are gated by the `is_admin()` RLS function.

### Role Assignment Flow
```
Supabase Dashboard SQL Editor (secure, server-side)
  → update auth.users set raw_app_meta_data = '{"role":"admin"}'
  → user logs in → JWT contains app_metadata.role = "admin"
  → is_admin() returns true in RLS policies
  → admin writes to catalog tables succeed
```

### Admin Route Structure

```
/admin/index.html          → dashboard overview
/admin/products.html       → product list + CRUD
/admin/products/new.html   → create product form
/admin/categories.html     → category management
/admin/orders.html         → order list (read-only for now)
/admin/testimonials.html   → testimonial management
/admin/content.html        → homepage section content
```

### Admin Route Guard (must run on every admin page)

```javascript
// admin/auth-guard.js — import at top of every admin page script
import { supabase } from '../lib/supabase.js';

export async function enforceAdmin() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) { window.location.href = '/login.html'; return; }
  if (session.user?.app_metadata?.role !== 'admin') {
    window.location.href = '/';
  }
}
```

### Admin CRUD Pattern

Admin uses the same Supabase JS client. RLS allows writes because `is_admin()` returns true. No special client configuration needed.

```javascript
// Admin: create a product
const { data, error } = await supabase
  .from('products')
  .insert({ name, slug, description, base_price, category_id, is_published: false });
```

---

## 6. AI Style Match Flow

### Architecture Principle
The Anthropic API key must never reach the browser. The correct pattern is: frontend uploads photo → calls a Supabase Edge Function (server-side) → Edge Function calls Claude → returns product IDs → frontend renders recommendations.

### Full Data Flow

```
1. User selects photo + activity context (e.g. "pilates")
   ↓
2. Frontend: resizeImage(file, 1568px max)
   ↓
3. Frontend: uploadStylePhoto() → Supabase Storage user-uploads/{uid}/photo.jpg
             → returns storage path
   ↓
4. Frontend: generate signed URL for the photo (60s expiry)
   const { data } = await supabase.storage
     .from('user-uploads')
     .createSignedUrl(path, 60);
   ↓
5. Frontend: POST to Edge Function /functions/v1/style-match
   {
     "photo_url": signedUrl,
     "activity": "pilates",
     "preferences": { "style": "minimal", "colors": "neutral" }
   }
   Authorization: Bearer <user JWT>
   ↓
6. Edge Function (Deno, server-side):
   a. Verify Supabase JWT (supabase.auth.getUser(token))
   b. Fetch product catalog summary from DB (name, category, colors, id)
   c. Build Claude prompt with image URL + catalog context
   d. POST to https://api.anthropic.com/v1/messages
      model: claude-sonnet-4-6
      messages: [{ role: "user", content: [
        { type: "image", source: { type: "url", url: photoUrl } },
        { type: "text",  text: catalogPrompt }
      ]}]
   e. Parse Claude response → extract recommended product IDs
   f. Save session to ai_style_sessions table
   g. Return { product_ids: [...], style_summary: "..." }
   ↓
7. Frontend: query products by returned IDs
   → render recommendation cards
   ↓
8. Optional: save preferences to user_profiles.style_notes
```

### Edge Function: `style-match`

```typescript
// supabase/functions/style-match/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (req) => {
  // 1. Verify user JWT
  const authHeader = req.headers.get('Authorization');
  const userClient = createClient(SUPABASE_URL, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader! } }
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return new Response('Unauthorized', { status: 401 });

  const { photo_url, activity, preferences } = await req.json();

  // 2. Fetch catalog context (product names, colors, category)
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const { data: products } = await adminClient
    .from('products')
    .select('id, name, categories(name), styling_notes')
    .eq('is_published', true)
    .limit(50);

  const catalogContext = products
    .map(p => `ID:${p.id} | ${p.categories?.name} | ${p.name} | ${p.styling_notes}`)
    .join('\n');

  // 3. Call Claude vision API
  const claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json'
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-6',
      max_tokens: 1024,
      messages: [{
        role: 'user',
        content: [
          { type: 'image', source: { type: 'url', url: photo_url } },
          { type: 'text', text: buildStylePrompt(activity, preferences, catalogContext) }
        ]
      }]
    })
  });

  const claudeData = await claudeRes.json();
  const responseText = claudeData.content[0].text;

  // 4. Parse product IDs from response (structured via prompt)
  const recommendedIds = parseProductIds(responseText);

  // 5. Save session
  await adminClient.from('ai_style_sessions').insert({
    user_id: user.id,
    photo_storage_path: extractPathFromUrl(photo_url),
    activity_context: activity,
    style_summary: responseText,
    recommended_ids: recommendedIds
  });

  return new Response(JSON.stringify({ product_ids: recommendedIds, style_summary: responseText }), {
    headers: { 'Content-Type': 'application/json' }
  });
});

function buildStylePrompt(activity, preferences, catalog) {
  return `You are a personal stylist for Elvora, a premium women's activewear brand.

Analyze the person in this photo and recommend 3-5 products from our catalog that would suit their:
- Body proportions and silhouette
- Style aesthetic visible in the photo
- Activity context: ${activity}
- Stated preferences: ${JSON.stringify(preferences)}

CATALOG:
${catalog}

Respond in this exact JSON format:
{
  "recommended_ids": ["uuid1", "uuid2", "uuid3"],
  "style_summary": "2-3 sentence personal stylist note",
  "color_palette": ["#hex1", "#hex2"]
}`;
}
```

### Claude Prompt Design Principles
- Instruct Claude to return structured JSON — parse `recommended_ids` array directly.
- Pass catalog as compact text lines (ID + category + name + styling notes), not full product JSON.
- Keep catalog payload under ~2000 tokens (50 products at ~40 tokens each = 2000 tokens).
- Resize user photos to max 1568px long edge before upload to keep image tokens at ~1568 (roughly $0.005 per call with claude-sonnet-4-6).
- Include activity context and stated preferences in the prompt to constrain recommendations.

---

## 7. Cart Management (localStorage + Supabase Hybrid)

### Strategy
- Guest users (not logged in): cart lives in `localStorage` only.
- Authenticated users: cart lives in Supabase `cart_items` table, synced on every add/remove.
- On login: merge localStorage cart into Supabase, then clear localStorage.

### Why Hybrid
Building a fully Supabase-backed cart for anonymous users requires session IDs, anonymous auth, and complex cleanup. For a student project scope, localStorage for guests is simpler, reliable, and industry-standard (Shopify does this). Supabase cart for logged-in users ensures persistence across devices.

### Cart Module

```javascript
// lib/cart.js

const CART_KEY = 'elvora_cart';

function getLocalCart() {
  return JSON.parse(localStorage.getItem(CART_KEY) || '[]');
  // shape: [{ variant_id, quantity, product_name, variant_label, price, image_url }]
}

function saveLocalCart(items) {
  localStorage.setItem(CART_KEY, JSON.stringify(items));
  dispatchCartUpdate(items);
}

async function addToCart(variantId, quantity = 1) {
  const session = (await supabase.auth.getSession()).data.session;
  if (!session) {
    addToLocalCart(variantId, quantity);
    return;
  }
  const { error } = await supabase.from('cart_items')
    .upsert({ user_id: session.user.id, variant_id: variantId, quantity },
             { onConflict: 'user_id,variant_id', ignoreDuplicates: false });
  if (!error) await refreshRemoteCartUI();
}

async function mergeCartOnLogin(userId) {
  const local = getLocalCart();
  if (!local.length) return;
  const upserts = local.map(item => ({
    user_id: userId,
    variant_id: item.variant_id,
    quantity: item.quantity
  }));
  await supabase.from('cart_items')
    .upsert(upserts, { onConflict: 'user_id,variant_id' });
  localStorage.removeItem(CART_KEY);
}

async function getCart() {
  const session = (await supabase.auth.getSession()).data.session;
  if (!session) return enrichLocalCart(getLocalCart());
  const { data } = await supabase
    .from('cart_items')
    .select(`quantity, product_variants(id, size, color_name, price, products(name, base_price, product_images(storage_path)))`)
    .eq('user_id', session.user.id);
  return data;
}
```

---

## 8. API Key Security

### The Rule
The Anthropic API key must never appear in browser JavaScript, HTML, or any file shipped to the client. Exposing it means anyone inspecting the network tab or source code can extract and abuse it.

### Correct Pattern: Supabase Edge Function as Proxy

```
Browser → POST /functions/v1/style-match (with Supabase JWT, no Anthropic key)
Edge Function → POST api.anthropic.com (with Anthropic key from env var)
```

The Edge Function environment variable is set in the Supabase dashboard under Project Settings → Edge Functions → Secrets. It is never returned in responses and never bundled in client code.

### CORS
Edge Functions handle CORS. Add the `Access-Control-Allow-Origin` header to allow your frontend domain:

```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://elvora.netlify.app',
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

// Handle OPTIONS preflight
if (req.method === 'OPTIONS') {
  return new Response('ok', { headers: corsHeaders });
}
```

During development, use `'*'` for CORS origin, then lock to production domain before deployment.

### Supabase Anon Key (safe to expose)
The Supabase `anon` key is designed to be public. It identifies your project but has no privileges beyond what RLS allows. Treat it like a project identifier, not a secret. Do not confuse it with the `service_role` key — the service role key bypasses RLS entirely and must never leave the server.

---

## 9. Build Order

The dependency graph determines what must exist before each subsequent layer can be built. Build in this sequence:

### Phase 1: Foundation (Data Layer + Auth)
**What:** Supabase project setup, database schema, RLS policies, Auth configuration, seed data.
**Why first:** Every feature depends on data existing. Auth is required before cart, wishlist, and orders can work. Seed data enables visual work from day one.
**Deliverables:** All tables created, RLS enabled, admin role assigned, 20+ products seeded with images, categories seeded.

### Phase 2: Static Shell + Design System
**What:** HTML/CSS design system (typography, colors, spacing, components), homepage shell, navigation, responsive grid.
**Why second:** Establishes the visual language. All subsequent feature pages inherit from this. Can proceed in parallel with Phase 1 once schema is locked.
**Deliverables:** Design tokens, component library (buttons, cards, forms), homepage layout, responsive nav.

### Phase 3: Catalog (Depends on Phase 1)
**What:** Product listing pages, product detail pages, category browse, search, filtering.
**Why third:** Catalog is read-only against Phase 1 data. No auth required. This is the core browsable store.
**Deliverables:** `/products.html`, `/products/[slug].html`, category filters, search, product cards with variant swatches.

### Phase 4: Auth + Account (Depends on Phase 1, 2)
**What:** Signup, login, logout, account dashboard, profile edit, order history, wishlist.
**Why fourth:** Auth gates cart persistence and wishlist. Order history requires orders to exist (built next).
**Deliverables:** `/login.html`, `/signup.html`, `/account/*`, wishlist CRUD, session persistence.

### Phase 5: Cart + Checkout (Depends on Phase 3, 4)
**What:** Add to cart (guest + auth), cart page, checkout form, order creation, order confirmation.
**Why fifth:** Requires products from Phase 3 and auth from Phase 4. Cart merge happens at login (Phase 4 trigger).
**Deliverables:** Cart drawer/page, checkout flow, order confirmation, order stored in DB.

### Phase 6: Admin Panel (Depends on Phase 1, 4)
**What:** Admin-protected routes, product CRUD, category management, testimonial management, image upload.
**Why sixth:** Requires auth (Phase 4) and the full schema (Phase 1). Admin is isolated — does not block customer features.
**Deliverables:** `/admin/*` pages, full catalog CRUD, image upload to Storage, order read view.

### Phase 7: AI Style Match (Depends on Phase 1, 4, 5)
**What:** Edge Function deployment, photo upload flow, Claude integration, recommendation display, session saving.
**Why last:** Most complex integration. Requires the product catalog to be populated (Phase 1/Admin), auth for session saving (Phase 4), and Storage configured (part of Phase 1 setup). Build last to avoid blocking core e-commerce work.
**Deliverables:** `/style-match.html`, Edge Function deployed, recommendations rendering product cards, session history in account.

### Dependency Summary

```
Phase 1: Schema + Seed + Auth Config
    ↓
Phase 2: Design System (can overlap with Phase 1)
    ↓
Phase 3: Catalog (read-only, needs Phase 1 data)
    ↓
Phase 4: Auth + Account (needs Phase 1 + 2)
    ↓
Phase 5: Cart + Checkout (needs Phase 3 + 4)
    ↓
Phase 6: Admin Panel (needs Phase 1 + 4)
    ↓
Phase 7: AI Style Match (needs Phase 1 + 4 + Storage + Edge Functions)
```

---

## 10. Deployment Architecture

### Target: Static Frontend + Supabase Backend

No server to manage. No Docker. No custom API server. The entire architecture is two managed services.

```
┌──────────────────────────────────────┐
│  Netlify (or Vercel)                 │
│  Static file hosting + global CDN   │
│  ├── HTML files (all pages)          │
│  ├── CSS bundles                     │
│  ├── JS modules                      │
│  └── Public assets (fonts, icons)   │
│                                      │
│  Environment Variables (build time)  │
│  SUPABASE_URL=https://...            │
│  SUPABASE_ANON_KEY=eyJ...            │
└──────────────────────────────────────┘
              ↕ HTTPS (Supabase JS SDK + Edge Function calls)
┌──────────────────────────────────────┐
│  Supabase (managed cloud)            │
│  ├── PostgreSQL (database + RLS)     │
│  ├── Auth (JWT, email/password)      │
│  ├── Storage (product-images CDN,   │
│  │            user-uploads private)  │
│  └── Edge Functions (style-match)   │
│                                      │
│  Secrets (server-side only)          │
│  ANTHROPIC_API_KEY=sk-ant-...        │
│  SUPABASE_SERVICE_ROLE_KEY=eyJ...    │
└──────────────────────────────────────┘
```

### Configuration Pattern (Vanilla JS)

```javascript
// lib/supabase.js — single shared client instance
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

const SUPABASE_URL = 'https://xyzabc.supabase.co';   // safe to expose
const SUPABASE_ANON_KEY = 'eyJhbGci...';              // safe to expose

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

For Netlify: set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in Netlify environment variables and inject them at build time if using a bundler (Vite, etc.), or inline them directly for a no-build approach.

### Deployment Checklist
- [ ] Supabase RLS enabled on all tables before going live
- [ ] `ANTHROPIC_API_KEY` in Supabase Edge Function secrets (never in frontend)
- [ ] `service_role` key never in any client-side file
- [ ] Storage buckets configured (product-images: public, user-uploads: private)
- [ ] Admin role assigned via dashboard SQL before handoff
- [ ] Edge Function CORS locked to production domain (not `'*'`)
- [ ] Netlify build: `SUPABASE_URL` + `SUPABASE_ANON_KEY` as environment variables

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Calling Claude API Directly from the Browser
**What:** Putting `ANTHROPIC_API_KEY` in frontend JavaScript and calling `api.anthropic.com` directly.
**Why bad:** Key is visible in browser DevTools network tab. Anyone can extract and abuse it at your cost.
**Instead:** Always proxy through a Supabase Edge Function.

### Anti-Pattern 2: Skipping RLS on Any Table
**What:** Creating tables without enabling RLS (Supabase default is RLS disabled).
**Why bad:** Any user with the anon key can read all rows in the table — including other users' orders, profiles, and cart.
**Instead:** Enable RLS first, then add explicit policies. Default-deny is safe; default-allow is not.

### Anti-Pattern 3: Storing Live Product Prices in Order Items by Reference
**What:** Order items table with only `product_id` and `quantity` — joining to live product price at display time.
**Why bad:** Price changes after purchase will change displayed order total. This is legally and UX problematic.
**Instead:** Snapshot `unit_price`, `product_name`, `variant_label` at the time of order insertion.

### Anti-Pattern 4: Using the Service Role Key in Frontend Code
**What:** Using `SUPABASE_SERVICE_ROLE_KEY` in the browser client to bypass RLS for convenience.
**Why bad:** The service role key bypasses all RLS. Anyone who obtains it can read and write all data.
**Instead:** Use the anon key in the browser. Rely on RLS policies for access control. Use service role only in Edge Functions.

### Anti-Pattern 5: Storing Role in `user_metadata` Instead of `app_metadata`
**What:** Setting `raw_user_meta_data->>'role'` to 'admin' for admin users.
**Why bad:** Users can update their own `raw_user_meta_data` via the SDK — they could promote themselves to admin.
**Instead:** Always use `raw_app_meta_data` for authorization claims. This field requires service role key to update.

### Anti-Pattern 6: Separate Admin App / Separate Supabase Project
**What:** Building the admin panel as a completely separate app or pointing it to a different Supabase project.
**Why bad:** Doubles deployment complexity, complicates data access, increases maintenance burden.
**Instead:** Admin panel is `/admin/*` routes in the same app, protected by route guards and RLS `is_admin()` policies.

### Anti-Pattern 7: Loading Full Catalog into Edge Function Prompt
**What:** Passing all product data (descriptions, images, full JSON) to Claude in the style-match prompt.
**Why bad:** Quickly hits token limits and inflates cost. Claude doesn't need full descriptions to recommend products.
**Instead:** Pass compact catalog lines (ID, category, name, key style note — ~40 tokens per product). Keep catalog payload under 2000 tokens.

---

## Scalability Considerations

| Concern | At 100 users (current scope) | At 10K users | At 1M users |
|---------|------------------------------|--------------|-------------|
| DB reads | Direct Supabase queries, no cache needed | Add PostgREST connection pooling (PgBouncer, built into Supabase) | Read replicas, materialized views for catalog |
| Product images | Supabase Storage (Cloudflare CDN) | Same — CDN handles this well | Same |
| AI Style Match | Synchronous Edge Function response is fine | Add job queue, return job ID, poll for result | Queue + worker pool, async notification |
| Cart | localStorage + DB hybrid is sufficient | Same pattern works | Move to dedicated cart service |
| Auth | Supabase Auth handles this at any scale | Same | Same |

For the assessment context (100 users, demo purposes), none of the scale concerns apply. Build the simplest working architecture.

---

## Sources

- [Supabase Row Level Security Docs](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase Custom Claims & RBAC](https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac)
- [Supabase Storage Buckets](https://supabase.com/docs/guides/storage/buckets/fundamentals)
- [Supabase Storage CDN](https://supabase.com/docs/guides/storage/cdn/fundamentals)
- [Supabase Edge Functions Architecture](https://supabase.com/docs/guides/functions/architecture)
- [Supabase Edge Functions Security](https://supabase.com/docs/guides/functions/auth)
- [Supabase Password-Based Auth](https://supabase.com/docs/guides/auth/passwords)
- [Claude Vision API Docs](https://platform.claude.com/docs/en/build-with-claude/vision)
- [Supabase RLS Best Practices — Makerkit](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices)
- [Supabase RLS Production Patterns — DEV Community](https://dev.to/whoffagents/supabase-row-level-security-in-production-patterns-that-actually-work-2l78)
- [Security-First Guide to AI + Edge Functions — DEV Community](https://dev.to/devperez08/the-security-first-guide-to-ai-development-edge-functions-rate-limiting-and-supabase-2epf)
- [Netlify + Supabase Integration](https://docs.netlify.com/extend/install-and-use/setup-guides/supabase-integration/)
