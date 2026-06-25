-- =============================================================================
-- Elvora — Migration 005: AI Style Match Sessions
-- File: supabase/migrations/005_style_sessions.sql
-- Apply via: Supabase Dashboard → SQL Editor → paste → Run
--
-- Purpose: Persists AI Style Match sessions for authenticated users.
--   Guests can run the match but their results are not saved (D-06).
-- =============================================================================

-- Table: ai_style_sessions
-- Stores each Style Match session result for authenticated users.
CREATE TABLE IF NOT EXISTS ai_style_sessions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid REFERENCES auth.users (id) ON DELETE CASCADE,  -- nullable: guests produce no row
  preferences     jsonb NOT NULL,         -- { activity: string[], fit: string, aesthetic: string, colour: string }
  recommendations jsonb NOT NULL,         -- [{ name, product_ids, colour_guidance, why_it_works }]
  colour_guidance text,                   -- top-level colour palette note from AI
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Index: fast lookup by user, newest first
CREATE INDEX IF NOT EXISTS ai_style_sessions_user_id_created_at_idx
  ON ai_style_sessions (user_id, created_at DESC);

-- =============================================================================
-- Row Level Security (T-05-04-01)
-- =============================================================================
ALTER TABLE ai_style_sessions ENABLE ROW LEVEL SECURITY;

-- Policy: users can insert their own sessions only
CREATE POLICY "Users can insert own sessions"
  ON ai_style_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy: users can read their own sessions only
CREATE POLICY "Users can select own sessions"
  ON ai_style_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: users can delete their own sessions (optional cleanup)
CREATE POLICY "Users can delete own sessions"
  ON ai_style_sessions
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
