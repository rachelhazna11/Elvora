---
phase: 02
slug: brand-shell-homepage
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Browser + Tailwind CLI (static HTML — no automated test runner) |
| **Config file** | `tailwind.config.css` (Tailwind v4 CLI watches `src/input.css`) |
| **Quick run command** | `npx @tailwindcss/cli -i src/input.css -o dist/output.css --minify` |
| **Full suite command** | Open `index.html`, `about.html`, `contact.html` in browser + check console for errors |
| **Estimated runtime** | ~5 seconds (CSS build) + ~30 seconds (manual browser check) |

---

## Sampling Rate

- **After every task commit:** Run Tailwind CLI build — verify it exits 0 with no errors
- **After every plan wave:** Open all pages in browser, check console, verify responsive breakpoints at 375px / 768px / 1280px
- **Before `/gsd-verify-work`:** Full suite must be green (build passes, all 3 pages load, no console errors)
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | NF-001, NF-004 | — | N/A | build | `npx @tailwindcss/cli -i src/input.css -o dist/output.css --minify` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | NF-003, F-001 | — | No inline event handlers | manual | Open any page → check nav renders, mobile hamburger appears at 375px | ✅ | ⬜ pending |
| 02-01-03 | 01 | 1 | NF-001, NF-004 | — | N/A | build | `npx @tailwindcss/cli -i src/input.css -o dist/output.css --minify` | ✅ | ⬜ pending |
| 02-02-01 | 02 | 2 | F-001, NF-002 | — | No user data in hero | manual | Open index.html → hero loads Unsplash image, marquee animates | ✅ | ⬜ pending |
| 02-02-02 | 02 | 2 | F-002, F-004, F-005 | — | N/A | manual | Open index.html → scroll to collections grid, lookbook grid, brand story section | ✅ | ⬜ pending |
| 02-03-01 | 03 | 2 | F-043, F-044 | — | N/A | manual | Open about.html → content renders, no JS errors | ✅ | ⬜ pending |
| 02-03-02 | 03 | 2 | F-044, F-045 | — | No form submission to backend | manual | Open contact.html → FAQ accordion toggles, no console errors | ✅ | ⬜ pending |
| 02-04-01 | 04 | 3 | F-003, F-006, NF-002 | — | RLS: only SELECT from products table | manual | Open index.html → best sellers + testimonials load with loading skeleton then data | ✅ | ⬜ pending |
| 02-04-02 | 04 | 3 | F-007 | — | RLS: only INSERT to newsletter_subscribers | manual | Open index.html → submit newsletter form → success state displayed, no error toast | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- Tailwind CLI is already installed (Phase 01 established)
- Alpine.js loaded via CDN — no install required
- Supabase JS SDK loaded via CDN — no install required

*No Wave 0 test stubs needed — this is a static HTML/CSS/JS phase; verification is build + browser.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hero image loads above fold | F-001 | No headless browser available | Open index.html in Chrome; confirm hero img loads within 2s |
| Mobile nav drawer opens/closes | NF-003 | Requires touch/click interaction | Resize to 375px; tap hamburger → drawer opens; tap X → closes |
| Marquee scrolls continuously | NF-004 | CSS animation — visual only | Open index.html; confirm brand name strip scrolls left with no gaps |
| Scroll nav transparency | NF-004 | Requires scroll event observation | Open index.html; scroll down → nav gains background; scroll up → transparent |
| FAQ accordion toggles | F-045 | Requires click interaction | Open contact.html; click FAQ item → answer expands; click again → collapses |
| Best sellers skeleton → data | F-003 | Requires Supabase network call | Open index.html; verify skeleton shows then products populate (or empty state) |
| Newsletter form success state | F-007 | Requires form submit + Supabase insert | Submit email in newsletter section; verify success message (no RLS error) |

---

## Validation Sign-Off

- [ ] All tasks have manual verify instructions or build command
- [ ] Sampling continuity: build check after every task, browser check after every wave
- [ ] Wave 0: not applicable (static HTML phase)
- [ ] No watch-mode flags in CI commands
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter after all checks pass

**Approval:** pending
