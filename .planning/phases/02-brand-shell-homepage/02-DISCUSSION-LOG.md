# Phase 2: Brand Shell + Homepage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 2-Brand Shell + Homepage
**Areas discussed:** Prototype fidelity, Mobile navigation, Shared nav & footer, About + Contact depth

---

## Prototype Fidelity

| Option | Description | Selected |
|--------|-------------|----------|
| Port it faithfully | Treat elvora_updated-3.html as implementation reference, port structure and visual patterns directly into Tailwind v4 | ✓ |
| Use as visual reference only | Read for colour/font/tone direction; design layout independently | |
| Lift sections directly | Copy specific sections verbatim, rebuild others fresh | |

**User's choice:** Port it faithfully

---

| Option | Description | Selected |
|--------|-------------|----------|
| Match it exactly (pixel-perfect) | Use arbitrary value syntax [100px] to preserve exact prototype values | |
| Match it loosely with Tailwind scale | Use closest Tailwind scale values (py-24, px-16) — near-identical visually, cleaner code | ✓ |
| You decide | Executor uses judgment | |

**User's choice:** Match it loosely with Tailwind scale

---

| Option | Description | Selected |
|--------|-------------|----------|
| Unsplash editorial photo URL | Hardcode a curated Unsplash URL in the hero image slot | ✓ |
| CSS gradient placeholder | Keep a soft gradient box like the prototype's placeholder | |
| You decide | Executor picks an appropriate image | |

**User's choice:** Unsplash editorial photo URL

---

## Mobile Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Hamburger + slide-out drawer | Hamburger icon opens full-height slide-in panel from the right | ✓ |
| Hamburger + dropdown overlay | Full-screen overlay fades in over content, large centered nav links | |
| Bottom navigation bar | Persistent bottom bar with icons | |

**User's choice:** Hamburger + slide-out drawer

---

| Option | Description | Selected |
|--------|-------------|----------|
| Transparent → frosted glass | Nav starts transparent, transitions to beige backdrop-blur after ~80px scroll | ✓ |
| Always frosted glass | Frosted glass nav visible from the start | |
| Hide on scroll down, show on scroll up | Nav hides when scrolling down, reappears on scroll up | |

**User's choice:** Transparent → frosted glass (matches prototype behavior)

---

## Shared Nav & Footer

| Option | Description | Selected |
|--------|-------------|----------|
| JS-injected components | `js/components.js` exports nav and footer as HTML strings, inserts into placeholder divs | ✓ |
| Duplicate HTML per page | Copy full nav/footer HTML into each of the 11 pages | |
| Alpine.js fetch-based include | Each page fetches nav.html via fetch() and injects via x-html | |

**User's choice:** JS-injected components

---

| Option | Description | Selected |
|--------|-------------|----------|
| Stub it in Phase 2, wire in Phase 4 | Static nav icons in Phase 2; Alpine.store slots prepared but not populated | ✓ |
| Fully wire cart + auth state in Phase 2 | Phase 2 wires real Alpine.store({cart, user}) | |
| You decide | Executor decides the boundary | |

**User's choice:** Stub it in Phase 2, wire in Phase 4

---

## About + Contact Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Editorial brand story page | Full editorial layout: mission headline, 2–3 paragraphs, lifestyle images, CTA | ✓ |
| Minimal stub page | Single placeholder copy block with back-to-home link | |
| You decide | Executor fills appropriate editorial content | |

**User's choice:** Editorial brand story page

---

| Option | Description | Selected |
|--------|-------------|----------|
| FAQ accordion + brand contact info | Expandable FAQ (~6 questions) with Alpine.js x-show, plus email/Instagram | ✓ |
| Contact form + minimal FAQ | Contact form with validation + success message, 3–4 FAQ items | |
| FAQ accordion only | Just the FAQ accordion, no contact info | |

**User's choice:** FAQ accordion + brand contact info

---

## Claude's Discretion

- None — all areas had clear user selections.

## Deferred Ideas

- Contact form with email delivery — production feature, no email infrastructure in scope
- Hero video background — performance complexity, not required by ROADMAP
- Animated scroll transitions (Intersection Observer fade-ins) — nice-to-have, executor discretion
- Swiper.js carousel for testimonials/best sellers — executor discretion if item count warrants it
