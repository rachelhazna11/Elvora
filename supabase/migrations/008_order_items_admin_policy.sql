-- =============================================================================
-- Elvora — Admin RLS Policy: order_items admin SELECT
-- File: supabase/migrations/008_order_items_admin_policy.sql
-- Phase 7: Gap closure — UAT Test 9
--
-- The only existing policy on order_items (order_items_select_own from
-- 001_schema.sql) grants SELECT only where auth.uid() owns the order.
-- Admin viewing other users' orders triggers RLS → Supabase returns [] silently.
--
-- Pre-requisite: 001_schema.sql must already be applied (is_admin() must exist)
-- Idempotent: uses DROP IF EXISTS + CREATE pattern
-- =============================================================================

-- HOW TO APPLY:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Paste this entire file content and click "Run"
-- 3. Verify: Authentication → Policies → order_items table shows
--    "order_items_admin_select" policy

drop policy if exists "order_items_admin_select" on order_items;

create policy "order_items_admin_select"
  on order_items
  for select
  using (is_admin());
