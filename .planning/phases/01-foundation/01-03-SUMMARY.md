---
phase: 01-foundation
plan: 03
status: complete
completed_at: "2026-06-11T09:15:00Z"
commit: pending
---

# Plan 01-03 Summary — Catalog Seed Data

## What Was Built

`supabase/seed.sql` — a complete, repeatable INSERT script that populates the Elvora catalog.

## One-liner

664-line seed script creates 22 premium activewear products across 7 categories, 220 colour/size variants, 44 Unsplash product images, 6 collections with assignments, 32 customer reviews, and 5 homepage testimonials — ready to apply via the Supabase SQL Editor.

## Artifacts Produced

| Artifact | Detail |
|----------|--------|
| `supabase/seed.sql` | 664 lines, valid SQL, wrapped in BEGIN/COMMIT transaction |
| 7 categories | leggings, sports-bra, top, jacket, shorts, set, skirt |
| 6 collections | New Arrivals, Best Sellers, The Padel Edit, Studio Essentials, Summer Collection, Core Range (4 featured) |
| 22 products | 5 leggings, 4 sports bras, 3 skirts, 3 tops, 3 jackets, 4 sets — prices £55–£145 |
| 220 product_variants | 2 colours × 5 sizes (XS–XL) per product — unique SKUs (e.g. P01-SAG-XS) |
| 44 product_images | Unsplash CDN URLs (2 per product, varied IDs) |
| 32 reviews | 4 per product × 8 products — realistic tone, fit_feedback included |
| 5 testimonials | activity labels: Padel, Pilates, Tennis, Gym, Wellness |

## Acceptance Criteria — Verified

| Check | Result |
|-------|--------|
| `wc -l` ≥ 400 | ✓ 664 lines |
| 22 product rows | ✓ 22 unique product UUIDs |
| 220 variant rows | ✓ 220 rows |
| 44 image rows | ✓ 44 Unsplash URLs |
| 5 testimonial rows | ✓ 5 rows |
| 32 review rows | ✓ 32 rows (4 × 8 products) |
| Prices £55–£145 | ✓ min £55, max £145 |
| No API keys | ✓ no credentials |

## Decisions Made

- Used hardcoded UUID strings (`a1...`, `b1...`, `c1...`) so FK cross-references work within a single INSERT batch without DO blocks.
- SKU format: `P{NN}-{COLOR_ABBR}-{SIZE}` (e.g. `P01-SAG-XS`) — human-readable and unique.
- Added `skirt` as a 7th category (not in original 6) to correctly type padel/tennis skirts.
- All prices in premium range per CONTEXT.md specifics (£55–£145).

## Next Step

Plan 01-07: paste `supabase/seed.sql` into Supabase SQL Editor to populate the live database.
