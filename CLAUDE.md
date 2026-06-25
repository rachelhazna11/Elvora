<!-- GSD:project-start source:PROJECT.md -->

## Project

**Elvora**

Elvora is a premium women's activewear e-commerce platform that merges quiet luxury fashion aesthetics with modern wellness culture. Built as a university assessment portfolio project, it demonstrates a full-stack shopping experience targeting women aged 20–35 who value elegance, quality, and personal style in their activewear — for padel, pilates, tennis, gym, running, and wellness lifestyles.

The defining differentiator is an AI-powered Style Match feature: users upload a photo and receive personalized outfit recommendations from the Elvora catalog based on appearance, body proportions, and style preferences — no virtual try-on, no generative imagery. It feels like a premium personal stylist, not a complex AI tool.

Backend is powered by Supabase (auth, database, storage) for rapid implementation without backend overhead. An admin panel supports full CRUD operations for all catalog and content.

**Core Value:** A shopper lands on Elvora, uploads a photo, and within moments receives a curated outfit recommendation that feels personally chosen for her — drawing her naturally into a premium catalog she wants to explore.

### Constraints

- **Scope**: Student-sized build — prioritize polished execution of core features over extensive feature coverage; avoid overengineering
- **Backend**: Supabase only — no custom server, no separate REST API needed
- **Payments**: Placeholder architecture only — no real payment processing required
- **Catalog**: Seeded sample data — no live inventory system needed
- **AI**: MVP recommendation only — no image generation, no virtual try-on
- **Assessment**: Must support deployment, demonstrate semantic HTML, responsive design, JavaScript functionality, and documented AI usage
- **Aesthetic**: Premium quiet luxury — every UI decision should reinforce the brand identity, not undercut it

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Recommended Stack

### Frontend Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Alpine.js | 3.15.12 | Reactive UI behavior (cart, modals, filters, auth state) | Declarative `x-data` in HTML; no build step; 15 KB; `Alpine.store()` handles global cart and auth state cleanly across pages without a SPA router |
| Vanilla JS (ES Modules) | ES2022 (native) | Data fetching, page routing logic, utility functions | Used alongside Alpine for heavier logic that doesn't belong in HTML attributes |

### CSS Approach

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Tailwind CSS v4 (CLI build) | 4.x (latest) | Utility-first styling | Zero opinion on design — every visual decision is yours; production bundle is 5–20 KB after tree-shaking; enforces consistent spacing/typography scale; ideal for bespoke luxury aesthetics |
| CSS Custom Properties | Native | Brand tokens (color palette, font stack, spacing scale) | Define `--color-cream`, `--color-sage`, `--font-display` once; Tailwind `theme()` can reference them |

### Backend — Supabase

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| @supabase/supabase-js | 2.x (latest, ≥2.79) | Database, Auth, Storage client | Single SDK for all backend operations; browser-safe with anon/publishable key + RLS |
| Supabase Auth | built-in | Email/password sign-up, login, session management | No separate auth library needed; handles JWT refresh automatically |
| Supabase Storage | built-in | Product images, AI style-match photo uploads | S3-compatible; generates public URLs; supports image transforms |
| Supabase PostgreSQL | built-in | All persistent data: products, orders, cart, wishlist, reviews, AI preferences | Full relational DB with RLS policies per table |

- The `anon` (publishable) key is safe to expose in browser code — this is by design.
- Security is enforced by Row Level Security (RLS) policies on every table, NOT by hiding the key.
- **Enable RLS on every table.** Tables with RLS disabled are readable by anyone with the anon key (CVE-2025-48757 affected 10% of audited Supabase apps this way).
- The `service_role` key must NEVER appear in frontend code. It bypasses RLS entirely.
- Typical RLS policy for products (public read): `USING (true)` for SELECT, `USING (auth.uid() = user_id)` for user-owned rows.
- 500 MB database, 1 GB file storage, 50,000 MAUs, unlimited API requests
- Free projects pause after 1 week of inactivity — resume manually before demos

### AI Integration — Claude Vision API

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Claude API (Anthropic) | claude-haiku-4-5 | Style Match: analyze user photo → recommend catalog products | Fastest + cheapest Claude model with full vision support; $1/$5 per MTok input/output; sufficient for outfit recommendation task |
| Vercel Functions | Node.js 20 | API key proxy — browser calls Vercel function, function calls Claude | Keeps `ANTHROPIC_API_KEY` out of browser bundle; Vercel free tier includes 100,000 invocations/month |

### Image Upload — Supabase Storage (Product Images)

### Deployment

| Platform | Tier | Why |
|----------|------|-----|
| Vercel | Free | Framework-agnostic; handles static HTML + Alpine naturally; free Vercel Functions for Claude proxy; GitHub CI built-in; 100 GB bandwidth/month free |
| Cloudflare Pages | Free (alternative) | Generous free tier; edge functions available; slightly more setup for environment variables |

# vercel.json

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Swiper.js | 11.x | Touch/swipe product image gallery, hero carousel | Product detail page image slider; homepage hero; mobile-optimized |
| Choices.js | 10.x | Accessible custom `<select>` for size/color filters | Replaces native selects with styled dropdowns matching brand aesthetic |
| Tom Select | 2.x | Alternative to Choices.js for tag-style multi-select | Use for filter UI if multi-select is needed |
| Toastify-js | 1.x | Non-blocking toast notifications (add to cart, wishlist saved, error) | Lightweight; no dependencies; matches quiet luxury if styled correctly |

### Build Tooling

| Tool | Version | Purpose | Why |
|------|---------|---------|-----|
| Tailwind CSS CLI | 4.x | Compile and minify CSS | Standalone binary, no Node project setup required; `npx @tailwindcss/cli` |
| Vite (optional) | 5.x | Module bundler if JS complexity grows | Recommended if using ES module imports across many files; enables tree-shaking, env vars, and fast HMR |

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
| AI proxy | Vercel Functions | Supabase Edge Functions | Both work; Vercel keeps all hosting in one place; Supabase Edge Functions are Deno-based (less familiar) |
| AI proxy | Vercel Functions | Direct browser call | NEVER — exposes API key in devtools |
| Deployment | Vercel | GitHub Pages | GitHub Pages is static-only; no serverless functions for Claude proxy; would require a separate backend |

## Installation

### CDN-first setup (no build step except Tailwind)

### Tailwind CSS CLI

# One-time setup

# Development (watch mode)

# Production build

### Vercel Functions (Claude proxy)

# Local dev (requires Vercel CLI)

# .env (local only, never commit)

### Vite (if adopted later)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Alpine.js for this scope | HIGH | Documented Supabase+Alpine integration; proven e-commerce cart pattern via `Alpine.store`; actively maintained at v3.15.12 |
| Supabase JS SDK v2 | HIGH | Official docs; CDN install confirmed; anon key + RLS security model well-documented; free tier limits confirmed sufficient |
| Tailwind v4 for luxury aesthetic | HIGH | No framework opinions imposed; luxury brands (Alo Yoga tier) commonly use utility-first CSS; v4 CLI confirmed stable |
| Claude Haiku for vision | HIGH | All current Claude models confirmed vision-capable; Haiku pricing and model ID confirmed from official docs; proxy pattern is standard practice |
| Vercel Functions as proxy | HIGH | Standard pattern; widely documented; 100k invocations/month free; sufficient for assessment demo load |
| Deployment on Vercel free | HIGH | Static HTML + Alpine + Vercel Functions confirmed working pattern; 100 GB bandwidth sufficient |
| Vite as optional bundler | MEDIUM | Recommended only if project grows; skip for early phases to avoid premature tooling overhead |

## What NOT to Use

| Technology | Reason to Avoid |
|------------|-----------------|
| React / Next.js | Overengineered for this scope; introduces build complexity, JSX, hydration concerns; assessment grades semantic HTML not component trees |
| Vue 3 full build | Heavier than Alpine for a multi-page app without SPA routing; Alpine handles the needed reactive surfaces |
| SvelteKit | Requires compilation step and framework conventions that don't align with "lightweight JS framework" constraint |
| Bootstrap 5 | Imposes visual identity that conflicts with premium quiet-luxury brand aesthetic; utility override fights Bootstrap defaults |
| Firebase / Amplify | Redundant with Supabase already chosen; two backend services adds unnecessary complexity |
| Express.js / custom server | Explicitly out of scope per project constraints; Supabase + Vercel Functions replaces it entirely |
| GraphQL | No benefit at this data complexity level; Supabase's PostgREST query builder via the JS SDK is sufficient |
| Webpack | Unnecessary if using Vite or no bundler; Webpack config overhead is not justified |
| Redux / Zustand | Alpine.store() is sufficient for cart, auth, and filter state; no need for external state library |
| HTMX | Designed for server-rendered HTML fragments; Supabase is a client SDK, not an HTML server; wrong paradigm |
| Tailwind CDN Play CDN | Development/demo only; not suitable for production; cannot customize design tokens; use CLI instead |

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
- Vercel Functions docs: https://vercel.com/docs/functions
- Vercel environment variables: https://vercel.com/docs/projects/environment-variables
- Vercel free tier limits: https://vercel.com/pricing
- Tailwind CSS v4 CDN/Play CDN: https://tailwindcss.com/docs/installation/play-cdn
- Tailwind v4 announcement: https://tailwindcss.com/blog/tailwindcss-v4

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
