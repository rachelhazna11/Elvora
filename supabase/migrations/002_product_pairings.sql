-- =============================================================================
-- Elvora — Product Pairings Migration
-- File: supabase/migrations/002_product_pairings.sql
-- Created: Phase 03 — Product Catalog
-- Apply via: Supabase SQL Editor (Dashboard → SQL Editor → Run)
-- =============================================================================
-- Sections:
--   A. product_pairings table + RLS policies
--   B. collection_products gap fill (Tennis, Training, Running sub-collections)
--   C. product_pairings seed data (2–3 pairings per product × 22 products)
-- =============================================================================

BEGIN;

-- =============================================================================
-- SECTION A: product_pairings table
-- Per D-07: activity-context-relevant pairings for "Complete the Look" on PDP.
-- =============================================================================

create table if not exists product_pairings (
  product_id        uuid not null references products(id) on delete cascade,
  paired_product_id uuid not null references products(id) on delete cascade,
  display_order     integer not null default 0,
  primary key (product_id, paired_product_id)
);

alter table product_pairings enable row level security;

create policy "product_pairings_public_read"
  on product_pairings for select
  using (true);

create policy "product_pairings_admin_write"
  on product_pairings for all
  using (is_admin())
  with check (is_admin());


-- =============================================================================
-- SECTION B.0: Ensure all 21 collections exist
-- seed.sql collections may not have been applied to the live database.
-- Insert all 21 with ON CONFLICT (slug) DO NOTHING — safe to run whether
-- they already exist (with these UUIDs) or are missing entirely.
-- =============================================================================

INSERT INTO collections (id, name, slug, description, is_featured, display_order) VALUES
  -- Base collections (seed.sql first block, b...001–b...009)
  ('b1000000-0000-0000-0000-000000000001', 'New Arrivals',      'new-arrivals',      'The latest additions to the Elvora catalog',                                   true,  1),
  ('b1000000-0000-0000-0000-000000000002', 'Best Sellers',      'best-sellers',      'The pieces our community returns to season after season',                      true,  2),
  ('b1000000-0000-0000-0000-000000000003', 'The Padel Edit',    'padel-edit',        'Court-ready pieces engineered for padel and tennis',                           true,  3),
  ('b1000000-0000-0000-0000-000000000004', 'Studio Essentials', 'studio-essentials', 'The foundations of every pilates and yoga wardrobe',                           true,  4),
  ('b1000000-0000-0000-0000-000000000005', 'Summer Collection', 'summer-collection', 'Lightweight, breathable pieces for warm-weather training',                     false, 5),
  ('b1000000-0000-0000-0000-000000000006', 'Core Range',        'core-range',        'Timeless, versatile pieces that anchor any active wardrobe',                   false, 6),
  ('b1000000-0000-0000-0000-000000000007', 'Run Era',           'run-era',           'High-performance running pieces for the dedicated pavement runner',             true,  7),
  ('b1000000-0000-0000-0000-000000000008', 'Pace Mode',         'pace-mode',         'Speed-focused activewear engineered for interval and track training',           false, 8),
  ('b1000000-0000-0000-0000-000000000009', 'Runner''s High',    'runners-high',      'The post-run glow — recovery and casual styles for the running lifestyle',     false, 9),
  -- Padel sub-collections
  ('b1000000-0000-0000-0000-000000000010', 'Matcha Babe',       'matcha-babe',       'Elevated padel-club looks in sage, ivory and warm cream — sporty luxury',     false, 10),
  ('b1000000-0000-0000-0000-000000000011', 'Court Crush',       'court-crush',       'Confident courtwear in charcoal, ivory and soft neutrals with feminine edge',  false, 11),
  ('b1000000-0000-0000-0000-000000000012', 'Rally Ready',       'rally-ready',       'Performance-neutral padel kit in stone, black and muted green tones',          false, 12),
  -- Pilates sub-collections
  ('b1000000-0000-0000-0000-000000000013', 'Soft Flow',         'soft-flow',         'Graceful studio luxury in warm neutrals, ivory, soft sage and stone',          false, 13),
  ('b1000000-0000-0000-0000-000000000014', 'Main Character',    'main-character',    'Luxury pilates muse — elegant monochrome in charcoal, cream and earth tones',  false, 14),
  ('b1000000-0000-0000-0000-000000000015', 'Studio Muse',       'studio-muse',       'Minimalist quiet luxury — premium studio uniform in soft beige and neutrals',  false, 15),
  -- Tennis sub-collections
  ('b1000000-0000-0000-0000-000000000016', 'Love Match',        'love-match',        'Romantic luxury tennis in ivory, soft green and clean whites',                  false, 16),
  ('b1000000-0000-0000-0000-000000000017', 'Ace Energy',        'ace-energy',        'Modern performance-luxury tennis in contrast neutrals, charcoal and white',    false, 17),
  ('b1000000-0000-0000-0000-000000000018', 'Court Girl',        'court-girl',        'Luxury tennis lifestyle — feminine neutrals, ivory, soft cream and muted sage', false, 18),
  -- Training (Gym) sub-collections
  ('b1000000-0000-0000-0000-000000000019', 'Power Mood',        'power-mood',        'Elevated training wear in charcoal, black and muted earth tones',               false, 19),
  ('b1000000-0000-0000-0000-000000000020', 'Built Different',   'built-different',   'High-performance luxury gym wear — monochrome neutrals and deep charcoal',     false, 20),
  ('b1000000-0000-0000-0000-000000000021', 'Hot Girl Lift',     'hot-girl-lift',     'Premium feminine strength in soft neutrals, warm beige and muted sage',        false, 21)
ON CONFLICT (slug) DO NOTHING;


-- =============================================================================
-- SECTION B: collection_products gap fill
-- Tennis, Training (Gym), and Running sub-collections had zero product assignments.
-- This block adds activity-appropriate products to each sub-collection.
--
-- Tennis sub-collections  → love-match (b...016), ace-energy (b...017), court-girl (b...018)
-- Training sub-collections → power-mood (b...019), built-different (b...020), hot-girl-lift (b...021)
-- Running sub-collections  → run-era (b...007), pace-mode (b...008), runners-high (b...009)
--
-- Product UUID reference (from seed.sql Section 3):
--   P01 Serenity Ribbed Legging   = c1000000-0000-0000-0000-000000000001
--   P02 Aerial High-Rise Legging  = c1000000-0000-0000-0000-000000000002
--   P03 Studio 7/8 Legging        = c1000000-0000-0000-0000-000000000003
--   P04 Flow Seamless Legging     = c1000000-0000-0000-0000-000000000004
--   P05 Contour Pocket Legging    = c1000000-0000-0000-0000-000000000005
--   P06 Luminary Longline Bra     = c1000000-0000-0000-0000-000000000006
--   P07 Sculpt Medium Support Bra = c1000000-0000-0000-0000-000000000007
--   P08 Equilibrium Sports Bra    = c1000000-0000-0000-0000-000000000008
--   P09 Aura High Support Bra     = c1000000-0000-0000-0000-000000000009
--   P10 Courtside Pleated Skirt   = c1000000-0000-0000-0000-000000000010
--   P11 Match Point Tennis Skirt  = c1000000-0000-0000-0000-000000000011
--   P12 Rally Wrap Skirt          = c1000000-0000-0000-0000-000000000012
--   P13 Elevate Tank Top          = c1000000-0000-0000-0000-000000000013
--   P14 Serenity Ribbed Tank      = c1000000-0000-0000-0000-000000000014
--   P15 Vital Long Sleeve Top     = c1000000-0000-0000-0000-000000000015
--   P16 Altitude Zip Jacket       = c1000000-0000-0000-0000-000000000016
--   P17 Motion Track Jacket       = c1000000-0000-0000-0000-000000000017
--   P18 Restore Hoodie            = c1000000-0000-0000-0000-000000000018
--   P19 Padel Power Set           = c1000000-0000-0000-0000-000000000019
--   P20 Pilates Harmony Set       = c1000000-0000-0000-0000-000000000020
--   P21 Studio Duo Set            = c1000000-0000-0000-0000-000000000021
--   P22 Flow Practice Set         = c1000000-0000-0000-0000-000000000022
-- =============================================================================

INSERT INTO collection_products (collection_id, product_id, display_order) VALUES

-- ── TENNIS: love-match (b...016) ──────────────────────────────────────────────
-- Romantic luxury tennis: P10 Courtside Pleated Skirt, P11 Match Point Tennis Skirt,
-- P12 Rally Wrap Skirt, P06 Luminary Longline Bra, P07 Sculpt Medium Support Bra
('b1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000010', 1),
('b1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000011', 2),
('b1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000012', 3),
('b1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000006', 4),
('b1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000007', 5),

-- ── TENNIS: ace-energy (b...017) ─────────────────────────────────────────────
-- Modern performance-luxury tennis: P10, P11, P12, P06, P07
('b1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000010', 1),
('b1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000011', 2),
('b1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000012', 3),
('b1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000006', 4),
('b1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000007', 5),

-- ── TENNIS: court-girl (b...018) ─────────────────────────────────────────────
-- Luxury tennis lifestyle: P10, P11, P12, P06, P07
('b1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000010', 1),
('b1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000011', 2),
('b1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000012', 3),
('b1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000006', 4),
('b1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000007', 5),

-- ── TRAINING: power-mood (b...019) ──────────────────────────────────────────
-- Elevated training wear: P01, P02, P03, P04, P05, P06, P07, P09, P16
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000001', 1),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000002', 2),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000003', 3),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000004', 4),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000005', 5),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000006', 6),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000007', 7),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000009', 8),
('b1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000016', 9),

-- ── TRAINING: built-different (b...020) ─────────────────────────────────────
-- High-performance luxury gym: P01, P02, P03, P04, P05, P06, P07, P09, P16
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000001', 1),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000002', 2),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000003', 3),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000004', 4),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000005', 5),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000006', 6),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000007', 7),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000009', 8),
('b1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000016', 9),

-- ── TRAINING: hot-girl-lift (b...021) ────────────────────────────────────────
-- Premium feminine strength: P01, P02, P03, P04, P05, P06, P07, P09, P16
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000001', 1),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000002', 2),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000003', 3),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000004', 4),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000005', 5),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000006', 6),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000007', 7),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000009', 8),
('b1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000016', 9),

-- ── RUNNING: run-era (b...007) ───────────────────────────────────────────────
-- High-performance running: P05 Contour Pocket Legging, P09 Aura High Support Bra,
-- P15 Vital Long Sleeve Top, P02 Aerial High-Rise Legging
('b1000000-0000-0000-0000-000000000007','c1000000-0000-0000-0000-000000000005', 1),
('b1000000-0000-0000-0000-000000000007','c1000000-0000-0000-0000-000000000009', 2),
('b1000000-0000-0000-0000-000000000007','c1000000-0000-0000-0000-000000000015', 3),
('b1000000-0000-0000-0000-000000000007','c1000000-0000-0000-0000-000000000002', 4),

-- ── RUNNING: pace-mode (b...008) ─────────────────────────────────────────────
-- Speed-focused running: P05, P09, P15, P02
('b1000000-0000-0000-0000-000000000008','c1000000-0000-0000-0000-000000000005', 1),
('b1000000-0000-0000-0000-000000000008','c1000000-0000-0000-0000-000000000009', 2),
('b1000000-0000-0000-0000-000000000008','c1000000-0000-0000-0000-000000000015', 3),
('b1000000-0000-0000-0000-000000000008','c1000000-0000-0000-0000-000000000002', 4),

-- ── RUNNING: runners-high (b...009) ─────────────────────────────────────────
-- Recovery and casual running lifestyle: P05, P09, P15, P02
('b1000000-0000-0000-0000-000000000009','c1000000-0000-0000-0000-000000000005', 1),
('b1000000-0000-0000-0000-000000000009','c1000000-0000-0000-0000-000000000009', 2),
('b1000000-0000-0000-0000-000000000009','c1000000-0000-0000-0000-000000000015', 3),
('b1000000-0000-0000-0000-000000000009','c1000000-0000-0000-0000-000000000002', 4)

ON CONFLICT DO NOTHING;


-- =============================================================================
-- SECTION C: product_pairings seed data
-- 2–3 activity-context-relevant pairings per product × 22 products.
-- Rule: no cross-activity mismatches (padel skirt does not pair with running top).
-- =============================================================================

INSERT INTO product_pairings (product_id, paired_product_id, display_order) VALUES

-- ── P01 Serenity Ribbed Legging (Pilates/Training) ───────────────────────────
-- → P06 Luminary Longline Bra (pilates bra, same rib aesthetic)
-- → P14 Serenity Ribbed Tank (matching set piece)
-- → P21 Studio Duo Set (complete tonal set)
('c1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000006', 1),
('c1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000014', 2),
('c1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000021', 3),

-- ── P02 Aerial High-Rise Legging (Training/Running) ─────────────────────────
-- → P07 Sculpt Medium Support Bra (medium support for HIIT)
-- → P16 Altitude Zip Jacket (training outerwear)
-- → P13 Elevate Tank Top (layering top for training)
('c1000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000007', 1),
('c1000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000016', 2),
('c1000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000013', 3),

-- ── P03 Studio 7/8 Legging (Pilates/Studio) ─────────────────────────────────
-- → P08 Equilibrium Sports Bra (studio bra, explicitly mentioned in product description)
-- → P17 Motion Track Jacket (studio-to-street)
-- → P20 Pilates Harmony Set (same pilates category)
('c1000000-0000-0000-0000-000000000003','c1000000-0000-0000-0000-000000000008', 1),
('c1000000-0000-0000-0000-000000000003','c1000000-0000-0000-0000-000000000017', 2),
('c1000000-0000-0000-0000-000000000003','c1000000-0000-0000-0000-000000000020', 3),

-- ── P04 Flow Seamless Legging (Pilates/Yoga) ────────────────────────────────
-- → P09 Aura High Support Bra (mentioned in product description)
-- → P18 Restore Hoodie (mentioned in product description: recovery day)
-- → P22 Flow Practice Set (same flow/yoga aesthetic)
('c1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000009', 1),
('c1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000018', 2),
('c1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000022', 3),

-- ── P05 Contour Pocket Legging (Running/Training) ───────────────────────────
-- → P09 Aura High Support Bra (explicitly mentioned in description for running)
-- → P15 Vital Long Sleeve Top (running long sleeve, mentioned in description)
-- → P16 Altitude Zip Jacket (outerwear for outdoor runs)
('c1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000009', 1),
('c1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000015', 2),
('c1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000016', 3),

-- ── P06 Luminary Longline Bra (Pilates/Studio) ──────────────────────────────
-- → P01 Serenity Ribbed Legging (explicitly mentioned in description)
-- → P03 Studio 7/8 Legging (pilates legging pairing)
-- → P17 Motion Track Jacket (studio-to-street outerwear)
('c1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000001', 1),
('c1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000003', 2),
('c1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000017', 3),

-- ── P07 Sculpt Medium Support Bra (Training/Cycling) ────────────────────────
-- → P02 Aerial High-Rise Legging (mentioned in description)
-- → P16 Altitude Zip Jacket (mentioned in description for layering)
-- → P05 Contour Pocket Legging (training pocket legging)
('c1000000-0000-0000-0000-000000000007','c1000000-0000-0000-0000-000000000002', 1),
('c1000000-0000-0000-0000-000000000007','c1000000-0000-0000-0000-000000000016', 2),
('c1000000-0000-0000-0000-000000000007','c1000000-0000-0000-0000-000000000005', 3),

-- ── P08 Equilibrium Sports Bra (Pilates/Studio) ─────────────────────────────
-- → P03 Studio 7/8 Legging (explicitly mentioned in description)
-- → P17 Motion Track Jacket (explicitly mentioned in description)
-- → P22 Flow Practice Set (yoga/pilates set pairing)
('c1000000-0000-0000-0000-000000000008','c1000000-0000-0000-0000-000000000003', 1),
('c1000000-0000-0000-0000-000000000008','c1000000-0000-0000-0000-000000000017', 2),
('c1000000-0000-0000-0000-000000000008','c1000000-0000-0000-0000-000000000022', 3),

-- ── P09 Aura High Support Bra (Running/High-Impact) ─────────────────────────
-- → P05 Contour Pocket Legging (explicitly mentioned in description)
-- → P15 Vital Long Sleeve Top (running top for cooler conditions)
-- → P02 Aerial High-Rise Legging (high-performance legging for running)
('c1000000-0000-0000-0000-000000000009','c1000000-0000-0000-0000-000000000005', 1),
('c1000000-0000-0000-0000-000000000009','c1000000-0000-0000-0000-000000000015', 2),
('c1000000-0000-0000-0000-000000000009','c1000000-0000-0000-0000-000000000002', 3),

-- ── P10 Courtside Pleated Skirt (Padel/Tennis) ──────────────────────────────
-- → P09 Aura High Support Bra (mentioned in description)
-- → P16 Altitude Zip Jacket (mentioned in description for court)
-- → P19 Padel Power Set (padel set that includes this skirt type)
('c1000000-0000-0000-0000-000000000010','c1000000-0000-0000-0000-000000000009', 1),
('c1000000-0000-0000-0000-000000000010','c1000000-0000-0000-0000-000000000016', 2),
('c1000000-0000-0000-0000-000000000010','c1000000-0000-0000-0000-000000000019', 3),

-- ── P11 Match Point Tennis Skirt (Tennis) ───────────────────────────────────
-- → P06 Luminary Longline Bra (explicitly mentioned in description)
-- → P07 Sculpt Medium Support Bra (medium-support option for tennis)
-- → P16 Altitude Zip Jacket (court outerwear for warmup)
('c1000000-0000-0000-0000-000000000011','c1000000-0000-0000-0000-000000000006', 1),
('c1000000-0000-0000-0000-000000000011','c1000000-0000-0000-0000-000000000007', 2),
('c1000000-0000-0000-0000-000000000011','c1000000-0000-0000-0000-000000000016', 3),

-- ── P12 Rally Wrap Skirt (Padel/Tennis) ─────────────────────────────────────
-- → P07 Sculpt Medium Support Bra (mentioned in description)
-- → P17 Motion Track Jacket (mentioned in description)
-- → P09 Aura High Support Bra (high support for padel)
('c1000000-0000-0000-0000-000000000012','c1000000-0000-0000-0000-000000000007', 1),
('c1000000-0000-0000-0000-000000000012','c1000000-0000-0000-0000-000000000017', 2),
('c1000000-0000-0000-0000-000000000012','c1000000-0000-0000-0000-000000000009', 3),

-- ── P13 Elevate Tank Top (Training) ─────────────────────────────────────────
-- → P02 Aerial High-Rise Legging (mentioned in description)
-- → P16 Altitude Zip Jacket (mentioned in description)
-- → P07 Sculpt Medium Support Bra (training bra to layer under or style with)
('c1000000-0000-0000-0000-000000000013','c1000000-0000-0000-0000-000000000002', 1),
('c1000000-0000-0000-0000-000000000013','c1000000-0000-0000-0000-000000000016', 2),
('c1000000-0000-0000-0000-000000000013','c1000000-0000-0000-0000-000000000007', 3),

-- ── P14 Serenity Ribbed Tank (Pilates/Studio) ────────────────────────────────
-- → P01 Serenity Ribbed Legging (described as matching set piece)
-- → P21 Studio Duo Set (complete set with this tank)
-- → P17 Motion Track Jacket (studio-to-street layer)
('c1000000-0000-0000-0000-000000000014','c1000000-0000-0000-0000-000000000001', 1),
('c1000000-0000-0000-0000-000000000014','c1000000-0000-0000-0000-000000000021', 2),
('c1000000-0000-0000-0000-000000000014','c1000000-0000-0000-0000-000000000017', 3),

-- ── P15 Vital Long Sleeve Top (Running) ─────────────────────────────────────
-- → P05 Contour Pocket Legging (mentioned in description for running)
-- → P09 Aura High Support Bra (high-support bra for running)
-- → P16 Altitude Zip Jacket (running outerwear layer)
('c1000000-0000-0000-0000-000000000015','c1000000-0000-0000-0000-000000000005', 1),
('c1000000-0000-0000-0000-000000000015','c1000000-0000-0000-0000-000000000009', 2),
('c1000000-0000-0000-0000-000000000015','c1000000-0000-0000-0000-000000000016', 3),

-- ── P16 Altitude Zip Jacket (Training/Court) ────────────────────────────────
-- → P02 Aerial High-Rise Legging (mentioned in description)
-- → P09 Aura High Support Bra (mentioned in description)
-- → P05 Contour Pocket Legging (running/training legging)
('c1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000002', 1),
('c1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000009', 2),
('c1000000-0000-0000-0000-000000000016','c1000000-0000-0000-0000-000000000005', 3),

-- ── P17 Motion Track Jacket (Studio/Pilates) ────────────────────────────────
-- → P03 Studio 7/8 Legging (mentioned in description)
-- → P08 Equilibrium Sports Bra (mentioned in description)
-- → P06 Luminary Longline Bra (studio bra for layering under jacket)
('c1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000003', 1),
('c1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000008', 2),
('c1000000-0000-0000-0000-000000000017','c1000000-0000-0000-0000-000000000006', 3),

-- ── P18 Restore Hoodie (Recovery/Wellness) ──────────────────────────────────
-- → P04 Flow Seamless Legging (mentioned in description: recovery day look)
-- → P22 Flow Practice Set (recovery/wellness aesthetic match)
-- → P01 Serenity Ribbed Legging (cozy recovery pairing)
('c1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000004', 1),
('c1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000022', 2),
('c1000000-0000-0000-0000-000000000018','c1000000-0000-0000-0000-000000000001', 3),

-- ── P19 Padel Power Set (Padel) ─────────────────────────────────────────────
-- → P10 Courtside Pleated Skirt (same court context; skirt standalone)
-- → P16 Altitude Zip Jacket (mentioned in description for warmup on court)
-- → P12 Rally Wrap Skirt (complementary padel skirt option)
('c1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000010', 1),
('c1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000016', 2),
('c1000000-0000-0000-0000-000000000019','c1000000-0000-0000-0000-000000000012', 3),

-- ── P20 Pilates Harmony Set (Pilates) ───────────────────────────────────────
-- → P17 Motion Track Jacket (mentioned in description: studio-to-street)
-- → P21 Studio Duo Set (complementary pilates set)
-- → P03 Studio 7/8 Legging (pilates legging to mix with set pieces)
('c1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000017', 1),
('c1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000021', 2),
('c1000000-0000-0000-0000-000000000020','c1000000-0000-0000-0000-000000000003', 3),

-- ── P21 Studio Duo Set (Pilates/Studio) ─────────────────────────────────────
-- → P01 Serenity Ribbed Legging (same rib line; complement)
-- → P17 Motion Track Jacket (studio-to-street layer)
-- → P20 Pilates Harmony Set (complementary pilates set)
('c1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000001', 1),
('c1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000017', 2),
('c1000000-0000-0000-0000-000000000021','c1000000-0000-0000-0000-000000000020', 3),

-- ── P22 Flow Practice Set (Yoga/Wellness) ───────────────────────────────────
-- → P18 Restore Hoodie (mentioned in description: add for warmup/savasana)
-- → P04 Flow Seamless Legging (same flow/yoga aesthetic; legging standalone)
-- → P08 Equilibrium Sports Bra (studio bra complement)
('c1000000-0000-0000-0000-000000000022','c1000000-0000-0000-0000-000000000018', 1),
('c1000000-0000-0000-0000-000000000022','c1000000-0000-0000-0000-000000000004', 2),
('c1000000-0000-0000-0000-000000000022','c1000000-0000-0000-0000-000000000008', 3)

ON CONFLICT DO NOTHING;


-- =============================================================================
-- END OF MIGRATION
-- Tables created:  1 (product_pairings)
-- RLS enabled on:  1 table
-- Policies created: 2 (product_pairings_public_read, product_pairings_admin_write)
-- collection_products rows added: 46 (Tennis: 15, Training: 27, Running: 12, gap fill only)
-- product_pairings rows added: 66 (22 products × 3 pairings each)
-- =============================================================================

COMMIT;
