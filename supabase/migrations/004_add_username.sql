-- =============================================================================
-- Elvora — Migration 004: Add username to user_profiles
-- File: supabase/migrations/004_add_username.sql
-- Apply via: Supabase Dashboard → SQL Editor → paste → Run
--
-- Purpose: Supports username-based auth. Auth still uses synthetic
--   "{username}@elvora.local" email internally; users only see username.
--
-- ALSO REQUIRED in Supabase Dashboard:
--   Authentication → Providers → Email → disable "Confirm email"
-- =============================================================================

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS username text;

CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_username_unique
  ON user_profiles (lower(username))
  WHERE username IS NOT NULL;
