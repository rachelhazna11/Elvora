---
slug: google-oauth
date: 2026-06-15
status: complete
commit: a3c40ce
---

# Summary

Added Google OAuth login and registration via Supabase `signInWithOAuth`.

## What changed

- **`js/auth.js`** — `signInWithGoogle()` calls `supabase.auth.signInWithOAuth({ provider: 'google' })` with `redirectTo: window.location.origin + '/account.html'`. Exposed as `window.signInWithGoogle`.
- **`auth.html`** — "Continue with Google" button + "or" divider added to both sign-in and sign-up panels.
- **`account.html`** — `loadProfile` else-branch now auto-upserts a `user_profiles` row from Google metadata (`given_name`/`family_name`/`name`) on first OAuth login.
- **`src/input.css`** — `.auth-divider` and `.auth-oauth-btn` CSS classes added.

## Required manual step (Supabase Dashboard)

Authentication → Providers → Google → enable, paste **Client ID** and **Client Secret** from Google Cloud Console OAuth 2.0 credentials.

Also add `https://elvorastudio.netlify.app/account.html` as an authorized redirect URI in Google Cloud Console.
