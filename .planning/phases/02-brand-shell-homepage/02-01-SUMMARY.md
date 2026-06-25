# Plan 01 Summary — Design System + Components + HTML Stubs

**Phase:** 02-brand-shell-homepage
**Plan:** 01
**Wave:** 1
**Status:** Complete
**Executed:** 2026-06-12

## What Was Built

### src/input.css
Extended with component utilities and keyframes (appended after existing tokens — existing @theme, :root, body blocks unchanged):
- `@layer components`: `.section-label`, `.section-title`, `.btn-primary`, `.btn-primary:hover`, `.btn-secondary`, `.btn-secondary:hover`
- `@keyframes marquee` + `.marquee-track` + `@media (prefers-reduced-motion)` override
- `@keyframes scrollAnim` for hero scroll indicator
- `.collections-grid` responsive class (2fr 1fr 1fr on md+, 1fr mobile) + `.padel-card` span-2-rows

### js/components.js (new)
ES module side-effect file:
- Imports `supabase` from `./supabase.js` and exposes it as `window.supabase` for Alpine inline x-data
- Registers `Alpine.store('cart', { count: 0, items: [] })` and `Alpine.store('auth', { user: null, loggedIn: false })` on `alpine:init`
- `navHTML` string: fixed nav with scroll transparency (scrollY > 80), mobile hamburger drawer, active link detection via `data-page` attributes
- `footerHTML` string: 4-column charcoal footer with brand col, shop/help/brand link columns, copyright
- Injects nav+footer via `getElementById('nav-root'/'footer-root')` + `Alpine.initTree()`
- Sets `text-rose` on active nav link based on `window.location.pathname`

### HTML Stubs Updated (9 files)
All updated with: corrected font URL (Playfair 700/700i + Poppins 400/600 only), Alpine CDN defer, nav-root div, footer-root div (except admin.html), script load order (__env.js → supabase.js → components.js).

## Verification

- ✅ `.btn-primary` present in compiled css/style.css
- ✅ `alpine:init` in js/components.js
- ✅ All 9 HTML files have `id="nav-root"`
- ✅ All 9 HTML files have alpinejs@3.15.12
- ✅ admin.html does NOT have `id="footer-root"`
- ✅ No `wght@300` in any deliverable HTML file
- ✅ Tailwind CLI build: Done in ~35ms, no errors
