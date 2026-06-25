---
phase: quick
plan: 260613-vot
type: execute
wave: 1
depends_on: []
files_modified:
  - index.html
  - lookbook.html
  - js/components.js
  - supabase/seed.sql
autonomous: true
requirements: [QUICK-VOT-RUNNING]
must_haves:
  truths:
    - "Running appears as a named category in the homepage 'Shop by Category' grid"
    - "The three sub-categories Run Era, Pace Mode, Runner's High are visible under the Running card"
    - "Running links appear in the footer SHOP column in components.js"
    - "The lookbook 'The Power Run' label is updated to align with the Running sub-category identity"
    - "seed.sql includes three named Running collections (Run Era, Pace Mode, Runner's High) for Phase 03 use"
  artifacts:
    - path: "index.html"
      provides: "Running category card with sub-category names in Shop by Category section"
    - path: "lookbook.html"
      provides: "Running-aligned gallery label (Run Era)"
    - path: "js/components.js"
      provides: "Running sub-category links in footer SHOP column"
    - path: "supabase/seed.sql"
      provides: "Three Running sub-category collections seeded"
  key_links:
    - from: "index.html Running card"
      to: "/shop.html?collection=run-era (etc)"
      via: "href on cat-card anchor"
      pattern: "shop\\.html\\?collection=run-era"
---

<objective>
Add the Running category with three named sub-categories — Run Era, Pace Mode, Runner's High — across all current UI surfaces (homepage category grid, lookbook gallery labels, footer nav links) and seed data (collections table).

Purpose: Phase 03 (Product Catalog PLP + PDP) will use collection slugs to filter products. Establishing the three Running sub-collections now means the seed data and UI labels are consistent before PLP filtering is built.

Output: Updated index.html, lookbook.html, js/components.js, supabase/seed.sql — all reflecting the Running category structure with named sub-categories.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add Running category card to homepage + update footer nav links</name>
  <files>index.html, js/components.js</files>
  <action>
    In index.html, add a Running category card to the "Shop by Category" grid (the `.categories-grid` div, lines ~77–129). The card should:
    - Use `href="/shop.html?category=running"` on the anchor element with class `cat-card medium`
    - Use a running-appropriate Unsplash image: `https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=400&q=80` (alt="Running")
    - Display cat-icon `🏃` (no emoji if it looks off-brand; use an SVG or leave blank — keep it clean)
    - Show cat-name "Running" and cat-count "21 styles"
    - Below the cat-name, add a sub-categories hint line using a small `<div class="cat-subs">` element with text "Run Era · Pace Mode · Runner's High" — style it inline as `style="font-size:10px;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,0.6);margin-top:4px;"` so it sits beneath the cat-name without requiring new CSS classes
    - Insert the new card after the existing Wellness card (so order is Padel, Pilates, Tennis, Training, Wellness, Running)

    In js/components.js, inside the footer `<!-- Shop links -->` column (lines ~163–173), add three Running sub-category links after the Sport Hijab `</li>` and before the closing `</ul>`:
    ```
    <li><a href="/shop.html?collection=run-era" ...>Run Era</a></li>
    <li><a href="/shop.html?collection=pace-mode" ...>Pace Mode</a></li>
    <li><a href="/shop.html?collection=runners-high" ...>Runner's High</a></li>
    ```
    Apply the same Tailwind classes as existing footer links: `class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline"`.

    Do NOT add fenced code blocks to this action. The implementation above describes the identifiers, classes, href patterns, and content to use.
  </action>
  <verify>
    <automated>grep -c "collection=run-era" /Users/andika/Desktop/Elvora/index.html /Users/andika/Desktop/Elvora/js/components.js || true</automated>
  </verify>
  <done>
    index.html has a Running cat-card with "Run Era · Pace Mode · Runner's High" sub-text visible beneath the cat-name. js/components.js footer SHOP column has three new links: Run Era, Pace Mode, Runner's High pointing to collection slugs run-era, pace-mode, runners-high.
  </done>
</task>

<task type="auto">
  <name>Task 2: Update lookbook label + seed Running collections</name>
  <files>lookbook.html, supabase/seed.sql</files>
  <action>
    In lookbook.html, the gallery item at lines ~54–57 has label "The Power Run" — update its `gallery-label` span text to "Run Era" to align it with the first named Running sub-category. This is the large `span-6` hero gallery item using a running/athletic image, so the label change is natural. Leave all other gallery labels unchanged.

    In supabase/seed.sql, inside the SECTION 2: COLLECTIONS INSERT block (lines ~22–28), append three new collection rows for the Running sub-categories. Use sequential `display_order` values starting after the existing max (current max is 6 for 'core-range'). The rows to add:

    - id: `b1000000-0000-0000-0000-000000000007`, name: `Run Era`, slug: `run-era`, description: `High-performance running pieces for the dedicated pavement runner`, is_featured: true, display_order: 7
    - id: `b1000000-0000-0000-0000-000000000008`, name: `Pace Mode`, slug: `pace-mode`, description: `Speed-focused activewear engineered for interval and track training`, is_featured: false, display_order: 8
    - id: `b1000000-0000-0000-0000-000000000009`, name: `Runner's High`, slug: `runners-high`, description: `The post-run glow — recovery and casual styles for the running lifestyle`, is_featured: false, display_order: 9

    Also update the schema comment at line 72 of supabase/migrations/001_schema.sql from:
    `-- Product categories (Padel, Pilates, Tennis, Training, Running, Wellness).`
    to:
    `-- Product categories (Padel, Pilates, Tennis, Training, Running [Run Era · Pace Mode · Runner's High], Wellness).`

    Note: The seed.sql INSERT for collections uses this exact column order: `(id, name, slug, description, is_featured, display_order)` — confirm by reading line 22 before writing. Do not add extra columns. Each new row must end with a comma if more rows follow, or a semicolon to close the VALUES block. The existing closing `;` on the INSERT must move to after the last new row.
  </action>
  <verify>
    <automated>grep -c "run-era\|pace-mode\|runners-high\|Runner's High" /Users/andika/Desktop/Elvora/supabase/seed.sql /Users/andika/Desktop/Elvora/lookbook.html || true</automated>
  </verify>
  <done>
    lookbook.html gallery item span-6 shows label "Run Era" instead of "The Power Run". seed.sql collections INSERT has three new rows with slugs run-era, pace-mode, runners-high and display_order 7, 8, 9. The seed.sql INSERT statement is syntactically valid (no duplicate semicolons, all rows comma-separated). schema comment updated.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Static HTML → shop.html | category/collection query params are not executed server-side; no injection risk in Phase 02 static shell |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-vot-01 | Tampering | seed.sql collections INSERT | accept | Seed SQL runs in Supabase SQL Editor under developer auth — no untrusted input path |
| T-vot-SC | Tampering | npm/pip/cargo installs | accept | No package installs in this task — HTML/SQL edits only |
</threat_model>

<verification>
After both tasks complete:
1. Open index.html in browser — "Shop by Category" section shows a Running card with "Run Era · Pace Mode · Runner's High" sub-text beneath "Running"
2. Scroll to footer — SHOP column shows Run Era, Pace Mode, Runner's High links
3. Open lookbook.html — the large span-6 gallery item shows "Run Era" label
4. Inspect supabase/seed.sql — collections block has rows 7, 8, 9 for run-era, pace-mode, runners-high
</verification>

<success_criteria>
- Running category card visible in homepage grid with all three sub-category names in one subtitle line
- Footer nav in every page (via components.js) shows Run Era, Pace Mode, Runner's High under SHOP
- Lookbook Power Run editorial renamed to "Run Era" — consistent with seed collection name
- seed.sql ready to re-apply when Phase 03 PLP needs collection-based filtering
- No other categories modified, no layout broken, no new CSS classes required
</success_criteria>

<output>
Create `.planning/quick/260613-vot-update-running-category-sub-categories-t/260613-vot-SUMMARY.md` when done.
</output>
