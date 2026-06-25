# Technology Stack

**Project:** Elvora — Premium Women's Activewear E-Commerce
**Researched:** 2026-06-10
**Overall confidence:** HIGH

---

## Recommended Stack

### Frontend Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Alpine.js | 3.15.12 | Reactive UI behavior (cart, modals, filters, auth state) | Declarative `x-data` in HTML; no build step; 15 KB; `Alpine.store()` handles global cart and auth state cleanly across pages without a SPA router |
| Vanilla JS (ES Modules) | ES2022 (native) | Data fetching, page routing logic, utility functions | Used alongside Alpine for heavier logic that doesn't belong in HTML attributes |

**Rationale for Alpine over pure vanilla:** An e-commerce UI has dozens of small interactive surfaces — cart count badge, product image gallery, size selector, filter toggles, modal overlays, wishlist buttons, auth state in the navbar. Writing all of these in vanilla JS requires significant manual DOM wiring. Alpine lets you express them as HTML attributes (`x-show`, `x-model`, `x-for`, `x-on`) which is faster to write, easier to read in an assessment context, and more maintainable. The `Alpine.store('cart', {...})` API provides reactive global state that updates every component subscribed to it — exactly what a shopping cart needs.

**Rationale against React/Next.js:** React introduces a build pipeline, Node modules, JSX, component hydration, and deployment complexity that add no educational or functional value here. The assessment criteria reward semantic HTML and working JS interactions, both of which Alpine satisfies directly. Next.js would also conflict with the "no custom server" constraint unless used in pure static export mode, which sacrifices its primary value proposition.

**Rationale against HTMX:** HTMX is server-rendered-first. With Supabase as a client SDK (no custom HTML-serving server), HTMX has no HTML fragments to swap in. Alpine is the correct lightweight choice for a client-side Supabase integration.

---

### CSS Approach

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Tailwind CSS v4 (CLI build) | 4.x (latest) | Utility-first styling | Zero opinion on design — every visual decision is yours; production bundle is 5–20 KB after tree-shaking; enforces consistent spacing/typography scale; ideal for bespoke luxury aesthetics |
| CSS Custom Properties | Native | Brand tokens (color palette, font stack, spacing scale) | Define `--color-cream`, `--color-sage`, `--font-display` once; Tailwind `theme()` can reference them |

**Rationale for Tailwind v4 over custom CSS:** A premium quiet-luxury brand requires *precise* control over every spacing, color, and typographic decision. Bootstrap and similar frameworks impose their own visual opinion — every Bootstrap site looks like Bootstrap. Tailwind imposes none. For a student project the utility-first approach also moves faster than writing and maintaining a custom SCSS architecture. The v4 CLI produces a single optimized CSS file, compatible with any static host.

**Tailwind CDN Play CDN is NOT recommended for production** — it is a development-only tool. Use the Tailwind CLI (`npx @tailwindcss/cli`) to compile a production CSS file as part of the build.

**Luxury aesthetic tokens to configure in `tailwind.config.js`:**
```
Colors: cream (#F5F0E8), sage (#8A9E8E), slate (#4A5568), ivory (#FFFFF0), charcoal (#2D3748), warm-white (#FAFAF7)
Fonts: display → 'Cormorant Garamond' or 'Playfair Display' (serif), body → 'DM Sans' or 'Inter' (sans)
Spacing: generous — base unit 4px, rely on 8/12/16/24/32/48/64/96/128
```

**Google Fonts delivery:** Load via `<link rel="preconnect">` + `<link href="...fonts.googleapis.com...">` in the HTML `<head>`. Keep to two typefaces maximum.

---

### Backend — Supabase

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| @supabase/supabase-js | 2.x (latest, ≥2.79) | Database, Auth, Storage client | Single SDK for all backend operations; browser-safe with anon/publishable key + RLS |
| Supabase Auth | built-in | Email/password sign-up, login, session management | No separate auth library needed; handles JWT refresh automatically |
| Supabase Storage | built-in | Product images, AI style-match photo uploads | S3-compatible; generates public URLs; supports image transforms |
| Supabase PostgreSQL | built-in | All persistent data: products, orders, cart, wishlist, reviews, AI preferences | Full relational DB with RLS policies per table |

**SDK setup pattern (no bundler, CDN import):**
```html
<!-- In <head> of every page -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script>
  // supabase.js — loaded before Alpine
  const { createClient } = supabase;
  window._supabase = createClient(
    'https://YOUR_PROJECT_REF.supabase.co',
    'YOUR_PUBLISHABLE_ANON_KEY'
  );
</script>
```

For a bundled setup (Vite, recommended if complexity grows):
```js
// src/lib/supabase.js
import { createClient } from '@supabase/supabase-js';
export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);
```

**CRITICAL — Security model:**
- The `anon` (publishable) key is safe to expose in browser code — this is by design.
- Security is enforced by Row Level Security (RLS) policies on every table, NOT by hiding the key.
- **Enable RLS on every table.** Tables with RLS disabled are readable by anyone with the anon key (CVE-2025-48757 affected 10% of audited Supabase apps this way).
- The `service_role` key must NEVER appear in frontend code. It bypasses RLS entirely.
- Typical RLS policy for products (public read): `USING (true)` for SELECT, `USING (auth.uid() = user_id)` for user-owned rows.

**Supabase free tier limits (sufficient for assessment):**
- 500 MB database, 1 GB file storage, 50,000 MAUs, unlimited API requests
- Free projects pause after 1 week of inactivity — resume manually before demos

---

### AI Integration — Claude Vision API

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Claude API (Anthropic) | claude-haiku-4-5 | Style Match: analyze user photo → recommend catalog products | Fastest + cheapest Claude model with full vision support; $1/$5 per MTok input/output; sufficient for outfit recommendation task |
| Netlify Functions | Node.js 20 | API key proxy — browser calls Netlify function, function calls Claude | Keeps `ANTHROPIC_API_KEY` out of browser bundle; Netlify free tier includes 125,000 invocations/month |

**Why `claude-haiku-4-5` over Sonnet or Opus:** For the Style Match task — "analyze this photo and recommend 3 outfits from our catalog" — Haiku is fully capable and 3–5x cheaper. Reserve Sonnet/Opus for genuinely complex reasoning. Haiku at $1/MTok input means a typical style match call (image + catalog context prompt ≈ 3,000 tokens) costs ~$0.003 per request.

**Integration pattern — NEVER call Claude directly from the browser.** The API key would be visible in browser devtools. Use a Netlify Function as a thin proxy:

```
Browser                   Netlify Function              Claude API
  │                            │                             │
  │── POST /api/style-match ──>│                             │
  │   { imageBase64, prefs }   │── POST messages API ───────>│
  │                            │   Authorization: Bearer $ANTHROPIC_API_KEY
  │<── { recommendations } ───│<── { content } ────────────│
```

**Netlify Function skeleton:**
```js
// netlify/functions/style-match.js
export default async (req) => {
  const { imageBase64, catalogContext, preferences } = await req.json();
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': process.env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5',
      max_tokens: 1024,
      messages: [{
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: imageBase64 } },
          { type: 'text', text: catalogContext }
        ]
      }]
    })
  });
  const data = await response.json();
  return Response.json({ recommendations: data.content[0].text });
};
```

**Netlify AI Gateway (alternative):** Netlify has a built-in AI Gateway that auto-injects `ANTHROPIC_API_KEY` — no key management needed. Viable if using Netlify for deployment; evaluates per-project.

**Image handling for Style Match:**
1. User selects photo via `<input type="file" accept="image/*">`.
2. Browser converts to base64 using `FileReader.readAsDataURL()` — strip the `data:image/jpeg;base64,` prefix before sending.
3. Client sends base64 to the Netlify Function (do NOT upload to Supabase Storage first — adds latency and stores user photos unnecessarily).
4. Optionally, save the user's style preferences (not the photo) to Supabase after successful analysis.

**Resize before sending** to reduce token cost and latency: use `<canvas>` to resize to max 800px before base64 encoding. Claude vision accepts up to 2576px but larger = more tokens = higher cost.

---

### Image Upload — Supabase Storage (Product Images)

This is for product catalog images managed via the admin panel, NOT user style-match photos.

```js
// Upload product image
const { data, error } = await _supabase.storage
  .from('product-images')
  .upload(`${productId}/${filename}`, file, {
    contentType: file.type,
    upsert: true  // allow re-upload on update
  });

// Get public URL
const { data: urlData } = _supabase.storage
  .from('product-images')
  .getPublicUrl(`${productId}/${filename}`);

const publicUrl = urlData.publicUrl;
```

**Bucket policy:** Set `product-images` bucket to public read. Enforce size limits (10 MB max recommended) and MIME type validation on the admin upload form.

---

### Deployment

| Platform | Tier | Why |
|----------|------|-----|
| Netlify | Free | Framework-agnostic; handles static HTML + Alpine naturally; free Netlify Functions for Claude proxy; drag-and-drop deploy or GitHub CI; 100 GB bandwidth/month free |
| Vercel | Free (fallback) | Also works; slightly more opinionated toward Next.js but handles static fine; serverless functions available |
| Cloudflare Pages | Free (alternative) | Generous free tier; edge functions available; slightly more setup for environment variables |

**Recommended: Netlify.** The combination of static file hosting + Netlify Functions (for the Claude proxy) + environment variable support is the simplest path. Vercel is equally valid if already familiar — both support `VITE_SUPABASE_URL` style environment variables.

**Deployment configuration:**
```toml
# netlify.toml
[build]
  command = "npx @tailwindcss/cli -i ./src/input.css -o ./dist/output.css --minify"
  publish = "."

[functions]
  directory = "netlify/functions"

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
```

---

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Swiper.js | 11.x | Touch/swipe product image gallery, hero carousel | Product detail page image slider; homepage hero; mobile-optimized |
| Choices.js | 10.x | Accessible custom `<select>` for size/color filters | Replaces native selects with styled dropdowns matching brand aesthetic |
| Tom Select | 2.x | Alternative to Choices.js for tag-style multi-select | Use for filter UI if multi-select is needed |
| Toastify-js | 1.x | Non-blocking toast notifications (add to cart, wishlist saved, error) | Lightweight; no dependencies; matches quiet luxury if styled correctly |

**No date library needed** (native `Intl.DateTimeFormat` handles order date formatting).
**No HTTP client needed** (`fetch` is sufficient; Supabase SDK wraps it internally).
**No state management library** (Alpine.store covers all cross-component state needs).

---

### Build Tooling

| Tool | Version | Purpose | Why |
|------|---------|---------|-----|
| Tailwind CSS CLI | 4.x | Compile and minify CSS | Standalone binary, no Node project setup required; `npx @tailwindcss/cli` |
| Vite (optional) | 5.x | Module bundler if JS complexity grows | Recommended if using ES module imports across many files; enables tree-shaking, env vars, and fast HMR |

**Start without Vite.** For the first 2–3 phases, a flat file structure with Alpine via CDN and Supabase via CDN is sufficient. Introduce Vite only if module management becomes painful (circular imports, many files). The Tailwind CLI is always needed regardless.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Frontend framework | Alpine.js 3.x | React 18 / Next.js 14 | Requires build pipeline, JSX, npm, component hydration; overengineered for assessment scope; contradicts "semantic HTML" criterion |
| Frontend framework | Alpine.js 3.x | Vue 3 (CDN) | Viable but heavier API surface than needed; Alpine's HTML-first approach is more natural for static multi-page layout |
| Frontend framework | Alpine.js 3.x | Svelte/SvelteKit | Requires build step and compilation; adds complexity; loses the direct HTML semantic readability |
| CSS | Tailwind CSS v4 | Bootstrap 5 | Every Bootstrap site looks like Bootstrap; not appropriate for a premium brand aesthetic requiring full visual control |
| CSS | Tailwind CSS v4 | Pure custom CSS | Faster to build with Tailwind; consistent scale; custom CSS viable but slower without a preprocessor setup |
| CSS | Tailwind CSS v4 | Tailwind v3 | v4 is current; v3 has different config format; no reason to use older version on greenfield |
| AI model | claude-haiku-4-5 | claude-sonnet-4-6 | 3x more expensive; not needed for outfit recommendation task; Haiku is sufficient |
| AI proxy | Netlify Functions | Supabase Edge Functions | Both work; Netlify keeps all hosting in one place; Supabase Edge Functions are Deno-based (less familiar) |
| AI proxy | Netlify Functions | Direct browser call | NEVER — exposes API key in devtools |
| Deployment | Netlify | GitHub Pages | GitHub Pages is static-only; no serverless functions for Claude proxy; would require a separate backend |

---

## Installation

### CDN-first setup (no build step except Tailwind)

```html
<!-- index.html <head> -->
<link rel="stylesheet" href="/dist/output.css">
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

### Tailwind CSS CLI

```bash
# One-time setup
npm install -D @tailwindcss/cli

# Development (watch mode)
npx @tailwindcss/cli -i ./src/input.css -o ./dist/output.css --watch

# Production build
npx @tailwindcss/cli -i ./src/input.css -o ./dist/output.css --minify
```

### Netlify Functions (Claude proxy)

```bash
# Local dev
npm install -D netlify-cli
npx netlify dev  # serves site + functions locally at localhost:8888
```

```bash
# .env (local only, never commit)
ANTHROPIC_API_KEY=sk-ant-...
VITE_SUPABASE_URL=https://YOUR_REF.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

### Vite (if adopted later)

```bash
npm create vite@latest elvora -- --template vanilla
npm install @supabase/supabase-js alpinejs
npm install -D tailwindcss @tailwindcss/vite
```

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Alpine.js for this scope | HIGH | Documented Supabase+Alpine integration; proven e-commerce cart pattern via `Alpine.store`; actively maintained at v3.15.12 |
| Supabase JS SDK v2 | HIGH | Official docs; CDN install confirmed; anon key + RLS security model well-documented; free tier limits confirmed sufficient |
| Tailwind v4 for luxury aesthetic | HIGH | No framework opinions imposed; luxury brands (Alo Yoga tier) commonly use utility-first CSS; v4 CLI confirmed stable |
| Claude Haiku for vision | HIGH | All current Claude models confirmed vision-capable; Haiku pricing and model ID confirmed from official docs; proxy pattern is standard practice |
| Netlify Functions as proxy | HIGH | Standard pattern; widely documented; 125k invocations/month free; sufficient for assessment demo load |
| Deployment on Netlify free | HIGH | Static HTML + Alpine + Netlify Functions confirmed working pattern; 100 GB bandwidth sufficient |
| Vite as optional bundler | MEDIUM | Recommended only if project grows; skip for early phases to avoid premature tooling overhead |

---

## What NOT to Use

| Technology | Reason to Avoid |
|------------|-----------------|
| React / Next.js | Overengineered for this scope; introduces build complexity, JSX, hydration concerns; assessment grades semantic HTML not component trees |
| Vue 3 full build | Heavier than Alpine for a multi-page app without SPA routing; Alpine handles the needed reactive surfaces |
| SvelteKit | Requires compilation step and framework conventions that don't align with "lightweight JS framework" constraint |
| Bootstrap 5 | Imposes visual identity that conflicts with premium quiet-luxury brand aesthetic; utility override fights Bootstrap defaults |
| Firebase / Amplify | Redundant with Supabase already chosen; two backend services adds unnecessary complexity |
| Express.js / custom server | Explicitly out of scope per project constraints; Supabase + Netlify Functions replaces it entirely |
| GraphQL | No benefit at this data complexity level; Supabase's PostgREST query builder via the JS SDK is sufficient |
| Webpack | Unnecessary if using Vite or no bundler; Webpack config overhead is not justified |
| Redux / Zustand | Alpine.store() is sufficient for cart, auth, and filter state; no need for external state library |
| HTMX | Designed for server-rendered HTML fragments; Supabase is a client SDK, not an HTML server; wrong paradigm |
| Tailwind CDN Play CDN | Development/demo only; not suitable for production; cannot customize design tokens; use CLI instead |

---

## Sources

- Alpine.js installation docs: https://alpinejs.dev/essentials/installation
- Alpine.js global store API: https://alpinejs.dev/globals/alpine-store
- Supabase JS SDK reference: https://supabase.com/docs/reference/javascript/installing
- Supabase Storage upload reference: https://supabase.com/docs/reference/javascript/storage-from-upload
- Supabase Storage quickstart: https://supabase.com/docs/guides/storage/quickstart
- Supabase RLS docs: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase security 2025 retro: https://supabase.com/blog/supabase-security-2025-retro
- Supabase anon key security explanation: https://lilting.ch/en/articles/supabase-security-rls
- CVE-2025-48757 RLS disclosure: https://vibeappscanner.com/is-supabase-safe
- Supabase free tier limits: https://supabase.com/pricing
- Claude models overview (official): https://platform.claude.com/docs/en/about-claude/models/overview
- Claude vision docs: https://platform.claude.com/docs/en/build-with-claude/vision
- Netlify Functions API key proxy: https://msof.me/blog/protecting-api-keys-in-frontend-apps-with-netlify-functions/
- FreeCodeCamp Netlify Functions guide: https://www.freecodecamp.org/news/hide-api-keys-in-frontend-apps-using-netlify-functions/
- Netlify AI Gateway: https://www.netlify.com/platform/ai-gateway/
- Netlify free tier limits: https://www.netlify.com/pricing/
- Tailwind CSS v4 CDN/Play CDN: https://tailwindcss.com/docs/installation/play-cdn
- Tailwind v4 announcement: https://tailwindcss.com/blog/tailwindcss-v4
- Vercel vs Netlify comparison: https://vercel.com/kb/guide/vercel-vs-netlify
