# Phase 3: Product Catalog - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 3-Product Catalog
**Areas discussed:** PLP Filter, Product Pairings, PDP Gallery, PDP URL Routing, Search Bar

---

## PLP Filter

| Option | Description | Selected |
|--------|-------------|----------|
| Activity tabs via collections | Filter tabs map to collection slugs via collection_products join | ✓ |
| Activity tabs + garment sub-filter | Primary = activity, secondary = garment type | |
| Garment type tabs only | Keep existing shop.html approach (Leggings, Tops, Jackets) | |

**User's choice:** Activity tabs via collections

---

| Option | Description | Selected |
|--------|-------------|----------|
| Activity tabs only | No sub-categories on PLP | |
| Activity tabs + sub-category pills | e.g., Padel → Matcha Babe, Court Crush, Rally Ready pills | ✓ |
| You decide | Claude picks simpler option | |

**User's choice:** Activity tabs + sub-category pills

---

| Option | Description | Selected |
|--------|-------------|----------|
| URL query params (?category=padel&sub=matcha-babe) | Shareable URLs, browser back/forward | ✓ |
| Alpine.js reactive state only (no URL) | Simpler but breaks ROADMAP success criteria | |
| You decide | Follow ROADMAP requirement | |

**User's choice:** URL query params

---

| Option | Description | Selected |
|--------|-------------|----------|
| Re-fetch from Supabase on each filter change | New query per tab/pill click | ✓ |
| Load all products once, filter client-side | Alpine computed property, no re-fetch | |
| You decide | — | |

**User's choice:** Re-fetch from Supabase on each filter change

---

## Product Pairings

| Option | Description | Selected |
|--------|-------------|----------|
| New migration: add product_pairings table | Clean, admin-manageable, proper schema | ✓ |
| Same-collection proxy (no new table) | Products from same collection as "Complete the Look" | |
| Hardcode in styling_suggestions field | Use existing text field for pairing slugs | |

**User's choice:** New migration: add product_pairings table

---

| Option | Description | Selected |
|--------|-------------|----------|
| New migration file + manual SQL Editor | Write 002_product_pairings.sql, apply via Supabase dashboard | ✓ |
| Append to existing 001_schema.sql | Add to bottom of existing migration | |

**User's choice:** New migration file + manual SQL Editor (consistent with D-08 cloud-only workflow)

---

## PDP Gallery

| Option | Description | Selected |
|--------|-------------|----------|
| Swiper.js (CDN) | Battle-tested, CLAUDE.md listed, thumbnail sync | ✓ |
| Alpine.js + CSS scroll-snap | No extra library, more custom CSS needed | |

**User's choice:** Swiper.js (CDN)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Use Unsplash URLs as-is for Phase 3 | Document Supabase transform pattern, apply in Phase 7 | ✓ |
| Append Unsplash sizing params manually | ?w=1200&q=80 on Unsplash URLs | |

**User's choice:** Use Unsplash URLs as-is (apply Unsplash params for sizing, defer Supabase Storage transforms to Phase 7)

---

## PDP URL Routing

| Option | Description | Selected |
|--------|-------------|----------|
| ?slug=serenity-ribbed-legging | Human-readable, update shop.html links | ✓ |
| ?id=c1000000-... (UUID) | Current shop.html already uses this | |

**User's choice:** Slug-based URL (?slug=)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Redirect to shop.html on invalid slug | Clean UX | ✓ |
| Show error state inline | Product not found message | |

**User's choice:** Redirect to shop.html

---

## Search Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Click-to-expand search in nav | Icon → inline expanding input, Alpine x-show | ✓ |
| Modal/overlay search | Full overlay, premium brand pattern | |

**User's choice:** Click-to-expand search in nav

---

| Option | Description | Selected |
|--------|-------------|----------|
| Supabase ilike filter | .ilike('name', '%query%').limit(6), simple, no setup | ✓ |
| Supabase Full-Text Search (FTS) | tsvector, more powerful, requires index setup | |

**User's choice:** Supabase ilike filter

---

## Claude's Discretion

- Unsplash URL sizing params: `?w=1200&q=80` for PDP main, `?w=200&q=60` for thumbnails, `?w=800&q=80` for cards
- Sticky ATC bar implementation approach: IntersectionObserver on the main ATC button
- Collection slug → activity mapping: to be confirmed by planner from seed data
- Sub-category pills: horizontal scrollable row, same pill style as activity tabs but smaller

## Deferred Ideas

- Real Supabase Storage image transforms — Phase 7 (when admin panel enables image uploads)
- Review submission — F-019 explicitly out of v1 scope
- Wishlist button active state — Phase 4 (requires auth)
- Price range slider / size filter — post-assessment v2
