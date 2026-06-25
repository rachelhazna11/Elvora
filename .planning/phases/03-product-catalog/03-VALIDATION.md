---
phase: 3
slug: product-catalog
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — project uses manual browser testing (no Jest/Vitest/Playwright configured) |
| **Config file** | None |
| **Quick run command** | Open `shop.html` in browser; check console for JS errors |
| **Full suite command** | Manual walkthrough: all 5 PLP success criteria + all 5 PDP success criteria per CONTEXT.md |
| **Estimated runtime** | ~15–20 minutes (manual) |

---

## Sampling Rate

- **After every task commit:** Reload the relevant page in browser, check console for errors
- **After every plan wave:** Run full manual walkthrough checklist below
- **Before `/gsd-verify-work`:** All checklist items must pass
- **Max feedback latency:** Manual — check per task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Verification Method | Status |
|---------|------|------|-------------|-----------------|-----------|---------------------|--------|
| seed-fix | W0 | 0 | F-008, F-009 | N/A | Manual | Run SQL patch; check activity tabs return products | ⬜ pending |
| pairings-migration | W0 | 0 | F-017 | RLS: public SELECT only | Manual | Apply 002_product_pairings.sql via SQL Editor | ⬜ pending |
| plp-filter | — | 1 | F-009 | N/A | Manual | Click Padel tab → URL `?category=padel`; grid shows padel products | ⬜ pending |
| plp-subcategory | — | 1 | F-009 | N/A | Manual | Click sub-pill → grid filters further | ⬜ pending |
| plp-sort | — | 1 | F-012 | N/A | Manual | Sort "Price Low–High" → URL `?sort=price-asc`; grid reorders | ⬜ pending |
| plp-cards | — | 1 | F-008, F-010 | N/A | Manual | 22 product cards visible; hover swatch → image changes | ⬜ pending |
| nav-search | — | 1 | F-011 | N/A | Manual | Type ≥2 chars → dropdown; Enter → shop.html?search=; click → product.html | ⬜ pending |
| pdp-gallery | — | 2 | F-013 | N/A | Manual | Swipe gallery; click thumbnail → main image updates | ⬜ pending |
| pdp-swatch | — | 2 | F-013, F-010 | N/A | Manual | Select colour swatch → main image updates | ⬜ pending |
| pdp-sticky-atc | — | 2 | F-014 | N/A | Manual | Scroll past ATC → sticky bar appears; scroll back → hides | ⬜ pending |
| pdp-size-modal | — | 2 | F-015 | N/A | Manual | Open modal → Tab cycles within; Escape closes | ⬜ pending |
| pdp-fabric | — | 2 | F-016 | N/A | Manual | Click accordion → expands; click again → collapses | ⬜ pending |
| pdp-pairings | — | 2 | F-017 | N/A | Manual | "Complete the Look" shows 2–3 cards | ⬜ pending |
| pdp-related | — | 2 | F-018 | N/A | Manual | "You Might Also Love" shows ≥4 products | ⬜ pending |
| pdp-reviews | — | 2 | F-019 | N/A | Manual | 5 reviews + "Load More" loads next batch | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **SQL seed patch** — add product-to-collection assignments for Tennis, Training, and Running activity tabs (currently empty in `collection_products`)
- [ ] **Sub-category collection assignments** — add product rows for all 15 sub-category collections (slugs b000…010–b000…021) so sub-pill filtering returns results
- [ ] **`002_product_pairings.sql`** applied to live Supabase via SQL Editor before PDP "Complete the Look" testing

*Existing infrastructure (CDN scripts, Supabase client) covers all other phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Activity filter returns correct products | F-009 | No test runner; requires live Supabase + DOM | Click each tab; verify grid contents against seed data |
| Colour swatch hover updates card image | F-010 | DOM event + image URL swap | Hover each swatch; confirm image src changes |
| Swiper gallery swipe on mobile | F-013 | Touch event; needs real device or browser devtools mobile sim | Open Chrome devtools → mobile mode; swipe gallery |
| Sticky ATC IntersectionObserver | F-014 | Scroll event; requires browser | Scroll down PDP; verify sticky bar slides in |
| Focus trap in size guide modal | F-015 | Keyboard focus management | Tab through modal elements; verify focus loops; Escape closes |
| Load more reviews pagination | F-019 | Supabase range query + DOM append | Click "Load More"; verify new reviews appended |

---

## Validation Sign-Off

- [ ] All tasks have a manual verification method
- [ ] Wave 0 SQL patches applied before Wave 1 testing
- [ ] No tasks marked ⬜ pending at phase completion
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
