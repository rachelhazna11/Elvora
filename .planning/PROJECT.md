# Elvora

## What This Is

Elvora is a premium women's activewear e-commerce platform that merges quiet luxury fashion aesthetics with modern wellness culture. Built as a university assessment portfolio project, it demonstrates a full-stack shopping experience targeting women aged 20–35 who value elegance, quality, and personal style in their activewear — for padel, pilates, tennis, gym, running, and wellness lifestyles.

The defining differentiator is an AI-powered Style Match feature: users upload a photo and receive personalized outfit recommendations from the Elvora catalog based on appearance, body proportions, and style preferences — no virtual try-on, no generative imagery. It feels like a premium personal stylist, not a complex AI tool.

Backend is powered by Supabase (auth, database, storage) for rapid implementation without backend overhead. An admin panel supports full CRUD operations for all catalog and content.

## Core Value

A shopper lands on Elvora, uploads a photo, and within moments receives a curated outfit recommendation that feels personally chosen for her — drawing her naturally into a premium catalog she wants to explore.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Premium editorial homepage — hero section, featured collections (Padel, Pilates, Tennis, Training), best sellers, lifestyle inspiration, brand story, testimonials, newsletter signup
- [ ] Product catalog with browse-by-activity-category, search, and filtering
- [ ] Premium product cards with color variants, size options, and styling suggestions
- [ ] Product detail pages with imagery, description, fabric/material details, sizing, recommended matching items, and related products
- [ ] Shopping cart with add/remove, quantity adjustment, order summary, and basic promo code support
- [ ] Checkout flow with shipping information, payment architecture placeholder, and order confirmation
- [ ] Customer accounts with signup/login, profile management, wishlist/saved items, order history, and saved AI style preferences
- [ ] Customer reviews on product pages
- [ ] AI Style Match MVP: photo upload → outfit combination recommendations → complementary color suggestions → activity-based product recommendations (no try-on, no image generation)
- [ ] Brand & content pages (About / Brand Story, wellness and lifestyle storytelling)
- [ ] Admin panel with full CRUD: products, collections, categories, testimonials, homepage content sections
- [ ] Supabase-backed persistence: users, products, categories, wishlist, cart, orders, AI style preferences
- [ ] Realistic seeded catalog: sports bras, leggings, tennis skirts, jackets, padel sets, pilates sets — each with name, category, price, images, color variants, sizes, materials, description, styling suggestions
- [ ] Responsive mobile-first UX throughout

### Out of Scope

- Virtual try-on or generative clothing replacement on user photos — assessment scope, no such complexity needed
- Real payment processing — placeholder architecture only; not a live transactional store
- Live inventory management — seeded sample data only
- Mobile app — web-only, responsive design
- Real-time features (live chat, live stock updates) — not required for assessment scope
- Third-party integrations (Shopify, ERP, shipping APIs) — not in student scope

## Context

**Assessment context:** University website development assessment. Grading criteria emphasize working deployment, clean semantic HTML structure, responsive UI/UX, functional JavaScript interactions, clear user flow, maintainable code, and documented AI usage. Polished execution matters more than feature breadth.

**Visual target:** The experience should feel like Alo Yoga, Varley, or a premium European wellness brand — "quiet luxury" activewear, not generic sports e-commerce. Neutral palettes (cream, sage, slate, ivory), editorial photography framing, refined typography, generous whitespace. Every UI decision should reinforce the brand identity.

**Tech stack:** Supabase handles auth, database (PostgreSQL), and file storage. Frontend is HTML/CSS/JavaScript (or a lightweight JS framework), mobile-first responsive. The admin panel is a protected section of the same web app.

**AI integration:** The AI Style Match feature is a genuine differentiator in the assessment context. It should be documented clearly and implemented as an MVP: photo analysis + preference inputs → catalog product recommendations. Uses the **Google Gemini Vision API** to analyze uploaded images and map to catalog items. API key is stored in Supabase Edge Function secrets only — never in any frontend file.

**No prior codebase:** This is a fresh greenfield project — no existing files to migrate or reference.

## Constraints

- **Scope**: Student-sized build — prioritize polished execution of core features over extensive feature coverage; avoid overengineering
- **Backend**: Supabase only — no custom server, no separate REST API needed
- **Payments**: Placeholder architecture only — no real payment processing required
- **Catalog**: Seeded sample data — no live inventory system needed
- **AI**: MVP recommendation only — no image generation, no virtual try-on
- **Assessment**: Must support deployment, demonstrate semantic HTML, responsive design, JavaScript functionality, and documented AI usage
- **Aesthetic**: Premium quiet luxury — every UI decision should reinforce the brand identity, not undercut it

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| AI Style Match as MVP (recommendation only, no try-on) | Keeps scope realistic for student build while preserving genuine differentiation | — Pending |
| Gemini Vision API for AI Style Match | Google Gemini provides vision-capable multimodal inference; key stored in Edge Function secrets only | — Pending |
| Supabase as sole backend | Eliminates custom server complexity; provides auth, DB, and storage in one service | — Pending |
| Seeded catalog instead of live inventory | Assessment context; enables polished demo without production infrastructure | — Pending |
| Payment architecture placeholder | Assessment requirement met without complex payment provider integration | — Pending |
| Quiet luxury visual direction (Alo Yoga / Varley benchmark) | Differentiates from generic sports e-commerce; aligns with target audience values | — Pending |
| Admin panel as protected web section (not separate app) | Keeps codebase unified and deployment simple for student scope | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-10 after initialization*
