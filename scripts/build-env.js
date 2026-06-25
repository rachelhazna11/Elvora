// Writes js/__env.js with build-time env vars so Alpine/JS can read them.
// Called during `npm run build` — Vercel injects env vars before build runs.
const fs = require('fs');
const url = process.env.SUPABASE_URL || '';
const key = process.env.SUPABASE_ANON_KEY || '';
fs.writeFileSync(
  'js/__env.js',
  `window.__ENV = { SUPABASE_URL: '${url}', SUPABASE_ANON_KEY: '${key}' };\n`
);
console.log('js/__env.js written');
