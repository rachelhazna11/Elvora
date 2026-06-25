---
phase: 01-foundation
reviewed: 2026-06-12T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - netlify.toml
  - .env.example
  - .gitignore
  - .github/workflows/keepalive.yml
  - index.html
  - shop.html
  - product.html
  - cart.html
  - checkout.html
  - auth.html
  - account.html
  - style-match.html
  - about.html
  - contact.html
  - admin.html
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-06-12
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

This review covers the two gap-closure plans for Phase 01 foundation: Plan 01-08 (build-time `window.__ENV` injection via Netlify echo command) and Plan 01-09 (keepalive cron changed from weekly to daily). Supporting JS modules (`js/supabase.js`, `js/auth.js`, `js/products.js`, etc.) were read as called-code context.

The `__env.js` injection approach is architecturally sound — plain script before ES module guarantees synchronous execution order, and the `.gitignore` exclusion pattern is correct. The 11 HTML shells are consistently updated. The keepalive cron expression is syntactically correct and the change to daily achieves the stated goal.

Two critical issues are present: the build-time `echo` command performs unquoted shell expansion of env var values into a single-quoted JS string literal, creating a JS syntax break if a value contains a single-quote character (latent but unguarded); and the Netlify catch-all SPA redirect (`/* → /index.html` status 200) is incorrect for a multi-page application — it was pre-existing but is present in the reviewed file and causes incorrect behavior for clean-path URLs.

Four warnings cover: missing `curl` timeout in the keepalive job, the keepalive requiring a GitHub secret (separate from Netlify env vars, easy to miss), no local-dev story for `__env.js`, and the `css/` directory not being committed (relies on Tailwind CLI auto-creating it).

---

## Critical Issues

### CR-01: Single-quote in env var value breaks generated JS syntax

**File:** `netlify.toml:2`

**Issue:** The build command expands `${SUPABASE_URL}` and `${SUPABASE_ANON_KEY}` inside a shell double-quoted string and writes them into JS single-quoted string literals:

```
echo "window.__ENV = { SUPABASE_URL: '${SUPABASE_URL}', SUPABASE_ANON_KEY: '${SUPABASE_ANON_KEY}' };" > js/__env.js
```

If either value contains a single-quote character (`'`), the resulting `js/__env.js` becomes syntactically invalid JavaScript. For example, a value of `abc'def` would produce:

```js
window.__ENV = { SUPABASE_URL: 'abc'def', ... };
```

This causes a `SyntaxError` when the browser loads `__env.js`, which silently fails (a `<script src>` 404/error doesn't throw), leaving `window.__ENV` undefined. Every page then initialises Supabase with `undefined` credentials and throws `supabaseUrl is required` at module load time.

Supabase URLs (`https://xxx.supabase.co`) and anon JWT keys (`eyJ...`) do not contain single quotes today, so this is currently latent. However, it is unguarded against future key rotation or project changes and should be fixed before the pattern is treated as stable infrastructure.

**Fix:** Use JSON serialisation in the echo command so values are safely double-quoted and escaped:

```toml
command = "npm install && npm run build:css && printf 'window.__ENV = %s;' \"$(node -e \"process.stdout.write(JSON.stringify({SUPABASE_URL:process.env.SUPABASE_URL,SUPABASE_ANON_KEY:process.env.SUPABASE_ANON_KEY}))\" )\" > js/__env.js"
```

Or, simpler with a tiny Node inline script placed in `scripts/gen-env.js`:

```js
// scripts/gen-env.js
const fs = require('fs');
const env = {
  SUPABASE_URL: process.env.SUPABASE_URL || '',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || ''
};
fs.writeFileSync('js/__env.js', `window.__ENV = ${JSON.stringify(env)};`);
```

```toml
command = "npm install && npm run build:css && node scripts/gen-env.js"
```

---

### CR-02: Catch-all SPA redirect breaks multi-page app clean-path navigation

**File:** `netlify.toml:8-10`

**Issue:** The redirect rule:

```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

is a standard SPA rewrite, but Elvora is a multi-page application (MPA) — each page is a separate `.html` file. Netlify applies redirect rules only when no matching static file exists. Direct `.html` URL requests (`/shop.html`, `/product.html`, etc.) are served correctly because Netlify finds the file before consulting redirect rules.

The defect is for clean-path URLs without the `.html` extension: `/shop`, `/product`, `/cart`, `/admin`, `/auth`, `/account`, `/style-match`, `/about`, `/contact` all 404 on the file system, triggering the rewrite to `/index.html`. The visitor sees the homepage content — with a 200 status — instead of the intended page or a real 404. This means:

- Internal links authored without `.html` suffix silently display the wrong page
- Broken link detection tools see 200 everywhere, hiding navigation errors
- The admin page becomes reachable at `/admin` but serves homepage HTML — the Phase 7 Alpine.js auth guard won't be present, potentially confusing users

**Fix:** Either (a) remove the catch-all entirely if all navigation uses `.html` extensions, or (b) enumerate per-page rewrites for clean paths:

```toml
[[redirects]]
  from = "/shop"
  to = "/shop.html"
  status = 200

[[redirects]]
  from = "/product"
  to = "/product.html"
  status = 200

# ... one rule per page

[[redirects]]
  from = "/*"
  to = "/404.html"
  status = 404
```

Option (a) is the lower-risk choice given the current MPA structure.

---

## Warnings

### WR-01: keepalive `curl` has no timeout — job can hang indefinitely

**File:** `.github/workflows/keepalive.yml:14`

**Issue:** The keepalive step runs:

```sh
curl -f "${{ secrets.SUPABASE_URL }}/auth/v1/health"
```

Without `--max-time`, `curl` will wait for a TCP connection and response indefinitely. If Supabase's health endpoint is slow or unresponsive, the GitHub Actions runner holds the job slot until the runner's own 6-hour hard timeout. This wastes a free-tier concurrency slot and delays detection of the failure.

**Fix:** Add a connection and transfer timeout:

```yaml
run: |
  curl -f --max-time 30 --connect-timeout 10 "${{ secrets.SUPABASE_URL }}/auth/v1/health"
```

---

### WR-02: keepalive requires a GitHub secret separate from Netlify env vars — easy to miss

**File:** `.github/workflows/keepalive.yml:14`

**Issue:** The keepalive job reads `${{ secrets.SUPABASE_URL }}` from GitHub repository secrets. The Plan 01-08 SUMMARY instructs the user to set `SUPABASE_URL` in the **Netlify** dashboard — a completely separate secrets store. If the user follows only the 01-08 setup instructions, the GitHub secret is never set, the keepalive curl receives an empty URL string, and Supabase receives a health ping to a malformed URL. The job will fail silently (or `curl` exits with a non-zero code), and the free-tier project will not receive the daily ping despite the workflow appearing configured.

This is an operational gap: two separate setup steps (Netlify env var + GitHub secret) are required but only one is documented in the user-facing setup section.

**Fix:** Add an explicit step to the keepalive SUMMARY / User Setup Required section. Also consider failing fast if the secret is unset:

```yaml
- name: Check secret is set
  run: |
    if [ -z "${{ secrets.SUPABASE_URL }}" ]; then
      echo "ERROR: SUPABASE_URL GitHub secret is not set. Add it in repo Settings > Secrets and variables > Actions."
      exit 1
    fi
```

---

### WR-03: No local-dev story for `js/__env.js` — every page logs an uncaught Supabase error

**File:** `js/supabase.js:10` (called from all HTML files)

**Issue:** `js/__env.js` is gitignored and is only generated at Netlify build time. Running the HTML pages locally (via a dev server or direct file open) results in a 404 for `__env.js`. The plain `<script src="...">` tag silently swallows the 404, leaving `window.__ENV` undefined. `supabase.js` then calls:

```js
export const supabase = createClient(undefined, undefined);
```

`createClient` throws `"supabaseUrl is required"` at ES module evaluation time. This error propagates as a module rejection and breaks every stub module that imports from `supabase.js` (`auth.js`, `products.js`, `cart.js`, `style-match.js`, `admin.js`). Local development is completely broken for Supabase-dependent functionality with no diagnostic hint.

The `import.meta.env?.VITE_SUPABASE_URL` fallback in `supabase.js:7` only works if Vite is in use — there is no `vite dev` script in `package.json`.

**Fix:** Document a local-dev setup step. Simplest approach: add a `build:env` npm script and a `dev` script that creates `js/__env.js` locally from a `.env` file:

```json
"scripts": {
  "build:css": "tailwindcss -i src/input.css -o css/style.css --minify",
  "build:env": "node scripts/gen-env.js",
  "dev": "npm run build:env && npm run build:css -- --watch"
}
```

Alternatively, add a guard in `supabase.js` so missing config fails gracefully with a diagnostic message instead of an uncaught throw:

```js
if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.warn('[Elvora] Supabase credentials not found. Run npm run build:env or set Netlify env vars.');
}
export const supabase = (SUPABASE_URL && SUPABASE_ANON_KEY)
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;
```

---

### WR-04: `css/` directory is not committed — Tailwind CLI must auto-create it at build time

**File:** `.gitignore:4` / `netlify.toml:2`

**Issue:** `.gitignore` excludes `css/style.css` but `style.css` is the only file in `css/`. Git does not track empty directories, so when Netlify clones the repository, the `css/` directory does not exist. The build command runs `tailwindcss -i src/input.css -o css/style.css --minify`, which writes to `css/style.css`.

Tailwind CSS CLI v4 does create parent directories for the output path automatically, so this succeeds in practice. The risk is fragility: if the Tailwind CLI version changes, the build toolchain changes, or `build:css` is replaced, the missing directory assumption could silently cause a build failure.

**Fix:** Add a `.gitkeep` file to `css/` and remove `css/style.css` from `.gitignore` in favour of `css/*.css`:

```gitignore
# Generated CSS — not committed; Netlify builds it
css/*.css
!css/.gitkeep
```

Then:

```bash
touch css/.gitkeep
git add css/.gitkeep
```

This guarantees `css/` exists in every checkout.

---

## Info

### IN-01: API key referenced in `.env.example` does not match documented tech stack

**File:** `.env.example` (lines 14-15, read via `git show`)

**Issue:** `.env.example` documents:

```
# GEMINI_API_KEY — stored in Supabase Edge Function secrets only. NEVER here.
```

`CLAUDE.md` (the authoritative tech-stack document) specifies `Claude API (Anthropic) claude-haiku-4-5` as the AI model for Style Match. `PROJECT.md` (planning artifact) mentions `Google Gemini Vision API`. The two planning documents disagree, and `.env.example` follows the `PROJECT.md` choice. This ambiguity does not affect the current phase (AI integration is Phase 5), but the wrong key will be sought when Phase 5 setup begins.

**Fix:** Align all three documents before Phase 5 work starts. Update whichever document is authoritative. If Claude Haiku is the final choice (per `CLAUDE.md`), update `.env.example` and `PROJECT.md` to:

```
# ANTHROPIC_API_KEY — stored in Netlify Function environment only. NEVER here.
```

---

### IN-02: `about.html` and `contact.html` load `supabase.js` unnecessarily

**File:** `about.html:12-13`, `contact.html:12-13`

**Issue:** The about and contact pages are static content pages that do not require database access. Both load `js/__env.js` and `js/supabase.js`. This means any Supabase credential failure (missing `__env.js`, unset env vars) surfaces as a console error on purely informational pages. It also means these pages will be broken in offline/demo scenarios where Supabase is unreachable.

This is a minor quality concern for the current shell phase where all pages are stubs. It should be addressed when page content is filled in Phase 2.

**Fix:** Remove the Supabase script tags from `about.html` and `contact.html` unless Phase 2 design requires database-driven content (e.g. live testimonials) on these pages.

---

_Reviewed: 2026-06-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
