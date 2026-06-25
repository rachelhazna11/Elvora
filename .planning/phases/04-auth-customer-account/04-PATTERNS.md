# Phase 4: Auth + Customer Account — Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 7
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `js/auth.js` | service | request-response | `js/products.js` | role-match |
| `js/components.js` (extend) | provider/store | event-driven | `js/cart.js` + existing `components.js` | exact |
| `auth.html` | component/page | request-response | `product.html` (x-data + init pattern) | role-match |
| `account.html` | component/page | CRUD | `product.html` (x-data + init + x-show tabs) | role-match |
| `shop.html` (extend wishlist) | component | CRUD | `product.html` (addToCart + Toastify pattern) | exact |
| `product.html` (extend wishlist) | component | CRUD | `product.html` line 190 (Toastify + Alpine state) | exact |
| `src/input.css` (extend) | config/style | — | `src/input.css` bottom sections (Phase 3 component classes) | exact |

---

## Pattern Assignments

### `js/auth.js` (service, request-response)

**Analog:** `js/products.js` — Supabase client call pattern, ES module export style.

**Imports pattern** (`js/products.js` lines 1–3):
```js
// js/products.js
import { supabase } from './supabase.js';
```

**Core Supabase call pattern** (`js/products.js` lines 87–105):
```js
export async function getProduct(slug) {
  const { data, error } = await supabase
    .from('products')
    .select(`id, name, slug, ...`)
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (error || !data) return null;
  return data;
}
```

**Auth-specific implementation** — for each stub:

```js
// signUp
export async function signUp(email, password, firstName, lastName) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { first_name: firstName, last_name: lastName } },
  });
  if (error) throw error;
  // Insert into user_profiles after signup
  if (data.user) {
    await supabase.from('user_profiles').insert({
      user_id: data.user.id,
      first_name: firstName,
      last_name: lastName,
      email,
    });
  }
  return data;
}

// signIn
export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

// signOut
export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

// getUser
export async function getUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

// onAuthChange — synchronous, returns unsubscribe handle
export function onAuthChange(callback) {
  const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
    callback(session?.user ?? null);
  });
  return subscription;
}
```

**Window exposure pattern** (`js/products.js` lines 133–138 — expose to Alpine inline x-data):
```js
window.getProducts    = getProducts;
window.searchProducts = searchProducts;
```
Apply same to `auth.js`:
```js
// Expose for Alpine inline expressions (signOut called from nav dropdown)
window.elvoraSignOut = signOut;
```

---

### `js/components.js` — Auth State Extension (provider, event-driven)

**Analog:** `js/cart.js` (Alpine.store init + event-driven subscription pattern) + existing `js/components.js` (store registration at lines 14–22).

**Existing store registration pattern** (`js/components.js` lines 14–22):
```js
function registerStores() {
  if (!Alpine.store('cart')) Alpine.store('cart', { count: 0, items: [] });
  if (!Alpine.store('auth')) Alpine.store('auth', { user: null, loggedIn: false });
}
document.addEventListener('alpine:init', registerStores);
if (window.Alpine) registerStores();
```

**Cart store init pattern for reference** (`js/cart.js` lines 23–72):
```js
function initCartStore() {
  if (!window.Alpine) return;
  Alpine.store('cart', {
    items: savedItems,
    get count() { return this.items.reduce((n, i) => n + i.qty, 0); },
    add({ ... }) { ... saveToStorage(this.items); },
  });
}
document.addEventListener('alpine:init', initCartStore);
if (window.Alpine) initCartStore();
```

**Auth initialization to add** — add after the existing `registerStores` block in `components.js`:
```js
import { getUser, onAuthChange } from './auth.js';

async function initAuth() {
  // Populate store from current session
  const user = await getUser();
  Alpine.store('auth').user = user;
  Alpine.store('auth').loggedIn = !!user;

  // Keep in sync on tab/token changes
  onAuthChange((user) => {
    Alpine.store('auth').user = user;
    Alpine.store('auth').loggedIn = !!user;
  });
}

// Call after stores are registered
document.addEventListener('alpine:init', () => { registerStores(); initAuth(); });
if (window.Alpine) { registerStores(); initAuth(); }
```

**Nav logged-in dropdown HTML to inject** — replaces the static account link at `components.js` lines 130–134. Pattern follows the existing search dropdown (`x-show`, `@click.outside`, `position: absolute`):
```html
<!-- User account — guest state -->
<a x-show="!$store.auth.loggedIn" href="/auth.html" ...>
  <svg ...person icon...</svg>
</a>

<!-- User account — logged-in state -->
<div x-show="$store.auth.loggedIn" class="relative" @click.outside="userDropOpen = false" style="display:none;">
  <button @click="userDropOpen = !userDropOpen" class="nav-user-trigger" :aria-expanded="userDropOpen">
    <svg ...person icon...</svg>
    <span class="nav-user-name" x-text="$store.auth.user?.user_metadata?.first_name || 'Account'"></span>
  </button>
  <div x-show="userDropOpen" class="nav-dropdown" style="display:none;">
    <a href="/account.html" class="nav-dropdown-item">My Account</a>
    <a href="/account.html#wishlist" class="nav-dropdown-item">Wishlist</a>
    <div class="nav-dropdown-divider"></div>
    <button @click="window.elvoraSignOut().then(() => { $store.auth.user = null; $store.auth.loggedIn = false; window.location.href='/index.html'; })" class="nav-dropdown-item danger">Sign Out</button>
  </div>
</div>
```
Add `userDropOpen: false` to the nav `x-data` object at `components.js` line 29.

---

### `auth.html` (component/page, request-response)

**Analog:** `product.html` — Alpine `x-data` with `async init()`, URL param reading, `x-show` panels, Toastify on success, inline error handling.

**Alpine x-data + init() pattern** (`product.html` lines 20–64):
```js
// product.html <main x-data="{ ... async init() { ... } }">
async init() {
  const slug = new URLSearchParams(window.location.search).get('slug');
  if (!slug) { window.location.href = '/shop.html'; return; }
  const data = await window.getProduct(slug);
  if (!data) { window.location.href = '/shop.html'; return; }
  this.product = data;
  this.loading = false;
},
```

**auth.html x-data to implement** (same pattern, URL param → tab selection):
```js
x-data="{
  tab: 'signin',
  loading: false,
  error: '',

  // Sign In form fields
  siEmail: '', siPassword: '',

  // Sign Up form fields
  suFirst: '', suLast: '', suEmail: '', suPassword: '', suConfirm: '',

  async init() {
    const tab = new URLSearchParams(location.search).get('tab');
    if (tab === 'signup') this.tab = 'signup';
    // Redirect if already logged in
    const user = await window.supabase.auth.getUser();
    if (user?.data?.user) window.location.href = '/account.html';
  },

  async handleSignIn() {
    this.loading = true; this.error = '';
    try {
      await window.signIn(this.siEmail, this.siPassword);
      window.location.href = '/account.html';
    } catch (e) {
      this.error = 'Incorrect email or password. Please try again.';
    } finally { this.loading = false; }
  },

  async handleSignUp() {
    if (this.suPassword !== this.suConfirm) { this.error = 'Passwords do not match.'; return; }
    if (this.suPassword.length < 8) { this.error = 'Password must be at least 8 characters.'; return; }
    this.loading = true; this.error = '';
    try {
      await window.signUp(this.suEmail, this.suPassword, this.suFirst, this.suLast);
      Toastify({
        text: 'Welcome to Elvora, ' + this.suFirst + '!',
        duration: 2000,
        gravity: 'bottom', position: 'right',
        style: { background: 'var(--sage)', color: '#fff', borderRadius: '50px', fontSize: '12px', letterSpacing: '2px' },
      }).showToast();
      setTimeout(() => { window.location.href = '/account.html'; }, 2000);
    } catch (e) {
      this.error = e.message?.includes('already') ? 'An account with this email already exists.' : e.message;
    } finally { this.loading = false; }
  },
}"
```

**x-show tab toggle pattern** (same as `x-show` usage throughout `product.html`):
```html
<!-- Tab buttons -->
<button @click="tab = 'signin'" :class="tab === 'signin' ? 'active' : ''" class="auth-tab">Sign In</button>
<button @click="tab = 'signup'" :class="tab === 'signup' ? 'active' : ''" class="auth-tab">Create Account</button>

<!-- Form panels -->
<div x-show="tab === 'signin'" x-transition:enter="transition-opacity duration-150">
  ...sign in form...
</div>
<div x-show="tab === 'signup'" x-transition:enter="transition-opacity duration-150" style="display:none;">
  ...create account form...
</div>
```

**Form HTML pattern** — reuses `.form-group`, `.form-label`, `.form-input`, `.form-submit` from `src/input.css` lines 643–662:
```html
<div class="form-group">
  <label class="form-label" for="si-email">Email Address</label>
  <input class="form-input" type="email" id="si-email" x-model="siEmail" placeholder="your@email.com" required>
</div>
<button class="form-submit auth-submit" @click.prevent="handleSignIn()" :disabled="loading" x-text="loading ? 'Signing In…' : 'Sign In'"></button>
<p x-show="error" x-text="error" role="alert" style="color:var(--rose);font-size:14px;margin-top:8px;display:none;"></p>
```

---

### `account.html` (component/page, CRUD)

**Analog:** `product.html` — multi-panel `x-data` with `async init()`, multiple async data loads in `Promise.all`, `x-show` for panel switching.

**Multi-load init pattern** (`product.html` lines 58–63):
```js
await Promise.all([
  this.loadAggregateRating(),
  this.loadPairings(),
  this.loadRelated(),
  this.loadReviews(),
]);
```

**account.html x-data structure:**
```js
x-data="{
  activeTab: 'profile',
  loading: true,

  // Profile
  profile: { first_name: '', last_name: '', email: '' },
  profileLoading: false,

  // Wishlist
  wishlistItems: [],
  wishlistLoading: false,

  // Preferences
  prefs: { activity: null, fit: null, aesthetic: null, colour: null },
  prefsLoading: false,

  async init() {
    // Redirect if not logged in
    const { data: { user } } = await window.supabase.auth.getUser();
    if (!user) { window.location.href = '/auth.html?tab=signin'; return; }

    // Set tab from hash
    const hash = location.hash.replace('#', '');
    if (['profile', 'wishlist', 'preferences'].includes(hash)) this.activeTab = hash;

    this.loading = false;
    await Promise.all([
      this.loadProfile(user),
      this.loadWishlist(user),
    ]);
  },

  async loadProfile(user) {
    const { data } = await window.supabase
      .from('user_profiles')
      .select('first_name, last_name, preferred_activity, fit_preference, style_aesthetic, colour_preference')
      .eq('user_id', user.id)
      .single();
    if (data) {
      this.profile = { first_name: data.first_name || '', last_name: data.last_name || '', email: user.email };
      this.prefs = { activity: data.preferred_activity, fit: data.fit_preference, aesthetic: data.style_aesthetic, colour: data.colour_preference };
    }
  },

  async loadWishlist(user) {
    this.wishlistLoading = true;
    const { data } = await window.supabase
      .from('wishlist_items')
      .select('id, product_id, products(id, name, slug, base_price, product_images(url, alt_text, display_order))')
      .eq('user_id', user.id);
    this.wishlistItems = (data || []).map(row => ({
      wishlistId: row.id,
      ...row.products,
      image: row.products?.product_images?.[0]?.url,
    }));
    this.wishlistLoading = false;
  },

  setTab(tab) {
    this.activeTab = tab;
    location.hash = tab;
  },
}"
```

**Sidebar tab HTML pattern** (modelled on x-show in `product.html` accordion tabs):
```html
<nav class="account-nav" role="navigation" aria-label="Account navigation">
  <button @click="setTab('profile')" class="account-nav-item" :class="{ 'active': activeTab === 'profile' }" :aria-current="activeTab === 'profile' ? 'page' : false">Profile</button>
  <button @click="setTab('wishlist')" class="account-nav-item" :class="{ 'active': activeTab === 'wishlist' }">Wishlist</button>
  <button @click="setTab('preferences')" class="account-nav-item" :class="{ 'active': activeTab === 'preferences' }">Style Preferences</button>
</nav>

<!-- Content panels -->
<div x-show="activeTab === 'profile'" class="account-section">...</div>
<div x-show="activeTab === 'wishlist'" class="account-section" style="display:none;">...</div>
<div x-show="activeTab === 'preferences'" class="account-section" style="display:none;">...</div>
```

---

### `shop.html` and `product.html` — Wishlist Heart Toggle (component extension, CRUD)

**Analog:** `product.html` lines 180–202 — Toastify + Alpine state mutation pattern. The add-to-cart pattern is the closest exact match for optimistic toggle.

**Toastify call pattern to copy** (`product.html` lines 190–202):
```js
Toastify({
  text: 'Added to Bag',
  duration: 2500,
  gravity: 'bottom',
  position: 'right',
  style: {
    background: 'var(--charcoal)',
    color: '#ffffff',
    borderRadius: '50px',
    fontSize: '12px',
    letterSpacing: '2px',
  },
}).showToast();
```

**Wishlist toggle Alpine pattern to add to each product card x-data:**
```js
// Add to existing shop.html x-data or product card template
wishlistedIds: new Set(),

async initWishlist() {
  const { data: { user } } = await window.supabase.auth.getUser();
  if (!user) return;
  const { data } = await window.supabase
    .from('wishlist_items')
    .select('product_id')
    .eq('user_id', user.id);
  this.wishlistedIds = new Set((data || []).map(r => r.product_id));
},

async toggleWishlist(productId) {
  const { data: { user } } = await window.supabase.auth.getUser();

  // Guest: toast + redirect
  if (!user) {
    Toastify({
      text: 'Sign in to save items to your wishlist',
      duration: 3000,
      gravity: 'bottom', position: 'right',
      style: { background: 'var(--charcoal)', color: '#fff', borderRadius: '50px', fontSize: '12px', letterSpacing: '2px' },
      onClick() { window.location.href = '/auth.html?tab=signin'; },
    }).showToast();
    setTimeout(() => { window.location.href = '/auth.html?tab=signin'; }, 2000);
    return;
  }

  // Optimistic toggle
  const wasWishlisted = this.wishlistedIds.has(productId);
  if (wasWishlisted) {
    this.wishlistedIds.delete(productId);
    this.wishlistedIds = new Set(this.wishlistedIds); // trigger Alpine reactivity
    const { error } = await window.supabase
      .from('wishlist_items')
      .delete()
      .eq('user_id', user.id)
      .eq('product_id', productId);
    if (error) {
      this.wishlistedIds.add(productId);
      this.wishlistedIds = new Set(this.wishlistedIds);
      Toastify({ text: 'Couldn\'t save item — try again', duration: 3000, gravity: 'bottom', position: 'right',
        style: { background: 'var(--rose)', color: '#fff', borderRadius: '50px', fontSize: '12px', letterSpacing: '2px' } }).showToast();
    }
  } else {
    this.wishlistedIds.add(productId);
    this.wishlistedIds = new Set(this.wishlistedIds);
    const { error } = await window.supabase
      .from('wishlist_items')
      .insert({ user_id: user.id, product_id: productId });
    if (error) {
      this.wishlistedIds.delete(productId);
      this.wishlistedIds = new Set(this.wishlistedIds);
      Toastify({ text: 'Couldn\'t save item — try again', duration: 3000, gravity: 'bottom', position: 'right',
        style: { background: 'var(--rose)', color: '#fff', borderRadius: '50px', fontSize: '12px', letterSpacing: '2px' } }).showToast();
    }
  }
},
```

**Heart button HTML** — replaces static `@click.prevent` at `product.html` line 458:
```html
<button
  class="wishlist-btn"
  :class="{ 'active': wishlistedIds.has(product.id) }"
  @click.prevent="toggleWishlist(product.id)"
  :aria-label="wishlistedIds.has(product.id) ? 'Remove from wishlist' : 'Add to wishlist'"
  :aria-pressed="wishlistedIds.has(product.id)"
>
  <span x-text="wishlistedIds.has(product.id) ? '♥' : '♡'"></span>
</button>
```

**Wishlist btn active state** — add to `src/input.css` (`.wishlist-btn` already at line 683):
```css
.wishlist-btn.active { background: var(--rose); color: white; }
```

---

### `src/input.css` — Phase 4 Component Classes (config/style)

**Analog:** Existing `@layer components` block at `src/input.css` lines 39–89. Same pattern: class name + inline CSS properties on one line per property.

**Existing pattern to copy** (`src/input.css` lines 643–662):
```css
.form-group { margin-bottom: 20px; }
.form-label {
  display: block; font-size: 11px; letter-spacing: 2px;
  text-transform: uppercase; color: var(--text-muted); margin-bottom: 8px; font-weight: 500;
}
.form-input {
  width: 100%; padding: 14px 20px;
  border: 1.5px solid rgba(46,46,46,0.15); border-radius: 12px;
  font-size: 14px; font-family: var(--font-body); color: var(--charcoal);
  background: var(--beige); outline: none; transition: border-color 0.2s;
}
.form-input:focus { border-color: var(--sage); }
.form-submit {
  width: 100%; background: var(--charcoal); color: white;
  border: none; border-radius: 50px; padding: 16px;
  font-size: 12px; letter-spacing: 3px; text-transform: uppercase;
  font-weight: 500; cursor: pointer; transition: background 0.2s; font-family: var(--font-body);
}
```

**Add at bottom of `src/input.css` under:**
```css
/* ─── Auth + Account — Phase 4 ─────────────────────────────────────────── */
```

All class definitions verbatim from `04-UI-SPEC.md` Component Inventory section (auth, account, profile, wishlist, preferences, nav dropdown). No new CSS variables — all values reference existing `:root` tokens.

---

## Shared Patterns

### Alpine Store Access
**Source:** `js/components.js` lines 14–22
**Apply to:** All pages that read auth state
```js
// Read auth state in Alpine x-data or HTML attributes
$store.auth.loggedIn   // boolean
$store.auth.user       // Supabase user object | null
$store.auth.user?.user_metadata?.first_name
```

### Supabase Client in HTML
**Source:** `js/components.js` line 8
**Apply to:** All inline Alpine x-data that call Supabase
```js
window.supabase = supabase; // already in components.js — use window.supabase in x-data strings
```

### Toastify Call Template
**Source:** `product.html` lines 190–202
**Apply to:** `auth.html` (success), `account.html` (save success/error), `shop.html`/`product.html` (wishlist guest + error)
```js
Toastify({
  text: '[message]',
  duration: 2000,         // 2000 = success, 3000 = error/info
  gravity: 'bottom',
  position: 'right',
  style: {
    background: 'var(--sage)',      // success
    // OR 'var(--charcoal)'         // neutral/info
    // OR 'var(--rose)'             // error
    color: '#ffffff',
    borderRadius: '50px',
    fontSize: '12px',
    letterSpacing: '2px',
  },
  onClick() { /* optional navigation */ },
}).showToast();
```

### ES Module Import + Window Exposure
**Source:** `js/products.js` lines 1–3, 133–138
**Apply to:** `js/auth.js`
```js
import { supabase } from './supabase.js';
// ... implementation ...
window.signIn  = signIn;
window.signUp  = signUp;
window.elvoraSignOut = signOut;  // 'signOut' conflicts with reserved name patterns
```

### Form Error Display
**Source:** Pattern established by contact form, convention from Phase 3
**Apply to:** `auth.html` — inline error below form (not toast)
```html
<p x-show="error" x-text="error" role="alert"
   style="color:var(--rose); font-size:14px; margin-top:8px; display:none;"></p>
```

---

## No Analog Found

All files have close analogs in the codebase. No files require falling back to RESEARCH.md patterns only.

---

## Metadata

**Analog search scope:** `js/`, `src/`, `product.html`, `shop.html`, `components.js`, `cart.js`
**Files scanned:** 7 source files read in full
**Pattern extraction date:** 2026-06-14
