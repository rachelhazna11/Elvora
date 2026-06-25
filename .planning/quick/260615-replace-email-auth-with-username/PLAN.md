---
slug: replace-email-auth-with-username
date: 2026-06-15
status: in-progress
---

# Replace Email Auth with Username Auth

## Goal
Remove email from auth flow. Users register and sign in with username only.
Register form: first name, last name, username, password, confirm password.
Fix profile data not saving to Supabase.

## Approach
Supabase Auth requires email internally — use synthetic `{username}@elvora.local`
transparently. Users never see it. Email confirmation must be disabled in Supabase dashboard.

## Files
- `supabase/migrations/004_add_username.sql` — add `username` unique column to user_profiles
- `js/auth.js` — rework signUp/signIn to use username → synthetic email
- `auth.html` — remove email field, add username field, update Alpine state
- `account.html` — replace email display with username display
