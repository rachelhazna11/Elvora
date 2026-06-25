# Phase 1: Foundation - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 21 new files (greenfield)
**Analogs found:** 0 codebase analogs / 21 files — single prototype reference only

---

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `index.html` | page-shell | request-response | `elvora_updated-3.html` (prototype) | visual-reference |
| `shop.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `product.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `cart.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `checkout.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `auth.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `account.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `style-match.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `about.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `contact.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `admin.html` | page-shell | request-response | `elvora_updated-3.html` | visual-reference |
| `js/supabase.js` | service | request-response | No analog — new file |  |
| `js/auth.js` | service | request-response | No analog — new file |  |
| `js/cart.js` | store | event-driven | No analog — new file |  |
| `js/products.js` | service | CRUD | No analog — new file |  |
| `js/style-match.js` | service | request-response | No analog — new file |  |
| `js/admin.js` | service | CRUD | No analog — new file |  |
| `src/input.css` | config | transform | No analog — new file |  |
| `supabase/migrations/*.sql` | migration | CRUD | No analog — new file |  |
| `supabase/seed.sql` | utility | batch | No analog — new file |  |
| `supabase/functions/style-match/index.ts` | middleware | request-response | No analog — new file |  |

---

## Prototype Reference Patterns

All visual and structural patterns come from `elvora_updated-3.html` (project root). This file is a single-file prototype — **not production code** — but defines the visual identity that all new files must carry forward.

### Color Tokens
**Source:** `elvora_updated-3.html` lines 9–19

```css
:root {
  --sage: #A8BFA3;
  --rose: #D8A7A7;
  --beige: #F5F1ED;
  --charcoal: #2E2E2E;
  --lavender: #C6B7E2;
  --white: #FFFFFF;
  --sage-light: #E8F0E6;
  --rose-light: #F5E8E8;
  --text-muted: #8A8A8A;
}
```

These must be declared as CSS custom properties in `src/input.css` and referenced via Tailwind v4 `theme()` calls. Do not hard-code hex values anywhere in HTML or JS.

### Typography Stack
**Source:** `elvora_updated-3.html` line 7

```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,500;0,700;1,400;1,500&family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
```

- **Display / headlines:** `Playfair Display` serif — used for hero titles, section titles, price display
- **Body / UI:** `Poppins` sans-serif — used for nav links, labels, body copy, buttons
- Rule: `font-family: 'Playfair Display', serif` on `.hero-title`, `.section-title`, badge numerals
- Rule: `font-family: 'Poppins', sans-serif` is the `body` default

### Body Base Style
**Source:** `elvora_updated-3.html` lines 21–30

```css
* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  font-family: 'Poppins', sans-serif;
  background: var(--beige);
  color: var(--charcoal);
  overflow-x: hidden;
}
```

### Navigation Pattern
**Source:** `elvora_updated-3.html` lines 33–41

```css
nav {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  display: flex; align-items: center; justify-content: space-between;
  padding: 20px 48px;
  background: rgba(245,241,237,0.92);   /* --beige at 92% opacity */
  backdrop-filter: blur(16px);
  border-bottom: 1px solid rgba(168,191,163,0.2);  /* --sage at 20% */
  transition: all 0.3s ease;
}
```

Nav links: `font-size: 12px; letter-spacing: 2px; text-transform: uppercase; font-weight: 500`.
Hover state on all interactive nav elements: `color: var(--rose)`.

### Button Patterns
**Source:** `elvora_updated-3.html` lines 129–147

```css
/* Primary CTA */
.btn-primary {
  background: var(--charcoal); color: var(--white);
  padding: 16px 36px; border-radius: 50px;
  font-size: 12px; letter-spacing: 2px; text-transform: uppercase;
  font-weight: 500; transition: all 0.3s;
}
.btn-primary:hover { background: var(--rose); transform: translateY(-2px); }

/* Secondary / ghost */
.btn-secondary {
  background: transparent; color: var(--charcoal);
  padding: 16px 36px; border: 1.5px solid var(--charcoal); border-radius: 50px;
  font-size: 12px; letter-spacing: 2px; text-transform: uppercase; font-weight: 500;
}
.btn-secondary:hover { border-color: var(--rose); color: var(--rose); }
```

Border-radius on buttons is always `50px` (pill shape) — never square corners.

### Section Label + Title Pattern
**Source:** `elvora_updated-3.html` lines 231–242

```css
.section-label {
  font-size: 10px; letter-spacing: 5px; text-transform: uppercase;
  color: var(--sage); font-weight: 500; margin-bottom: 16px;
}
.section-title {
  font-family: 'Playfair Display', serif;
  font-size: clamp(32px, 4vw, 52px); font-weight: 700;
  line-height: 1.15; color: var(--charcoal);
}
.section-title em { font-style: italic; color: var(--rose); }
```

All section headings follow: small-caps label in sage → large Playfair Display title → italic `em` words coloured in rose.

### HTML Shell `<head>` Boilerplate
**Source:** `elvora_updated-3.html` lines 1–7

Every HTML page must include exactly:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ELVORA — [Page Name]</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,500;0,700;1,400;1,500&family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
</head>
```

No inline `<style>` blocks (NF-006). No inline `<script>` blocks. All JS loaded as ES modules via `<script type="module" src="/js/...">` at end of `<body>`.

### Unsplash URL Format for Seed Images
**Source:** `elvora_updated-3.html` lines 1903–1910 (lookbook gallery)

```
https://images.unsplash.com/photo-{id}?w=800&q=80
```

Sizes used in prototype: `w=1000` (hero/full-width), `w=700` (large panels), `w=500` (medium cards), `w=400` (small cards). Seed SQL must follow this format. No other image host.

---

## Pattern Assignments

### `index.html` through `admin.html` (page shells)

Phase 1 creates empty shells only — no page content, no Alpine directives. Each shell follows the boilerplate above with correct `<title>` and a single `<main>` placeholder.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ELVORA — [Page Name]</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,500;0,700;1,400;1,500&family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
</head>
<body>
  <main><!-- Phase [X] fills this --></main>
  <script type="module" src="/js/supabase.js"></script>
</body>
</html>
```

---

### `js/supabase.js` (service, request-response)

No codebase analog. Pattern: initialize Supabase client once from env vars, export the singleton. All other JS modules import `supabase` from this file — never re-initialize.

```js
// js/supabase.js
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = import.meta.env?.VITE_SUPABASE_URL ?? window.__ENV?.SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env?.VITE_SUPABASE_ANON_KEY ?? window.__ENV?.SUPABASE_ANON_KEY;

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

Phase 1 stub: populate with real values from `.env`. The `service_role` key must never appear here.

---

### `js/auth.js`, `js/cart.js`, `js/products.js`, `js/style-match.js`, `js/admin.js` (stubs)

Phase 1 creates stub files only — exported functions with `// TODO: Phase X` comments. Each imports `supabase` from `./supabase.js`.

```js
// js/auth.js (stub)
import { supabase } from './supabase.js';

export async function signIn(email, password) {
  // TODO: Phase 4
}

export async function signOut() {
  // TODO: Phase 4
}
```

Same stub pattern for all other JS modules.

---

### `src/input.css` (config, transform)

Tailwind v4 source file. Must declare CSS custom properties in `:root` from the prototype tokens, then use `@theme` for Tailwind to reference them.

```css
/* src/input.css */
@import "tailwindcss";

@theme {
  --color-sage: #A8BFA3;
  --color-rose: #D8A7A7;
  --color-beige: #F5F1ED;
  --color-charcoal: #2E2E2E;
  --color-lavender: #C6B7E2;
  --color-sage-light: #E8F0E6;
  --color-rose-light: #F5E8E8;
  --color-text-muted: #8A8A8A;

  --font-display: 'Playfair Display', serif;
  --font-body: 'Poppins', sans-serif;
}

:root {
  /* Mirror as native CSS custom properties for non-Tailwind CSS */
  --sage: #A8BFA3;
  --rose: #D8A7A7;
  --beige: #F5F1ED;
  --charcoal: #2E2E2E;
  --lavender: #C6B7E2;
  --sage-light: #E8F0E6;
  --rose-light: #F5E8E8;
  --text-muted: #8A8A8A;
}

body {
  font-family: var(--font-body);
  background-color: var(--beige);
  color: var(--charcoal);
  overflow-x: hidden;
}
```

---

### `supabase/migrations/*.sql` (migration, CRUD)

No codebase analog. Schema covers 16 tables per F-046. Pattern for every table:

```sql
-- supabase/migrations/001_initial_schema.sql
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  category text not null,
  base_price numeric(10,2) not null,
  created_at timestamptz default now()
);

-- RLS: enable on every table immediately after creation
alter table products enable row level security;

-- Public read policy (products are browsable by anyone)
create policy "products_public_read" on products
  for select using (true);
```

The `is_admin()` helper function (required by F-047) must be defined before any admin-only policies:

```sql
create or replace function is_admin()
returns boolean
language sql security definer
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
$$;
```

---

### `supabase/seed.sql` (utility, batch)

No codebase analog. Seed must insert 20+ products with realistic premium names, fabric descriptions, and GBP price points (£65–£145). All images reference Unsplash CDN URLs in the format `https://images.unsplash.com/photo-{id}?w=800&q=80`.

Example row pattern:
```sql
insert into products (name, slug, description, category, base_price) values
('Serenity Ribbed Legging', 'serenity-ribbed-legging',
 '78% recycled nylon, 22% elastane. High-rise, four-way stretch, squat-proof.',
 'leggings', 85.00);
```

Product categories to cover (6 types per F-050): `leggings`, `sports-bra`, `top`, `jacket`, `shorts`, `set`.
Colour variants per F-050: minimum 2 colours per product (`Sage`, `Ivory`, `Chalk`, `Forest`, `Slate`, `Rose`).

---

### `supabase/functions/style-match/index.ts` (middleware, request-response)

No codebase analog. Deno runtime. Phase 1 stub pattern per D-12 through D-15:

```typescript
// supabase/functions/style-match/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "https://elvora.netlify.app",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // JWT verification
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401, headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  // Parse and log request shape
  const body = await req.json();
  // Expected: { photo_url: string, preferences: { activity, fit, aesthetic, colour } }
  console.log("style-match request:", JSON.stringify(body));

  // Mock response — Phase 5 replaces only this block
  const mockResponse = {
    recommendations: [
      {
        name: "Mock Outfit 1",
        product_ids: ["seed-product-id-1", "seed-product-id-2"],
        colour_guidance: "Earthy tones complement your natural colouring — lean into sage and ivory.",
      },
    ],
  };

  return new Response(JSON.stringify(mockResponse), {
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
});
```

CORS origin is locked to `https://elvora.netlify.app` per D-15. Phase 5 replaces only the mock block — all surrounding infrastructure stays identical.

---

### `.env.example` (config)

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
# NEVER add SERVICE_ROLE_KEY here
```

`.env` is gitignored. `.env.example` is committed.

---

### `netlify.toml` (config)

```toml
[build]
  command = "npx @tailwindcss/cli@next -i src/input.css -o css/style.css --minify"
  publish = "."

[build.environment]
  NODE_VERSION = "20"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

### `.github/workflows/keepalive.yml` (config)

GitHub Actions cron pinging Supabase `/auth/v1/health` to prevent free-tier project pausing (F-051):

```yaml
name: Supabase Keep-Alive
on:
  schedule:
    - cron: '0 8 * * 1'  # Every Monday 08:00 UTC
jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Supabase health
        run: curl -f "${{ secrets.SUPABASE_URL }}/auth/v1/health"
```

---

## Shared Patterns

### No Inline JS Rule (NF-006)
**Apply to:** All HTML files
All JavaScript goes in `js/*.js` ES module files. HTML pages load them via `<script type="module" src="/js/filename.js">` at the bottom of `<body>`. No `<script>` tags with inline code. No `onclick=""` attributes.

### Environment Variable Access
**Apply to:** `js/supabase.js`, `netlify.toml`, `.env.example`
- Browser JS reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` only (never `SERVICE_ROLE_KEY`)
- Netlify platform env vars are the source of truth for deployment
- Local `.env` provides values for development; `.env.example` documents the shape

### RLS on Every Table
**Apply to:** All `supabase/migrations/*.sql`
Every `create table` statement is immediately followed by `alter table X enable row level security`. No table is left with RLS disabled.

### Hover Colour Convention
**Apply to:** All HTML/CSS across the project
Interactive element hover states use `var(--rose)` for colour transitions (links, buttons, icons). The prototype establishes this at lines 67, 78, 137, 147, 260.

---

## No Analog Found

All files in this phase are new with no codebase analog. The prototype `elvora_updated-3.html` provides visual direction for HTML shells and CSS tokens but is not copied as production code.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| All 21 files | various | various | Greenfield — no prior source files exist |

---

## Metadata

**Analog search scope:** project root (single prototype file)
**Files scanned:** 1 (`elvora_updated-3.html`, ~2000+ lines)
**Pattern extraction date:** 2026-06-10
