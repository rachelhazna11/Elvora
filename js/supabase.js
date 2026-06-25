// js/supabase.js
// Shared Supabase client — initialized once and imported by all other modules.
// Service role key MUST NOT appear here — RLS enforces access control.

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = import.meta.env?.VITE_SUPABASE_URL ?? window.__ENV?.SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env?.VITE_SUPABASE_ANON_KEY ?? window.__ENV?.SUPABASE_ANON_KEY;

const noop = () => Promise.resolve({ data: null, error: { message: 'Supabase not configured' } });
const stub = new Proxy({}, { get: () => stub, apply: noop });

export const supabase = SUPABASE_URL && SUPABASE_ANON_KEY
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : stub;

// Expose to window so Alpine inline x-data methods (loadPairings, loadRelated,
// loadReviews, loadAggregateRating) can call window.supabase directly.
// Alpine x-data strings run in global scope — cannot use ES module exports.
window.supabase = supabase;
