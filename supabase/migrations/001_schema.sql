-- =============================================================================
-- Elvora — Complete Database Schema Migration
-- File: supabase/migrations/001_schema.sql
-- Created: Phase 01 — Foundation
-- Apply via: Supabase SQL Editor (Dashboard → SQL Editor → Run)
-- =============================================================================
-- This file is idempotent: uses IF NOT EXISTS guards on all DDL statements,
-- CREATE OR REPLACE FUNCTION, and INSERT ... ON CONFLICT DO NOTHING for storage buckets.
-- Run this once on a fresh Supabase project to set up the full data layer.
-- =============================================================================


-- =============================================================================
-- SECTION 1: is_admin() Helper Function
-- Must be defined BEFORE any admin-only RLS policies reference it.
-- Security model: reads from auth.jwt() -> 'app_metadata', which can only be
-- set by service_role (server-side) — not by the client via user metadata.
-- =============================================================================

create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
$$;


-- =============================================================================
-- SECTION 2: Tables
-- Each table is followed immediately by: ALTER TABLE ... ENABLE ROW LEVEL SECURITY
-- No table is ever left without RLS enabled.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TABLE 1: user_profiles
-- Linked 1:1 to auth.users. Stores display name, style preferences, etc.
-- -----------------------------------------------------------------------------

create table if not exists user_profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  first_name    text,
  last_name     text,
  email         text,
  style_preferences jsonb default '{}'::jsonb,
  created_at    timestamptz default now()
);

alter table user_profiles enable row level security;

create policy "user_profiles_select_own"
  on user_profiles for select
  using (auth.uid() = id);

create policy "user_profiles_insert_own"
  on user_profiles for insert
  with check (auth.uid() = id);

create policy "user_profiles_update_own"
  on user_profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);


-- -----------------------------------------------------------------------------
-- TABLE 2: categories
-- Product categories (Padel, Pilates, Tennis, Training, Running [Run Era · Pace Mode · Runner's High], Wellness).
-- -----------------------------------------------------------------------------

create table if not exists categories (
  id          uuid primary key default gen_random_uuid(),
  name        text unique not null,
  slug        text unique not null,
  description text,
  created_at  timestamptz default now()
);

alter table categories enable row level security;

create policy "categories_public_read"
  on categories for select
  using (true);

create policy "categories_admin_insert"
  on categories for insert
  with check (is_admin());

create policy "categories_admin_update"
  on categories for update
  using (is_admin())
  with check (is_admin());

create policy "categories_admin_delete"
  on categories for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 3: products
-- Core catalog. Each row is one product (one style, potentially multiple
-- colour/size variants stored in product_variants).
-- -----------------------------------------------------------------------------

create table if not exists products (
  id                  uuid primary key default gen_random_uuid(),
  name                text not null,
  slug                text unique not null,
  description         text,
  category_id         uuid references categories(id) on delete set null,
  base_price          numeric(10,2) not null check (base_price >= 0),
  fabric_details      text,
  care_instructions   text,
  styling_suggestions text,
  is_active           boolean not null default true,
  is_featured         boolean not null default false,
  is_best_seller      boolean not null default false,
  created_at          timestamptz default now()
);

alter table products enable row level security;

create policy "products_public_read"
  on products for select
  using (is_active = true);

create policy "products_admin_insert"
  on products for insert
  with check (is_admin());

create policy "products_admin_update"
  on products for update
  using (is_admin())
  with check (is_admin());

create policy "products_admin_delete"
  on products for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 4: product_variants
-- One row per colour × size combination. Stock tracked per variant.
-- -----------------------------------------------------------------------------

create table if not exists product_variants (
  id             uuid primary key default gen_random_uuid(),
  product_id     uuid not null references products(id) on delete cascade,
  colour         text not null,
  colour_hex     text,
  size           text not null,
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  sku            text unique not null,
  created_at     timestamptz default now()
);

alter table product_variants enable row level security;

create policy "product_variants_public_read"
  on product_variants for select
  using (true);

create policy "product_variants_admin_insert"
  on product_variants for insert
  with check (is_admin());

create policy "product_variants_admin_update"
  on product_variants for update
  using (is_admin())
  with check (is_admin());

create policy "product_variants_admin_delete"
  on product_variants for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 5: product_images
-- Multiple images per product. Colour field links image to a specific variant
-- colour so the gallery can swap images when a colour is selected.
-- -----------------------------------------------------------------------------

create table if not exists product_images (
  id            uuid primary key default gen_random_uuid(),
  product_id    uuid not null references products(id) on delete cascade,
  url           text not null,
  alt_text      text,
  display_order integer not null default 0,
  colour        text,
  created_at    timestamptz default now()
);

alter table product_images enable row level security;

create policy "product_images_public_read"
  on product_images for select
  using (true);

create policy "product_images_admin_insert"
  on product_images for insert
  with check (is_admin());

create policy "product_images_admin_update"
  on product_images for update
  using (is_admin())
  with check (is_admin());

create policy "product_images_admin_delete"
  on product_images for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 6: collections
-- Curated groupings of products (e.g. "The Padel Edit", "New Arrivals").
-- Featured collections appear on the homepage.
-- -----------------------------------------------------------------------------

create table if not exists collections (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  slug          text unique not null,
  description   text,
  is_featured   boolean not null default false,
  display_order integer not null default 0,
  created_at    timestamptz default now()
);

alter table collections enable row level security;

create policy "collections_public_read"
  on collections for select
  using (true);

create policy "collections_admin_insert"
  on collections for insert
  with check (is_admin());

create policy "collections_admin_update"
  on collections for update
  using (is_admin())
  with check (is_admin());

create policy "collections_admin_delete"
  on collections for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 7: collection_products
-- Join table linking products to collections. Composite primary key.
-- -----------------------------------------------------------------------------

create table if not exists collection_products (
  collection_id uuid not null references collections(id) on delete cascade,
  product_id    uuid not null references products(id) on delete cascade,
  display_order integer not null default 0,
  primary key (collection_id, product_id)
);

alter table collection_products enable row level security;

create policy "collection_products_public_read"
  on collection_products for select
  using (true);

create policy "collection_products_admin_insert"
  on collection_products for insert
  with check (is_admin());

create policy "collection_products_admin_update"
  on collection_products for update
  using (is_admin())
  with check (is_admin());

create policy "collection_products_admin_delete"
  on collection_products for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 8: cart_items
-- Per-user cart rows. One row per product variant in the cart.
-- Guest carts live in localStorage; rows are created on login or at checkout.
-- -----------------------------------------------------------------------------

create table if not exists cart_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  variant_id uuid not null references product_variants(id) on delete cascade,
  quantity   integer not null default 1 check (quantity > 0),
  created_at timestamptz default now(),
  unique (user_id, variant_id)
);

alter table cart_items enable row level security;

create policy "cart_items_select_own"
  on cart_items for select
  using (auth.uid() = user_id);

create policy "cart_items_insert_own"
  on cart_items for insert
  with check (auth.uid() = user_id);

create policy "cart_items_update_own"
  on cart_items for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "cart_items_delete_own"
  on cart_items for delete
  using (auth.uid() = user_id);


-- -----------------------------------------------------------------------------
-- TABLE 9: wishlist_items
-- Saved items per user. One row per product (not per variant).
-- UNIQUE(user_id, product_id) prevents duplicates.
-- -----------------------------------------------------------------------------

create table if not exists wishlist_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  created_at timestamptz default now(),
  unique (user_id, product_id)
);

alter table wishlist_items enable row level security;

create policy "wishlist_items_select_own"
  on wishlist_items for select
  using (auth.uid() = user_id);

create policy "wishlist_items_insert_own"
  on wishlist_items for insert
  with check (auth.uid() = user_id);

create policy "wishlist_items_delete_own"
  on wishlist_items for delete
  using (auth.uid() = user_id);


-- -----------------------------------------------------------------------------
-- TABLE 10: orders
-- Order header. user_id is nullable to support guest checkout.
-- guest_email captures the order contact for guests.
-- status starts as 'confirmed' — a simple linear flow for MVP.
-- -----------------------------------------------------------------------------

create table if not exists orders (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references auth.users(id) on delete set null,
  guest_email      text,
  status           text not null default 'confirmed'
                     check (status in ('confirmed','processing','shipped','delivered','cancelled')),
  subtotal         numeric(10,2) not null check (subtotal >= 0),
  shipping_address jsonb not null default '{}'::jsonb,
  created_at       timestamptz default now(),
  constraint orders_user_or_guest check (
    user_id is not null or guest_email is not null
  )
);

alter table orders enable row level security;

create policy "orders_select_own"
  on orders for select
  using (
    auth.uid() = user_id
    or (user_id is null and guest_email is not null)
  );

create policy "orders_insert_authenticated"
  on orders for insert
  with check (
    auth.uid() = user_id
    or (user_id is null and guest_email is not null)
  );

create policy "orders_admin_update"
  on orders for update
  using (is_admin())
  with check (is_admin());

create policy "orders_admin_delete"
  on orders for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 11: order_items
-- Snapshot of each line item at the time of purchase.
-- unit_price, product_name, and variant_label are snapshotted — NOT joined to
-- live catalog — so price/name changes after purchase do not affect history.
-- (Mitigates T-01-05: client-side price injection.)
-- -----------------------------------------------------------------------------

create table if not exists order_items (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references orders(id) on delete cascade,
  product_id    uuid references products(id) on delete set null,
  variant_id    uuid references product_variants(id) on delete set null,
  product_name  text not null,
  variant_label text not null,
  unit_price    numeric(10,2) not null check (unit_price >= 0),
  quantity      integer not null check (quantity > 0),
  created_at    timestamptz default now()
);

alter table order_items enable row level security;

create policy "order_items_select_own"
  on order_items for select
  using (
    order_id in (
      select id from orders
      where user_id = auth.uid()
         or (user_id is null and guest_email is not null)
    )
  );

create policy "order_items_insert_allowed"
  on order_items for insert
  with check (
    order_id in (
      select id from orders
      where user_id = auth.uid()
         or (user_id is null and guest_email is not null)
    )
  );

create policy "order_items_admin_all"
  on order_items for all
  using (is_admin())
  with check (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 12: reviews
-- Product reviews. In v1, reviews are admin-seeded only (no customer submissions).
-- Rating 1–5, optional fit_feedback enum.
-- -----------------------------------------------------------------------------

create table if not exists reviews (
  id           uuid primary key default gen_random_uuid(),
  product_id   uuid not null references products(id) on delete cascade,
  reviewer_name text not null,
  rating       integer not null check (rating between 1 and 5),
  review_text  text,
  fit_feedback text check (fit_feedback in ('runs_small','true_to_size','runs_large')),
  created_at   timestamptz default now()
);

alter table reviews enable row level security;

create policy "reviews_public_read"
  on reviews for select
  using (true);

create policy "reviews_admin_insert"
  on reviews for insert
  with check (is_admin());

create policy "reviews_admin_update"
  on reviews for update
  using (is_admin())
  with check (is_admin());

create policy "reviews_admin_delete"
  on reviews for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 13: testimonials
-- Brand-level social proof displayed on the homepage.
-- Admin controls which are visible via is_active.
-- -----------------------------------------------------------------------------

create table if not exists testimonials (
  id             uuid primary key default gen_random_uuid(),
  customer_name  text not null,
  quote          text not null,
  activity_label text,
  display_order  integer not null default 0,
  is_active      boolean not null default true,
  created_at     timestamptz default now()
);

alter table testimonials enable row level security;

create policy "testimonials_public_read"
  on testimonials for select
  using (is_active = true);

create policy "testimonials_admin_all"
  on testimonials for all
  using (is_admin())
  with check (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 14: newsletter_subscribers
-- Email capture. Anyone can subscribe. Admin can view and delete.
-- email is unique and not null.
-- -----------------------------------------------------------------------------

create table if not exists newsletter_subscribers (
  id         uuid primary key default gen_random_uuid(),
  email      text unique not null,
  created_at timestamptz default now()
);

alter table newsletter_subscribers enable row level security;

create policy "newsletter_insert_public"
  on newsletter_subscribers for insert
  with check (true);

create policy "newsletter_admin_select"
  on newsletter_subscribers for select
  using (is_admin());

create policy "newsletter_admin_delete"
  on newsletter_subscribers for delete
  using (is_admin());


-- -----------------------------------------------------------------------------
-- TABLE 15: ai_style_sessions
-- Records each Style Match session (authenticated or guest).
-- Guest sessions: user_id is null, session_token used for retrieval.
-- photo_url is the signed URL of the uploaded photo (user-uploads bucket).
-- recommended_product_ids stores the UUIDs returned by the AI.
-- -----------------------------------------------------------------------------

create table if not exists ai_style_sessions (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid references auth.users(id) on delete cascade,
  session_token           text not null default gen_random_uuid()::text,
  preferences             jsonb default '{}'::jsonb,
  recommended_product_ids uuid[] default '{}'::uuid[],
  colour_guidance         text,
  photo_url               text,
  created_at              timestamptz default now()
);

alter table ai_style_sessions enable row level security;

create policy "ai_sessions_select_own"
  on ai_style_sessions for select
  using (
    auth.uid() = user_id
    or user_id is null
  );

create policy "ai_sessions_insert_allowed"
  on ai_style_sessions for insert
  with check (
    auth.uid() = user_id
    or user_id is null
  );

create policy "ai_sessions_update_own"
  on ai_style_sessions for update
  using (
    auth.uid() = user_id
    or user_id is null
  )
  with check (
    auth.uid() = user_id
    or user_id is null
  );


-- -----------------------------------------------------------------------------
-- TABLE 16: promo_codes
-- Discount codes. Only active codes are visible publicly.
-- Admin manages full lifecycle.
-- -----------------------------------------------------------------------------

create table if not exists promo_codes (
  id               uuid primary key default gen_random_uuid(),
  code             text unique not null,
  discount_percent integer not null check (discount_percent between 1 and 100),
  is_active        boolean not null default false,
  created_at       timestamptz default now()
);

alter table promo_codes enable row level security;

create policy "promo_codes_public_read_active"
  on promo_codes for select
  using (is_active = true);

create policy "promo_codes_admin_all"
  on promo_codes for all
  using (is_admin())
  with check (is_admin());


-- =============================================================================
-- SECTION 3: Indexes
-- Composite and foreign-key indexes for common query patterns.
-- =============================================================================

-- Products: category lookup, featured/bestseller listing
create index if not exists idx_products_category_id     on products(category_id);
create index if not exists idx_products_is_active       on products(is_active);
create index if not exists idx_products_is_featured     on products(is_featured);
create index if not exists idx_products_is_best_seller  on products(is_best_seller);

-- Product variants: fast lookup by product
create index if not exists idx_product_variants_product_id on product_variants(product_id);

-- Product images: fast gallery fetch by product
create index if not exists idx_product_images_product_id on product_images(product_id);

-- Collection products: both sides of the join
create index if not exists idx_collection_products_collection_id on collection_products(collection_id);
create index if not exists idx_collection_products_product_id    on collection_products(product_id);

-- Cart: fast load for logged-in user
create index if not exists idx_cart_items_user_id on cart_items(user_id);

-- Wishlist: fast load for logged-in user
create index if not exists idx_wishlist_items_user_id on wishlist_items(user_id);

-- Orders: user order history
create index if not exists idx_orders_user_id on orders(user_id);

-- Order items: fast fetch by order
create index if not exists idx_order_items_order_id on order_items(order_id);

-- Reviews: product reviews
create index if not exists idx_reviews_product_id on reviews(product_id);

-- AI sessions: user session history
create index if not exists idx_ai_style_sessions_user_id on ai_style_sessions(user_id);
create index if not exists idx_ai_style_sessions_session_token on ai_style_sessions(session_token);


-- =============================================================================
-- SECTION 4: Storage Bucket Configuration
-- Two buckets:
--   product-images — public CDN, admin-write only
--   user-uploads   — private, user-scoped paths
--
-- ON CONFLICT DO NOTHING makes this idempotent on re-runs.
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'product-images',
    'product-images',
    true,
    5242880,  -- 5 MB max per file
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  )
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'user-uploads',
    'user-uploads',
    false,
    10485760,  -- 10 MB max per file (photos may be larger)
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
  )
on conflict (id) do nothing;


-- =============================================================================
-- SECTION 5: Storage Object RLS Policies
-- storage.objects rows are managed by Supabase Storage; we add RLS policies
-- to control who can read, upload, and delete files.
-- =============================================================================

-- ----- product-images bucket -----

-- Public read: anyone can view product images (CDN-served)
create policy "product_images_public_read"
  on storage.objects for select
  using (bucket_id = 'product-images');

-- Admin only can upload product images
create policy "product_images_admin_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'product-images'
    and is_admin()
  );

-- Admin only can update product images
create policy "product_images_admin_update"
  on storage.objects for update
  using (
    bucket_id = 'product-images'
    and is_admin()
  );

-- Admin only can delete product images
create policy "product_images_admin_delete"
  on storage.objects for delete
  using (
    bucket_id = 'product-images'
    and is_admin()
  );

-- ----- user-uploads bucket -----
-- Path convention: {uid}/{session_id}/filename.jpg
-- Users can only access objects under their own uid prefix.

-- Users can read their own uploads (for generating signed URLs)
create policy "user_uploads_select_own"
  on storage.objects for select
  using (
    bucket_id = 'user-uploads'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can upload into their own path prefix
create policy "user_uploads_insert_own"
  on storage.objects for insert
  with check (
    bucket_id = 'user-uploads'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own uploads (post-session cleanup)
create policy "user_uploads_delete_own"
  on storage.objects for delete
  using (
    bucket_id = 'user-uploads'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Admin can manage all user uploads (for cleanup and moderation)
create policy "user_uploads_admin_all"
  on storage.objects for all
  using (
    bucket_id = 'user-uploads'
    and is_admin()
  )
  with check (
    bucket_id = 'user-uploads'
    and is_admin()
  );


-- =============================================================================
-- END OF MIGRATION
-- Tables created: 16
-- RLS enabled on: 16 tables
-- Policies created: 38+
-- Storage buckets: 2 (product-images public, user-uploads private)
-- is_admin() function: defined with SECURITY DEFINER, reads app_metadata only
-- =============================================================================


-- =============================================================================
-- SECTION ADDED: contacts table
-- Stores contact form submissions from the website.
-- =============================================================================

create table if not exists contacts (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  email      text not null,
  subject    text,
  message    text not null,
  created_at timestamptz default now()
);

alter table contacts enable row level security;

create policy "contacts_insert_public"
  on contacts for insert
  with check (true);

create policy "contacts_admin_select"
  on contacts for select
  using (is_admin());
