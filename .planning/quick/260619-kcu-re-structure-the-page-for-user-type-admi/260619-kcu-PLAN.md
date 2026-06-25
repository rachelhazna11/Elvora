---
phase: quick
plan: 260619-kcu
type: execute
wave: 1
depends_on: []
files_modified:
  - js/admin-redirect.js
  - index.html
  - shop.html
  - product.html
  - cart.html
  - checkout.html
  - account.html
  - about.html
  - contact.html
  - lookbook.html
  - style-match.html
  - setup-profile.html
  - auth.html
autonomous: true
requirements:
  - admin-redirect
must_haves:
  truths:
    - "Admin user visiting any storefront page is redirected to admin.html before the page renders"
    - "Non-admin users (shoppers) and guests see no change in behavior"
    - "No flash of storefront content before redirect fires"
  artifacts:
    - path: "js/admin-redirect.js"
      provides: "Early admin role check and redirect logic"
  key_links:
    - from: "js/admin-redirect.js"
      to: "admin.html"
      via: "window.location.replace('/admin.html') when app_metadata.role === 'admin'"
---

<objective>
Add early admin redirect to all storefront pages. When an admin user loads any storefront page, they are redirected to admin.html before Alpine initializes and before any storefront content renders.

Purpose: Admins have no need for the shopper UI — redirect them immediately to the admin panel. Shoppers and guests are unaffected.
Output: js/admin-redirect.js (new shared module) + one-line script tag added to all 12 storefront HTML pages.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md

Key decisions in effect:
- Admin role stored in JWT app_metadata: `app_metadata.role === 'admin'`
- Supabase JS SDK loaded via CDN ESM singleton at js/supabase.js
- `window.supabase` is exposed by components.js (loaded later), so admin-redirect.js must import supabase.js directly
- components.js is loaded on every storefront page as a type="module" script at end of body
- admin.html must NOT include this redirect (would create infinite loop)
- auth.html must NOT include this redirect (admin needs to be able to log in)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create js/admin-redirect.js</name>
  <files>js/admin-redirect.js</files>
  <action>
Create a new ES module at js/admin-redirect.js. This file imports the supabase singleton from ./supabase.js, calls supabase.auth.getUser() once, and if the returned user has app_metadata.role === 'admin' it calls window.location.replace('/admin.html') and returns early. If the user is not an admin or is not logged in, the module does nothing.

Implementation shape:

```
import { supabase } from './supabase.js';

(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user?.app_metadata?.role === 'admin') {
    window.location.replace('/admin.html');
  }
})();
```

Use window.location.replace (not href assignment) so the storefront page is removed from browser history — admins cannot press Back to reach it. No exports needed. Keep the file under 20 lines.

Do NOT import from components.js or auth.js — those modules have side effects (Alpine store registration, cart loading) that must not run during the redirect path. Import only from supabase.js.
  </action>
  <verify>
    <automated>node -e "const fs = require('fs'); const src = fs.readFileSync('js/admin-redirect.js','utf8'); if (!src.includes('supabase.auth.getUser')) throw new Error('missing getUser'); if (!src.includes('app_metadata')) throw new Error('missing app_metadata check'); if (!src.includes('location.replace')) throw new Error('missing replace'); console.log('admin-redirect.js OK');"</automated>
  </verify>
  <done>js/admin-redirect.js exists, imports supabase, calls getUser, checks app_metadata.role === 'admin', and calls window.location.replace('/admin.html') on match.</done>
</task>

<task type="auto">
  <name>Task 2: Add admin-redirect.js script tag to all storefront pages</name>
  <files>index.html, shop.html, product.html, cart.html, checkout.html, account.html, about.html, contact.html, lookbook.html, style-match.html, setup-profile.html</files>
  <action>
In each of the 11 storefront HTML pages listed, add the following script tag in the &lt;head&gt; section, AFTER the /js/__env.js script tag and AFTER /js/supabase.js script tag (which must already be present), but BEFORE the Alpine.js CDN script tag:

    &lt;script type="module" src="/js/admin-redirect.js"&gt;&lt;/script&gt;

Placement rationale: It must run as early as possible. Placing it in &lt;head&gt; before Alpine (which is deferred) means the async getUser() call begins as soon as the HTML is parsed, before Alpine processes any x-data attributes. The module import of supabase.js resolves from browser cache (already loaded by the preceding script tag).

EXCLUDE admin.html from this change — adding it there would create an infinite redirect loop.
EXCLUDE auth.html from this change — admins need to reach the login page.

For each file, find the existing line:
    &lt;script type="module" src="/js/supabase.js"&gt;&lt;/script&gt;
and add the new script tag on the line immediately after it.

Do not modify any other content in these files.
  </action>
  <verify>
    <automated>for f in index.html shop.html product.html cart.html checkout.html account.html about.html contact.html lookbook.html style-match.html setup-profile.html; do grep -q 'admin-redirect.js' "$f" && echo "$f OK" || echo "$f MISSING"; done</automated>
  </verify>
  <done>All 11 storefront HTML files contain the admin-redirect.js script tag in head. admin.html and auth.html do not contain it.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| browser → Supabase Auth | getUser() call verifies JWT server-side; cannot be spoofed by client |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-qk-kcu-01 | Elevation of Privilege | admin-redirect.js role check | mitigate | Role read from server-verified JWT app_metadata via supabase.auth.getUser() — not from localStorage or a client-writable field |
| T-qk-kcu-02 | Tampering | Browser history / Back button | mitigate | window.location.replace() removes storefront page from history stack |
| T-qk-kcu-03 | Denial of Service | Redirect loop | accept | admin.html and auth.html explicitly excluded from receiving the script tag |
</threat_model>

<verification>
Manual smoke test after execution:
1. Log in as admin user → navigate to index.html → confirm instant redirect to admin.html
2. Log in as regular shopper → navigate to index.html → confirm no redirect
3. Visit index.html as guest (no session) → confirm no redirect
4. Confirm admin.html does NOT have admin-redirect.js script tag (would loop)
5. Confirm auth.html does NOT have admin-redirect.js script tag
</verification>

<success_criteria>
- js/admin-redirect.js created with getUser() check and location.replace() redirect
- All 11 storefront pages have the script tag in head
- admin.html and auth.html excluded
- Redirect fires before Alpine renders any storefront content
</success_criteria>

<output>
Create `.planning/quick/260619-kcu-re-structure-the-page-for-user-type-admi/260619-kcu-SUMMARY.md` when done.
</output>
