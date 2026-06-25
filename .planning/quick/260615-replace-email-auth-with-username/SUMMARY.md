---
slug: replace-email-auth-with-username
date: 2026-06-15
status: complete
commit: 9b3bab7
---

# Summary

Replaced email-based authentication with username-based auth across the full auth flow.

## What changed

- **`js/auth.js`** — `signUp(username, password, firstName, lastName)` and `signIn(username, password)` now accept username. Synthetic email `{username}@elvora.local` is generated internally so Supabase Auth still works without exposing email to users.
- **`auth.html`** — Sign-in form: email → username field. Sign-up form: email field removed, username field added (letters/numbers/underscores validation). Error messages updated.
- **`account.html`** — Profile `email` state replaced with `username`. Sidebar shows `@username`. Profile form shows read-only username field.
- **`supabase/migrations/004_add_username.sql`** — Adds `username` text column + unique index on `lower(username)` to `user_profiles`.

## Required manual step (Supabase Dashboard)

1. Run migration 004 via SQL Editor
2. **Authentication → Providers → Email → disable "Confirm email"** — required so users are immediately authenticated without a confirmation link
