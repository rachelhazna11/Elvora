-- =============================================================================
-- Elvora — Phase 4 Migration: Style Preference Columns
-- File: supabase/migrations/003_phase4_user_profiles.sql
-- Created: Phase 04 — Auth + Customer Account
-- Apply via: Supabase Dashboard → SQL Editor → paste contents → Run
--
-- Purpose: Adds individual style preference columns to user_profiles table.
-- These columns are the canonical storage per D-10 and CONTEXT.md.
-- The existing style_preferences JSONB column is preserved (not dropped)
-- as it was defined in Phase 1 schema — these 4 new columns are the
-- primary storage going forward.
--
-- Column descriptions:
--   preferred_activity : one of 'all', 'padel', 'pilates', 'tennis', 'training', 'running' (or null)
--   fit_preference     : one of 'fitted', 'relaxed', 'longline' (or null)
--   style_aesthetic    : one of 'minimal', 'sporty', 'editorial' (or null)
--   colour_preference  : one of 'neutral', 'earth', 'sage', 'monochrome' (or null)
--
-- Phase 5 (AI Style Match) reads these columns to pre-fill the style match form.
-- =============================================================================

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS preferred_activity text,
  ADD COLUMN IF NOT EXISTS fit_preference text,
  ADD COLUMN IF NOT EXISTS style_aesthetic text,
  ADD COLUMN IF NOT EXISTS colour_preference text;
