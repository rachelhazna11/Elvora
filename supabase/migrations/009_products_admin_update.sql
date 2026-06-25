-- =============================================================================
-- Elvora — Admin RLS Policy: products admin UPDATE
-- File: supabase/migrations/009_products_admin_update.sql
-- Phase 7: Gap closure — UAT Test 10 (Best Sellers toggle)
--
-- 007_admin_policies.sql added products_admin_select (SELECT only).
-- adminSetBestSeller() and adminUpdateProduct() call Supabase UPDATE —
-- which RLS blocks silently with no error when no UPDATE policy exists.
-- is_best_seller stays unchanged, homepage returns no best sellers.
--
-- Pre-requisite: 001_schema.sql must already be applied (is_admin() must exist)
-- Idempotent: uses DROP IF EXISTS + CREATE pattern
-- =============================================================================

-- HOW TO APPLY:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Paste this entire file content and click "Run"
-- 3. Verify: Authentication → Policies → products table shows
--    "products_admin_update" policy

drop policy if exists "products_admin_update" on products;

create policy "products_admin_update"
  on products
  for update
  using (is_admin())
  with check (is_admin());
