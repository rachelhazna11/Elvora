# Elvora — Premium Women's Activewear

Elvora is a premium women's activewear e-commerce platform that merges quiet luxury fashion aesthetics with modern wellness culture. Built as a university assessment portfolio project, it demonstrates a full-stack shopping experience targeting women aged 20–35 who value elegance, quality, and personal style in their activewear.

The defining differentiator is an AI-powered Style Match feature: users upload a photo and receive personalised outfit recommendations from the Elvora catalogue based on appearance, body proportions, and style preferences — no virtual try-on, no generative imagery. It feels like a premium personal stylist.

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend UI | Alpine.js 3.x | Reactive cart, modals, auth state, filters |
| Styling | Tailwind CSS v4 (CLI build) | Utility-first; bespoke luxury design tokens |
| Backend | Supabase (Auth + DB + Storage) | Auth, PostgreSQL, file storage, RLS security |
| AI Proxy | Vercel Functions (Node.js 20) | Secure API key proxy for Claude Vision |
| AI Model | Claude Haiku (claude-haiku-4-5) | Style Match photo analysis + outfit recommendation |
| Deployment | Vercel | Static hosting + serverless functions |

---

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/elvora.git
   cd elvora
   ```

2. **Create your environment file**
   ```bash
   cp .env.example .env
   ```

3. **Add your Supabase credentials to `.env`**
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```
   Retrieve these from: Supabase Dashboard → Project Settings → API

4. **Open the site for local development**
   Open `index.html` directly in your browser, or use a local live server extension (e.g., VS Code Live Server).

   > Note: Supabase features (auth, products, cart) require a running Supabase project with the schema applied.

---

## Database

Apply the schema and seed data via the Supabase SQL Editor:

1. Go to your Supabase project → SQL Editor
2. Run `supabase/migrations/001_initial_schema.sql` — creates all 16 tables with RLS enabled
3. Run `supabase/seed.sql` once — inserts 20+ sample products and catalogue data

---

## Build

Tailwind CSS v4 must be compiled before the styles take effect.

**Development (watch mode):**
```bash
npx @tailwindcss/cli@next -i src/input.css -o css/style.css --watch
```

**Production build (minified):**
```bash
npx @tailwindcss/cli@next -i src/input.css -o css/style.css --minify
```

The compiled `css/style.css` is gitignored — Vercel runs the build command automatically on deploy.

---

## Deployment

This project deploys to **Vercel**. The `vercel.json` at the project root configures the build automatically.

**Steps:**
1. Push code to your GitHub repository (main branch)
2. Go to [vercel.com](https://vercel.com) → Add New Project → Import from GitHub
3. Select the Elvora repository; build settings are auto-detected from `vercel.json`
4. Before deploying, add environment variables in: Project Settings → Environment Variables
5. Click Deploy
6. The site will be live at your Vercel-assigned URL (e.g., `https://elvora.vercel.app`)

---

## Environment Variables

| Variable | Where to Set | Source |
|----------|-------------|--------|
| `SUPABASE_URL` | Vercel Project Settings → Environment Variables | Supabase Dashboard → Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Vercel Project Settings → Environment Variables | Supabase Dashboard → Project Settings → API → anon (public) key |
| `ANTHROPIC_API_KEY` | Vercel Project Settings → Environment Variables (Vercel Function only) | Anthropic Console → API Keys |

> Security note: The `SUPABASE_ANON_KEY` is safe to use in browser code — it is a publishable key. Security is enforced by Row Level Security (RLS) policies on every database table. The `service_role` key must never appear in any frontend file.

---

## AI Usage

This project uses Claude Haiku (claude-haiku-4-5) for the Style Match feature. Full documentation of AI usage, prompts, and decision log is in `AI-USAGE.md` (created in Phase 5).
