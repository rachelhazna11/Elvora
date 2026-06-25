-- =============================================================================
-- Elvora — Admin RLS Policy Additions
-- File: supabase/migrations/007_admin_policies.sql
-- Phase 7: Admin Panel
-- Apply via: Supabase SQL Editor (Dashboard → SQL Editor → Run)
--
-- Adds missing admin SELECT policies identified during Phase 7 RLS audit:
--   1. orders_admin_select — allows admin to read ALL orders
--   2. products_admin_select — allows admin to read ALL products including inactive drafts
--
-- Pre-requisite: 001_schema.sql must already be applied (is_admin() function must exist)
-- Idempotent: uses DROP IF EXISTS + CREATE pattern (safe to run multiple times)
-- =============================================================================

-- HOW TO APPLY:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Paste this entire file content
-- 3. Click "Run"
-- 4. Verify: go to Authentication → Policies → check orders and products tables
--    for new policies "orders_admin_select" and "products_admin_select"

-- Drop existing policies first to make this idempotent
-- (safe to run multiple times — does nothing if policy doesn't exist)
drop policy if exists "orders_admin_select" on orders;
drop policy if exists "products_admin_select" on products;

-- Policy 1: Admin can SELECT all orders (required for orders read view in admin panel)
-- Without this, RLS silently returns empty rows for admin user on orders table.
create policy "orders_admin_select"
  on orders
  for select
  using (is_admin());

-- Policy 2: Admin can SELECT all products including inactive drafts
-- Without this, admin only sees is_active=true products (public read policy filters)
-- This is needed to manage draft products and toggle is_active in admin panel.
create policy "products_admin_select"
  on products
  for select
  using (is_admin());
