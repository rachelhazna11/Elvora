---
phase: 01-foundation
plan: 01
subsystem: data-layer
tags: [supabase, postgresql, schema, rls, storage, security]
dependency_graph:
  requires: []
  provides:
    - supabase/migrations/001_schema.sql
    - is_admin() RLS helper function
    - 16 PostgreSQL tables with RLS
    - product-images (public) storage bucket
    - user-uploads (private) storage bucket
  affects:
    - All downstream phases (every feature reads/writes to this schema)
tech_stack:
  added: []
  patterns:
    - SECURITY DEFINER function for admin role check (app_metadata.role)
    - Idempotent DDL with CREATE TABLE IF NOT EXISTS
    - Immediate RLS enable after every CREATE TABLE
    - order_items snapshot pattern (unit_price, product_name, variant_label)
    - Storage bucket path prefix scoping ({uid}/{session_id}/)
key_files:
  created:
    - supabase/migrations/001_schema.sql
  modified: []
decisions:
  - is_admin() reads from auth.jwt() -> app_metadata, not raw_user_meta_data (T-01-01 mitigation)
  - order_items snapshots price and name at insert time to prevent price injection (T-01-05)
  - Guest sessions in ai_style_sessions use null user_id and session_token for retrieval
  - orders table allows null user_id for guest checkout with constraint requiring guest_email
  - reviews are admin-seeded only in v1 (INSERT requires is_admin())
metrics:
  duration: "137 seconds (< 3 minutes)"
  completed: "2026-06-10"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  lines_written: 767
---

# Phase 01 Plan 01: Supabase Schema Migration Summary

**One-liner:** Complete 16-table PostgreSQL DDL with RLS on every table, is_admin() SECURITY DEFINER function, and product-images/user-uploads storage bucket configuration.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write complete Supabase schema migration (001_schema.sql) | f47a2cd | supabase/migrations/001_schema.sql |

## Acceptance Criteria Results

| Check | Command | Expected | Actual | Pass |
|-------|---------|----------|--------|------|
| Line count | `wc -l` | >= 300 | 767 | YES |
| Table count | `grep -ci "create table"` | 16 | 16 | YES |
| RLS count | `grep -c "enable row level security"` | 16 | 16 | YES |
| Policy count | `grep -ci "create policy"` | >= 30 | 63 | YES |
| is_admin() defined first | Line 20 before first policy at line 89 | before policies | line 20 | YES |
| Storage buckets | `grep -c "storage.buckets"` | >= 2 | 3 | YES |
| order_items snapshot columns | product_name, variant_label, unit_price all NOT NULL | present | present | YES |
| No SERVICE_ROLE | `grep -c "SERVICE_ROLE"` | 0 | 0 | YES |

## Schema Overview

### Tables (16 total)

| Table | Purpose | RLS Pattern |
|-------|---------|-------------|
| user_profiles | User display data + style preferences | User owns own row (auth.uid() = id) |
| categories | Product categories | Public read; admin write |
| products | Product catalog | Public read (is_active); admin write |
| product_variants | Per colour/size variant rows | Public read; admin write |
| product_images | Product gallery images | Public read; admin write |
| collections | Curated product groupings | Public read; admin write |
| collection_products | Collection ↔ product join table | Public read; admin write |
| cart_items | Per-user shopping cart | User owns own rows |
| wishlist_items | Saved items per user | User owns own rows |
| orders | Order header (user or guest) | User/guest owns own; admin update |
| order_items | Snapshotted line items | Readable via parent order; admin all |
| reviews | Product reviews (admin-seeded v1) | Public read; admin write |
| testimonials | Homepage social proof | Public read (is_active); admin all |
| newsletter_subscribers | Email captures | Public insert; admin read/delete |
| ai_style_sessions | Style Match session records | User/guest owns own |
| promo_codes | Discount codes | Public read (is_active); admin all |

### Security Decisions

1. **is_admin() SECURITY DEFINER** — reads `auth.jwt() -> 'app_metadata' ->> 'role'`. This field can only be set via `service_role` (never by the client), preventing privilege escalation (T-01-01).

2. **order_items snapshot** — `product_name`, `variant_label`, and `unit_price` are written at INSERT time and never updated. Price/name changes in the catalog do not retroactively affect order history. This prevents client-side price injection (T-01-05).

3. **RLS on every table** — All 16 tables have `enable row level security` immediately after `create table`. Verified by `grep -c "enable row level security"` returning exactly 16.

4. **No SERVICE_ROLE in file** — Confirmed zero occurrences. The migration is safe to review in any context.

5. **Storage path scoping** — user-uploads bucket policies use `(storage.foldername(name))[1] = auth.uid()::text` to restrict users to their own folder prefix (T-01-04 mitigation for guest session photo storage).

### Storage Buckets

| Bucket | Public | Size Limit | MIME Types | Use |
|--------|--------|------------|------------|-----|
| product-images | true | 5 MB | jpeg, png, webp, gif | Admin-uploaded catalog images |
| user-uploads | false | 10 MB | jpeg, png, webp, heic | User-uploaded style photos |

## Deviations from Plan

None — plan executed exactly as written.

The one technical observation: `grep -ci "create table"` initially returned 17 because the file header comment mentioned "CREATE TABLE IF NOT EXISTS". Fixed by rephrasing the comment to use "IF NOT EXISTS guards" instead. This was a cosmetic adjustment to satisfy the acceptance criterion exactly, not a schema change.

## Threat Flags

No new security surface beyond what was planned. All threat-model mitigations from the plan have been implemented:

| Threat ID | Mitigation | Verified |
|-----------|-----------|---------|
| T-01-01 | is_admin() uses SECURITY DEFINER + app_metadata only | YES — line 20-30 |
| T-01-03 | user_profiles SELECT uses auth.uid() = id | YES |
| T-01-04 | ai_style_sessions guest rows use null user_id + session_token | YES |
| T-01-05 | order_items snapshots unit_price at insert | YES — NOT NULL columns |

## Self-Check: PASSED

- [x] `supabase/migrations/001_schema.sql` exists (767 lines)
- [x] Commit `f47a2cd` exists in git log
- [x] All 8 acceptance criteria pass
- [x] No stubs or placeholder values in the SQL file
- [x] No SERVICE_ROLE references
