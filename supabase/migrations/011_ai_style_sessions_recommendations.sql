-- =============================================================================
-- Elvora — Migration 011: Fix ai_style_sessions.recommendations column
-- File: supabase/migrations/011_ai_style_sessions_recommendations.sql
-- Apply via: Supabase Dashboard → SQL Editor → paste → Run
--
-- Problem: Migration 001 created ai_style_sessions WITHOUT a `recommendations`
--   column (it only had recommended_product_ids uuid[]). Migration 005 tried to
--   define the richer schema but used CREATE TABLE IF NOT EXISTS, which is a
--   no-op when the table already exists — so the `recommendations` column was
--   never actually added, on both existing and fresh deploys.
--
--   As a result the Style Match edge function INSERT (which writes a
--   `recommendations` jsonb payload) failed silently, and the Style Match
--   history page's getSessions() SELECT 400s with:
--     "column ai_style_sessions.recommendations does not exist"
--
-- Fix: add the missing column idempotently. Safe to run multiple times and
--   safe on fresh deploys (runs after both 001 and 005).
-- =============================================================================

-- Rich per-outfit recommendations from the AI:
-- [{ name, product_ids: string[], colour_guidance, why_it_works }]
ALTER TABLE ai_style_sessions
  ADD COLUMN IF NOT EXISTS recommendations jsonb;

-- Index for the history page's "newest first per user" query (no-op if present).
CREATE INDEX IF NOT EXISTS ai_style_sessions_user_id_created_at_idx
  ON ai_style_sessions (user_id, created_at DESC);
