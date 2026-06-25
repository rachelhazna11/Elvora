-- Elvora Seed Data — run once after 001_schema.sql has been applied. Idempotent if run in a fresh schema.
-- Populates: 7 categories, 6 collections, 22 products, 220 product variants,
--            44 product images, collection assignments, 32 reviews, 5 testimonials.

BEGIN;

-- ============================================================
-- SECTION 1: CATEGORIES
-- ============================================================
INSERT INTO categories (id, name, slug, description) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Leggings',    'leggings',    'High-performance leggings for every movement'),
  ('a1000000-0000-0000-0000-000000000002', 'Sports Bras', 'sports-bra',  'Supportive sports bras with a refined aesthetic'),
  ('a1000000-0000-0000-0000-000000000003', 'Tops',        'top',         'Elevated tanks and long-sleeve tops'),
  ('a1000000-0000-0000-0000-000000000004', 'Jackets',     'jacket',      'Refined outerwear for studio and court'),
  ('a1000000-0000-0000-0000-000000000005', 'Shorts',      'shorts',      'Lightweight shorts for active pursuits'),
  ('a1000000-0000-0000-0000-000000000006', 'Sets',        'set',         'Curated co-ordinate sets for a polished look'),
  ('a1000000-0000-0000-0000-000000000007', 'Skirts',      'skirt',       'Court-ready pleated and wrap skirts');

-- ============================================================
-- SECTION 2: COLLECTIONS
-- ============================================================
INSERT INTO collections (id, name, slug, description, is_featured, display_order) VALUES
  ('b1000000-0000-0000-0000-000000000001', 'New Arrivals',      'new-arrivals',      'The latest additions to the Elvora catalog',                          true,  1),
  ('b1000000-0000-0000-0000-000000000002', 'Best Sellers',      'best-sellers',      'The pieces our community returns to season after season',             true,  2),
  ('b1000000-0000-0000-0000-000000000003', 'The Padel Edit',    'padel-edit',        'Court-ready pieces engineered for padel and tennis',                  true,  3),
  ('b1000000-0000-0000-0000-000000000004', 'Studio Essentials', 'studio-essentials', 'The foundations of every pilates and yoga wardrobe',                  true,  4),
  ('b1000000-0000-0000-0000-000000000005', 'Summer Collection', 'summer-collection', 'Lightweight, breathable pieces for warm-weather training',            false, 5),
  ('b1000000-0000-0000-0000-000000000006', 'Core Range',        'core-range',        'Timeless, versatile pieces that anchor any active wardrobe',          false, 6),
  ('b1000000-0000-0000-0000-000000000007', 'Run Era',           'run-era',           'High-performance running pieces for the dedicated pavement runner',    true,  7),
  ('b1000000-0000-0000-0000-000000000008', 'Pace Mode',         'pace-mode',         'Speed-focused activewear engineered for interval and track training',  false, 8),
  ('b1000000-0000-0000-0000-000000000009', 'Runner''s High',    'runners-high',      'The post-run glow — recovery and casual styles for the running lifestyle', false, 9);

INSERT INTO collections (id, name, slug, description, is_featured, display_order) VALUES
  -- PADEL
  ('b1000000-0000-0000-0000-000000000010', 'Matcha Babe',     'matcha-babe',     'Elevated padel-club looks in sage, ivory and warm cream — sporty luxury',      false, 10),
  ('b1000000-0000-0000-0000-000000000011', 'Court Crush',     'court-crush',     'Confident courtwear in charcoal, ivory and soft neutrals with feminine edge', false, 11),
  ('b1000000-0000-0000-0000-000000000012', 'Rally Ready',     'rally-ready',     'Performance-neutral padel kit in stone, black and muted green tones',         false, 12),
  -- PILATES
  ('b1000000-0000-0000-0000-000000000013', 'Soft Flow',       'soft-flow',       'Graceful studio luxury in warm neutrals, ivory, soft sage and stone',          false, 13),
  ('b1000000-0000-0000-0000-000000000014', 'Main Character',  'main-character',  'Luxury pilates muse — elegant monochrome in charcoal, cream and earth tones', false, 14),
  ('b1000000-0000-0000-0000-000000000015', 'Studio Muse',     'studio-muse',     'Minimalist quiet luxury — premium studio uniform in soft beige and neutrals', false, 15),
  -- TENNIS
  ('b1000000-0000-0000-0000-000000000016', 'Love Match',      'love-match',      'Romantic luxury tennis in ivory, soft green and clean whites',                 false, 16),
  ('b1000000-0000-0000-0000-000000000017', 'Ace Energy',      'ace-energy',      'Modern performance-luxury tennis in contrast neutrals, charcoal and white',   false, 17),
  ('b1000000-0000-0000-0000-000000000018', 'Court Girl',      'court-girl',      'Luxury tennis lifestyle — feminine neutrals, ivory, soft cream and muted sage',false, 18),
  -- GYM
  ('b1000000-0000-0000-0000-000000000019', 'Power Mood',      'power-mood',      'Elevated training wear in charcoal, black and muted earth tones',              false, 19),
  ('b1000000-0000-0000-0000-000000000020', 'Built Different', 'built-different', 'High-performance luxury gym wear — monochrome neutrals and deep charcoal',    false, 20),
  ('b1000000-0000-0000-0000-000000000021', 'Hot Girl Lift',   'hot-girl-lift',   'Premium feminine strength in soft neutrals, warm beige and muted sage',       false, 21);

-- ============================================================
-- SECTION 3: PRODUCTS  (22 products across 7 categories)
-- ============================================================
INSERT INTO products (id, name, slug, description, category_id, base_price, fabric_details, care_instructions, styling_suggestions, is_active, is_featured, is_best_seller) VALUES

-- LEGGINGS (5) -----------------------------------------------
('c1000000-0000-0000-0000-000000000001',
 'Serenity Ribbed Legging', 'serenity-ribbed-legging',
 'A flattering ribbed legging with a high, sculpting waistband. The Serenity Ribbed is our most versatile style — equally at home in the studio or at brunch.',
 'a1000000-0000-0000-0000-000000000001', 85.00,
 '78% recycled nylon, 22% elastane. Mid-weight compression with a subtle rib texture and four-way stretch.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Reshape while damp.',
 'Pair with the Serenity Ribbed Tank for a tonal look, or the Luminary Longline Bra for contrast.',
 true, false, true),

('c1000000-0000-0000-0000-000000000002',
 'Aerial High-Rise Legging', 'aerial-high-rise-legging',
 'A sleek, high-rise legging with a cloud-soft finish. Sits at the natural waist and provides a second-skin fit through the hip and thigh.',
 'a1000000-0000-0000-0000-000000000001', 89.00,
 '82% recycled polyester, 18% elastane. Ultra-smooth compressive knit with a matte finish and subtle sheen.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Lay flat to dry.',
 'Style with the Elevate Tank and Altitude Zip Jacket for a complete training look.',
 true, true, false),

('c1000000-0000-0000-0000-000000000003',
 'Studio 7/8 Legging', 'studio-7-8-legging',
 'A cropped 7/8-length legging designed for studio work. The relaxed ankle opening makes it ideal for pilates, barre, and yoga.',
 'a1000000-0000-0000-0000-000000000001', 79.00,
 '74% nylon, 26% elastane. Lightweight, moisture-wicking knit that moves with you through every pose.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Reshape while damp.',
 'Pairs beautifully with the Equilibrium Sports Bra and Motion Track Jacket for a studio-to-street look.',
 true, false, false),

('c1000000-0000-0000-0000-000000000004',
 'Flow Seamless Legging', 'flow-seamless-legging',
 'Our most technical legging — engineered with seamless construction for zero friction and maximum comfort during long sessions.',
 'a1000000-0000-0000-0000-000000000001', 95.00,
 '88% nylon, 12% elastane. Seamless jacquard-knit with targeted compression zones and a barely-there feel.',
 'Hand wash cold or machine wash on delicate cycle. Do not tumble dry.',
 'Wear with the Aura High Support Bra and Restore Hoodie for an athleisure-inspired outfit.',
 true, true, false),

('c1000000-0000-0000-0000-000000000005',
 'Contour Pocket Legging', 'contour-pocket-legging',
 'A sculpting legging with two deep side pockets designed for runners and anyone who carries essentials during training.',
 'a1000000-0000-0000-0000-000000000001', 92.00,
 '80% recycled nylon, 20% elastane. High-density compressive fabric with a smooth exterior and moisture-management lining.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Lay flat to dry.',
 'Pair with the Vital Long Sleeve Top for outdoor runs, or the Sculpt Medium Support Bra for gym sessions.',
 true, true, false),

-- SPORTS BRAS (4) --------------------------------------------
('c1000000-0000-0000-0000-000000000006',
 'Luminary Longline Bra', 'luminary-longline-bra',
 'A longline bra with a refined square-neck silhouette. Light support and full coverage make it ideal for pilates, yoga, and low-impact training.',
 'a1000000-0000-0000-0000-000000000002', 68.00,
 '76% recycled nylon, 24% elastane. Smooth compressive knit with a built-in shelf bra and removable pads.',
 'Machine wash cold, gentle cycle. Remove pads before washing. Lay flat to dry.',
 'Wear as a standalone top with the Serenity Ribbed Legging for a clean, minimal look.',
 true, false, true),

('c1000000-0000-0000-0000-000000000007',
 'Sculpt Medium Support Bra', 'sculpt-medium-support-bra',
 'A medium-support racerback bra with a defined underwire-free structure. Supportive enough for cycling and HIIT without sacrificing elegance.',
 'a1000000-0000-0000-0000-000000000002', 65.00,
 '82% recycled polyester, 18% elastane. Double-layer front panel provides structure; single-layer back for ventilation.',
 'Machine wash cold, gentle cycle. Remove pads before washing. Lay flat to dry.',
 'Layer under the Restore Hoodie or wear with the Aerial High-Rise Legging and Altitude Zip Jacket.',
 true, false, false),

('c1000000-0000-0000-0000-000000000008',
 'Equilibrium Sports Bra', 'equilibrium-sports-bra',
 'A minimal triangle bra with adjustable wide-set straps. The Equilibrium is our go-to for studio and low-impact movement.',
 'a1000000-0000-0000-0000-000000000002', 72.00,
 '74% nylon, 26% elastane. Lightweight, smooth fabric with a barely-there finish. Removable padding.',
 'Hand wash cold. Remove pads before washing. Lay flat to dry.',
 'Style with the Studio 7/8 Legging and Motion Track Jacket for an elevated studio look.',
 true, true, false),

('c1000000-0000-0000-0000-000000000009',
 'Aura High Support Bra', 'aura-high-support-bra',
 'A high-support bra designed for running and high-impact training. Encapsulation structure and wide underband provide maximum stability.',
 'a1000000-0000-0000-0000-000000000002', 78.00,
 '84% recycled nylon, 16% elastane. Multi-layer construction with bonded seams for zero chafe. Powerband underband.',
 'Machine wash cold, gentle cycle. Remove pads before washing. Lay flat to dry.',
 'Pair with the Contour Pocket Legging for a high-performance running kit.',
 true, true, false),

-- SKIRTS (3) --------------------------------------------------
('c1000000-0000-0000-0000-000000000010',
 'Courtside Pleated Skirt', 'courtside-pleated-skirt',
 'A sophisticated pleated skirt with built-in compression shorts. Designed for padel and tennis, the Courtside moves freely through every swing.',
 'a1000000-0000-0000-0000-000000000007', 85.00,
 'Outer: 94% polyester, 6% elastane. Built-in shorts: 82% nylon, 18% elastane. Lightweight, crease-resistant pleat fabric.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Hang to dry.',
 'Style with the Aura High Support Bra and Altitude Zip Jacket for a complete padel look.',
 true, true, true),

('c1000000-0000-0000-0000-000000000011',
 'Match Point Tennis Skirt', 'match-point-tennis-skirt',
 'A structured tennis skirt with a flared silhouette and internal side pockets. Designed to move freely on court without riding up.',
 'a1000000-0000-0000-0000-000000000007', 88.00,
 'Outer: 92% polyester, 8% elastane. Inner shorts: 80% nylon, 20% elastane. Quick-dry, anti-static fabric.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Hang to dry.',
 'Pair with the Luminary Longline Bra for a refined court-ready look.',
 true, false, false),

('c1000000-0000-0000-0000-000000000012',
 'Rally Wrap Skirt', 'rally-wrap-skirt',
 'A wrap-style skirt with a secure inner waistband and built-in shorts. The flowing silhouette makes it versatile for both court and casual wear.',
 'a1000000-0000-0000-0000-000000000007', 82.00,
 'Outer: 96% recycled polyester, 4% elastane. Inner shorts: 78% nylon, 22% elastane. Woven-like warp-knit outer.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Hang to dry.',
 'Style with the Sculpt Medium Support Bra and Motion Track Jacket.',
 true, true, false),

-- TOPS (3) ---------------------------------------------------
('c1000000-0000-0000-0000-000000000013',
 'Elevate Tank Top', 'elevate-tank-top',
 'A streamlined muscle tank with a clean racerback silhouette. The Elevate is designed to be worn with or without a bra.',
 'a1000000-0000-0000-0000-000000000003', 55.00,
 '90% modal, 10% elastane. Buttery-soft fabric with natural drape and a relaxed fit through the body.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Reshape while damp.',
 'Style with the Aerial High-Rise Legging and Altitude Zip Jacket for a complete training look.',
 true, true, false),

('c1000000-0000-0000-0000-000000000014',
 'Serenity Ribbed Tank', 'serenity-ribbed-tank',
 'A fitted ribbed tank that coordinates perfectly with the Serenity Ribbed Legging. Wear as part of the matching set or as a standalone piece.',
 'a1000000-0000-0000-0000-000000000003', 58.00,
 '78% recycled nylon, 22% elastane. Matching rib texture to the Serenity Ribbed Legging. Built-in shelf bra.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Reshape while damp.',
 'Pairs as a set with the Serenity Ribbed Legging for a coordinated tonal look.',
 true, true, false),

('c1000000-0000-0000-0000-000000000015',
 'Vital Long Sleeve Top', 'vital-long-sleeve-top',
 'A technical long-sleeve top with thumbhole cuffs and a seamless back panel. Ideal for outdoor runs in cooler conditions.',
 'a1000000-0000-0000-0000-000000000003', 72.00,
 '86% recycled polyester, 14% elastane. Four-way stretch with reflective trim and a semi-fitted silhouette.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Lay flat to dry.',
 'Style with the Contour Pocket Legging for a complete running kit.',
 true, false, false),

-- JACKETS (3) ------------------------------------------------
('c1000000-0000-0000-0000-000000000016',
 'Altitude Zip Jacket', 'altitude-zip-jacket',
 'A full-zip technical jacket with a refined silhouette. The Altitude is engineered for performance but designed for everyday wear.',
 'a1000000-0000-0000-0000-000000000004', 125.00,
 '92% recycled polyester, 8% elastane. Lightweight, packable ripstop with a DWR finish. Interior mesh lining.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Re-apply DWR treatment annually.',
 'Style with the Aerial High-Rise Legging and Aura High Support Bra for a complete training look.',
 true, false, true),

('c1000000-0000-0000-0000-000000000017',
 'Motion Track Jacket', 'motion-track-jacket',
 'A structured track jacket with a boxy silhouette and clean lines. The Motion is our most versatile outerwear piece.',
 'a1000000-0000-0000-0000-000000000004', 138.00,
 '88% recycled nylon, 12% elastane. Lightweight, packable, with a stretch-knit collar and cuffs.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Lay flat to dry.',
 'Wear over the Studio 7/8 Legging and Equilibrium Sports Bra for a clean studio look.',
 true, true, false),

('c1000000-0000-0000-0000-000000000018',
 'Restore Hoodie', 'restore-hoodie',
 'A plush pull-over hoodie designed for recovery and rest days. The Restore wraps you in luxury without sacrificing a refined silhouette.',
 'a1000000-0000-0000-0000-000000000004', 115.00,
 '60% organic cotton, 30% recycled polyester, 10% elastane. French terry inside, smooth outside. Relaxed fit.',
 'Machine wash cold, gentle cycle. Tumble dry low. Remove promptly to preserve shape.',
 'Style with the Flow Seamless Legging for a cozy, elevated recovery day look.',
 true, true, false),

-- SETS (4) ---------------------------------------------------
('c1000000-0000-0000-0000-000000000019',
 'Padel Power Set', 'padel-power-set',
 'A complete padel kit — Courtside Pleated Skirt and matching Aura High Support Bra. Engineered for court performance with an elevated aesthetic.',
 'a1000000-0000-0000-0000-000000000006', 145.00,
 'Bra: 84% recycled nylon, 16% elastane. Skirt: 94% polyester, 6% elastane with built-in compression shorts.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Hang to dry.',
 'Add the Altitude Zip Jacket for warmup and cooldown on court.',
 true, true, false),

('c1000000-0000-0000-0000-000000000020',
 'Pilates Harmony Set', 'pilates-harmony-set',
 'The Luminary Longline Bra and Studio 7/8 Legging, curated as a matched set. A refined combination for the pilates studio.',
 'a1000000-0000-0000-0000-000000000006', 138.00,
 'Bra: 76% recycled nylon, 24% elastane. Legging: 74% nylon, 26% elastane. Both share a smooth-knit construction.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Reshape while damp.',
 'Layer with the Motion Track Jacket for studio-to-street transitions.',
 true, true, false),

('c1000000-0000-0000-0000-000000000021',
 'Studio Duo Set', 'studio-duo-set',
 'The Serenity Ribbed Tank and Serenity Ribbed Legging matched in the same rib texture for a seamless tonal look.',
 'a1000000-0000-0000-0000-000000000006', 132.00,
 '78% recycled nylon, 22% elastane throughout. Matching rib texture creates a co-ordinated appearance.',
 'Machine wash cold, gentle cycle. Do not tumble dry. Reshape while damp.',
 'A complete look that moves from the studio to the coffee shop effortlessly.',
 true, true, false),

('c1000000-0000-0000-0000-000000000022',
 'Flow Practice Set', 'flow-practice-set',
 'The Equilibrium Sports Bra and Flow Seamless Legging — a minimal, seamless combination for yoga and meditation practice.',
 'a1000000-0000-0000-0000-000000000006', 128.00,
 'Bra: 74% nylon, 26% elastane. Legging: 88% nylon, 12% elastane. Both seamless-knit for zero distraction.',
 'Hand wash cold or machine wash on delicate cycle. Do not tumble dry.',
 'Add the Restore Hoodie for warmup before and savasana after.',
 true, true, false);

-- ============================================================
-- SECTION 4: PRODUCT VARIANTS  (2 colours × 5 sizes = 10 per product × 22 products = 220 rows)
-- Colour hex: Sage=#A8BFA3, Ivory=#FAFAF7, Chalk=#F0EDE8, Forest=#3D5A47,
--             Slate=#6B7280, Rose=#D8A7A7, Obsidian=#2D2D2D, Dune=#C4B49A
-- ============================================================
INSERT INTO product_variants (product_id, colour, colour_hex, size, stock_quantity, sku) VALUES
-- P01 Serenity Ribbed Legging — Sage / Chalk
('c1000000-0000-0000-0000-000000000001','Sage',  '#A8BFA3','XS',12,'P01-SAG-XS'),
('c1000000-0000-0000-0000-000000000001','Sage',  '#A8BFA3','S', 18,'P01-SAG-S'),
('c1000000-0000-0000-0000-000000000001','Sage',  '#A8BFA3','M', 20,'P01-SAG-M'),
('c1000000-0000-0000-0000-000000000001','Sage',  '#A8BFA3','L', 15,'P01-SAG-L'),
('c1000000-0000-0000-0000-000000000001','Sage',  '#A8BFA3','XL', 8,'P01-SAG-XL'),
('c1000000-0000-0000-0000-000000000001','Chalk', '#F0EDE8','XS',10,'P01-CHK-XS'),
('c1000000-0000-0000-0000-000000000001','Chalk', '#F0EDE8','S', 15,'P01-CHK-S'),
('c1000000-0000-0000-0000-000000000001','Chalk', '#F0EDE8','M', 18,'P01-CHK-M'),
('c1000000-0000-0000-0000-000000000001','Chalk', '#F0EDE8','L', 12,'P01-CHK-L'),
('c1000000-0000-0000-0000-000000000001','Chalk', '#F0EDE8','XL', 6,'P01-CHK-XL'),
-- P02 Aerial High-Rise Legging — Sage / Ivory
('c1000000-0000-0000-0000-000000000002','Sage',  '#A8BFA3','XS',14,'P02-SAG-XS'),
('c1000000-0000-0000-0000-000000000002','Sage',  '#A8BFA3','S', 20,'P02-SAG-S'),
('c1000000-0000-0000-0000-000000000002','Sage',  '#A8BFA3','M', 22,'P02-SAG-M'),
('c1000000-0000-0000-0000-000000000002','Sage',  '#A8BFA3','L', 16,'P02-SAG-L'),
('c1000000-0000-0000-0000-000000000002','Sage',  '#A8BFA3','XL', 9,'P02-SAG-XL'),
('c1000000-0000-0000-0000-000000000002','Ivory', '#FAFAF7','XS',11,'P02-IVY-XS'),
('c1000000-0000-0000-0000-000000000002','Ivory', '#FAFAF7','S', 17,'P02-IVY-S'),
('c1000000-0000-0000-0000-000000000002','Ivory', '#FAFAF7','M', 19,'P02-IVY-M'),
('c1000000-0000-0000-0000-000000000002','Ivory', '#FAFAF7','L', 13,'P02-IVY-L'),
('c1000000-0000-0000-0000-000000000002','Ivory', '#FAFAF7','XL', 7,'P02-IVY-XL'),
-- P03 Studio 7/8 Legging — Slate / Obsidian
('c1000000-0000-0000-0000-000000000003','Slate',   '#6B7280','XS',10,'P03-SLT-XS'),
('c1000000-0000-0000-0000-000000000003','Slate',   '#6B7280','S', 16,'P03-SLT-S'),
('c1000000-0000-0000-0000-000000000003','Slate',   '#6B7280','M', 18,'P03-SLT-M'),
('c1000000-0000-0000-0000-000000000003','Slate',   '#6B7280','L', 12,'P03-SLT-L'),
('c1000000-0000-0000-0000-000000000003','Slate',   '#6B7280','XL', 6,'P03-SLT-XL'),
('c1000000-0000-0000-0000-000000000003','Obsidian','#2D2D2D','XS', 9,'P03-OBS-XS'),
('c1000000-0000-0000-0000-000000000003','Obsidian','#2D2D2D','S', 14,'P03-OBS-S'),
('c1000000-0000-0000-0000-000000000003','Obsidian','#2D2D2D','M', 16,'P03-OBS-M'),
('c1000000-0000-0000-0000-000000000003','Obsidian','#2D2D2D','L', 11,'P03-OBS-L'),
('c1000000-0000-0000-0000-000000000003','Obsidian','#2D2D2D','XL', 5,'P03-OBS-XL'),
-- P04 Flow Seamless Legging — Rose / Ivory
('c1000000-0000-0000-0000-000000000004','Rose',  '#D8A7A7','XS',12,'P04-RSE-XS'),
('c1000000-0000-0000-0000-000000000004','Rose',  '#D8A7A7','S', 16,'P04-RSE-S'),
('c1000000-0000-0000-0000-000000000004','Rose',  '#D8A7A7','M', 14,'P04-RSE-M'),
('c1000000-0000-0000-0000-000000000004','Rose',  '#D8A7A7','L', 10,'P04-RSE-L'),
('c1000000-0000-0000-0000-000000000004','Rose',  '#D8A7A7','XL', 6,'P04-RSE-XL'),
('c1000000-0000-0000-0000-000000000004','Ivory', '#FAFAF7','XS', 9,'P04-IVY-XS'),
('c1000000-0000-0000-0000-000000000004','Ivory', '#FAFAF7','S', 13,'P04-IVY-S'),
('c1000000-0000-0000-0000-000000000004','Ivory', '#FAFAF7','M', 15,'P04-IVY-M'),
('c1000000-0000-0000-0000-000000000004','Ivory', '#FAFAF7','L',  9,'P04-IVY-L'),
('c1000000-0000-0000-0000-000000000004','Ivory', '#FAFAF7','XL', 5,'P04-IVY-XL'),
-- P05 Contour Pocket Legging — Forest / Sage
('c1000000-0000-0000-0000-000000000005','Forest','#3D5A47','XS',10,'P05-FOR-XS'),
('c1000000-0000-0000-0000-000000000005','Forest','#3D5A47','S', 15,'P05-FOR-S'),
('c1000000-0000-0000-0000-000000000005','Forest','#3D5A47','M', 17,'P05-FOR-M'),
('c1000000-0000-0000-0000-000000000005','Forest','#3D5A47','L', 11,'P05-FOR-L'),
('c1000000-0000-0000-0000-000000000005','Forest','#3D5A47','XL', 6,'P05-FOR-XL'),
('c1000000-0000-0000-0000-000000000005','Sage',  '#A8BFA3','XS',11,'P05-SAG-XS'),
('c1000000-0000-0000-0000-000000000005','Sage',  '#A8BFA3','S', 14,'P05-SAG-S'),
('c1000000-0000-0000-0000-000000000005','Sage',  '#A8BFA3','M', 16,'P05-SAG-M'),
('c1000000-0000-0000-0000-000000000005','Sage',  '#A8BFA3','L', 10,'P05-SAG-L'),
('c1000000-0000-0000-0000-000000000005','Sage',  '#A8BFA3','XL', 5,'P05-SAG-XL'),
-- P06 Luminary Longline Bra — Sage / Ivory
('c1000000-0000-0000-0000-000000000006','Sage',  '#A8BFA3','XS',14,'P06-SAG-XS'),
('c1000000-0000-0000-0000-000000000006','Sage',  '#A8BFA3','S', 18,'P06-SAG-S'),
('c1000000-0000-0000-0000-000000000006','Sage',  '#A8BFA3','M', 22,'P06-SAG-M'),
('c1000000-0000-0000-0000-000000000006','Sage',  '#A8BFA3','L', 16,'P06-SAG-L'),
('c1000000-0000-0000-0000-000000000006','Sage',  '#A8BFA3','XL', 8,'P06-SAG-XL'),
('c1000000-0000-0000-0000-000000000006','Ivory', '#FAFAF7','XS',12,'P06-IVY-XS'),
('c1000000-0000-0000-0000-000000000006','Ivory', '#FAFAF7','S', 16,'P06-IVY-S'),
('c1000000-0000-0000-0000-000000000006','Ivory', '#FAFAF7','M', 20,'P06-IVY-M'),
('c1000000-0000-0000-0000-000000000006','Ivory', '#FAFAF7','L', 14,'P06-IVY-L'),
('c1000000-0000-0000-0000-000000000006','Ivory', '#FAFAF7','XL', 7,'P06-IVY-XL'),
-- P07 Sculpt Medium Support Bra — Chalk / Rose
('c1000000-0000-0000-0000-000000000007','Chalk', '#F0EDE8','XS',10,'P07-CHK-XS'),
('c1000000-0000-0000-0000-000000000007','Chalk', '#F0EDE8','S', 14,'P07-CHK-S'),
('c1000000-0000-0000-0000-000000000007','Chalk', '#F0EDE8','M', 17,'P07-CHK-M'),
('c1000000-0000-0000-0000-000000000007','Chalk', '#F0EDE8','L', 12,'P07-CHK-L'),
('c1000000-0000-0000-0000-000000000007','Chalk', '#F0EDE8','XL', 5,'P07-CHK-XL'),
('c1000000-0000-0000-0000-000000000007','Rose',  '#D8A7A7','XS', 9,'P07-RSE-XS'),
('c1000000-0000-0000-0000-000000000007','Rose',  '#D8A7A7','S', 13,'P07-RSE-S'),
('c1000000-0000-0000-0000-000000000007','Rose',  '#D8A7A7','M', 15,'P07-RSE-M'),
('c1000000-0000-0000-0000-000000000007','Rose',  '#D8A7A7','L', 10,'P07-RSE-L'),
('c1000000-0000-0000-0000-000000000007','Rose',  '#D8A7A7','XL', 4,'P07-RSE-XL'),
-- P08 Equilibrium Sports Bra — Slate / Ivory
('c1000000-0000-0000-0000-000000000008','Slate', '#6B7280','XS',11,'P08-SLT-XS'),
('c1000000-0000-0000-0000-000000000008','Slate', '#6B7280','S', 15,'P08-SLT-S'),
('c1000000-0000-0000-0000-000000000008','Slate', '#6B7280','M', 18,'P08-SLT-M'),
('c1000000-0000-0000-0000-000000000008','Slate', '#6B7280','L', 13,'P08-SLT-L'),
('c1000000-0000-0000-0000-000000000008','Slate', '#6B7280','XL', 6,'P08-SLT-XL'),
('c1000000-0000-0000-0000-000000000008','Ivory', '#FAFAF7','XS',10,'P08-IVY-XS'),
('c1000000-0000-0000-0000-000000000008','Ivory', '#FAFAF7','S', 14,'P08-IVY-S'),
('c1000000-0000-0000-0000-000000000008','Ivory', '#FAFAF7','M', 17,'P08-IVY-M'),
('c1000000-0000-0000-0000-000000000008','Ivory', '#FAFAF7','L', 11,'P08-IVY-L'),
('c1000000-0000-0000-0000-000000000008','Ivory', '#FAFAF7','XL', 5,'P08-IVY-XL'),
-- P09 Aura High Support Bra — Obsidian / Forest
('c1000000-0000-0000-0000-000000000009','Obsidian','#2D2D2D','XS',10,'P09-OBS-XS'),
('c1000000-0000-0000-0000-000000000009','Obsidian','#2D2D2D','S', 15,'P09-OBS-S'),
('c1000000-0000-0000-0000-000000000009','Obsidian','#2D2D2D','M', 17,'P09-OBS-M'),
('c1000000-0000-0000-0000-000000000009','Obsidian','#2D2D2D','L', 12,'P09-OBS-L'),
('c1000000-0000-0000-0000-000000000009','Obsidian','#2D2D2D','XL', 6,'P09-OBS-XL'),
('c1000000-0000-0000-0000-000000000009','Forest', '#3D5A47','XS', 8,'P09-FOR-XS'),
('c1000000-0000-0000-0000-000000000009','Forest', '#3D5A47','S', 12,'P09-FOR-S'),
('c1000000-0000-0000-0000-000000000009','Forest', '#3D5A47','M', 14,'P09-FOR-M'),
('c1000000-0000-0000-0000-000000000009','Forest', '#3D5A47','L',  9,'P09-FOR-L'),
('c1000000-0000-0000-0000-000000000009','Forest', '#3D5A47','XL', 4,'P09-FOR-XL'),
-- P10 Courtside Pleated Skirt — Ivory / Chalk
('c1000000-0000-0000-0000-000000000010','Ivory', '#FAFAF7','XS',13,'P10-IVY-XS'),
('c1000000-0000-0000-0000-000000000010','Ivory', '#FAFAF7','S', 18,'P10-IVY-S'),
('c1000000-0000-0000-0000-000000000010','Ivory', '#FAFAF7','M', 20,'P10-IVY-M'),
('c1000000-0000-0000-0000-000000000010','Ivory', '#FAFAF7','L', 14,'P10-IVY-L'),
('c1000000-0000-0000-0000-000000000010','Ivory', '#FAFAF7','XL', 7,'P10-IVY-XL'),
('c1000000-0000-0000-0000-000000000010','Chalk', '#F0EDE8','XS',10,'P10-CHK-XS'),
('c1000000-0000-0000-0000-000000000010','Chalk', '#F0EDE8','S', 14,'P10-CHK-S'),
('c1000000-0000-0000-0000-000000000010','Chalk', '#F0EDE8','M', 16,'P10-CHK-M'),
('c1000000-0000-0000-0000-000000000010','Chalk', '#F0EDE8','L', 11,'P10-CHK-L'),
('c1000000-0000-0000-0000-000000000010','Chalk', '#F0EDE8','XL', 5,'P10-CHK-XL'),
-- P11 Match Point Tennis Skirt — Sage / Ivory
('c1000000-0000-0000-0000-000000000011','Sage',  '#A8BFA3','XS',10,'P11-SAG-XS'),
('c1000000-0000-0000-0000-000000000011','Sage',  '#A8BFA3','S', 14,'P11-SAG-S'),
('c1000000-0000-0000-0000-000000000011','Sage',  '#A8BFA3','M', 16,'P11-SAG-M'),
('c1000000-0000-0000-0000-000000000011','Sage',  '#A8BFA3','L', 11,'P11-SAG-L'),
('c1000000-0000-0000-0000-000000000011','Sage',  '#A8BFA3','XL', 5,'P11-SAG-XL'),
('c1000000-0000-0000-0000-000000000011','Ivory', '#FAFAF7','XS', 9,'P11-IVY-XS'),
('c1000000-0000-0000-0000-000000000011','Ivory', '#FAFAF7','S', 12,'P11-IVY-S'),
('c1000000-0000-0000-0000-000000000011','Ivory', '#FAFAF7','M', 14,'P11-IVY-M'),
('c1000000-0000-0000-0000-000000000011','Ivory', '#FAFAF7','L',  9,'P11-IVY-L'),
('c1000000-0000-0000-0000-000000000011','Ivory', '#FAFAF7','XL', 4,'P11-IVY-XL'),
-- P12 Rally Wrap Skirt — Chalk / Dune
('c1000000-0000-0000-0000-000000000012','Chalk', '#F0EDE8','XS', 9,'P12-CHK-XS'),
('c1000000-0000-0000-0000-000000000012','Chalk', '#F0EDE8','S', 13,'P12-CHK-S'),
('c1000000-0000-0000-0000-000000000012','Chalk', '#F0EDE8','M', 15,'P12-CHK-M'),
('c1000000-0000-0000-0000-000000000012','Chalk', '#F0EDE8','L', 10,'P12-CHK-L'),
('c1000000-0000-0000-0000-000000000012','Chalk', '#F0EDE8','XL', 4,'P12-CHK-XL'),
('c1000000-0000-0000-0000-000000000012','Dune',  '#C4B49A','XS', 8,'P12-DUN-XS'),
('c1000000-0000-0000-0000-000000000012','Dune',  '#C4B49A','S', 11,'P12-DUN-S'),
('c1000000-0000-0000-0000-000000000012','Dune',  '#C4B49A','M', 13,'P12-DUN-M'),
('c1000000-0000-0000-0000-000000000012','Dune',  '#C4B49A','L',  8,'P12-DUN-L'),
('c1000000-0000-0000-0000-000000000012','Dune',  '#C4B49A','XL', 4,'P12-DUN-XL'),
-- P13 Elevate Tank Top — Ivory / Sage
('c1000000-0000-0000-0000-000000000013','Ivory', '#FAFAF7','XS',15,'P13-IVY-XS'),
('c1000000-0000-0000-0000-000000000013','Ivory', '#FAFAF7','S', 20,'P13-IVY-S'),
('c1000000-0000-0000-0000-000000000013','Ivory', '#FAFAF7','M', 24,'P13-IVY-M'),
('c1000000-0000-0000-0000-000000000013','Ivory', '#FAFAF7','L', 18,'P13-IVY-L'),
('c1000000-0000-0000-0000-000000000013','Ivory', '#FAFAF7','XL', 9,'P13-IVY-XL'),
('c1000000-0000-0000-0000-000000000013','Sage',  '#A8BFA3','XS',13,'P13-SAG-XS'),
('c1000000-0000-0000-0000-000000000013','Sage',  '#A8BFA3','S', 17,'P13-SAG-S'),
('c1000000-0000-0000-0000-000000000013','Sage',  '#A8BFA3','M', 21,'P13-SAG-M'),
('c1000000-0000-0000-0000-000000000013','Sage',  '#A8BFA3','L', 15,'P13-SAG-L'),
('c1000000-0000-0000-0000-000000000013','Sage',  '#A8BFA3','XL', 7,'P13-SAG-XL'),
-- P14 Serenity Ribbed Tank — Chalk / Rose
('c1000000-0000-0000-0000-000000000014','Chalk', '#F0EDE8','XS',12,'P14-CHK-XS'),
('c1000000-0000-0000-0000-000000000014','Chalk', '#F0EDE8','S', 16,'P14-CHK-S'),
('c1000000-0000-0000-0000-000000000014','Chalk', '#F0EDE8','M', 19,'P14-CHK-M'),
('c1000000-0000-0000-0000-000000000014','Chalk', '#F0EDE8','L', 13,'P14-CHK-L'),
('c1000000-0000-0000-0000-000000000014','Chalk', '#F0EDE8','XL', 6,'P14-CHK-XL'),
('c1000000-0000-0000-0000-000000000014','Rose',  '#D8A7A7','XS',10,'P14-RSE-XS'),
('c1000000-0000-0000-0000-000000000014','Rose',  '#D8A7A7','S', 13,'P14-RSE-S'),
('c1000000-0000-0000-0000-000000000014','Rose',  '#D8A7A7','M', 16,'P14-RSE-M'),
('c1000000-0000-0000-0000-000000000014','Rose',  '#D8A7A7','L', 11,'P14-RSE-L'),
('c1000000-0000-0000-0000-000000000014','Rose',  '#D8A7A7','XL', 5,'P14-RSE-XL'),
-- P15 Vital Long Sleeve Top — Slate / Forest
('c1000000-0000-0000-0000-000000000015','Slate', '#6B7280','XS', 9,'P15-SLT-XS'),
('c1000000-0000-0000-0000-000000000015','Slate', '#6B7280','S', 13,'P15-SLT-S'),
('c1000000-0000-0000-0000-000000000015','Slate', '#6B7280','M', 15,'P15-SLT-M'),
('c1000000-0000-0000-0000-000000000015','Slate', '#6B7280','L', 10,'P15-SLT-L'),
('c1000000-0000-0000-0000-000000000015','Slate', '#6B7280','XL', 4,'P15-SLT-XL'),
('c1000000-0000-0000-0000-000000000015','Forest','#3D5A47','XS', 8,'P15-FOR-XS'),
('c1000000-0000-0000-0000-000000000015','Forest','#3D5A47','S', 11,'P15-FOR-S'),
('c1000000-0000-0000-0000-000000000015','Forest','#3D5A47','M', 13,'P15-FOR-M'),
('c1000000-0000-0000-0000-000000000015','Forest','#3D5A47','L',  8,'P15-FOR-L'),
('c1000000-0000-0000-0000-000000000015','Forest','#3D5A47','XL', 4,'P15-FOR-XL'),
-- P16 Altitude Zip Jacket — Obsidian / Forest
('c1000000-0000-0000-0000-000000000016','Obsidian','#2D2D2D','XS',10,'P16-OBS-XS'),
('c1000000-0000-0000-0000-000000000016','Obsidian','#2D2D2D','S', 14,'P16-OBS-S'),
('c1000000-0000-0000-0000-000000000016','Obsidian','#2D2D2D','M', 16,'P16-OBS-M'),
('c1000000-0000-0000-0000-000000000016','Obsidian','#2D2D2D','L', 11,'P16-OBS-L'),
('c1000000-0000-0000-0000-000000000016','Obsidian','#2D2D2D','XL', 5,'P16-OBS-XL'),
('c1000000-0000-0000-0000-000000000016','Forest', '#3D5A47','XS', 8,'P16-FOR-XS'),
('c1000000-0000-0000-0000-000000000016','Forest', '#3D5A47','S', 12,'P16-FOR-S'),
('c1000000-0000-0000-0000-000000000016','Forest', '#3D5A47','M', 14,'P16-FOR-M'),
('c1000000-0000-0000-0000-000000000016','Forest', '#3D5A47','L',  9,'P16-FOR-L'),
('c1000000-0000-0000-0000-000000000016','Forest', '#3D5A47','XL', 4,'P16-FOR-XL'),
-- P17 Motion Track Jacket — Sage / Slate
('c1000000-0000-0000-0000-000000000017','Sage',  '#A8BFA3','XS', 9,'P17-SAG-XS'),
('c1000000-0000-0000-0000-000000000017','Sage',  '#A8BFA3','S', 13,'P17-SAG-S'),
('c1000000-0000-0000-0000-000000000017','Sage',  '#A8BFA3','M', 15,'P17-SAG-M'),
('c1000000-0000-0000-0000-000000000017','Sage',  '#A8BFA3','L', 10,'P17-SAG-L'),
('c1000000-0000-0000-0000-000000000017','Sage',  '#A8BFA3','XL', 4,'P17-SAG-XL'),
('c1000000-0000-0000-0000-000000000017','Slate', '#6B7280','XS', 8,'P17-SLT-XS'),
('c1000000-0000-0000-0000-000000000017','Slate', '#6B7280','S', 11,'P17-SLT-S'),
('c1000000-0000-0000-0000-000000000017','Slate', '#6B7280','M', 13,'P17-SLT-M'),
('c1000000-0000-0000-0000-000000000017','Slate', '#6B7280','L',  8,'P17-SLT-L'),
('c1000000-0000-0000-0000-000000000017','Slate', '#6B7280','XL', 3,'P17-SLT-XL'),
-- P18 Restore Hoodie — Ivory / Chalk
('c1000000-0000-0000-0000-000000000018','Ivory', '#FAFAF7','XS',12,'P18-IVY-XS'),
('c1000000-0000-0000-0000-000000000018','Ivory', '#FAFAF7','S', 16,'P18-IVY-S'),
('c1000000-0000-0000-0000-000000000018','Ivory', '#FAFAF7','M', 18,'P18-IVY-M'),
('c1000000-0000-0000-0000-000000000018','Ivory', '#FAFAF7','L', 13,'P18-IVY-L'),
('c1000000-0000-0000-0000-000000000018','Ivory', '#FAFAF7','XL', 6,'P18-IVY-XL'),
('c1000000-0000-0000-0000-000000000018','Chalk', '#F0EDE8','XS',10,'P18-CHK-XS'),
('c1000000-0000-0000-0000-000000000018','Chalk', '#F0EDE8','S', 14,'P18-CHK-S'),
('c1000000-0000-0000-0000-000000000018','Chalk', '#F0EDE8','M', 16,'P18-CHK-M'),
('c1000000-0000-0000-0000-000000000018','Chalk', '#F0EDE8','L', 11,'P18-CHK-L'),
('c1000000-0000-0000-0000-000000000018','Chalk', '#F0EDE8','XL', 5,'P18-CHK-XL'),
-- P19 Padel Power Set — Sage / Ivory
('c1000000-0000-0000-0000-000000000019','Sage',  '#A8BFA3','XS',10,'P19-SAG-XS'),
('c1000000-0000-0000-0000-000000000019','Sage',  '#A8BFA3','S', 14,'P19-SAG-S'),
('c1000000-0000-0000-0000-000000000019','Sage',  '#A8BFA3','M', 16,'P19-SAG-M'),
('c1000000-0000-0000-0000-000000000019','Sage',  '#A8BFA3','L', 11,'P19-SAG-L'),
('c1000000-0000-0000-0000-000000000019','Sage',  '#A8BFA3','XL', 5,'P19-SAG-XL'),
('c1000000-0000-0000-0000-000000000019','Ivory', '#FAFAF7','XS', 9,'P19-IVY-XS'),
('c1000000-0000-0000-0000-000000000019','Ivory', '#FAFAF7','S', 12,'P19-IVY-S'),
('c1000000-0000-0000-0000-000000000019','Ivory', '#FAFAF7','M', 14,'P19-IVY-M'),
('c1000000-0000-0000-0000-000000000019','Ivory', '#FAFAF7','L',  9,'P19-IVY-L'),
('c1000000-0000-0000-0000-000000000019','Ivory', '#FAFAF7','XL', 4,'P19-IVY-XL'),
-- P20 Pilates Harmony Set — Rose / Chalk
('c1000000-0000-0000-0000-000000000020','Rose',  '#D8A7A7','XS',11,'P20-RSE-XS'),
('c1000000-0000-0000-0000-000000000020','Rose',  '#D8A7A7','S', 15,'P20-RSE-S'),
('c1000000-0000-0000-0000-000000000020','Rose',  '#D8A7A7','M', 17,'P20-RSE-M'),
('c1000000-0000-0000-0000-000000000020','Rose',  '#D8A7A7','L', 12,'P20-RSE-L'),
('c1000000-0000-0000-0000-000000000020','Rose',  '#D8A7A7','XL', 5,'P20-RSE-XL'),
('c1000000-0000-0000-0000-000000000020','Chalk', '#F0EDE8','XS', 9,'P20-CHK-XS'),
('c1000000-0000-0000-0000-000000000020','Chalk', '#F0EDE8','S', 12,'P20-CHK-S'),
('c1000000-0000-0000-0000-000000000020','Chalk', '#F0EDE8','M', 15,'P20-CHK-M'),
('c1000000-0000-0000-0000-000000000020','Chalk', '#F0EDE8','L', 10,'P20-CHK-L'),
('c1000000-0000-0000-0000-000000000020','Chalk', '#F0EDE8','XL', 4,'P20-CHK-XL'),
-- P21 Studio Duo Set — Ivory / Sage
('c1000000-0000-0000-0000-000000000021','Ivory', '#FAFAF7','XS',11,'P21-IVY-XS'),
('c1000000-0000-0000-0000-000000000021','Ivory', '#FAFAF7','S', 15,'P21-IVY-S'),
('c1000000-0000-0000-0000-000000000021','Ivory', '#FAFAF7','M', 17,'P21-IVY-M'),
('c1000000-0000-0000-0000-000000000021','Ivory', '#FAFAF7','L', 12,'P21-IVY-L'),
('c1000000-0000-0000-0000-000000000021','Ivory', '#FAFAF7','XL', 5,'P21-IVY-XL'),
('c1000000-0000-0000-0000-000000000021','Sage',  '#A8BFA3','XS', 9,'P21-SAG-XS'),
('c1000000-0000-0000-0000-000000000021','Sage',  '#A8BFA3','S', 13,'P21-SAG-S'),
('c1000000-0000-0000-0000-000000000021','Sage',  '#A8BFA3','M', 15,'P21-SAG-M'),
('c1000000-0000-0000-0000-000000000021','Sage',  '#A8BFA3','L', 10,'P21-SAG-L'),
('c1000000-0000-0000-0000-000000000021','Sage',  '#A8BFA3','XL', 4,'P21-SAG-XL'),
-- P22 Flow Practice Set — Slate / Forest
('c1000000-0000-0000-0000-000000000022','Slate', '#6B7280','XS', 9,'P22-SLT-XS'),
('c1000000-0000-0000-0000-000000000022','Slate', '#6B7280','S', 13,'P22-SLT-S'),
('c1000000-0000-0000-0000-000000000022','Slate', '#6B7280','M', 15,'P22-SLT-M'),
('c1000000-0000-0000-0000-000000000022','Slate', '#6B7280','L', 10,'P22-SLT-L'),
('c1000000-0000-0000-0000-000000000022','Slate', '#6B7280','XL', 4,'P22-SLT-XL'),
('c1000000-0000-0000-0000-000000000022','Forest','#3D5A47','XS', 8,'P22-FOR-XS'),
('c1000000-0000-0000-0000-000000000022','Forest','#3D5A47','S', 11,'P22-FOR-S'),
('c1000000-0000-0000-0000-000000000022','Forest','#3D5A47','M', 13,'P22-FOR-M'),
('c1000000-0000-0000-0000-000000000022','Forest','#3D5A47','L',  8,'P22-FOR-L'),
('c1000000-0000-0000-0000-000000000022','Forest','#3D5A47','XL', 3,'P22-FOR-XL');

-- ============================================================
-- SECTION 5: PRODUCT IMAGES  (2 per product = 44 rows)
-- Unsplash CDN: https://images.unsplash.com/photo-{id}?w=800&q=80
-- ============================================================
INSERT INTO product_images (product_id, url, alt_text, display_order) VALUES
-- P01
('c1000000-0000-0000-0000-000000000001','https://images.unsplash.com/photo-1518611560-2d6d6d67c0b5?w=800&q=80','Serenity Ribbed Legging in Sage',1),
('c1000000-0000-0000-0000-000000000001','https://images.unsplash.com/photo-1549476464-37392f717d84?w=800&q=80','Serenity Ribbed Legging detail',2),
-- P02
('c1000000-0000-0000-0000-000000000002','https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80','Aerial High-Rise Legging in Sage',1),
('c1000000-0000-0000-0000-000000000002','https://images.unsplash.com/photo-1485727671739-f8a2c53dc3b7?w=800&q=80','Aerial High-Rise Legging lifestyle',2),
-- P03
('c1000000-0000-0000-0000-000000000003','https://images.unsplash.com/photo-1576678927702-ef95b4b85bb2?w=800&q=80','Studio 7/8 Legging in Slate',1),
('c1000000-0000-0000-0000-000000000003','https://images.unsplash.com/photo-1521805492803-d978ad99f54c?w=800&q=80','Studio 7/8 Legging in motion',2),
-- P04
('c1000000-0000-0000-0000-000000000004','https://images.unsplash.com/photo-1523394643039-a1a15e1d21a8?w=800&q=80','Flow Seamless Legging in Rose',1),
('c1000000-0000-0000-0000-000000000004','https://images.unsplash.com/photo-1594911772125-07fc7a2d8d9f?w=800&q=80','Flow Seamless Legging detail',2),
-- P05
('c1000000-0000-0000-0000-000000000005','https://images.unsplash.com/photo-1607962837359-5e7e89f86776?w=800&q=80','Contour Pocket Legging in Forest',1),
('c1000000-0000-0000-0000-000000000005','https://images.unsplash.com/photo-1599058945522-a14254e68bcb?w=800&q=80','Contour Pocket Legging on a run',2),
-- P06
('c1000000-0000-0000-0000-000000000006','https://images.unsplash.com/photo-1571731956672-f2b94d7dd2a4?w=800&q=80','Luminary Longline Bra in Sage',1),
('c1000000-0000-0000-0000-000000000006','https://images.unsplash.com/photo-1540206395880-7bd7dba0c9dd?w=800&q=80','Luminary Longline Bra front view',2),
-- P07
('c1000000-0000-0000-0000-000000000007','https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=800&q=80','Sculpt Medium Support Bra in Chalk',1),
('c1000000-0000-0000-0000-000000000007','https://images.unsplash.com/photo-1483381616986-69b93cbcb8b9?w=800&q=80','Sculpt Medium Support Bra back',2),
-- P08
('c1000000-0000-0000-0000-000000000008','https://images.unsplash.com/photo-1510440961977-1ae5eb878f41?w=800&q=80','Equilibrium Sports Bra in Slate',1),
('c1000000-0000-0000-0000-000000000008','https://images.unsplash.com/photo-1573742741869-a2c6ece2c2ed?w=800&q=80','Equilibrium Sports Bra lifestyle',2),
-- P09
('c1000000-0000-0000-0000-000000000009','https://images.unsplash.com/photo-1541534741688-6078c887d972?w=800&q=80','Aura High Support Bra in Obsidian',1),
('c1000000-0000-0000-0000-000000000009','https://images.unsplash.com/photo-1514481538271-cf9f84ea3b9d?w=800&q=80','Aura High Support Bra running',2),
-- P10
('c1000000-0000-0000-0000-000000000010','https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=800&q=80','Courtside Pleated Skirt in Ivory',1),
('c1000000-0000-0000-0000-000000000010','https://images.unsplash.com/photo-1535743686739-d47e40e04fe9?w=800&q=80','Courtside Pleated Skirt on court',2),
-- P11
('c1000000-0000-0000-0000-000000000011','https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=800&q=80','Match Point Tennis Skirt in Sage',1),
('c1000000-0000-0000-0000-000000000011','https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=800&q=80','Match Point Tennis Skirt in play',2),
-- P12
('c1000000-0000-0000-0000-000000000012','https://images.unsplash.com/photo-1552674605-db5fecabfe65?w=800&q=80','Rally Wrap Skirt in Chalk',1),
('c1000000-0000-0000-0000-000000000012','https://images.unsplash.com/photo-1554284126-aa88f22d8b74?w=800&q=80','Rally Wrap Skirt detail',2),
-- P13
('c1000000-0000-0000-0000-000000000013','https://images.unsplash.com/photo-1544216717-3bbf52512659?w=800&q=80','Elevate Tank Top in Ivory',1),
('c1000000-0000-0000-0000-000000000013','https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80','Elevate Tank Top lifestyle',2),
-- P14
('c1000000-0000-0000-0000-000000000014','https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?w=800&q=80','Serenity Ribbed Tank in Chalk',1),
('c1000000-0000-0000-0000-000000000014','https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=800&q=80','Serenity Ribbed Tank detail',2),
-- P15
('c1000000-0000-0000-0000-000000000015','https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80','Vital Long Sleeve Top in Slate',1),
('c1000000-0000-0000-0000-000000000015','https://images.unsplash.com/photo-1589477741273-cff00f01b7a4?w=800&q=80','Vital Long Sleeve Top running',2),
-- P16
('c1000000-0000-0000-0000-000000000016','https://images.unsplash.com/photo-1584464491033-f628c5e6cdc9?w=800&q=80','Altitude Zip Jacket in Obsidian',1),
('c1000000-0000-0000-0000-000000000016','https://images.unsplash.com/photo-1577925129943-4e9bb2cfaa0f?w=800&q=80','Altitude Zip Jacket lifestyle',2),
-- P17
('c1000000-0000-0000-0000-000000000017','https://images.unsplash.com/photo-1603455778955-f55f7c88c765?w=800&q=80','Motion Track Jacket in Sage',1),
('c1000000-0000-0000-0000-000000000017','https://images.unsplash.com/photo-1595074475690-6fd9e6a2e24d?w=800&q=80','Motion Track Jacket street style',2),
-- P18
('c1000000-0000-0000-0000-000000000018','https://images.unsplash.com/photo-1504945606086-04b7a7e1b8f2?w=800&q=80','Restore Hoodie in Ivory',1),
('c1000000-0000-0000-0000-000000000018','https://images.unsplash.com/photo-1548438294-1ad5d5f4f063?w=800&q=80','Restore Hoodie relaxed fit',2),
-- P19
('c1000000-0000-0000-0000-000000000019','https://images.unsplash.com/photo-1601342630314-55bfbd30553a?w=800&q=80','Padel Power Set in Sage',1),
('c1000000-0000-0000-0000-000000000019','https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80','Padel Power Set on court',2),
-- P20
('c1000000-0000-0000-0000-000000000020','https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=800&q=80','Pilates Harmony Set in Rose',1),
('c1000000-0000-0000-0000-000000000020','https://images.unsplash.com/photo-1587899897977-2cdea3f83ec9?w=800&q=80','Pilates Harmony Set in studio',2),
-- P21
('c1000000-0000-0000-0000-000000000021','https://images.unsplash.com/photo-1464490976047-673f71c3dbf5?w=800&q=80','Studio Duo Set in Ivory',1),
('c1000000-0000-0000-0000-000000000021','https://images.unsplash.com/photo-1550345332-701700c57906?w=800&q=80','Studio Duo Set tonal look',2),
-- P22
('c1000000-0000-0000-0000-000000000022','https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=800&q=80','Flow Practice Set in Slate',1),
('c1000000-0000-0000-0000-000000000022','https://images.unsplash.com/photo-1590487988917-01f01a8d4b2a?w=800&q=80','Flow Practice Set yoga pose',2);

-- ============================================================
-- SECTION 6: COLLECTION PRODUCTS
-- New Arrivals: P02, P04, P05, P09, P13, P19
-- Best Sellers: P01, P06, P10, P16
-- Padel Edit:   P10, P11, P12, P19
-- Studio Ess.:  P01, P02, P03, P06, P07, P08
-- Summer:       P08, P10, P11, P13, P14
-- Core Range:   P01, P03, P06, P13, P16, P18
-- ============================================================
INSERT INTO collection_products (collection_id, product_id, display_order) VALUES
-- New Arrivals
('b1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000002',1),
('b1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000004',2),
('b1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000005',3),
('b1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000009',4),
('b1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000013',5),
('b1000000-0000-0000-0000-000000000001','c1000000-0000-0000-0000-000000000019',6),
-- Best Sellers
('b1000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000001',1),
('b1000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000006',2),
('b1000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000010',3),
('b1000000-0000-0000-0000-000000000002','c1000000-0000-0000-0000-000000000016',4),
-- Padel Edit
('b1000000-0000-0000-0000-000000000003','c1000000-0000-0000-0000-000000000010',1),
('b1000000-0000-0000-0000-000000000003','c1000000-0000-0000-0000-000000000011',2),
('b1000000-0000-0000-0000-000000000003','c1000000-0000-0000-0000-000000000012',3),
('b1000000-0000-0000-0000-000000000003','c1000000-0000-0000-0000-000000000019',4),
-- Studio Essentials
('b1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000001',1),
('b1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000002',2),
('b1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000003',3),
('b1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000006',4),
('b1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000007',5),
('b1000000-0000-0000-0000-000000000004','c1000000-0000-0000-0000-000000000008',6),
-- Summer Collection
('b1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000008',1),
('b1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000010',2),
('b1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000011',3),
('b1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000013',4),
('b1000000-0000-0000-0000-000000000005','c1000000-0000-0000-0000-000000000014',5),
-- Core Range
('b1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000001',1),
('b1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000003',2),
('b1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000006',3),
('b1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000013',4),
('b1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000016',5),
('b1000000-0000-0000-0000-000000000006','c1000000-0000-0000-0000-000000000018',6);

-- ============================================================
-- SECTION 7: REVIEWS  (4 per product × 8 products = 32 rows)
-- Products: P01, P02, P06, P07, P10, P16, P19, P20
-- ============================================================
INSERT INTO reviews (product_id, reviewer_name, rating, review_text, fit_feedback) VALUES
-- P01 Serenity Ribbed Legging
('c1000000-0000-0000-0000-000000000001','Sophie H.',5,'Absolutely love these — the rib texture is so flattering and they hold their shape after multiple washes. The waistband sits perfectly.','true_to_size'),
('c1000000-0000-0000-0000-000000000001','Amara T.',5,'I bought the Sage and immediately ordered the Chalk. Incredibly comfortable for pilates and look elegant enough for coffee after class.','true_to_size'),
('c1000000-0000-0000-0000-000000000001','Elena R.',4,'Great quality and the compression is just right — supportive without feeling restrictive. Sizing is spot on.','true_to_size'),
('c1000000-0000-0000-0000-000000000001','Isabelle M.',5,'My favourite legging. The ribbed fabric is luxurious to the touch and the fit is incredibly flattering through the hip and thigh.','true_to_size'),
-- P02 Aerial High-Rise Legging
('c1000000-0000-0000-0000-000000000002','Clara B.',5,'Buttery soft and completely opaque. The high rise is genuinely high — stays put through every squat. My new gym staple.','true_to_size'),
('c1000000-0000-0000-0000-000000000002','Natasha W.',5,'These feel like wearing nothing — completely second-skin fit. The Sage colour is even more beautiful in person.','true_to_size'),
('c1000000-0000-0000-0000-000000000002','Julia F.',4,'Excellent quality. I found I needed to size down slightly for the most flattering fit — very stretchy fabric.','runs_large'),
('c1000000-0000-0000-0000-000000000002','Mia P.',5,'Wore these for a 10k and they were perfect. No riding, no chafing, and looked great for the post-run coffee too.','true_to_size'),
-- P06 Luminary Longline Bra
('c1000000-0000-0000-0000-000000000006','Olivia S.',5,'The perfect pilates bra. Longline fit is so flattering and the square neckline gives it a refined look. Worn it to three classes this week.','true_to_size'),
('c1000000-0000-0000-0000-000000000006','Priya K.',5,'Beautiful construction and incredibly comfortable. The removable pads stay in place perfectly — no shifting during class.','true_to_size'),
('c1000000-0000-0000-0000-000000000006','Charlotte N.',4,'Excellent light support for yoga. The ivory colour is true to the photo. I wish it came in more colours.','true_to_size'),
('c1000000-0000-0000-0000-000000000006','Zoe A.',5,'I wear this as a top on its own — the longline silhouette means you can skip the extra layer. Quality is exceptional.','true_to_size'),
-- P07 Sculpt Medium Support Bra
('c1000000-0000-0000-0000-000000000007','Francesca D.',5,'Finally a sports bra that looks elegant. The racerback sits beautifully and the medium support is perfect for spin class.','true_to_size'),
('c1000000-0000-0000-0000-000000000007','Anya L.',4,'Good support and really well made. The double-layer front panel provides structure without adding bulk.','true_to_size'),
('c1000000-0000-0000-0000-000000000007','Helena B.',5,'I sized up from my usual and the fit is perfect. Great for cycling and HIIT — stays in place even during high-intensity intervals.','runs_small'),
('c1000000-0000-0000-0000-000000000007','Simone V.',4,'Beautiful bra. The chalk colour is really versatile — goes with everything. Would recommend sizing up if you''re between sizes.','runs_small'),
-- P10 Courtside Pleated Skirt
('c1000000-0000-0000-0000-000000000010','Victoria P.',5,'Wore this for a padel tournament and received so many compliments. The pleats move beautifully and the built-in shorts are genuinely comfortable.','true_to_size'),
('c1000000-0000-0000-0000-000000000010','Alice G.',5,'The most elegant court skirt I have ever owned. The ivory colour is crisp and bright, and the fabric doesn''t crease on the drive to the club.','true_to_size'),
('c1000000-0000-0000-0000-000000000010','Rose M.',4,'Excellent quality and construction. The length is perfect — not too short, not too long. The pockets in the shorts are a bonus.','true_to_size'),
('c1000000-0000-0000-0000-000000000010','Stella O.',5,'I play three times a week and this skirt has held up perfectly after multiple washes. The pleat fabric stays crisp even after the dryer.','true_to_size'),
-- P16 Altitude Zip Jacket
('c1000000-0000-0000-0000-000000000016','Catherine M.',5,'The most versatile jacket I own. It''s light enough to pack into a bag but genuinely warm enough for cool mornings. The DWR finish handled a shower of rain perfectly.','true_to_size'),
('c1000000-0000-0000-0000-000000000016','Laura S.',5,'Obsidian is such a sophisticated colour. The silhouette is clean and modern — equally at home in the gym or running errands.','true_to_size'),
('c1000000-0000-0000-0000-000000000016','Emma T.',4,'Excellent jacket. The zip and hardware feel premium. I found the shoulders slightly wide for my frame — might size down next time.','runs_large'),
('c1000000-0000-0000-0000-000000000016','Grace H.',5,'Bought this as a training jacket and ended up wearing it everywhere. The packable design means it''s always in my bag.','true_to_size'),
-- P19 Padel Power Set
('c1000000-0000-0000-0000-000000000019','Valentina C.',5,'The best investment I''ve made for padel. Everything matches perfectly and the quality of both pieces is outstanding. Arrived quickly and beautifully packaged.','true_to_size'),
('c1000000-0000-0000-0000-000000000019','Beatrice F.',5,'The set fits perfectly and the sage colour is exactly as shown. The bra has excellent support for padel and the skirt doesn''t move during play.','true_to_size'),
('c1000000-0000-0000-0000-000000000019','Anna K.',4,'Great set. The skirt pleats are a little stiff initially but soften after the first wash. The bra fit is perfect.','true_to_size'),
('c1000000-0000-0000-0000-000000000019','Diana R.',5,'I''ve been looking for a premium padel set for months. This is exactly what I wanted — elegant, functional, and the fabric quality is exceptional.','true_to_size'),
-- P20 Pilates Harmony Set
('c1000000-0000-0000-0000-000000000020','Margot P.',5,'A perfect pilates set. The bra and legging have the same buttery-smooth texture and the rose colour is so pretty in person.','true_to_size'),
('c1000000-0000-0000-0000-000000000020','Sylvie L.',5,'I love how the pieces are designed to work together — the bra sits beautifully inside the legging waistband. Wore it for a reformer class and felt amazing.','true_to_size'),
('c1000000-0000-0000-0000-000000000020','Renée B.',4,'Very high quality. The chalk colour is lovely and neutral. Sizing is accurate — I ordered my usual size and it fits perfectly.','true_to_size'),
('c1000000-0000-0000-0000-000000000020','Elise N.',5,'The most comfortable set I''ve ever worn for pilates. The seamless construction means zero distraction during class. Worth every penny.','true_to_size');

-- ============================================================
-- SECTION 8: TESTIMONIALS  (5 brand-level quotes)
-- ============================================================
INSERT INTO testimonials (customer_name, quote, activity_label, display_order, is_active) VALUES
('Sophie H.', 'Elvora is the only brand that makes me feel truly elegant at the padel club. I receive compliments every single session.', 'Padel', 1, true),
('Amara T.', 'I''ve been doing reformer pilates for three years and I''ve never found anything that compares to the Serenity set. The quality is extraordinary.', 'Pilates', 2, true),
('Victoria P.', 'The Courtside Skirt changed how I dress for tennis. It''s the first court outfit I''ve worn where style and performance genuinely feel equal.', 'Tennis', 3, true),
('Clara B.', 'I wear Elvora to the gym, to brunch, to the supermarket. The pieces are so well-designed they work everywhere.', 'Gym', 4, true),
('Margot P.', 'The attention to detail is remarkable — every seam, every colour, every fabric choice feels considered. Elvora understands exactly what modern women want.', 'Wellness', 5, true);

COMMIT;
