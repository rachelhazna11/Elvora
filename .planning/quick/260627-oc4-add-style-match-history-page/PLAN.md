---
quick_id: 260627-oc4
slug: add-style-match-history-page
date: 2026-06-27
status: complete
---

# Quick Task: Style Match History Page

## Goal

Let logged-in users view their saved AI Style Match results. Saving already
happens server-side (the `style-match` edge function inserts every logged-in
result into `ai_style_sessions`); the missing piece is a page to read them
back. Wire the existing "Sesi Ini Tersimpan di Profilmu" CTA to this new page.

## Context (verified)

- `ai_style_sessions` table + RLS exist (migration `005_style_sessions.sql`).
- Edge function auto-saves results (`supabase/functions/style-match/index.ts:311`).
- `js/style-match.js` already exposes `window.getSessions({limit})` and
  `window.deleteSession(id)`.
- Product enrichment (product_ids → full products + images) currently lives
  inline in `style-match.html` (`enrichRecommendations`, ~L1187-1265).

## Tasks

1. **DRY the enrichment** — move `enrichRecommendations` into `js/style-match.js`
   as an exported function, expose on `window`, and have the inline method in
   `style-match.html` delegate to `window.enrichRecommendations`. Exact same
   logic — no behavior change to the working page.
2. **New page `style-history.html`** — same head/script wiring as
   style-match.html, lavender hero, guest→`/auth.html?tab=signin` redirect,
   lists sessions newest-first via `getSessions()`, each card shows date
   (id-ID locale), preference tags, colour guidance, and outfit cards reusing
   `.sm-outfit-*` markup + enrichment; per-session delete via `deleteSession()`
   with confirm + Toastify feedback; empty state with CTA to `/style-match.html`.
3. **Repoint CTA** — `style-match.html` button href → `/style-history.html`,
   update subtext.
4. **Nav link** — add "Riwayat Style Match" dropdown item in `js/components.js`
   for logged-in users.

## Verification

- New page loads, redirects guests, renders saved sessions with product images
  and links, delete removes a card, empty state shows for users with no history.
- style-match.html still works (enrichment delegation unchanged in behavior).
- No new secrets; RLS already scopes access per user.

## Files

- `js/style-match.js` (add shared `enrichRecommendations`)
- `style-match.html` (delegate enrichment; repoint CTA)
- `style-history.html` (new)
- `js/components.js` (nav link)
