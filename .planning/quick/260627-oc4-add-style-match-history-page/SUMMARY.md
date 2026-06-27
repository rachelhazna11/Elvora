---
quick_id: 260627-oc4
slug: add-style-match-history-page
date: 2026-06-27
status: complete
commit: 757504d
---

# Summary: Style Match History Page

## Outcome

Added a dedicated page for logged-in users to review their saved AI Style Match
results. Saving was already implemented server-side (the `style-match` edge
function inserts into `ai_style_sessions`); this task delivered the read/view
surface and wired the existing CTA to it.

## Changes

- **`style-history.html`** (new) — lavender hero, guest→`/auth.html?tab=signin`
  guard, lists sessions newest-first via `window.getSessions({limit:50})`. Each
  session card shows the created_at date/time (id-ID locale), preference tags
  (activity/fit/aesthetic/colour), colour guidance, and outfit cards reusing the
  `.sm-outfit-*` markup from the live results page. Per-session delete via
  `window.deleteSession(id)` with a confirm dialog + Toastify feedback. Empty
  state and error state with retry; CTA to `/style-match.html`.
- **`js/style-match.js`** — extracted `enrichRecommendations` (product_ids →
  full products + images, UUID validation, Unsplash URL handling) from the
  inline copy in `style-match.html` into a shared exported function, exposed as
  `window.enrichRecommendations`.
- **`style-match.html`** — inline `enrichRecommendations` now delegates to the
  shared `window.enrichRecommendations` (behavior unchanged, with a safe
  fallback if the module hasn't loaded). CTA button repointed from
  `/account.html` to `/style-history.html` with updated subtext.
- **`js/components.js`** — added "Riwayat Style Match" item to the logged-in
  nav dropdown.

## Verification

- `node --check` passes for `js/style-match.js` and `js/components.js`.
- The new page's inline app script parses (`new Function`).
- CTA (`style-match.html`) and nav link (`components.js`) resolve to
  `/style-history.html`; `enrichRecommendations` is exported and on `window`.
- Not run: live authenticated browser flow (requires a signed-in session +
  Supabase data) — left for the user to confirm in their environment. Risk is
  low: the page reuses already-working functions and verbatim result markup.

## Notes

- Committed locally on `main` (`757504d`); not pushed (push left to the user).
- No schema/RLS changes — `ai_style_sessions` already scopes rows per user.
