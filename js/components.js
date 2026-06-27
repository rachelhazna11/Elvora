// js/components.js
// Shared nav + footer injection, Alpine store registration, active link detection.
// Side-effect module — exports nothing.

import { supabase } from './supabase.js';
import { getUser, onAuthChange } from './auth.js';
import { mergeGuestCartToSupabase, loadCartFromSupabase, loadFromStorage } from './cart.js';

// Expose supabase client globally so Alpine inline x-data strings can access it
window.supabase = supabase;

// Register Alpine stores — must happen before Alpine.initTree calls below.
// alpine:init fires before Alpine processes the initial DOM, but ES modules
// load after deferred scripts, so the event has already fired by the time
// this module runs. We register stores directly via Alpine.store() instead.
function registerStores() {
  if (!Alpine.store('auth')) Alpine.store('auth', { user: null, loggedIn: false });
}

// Populate Alpine.store('auth') from live session and subscribe to changes.
// Runs on every page since components.js is loaded everywhere.
async function initAuth() {
  const user = await getUser();
  Alpine.store('auth').user = user;
  Alpine.store('auth').loggedIn = !!user;
  // Cart load handled by INITIAL_SESSION event handler below — no eager call here.

  onAuthChange(async (user, event) => {
    Alpine.store('auth').user = user;
    Alpine.store('auth').loggedIn = !!user;

    if (user && event === 'SIGNED_IN') {
      // Login action (manual or OAuth redirect) — merge guest cart then load authoritative state.
      try { await mergeGuestCartToSupabase(user); } catch (err) { console.warn('[cart] merge failed:', err); }
    } else if (user && event === 'INITIAL_SESSION') {
      // Page load with existing session — Supabase is authoritative; never merge here to avoid
      // doubling qty on every navigation (localStorage qty + Supabase qty would accumulate).
      try { await loadCartFromSupabase(user.id); } catch (err) { console.warn('[cart] load failed:', err); }
    } else if (!user) {
      const localItems = loadFromStorage();
      if (window.Alpine && Alpine.store('cart')) {
        Alpine.store('cart').items = localItems;
      }
    }
  });
}

// Guard: ensure registerStores/initAuth run exactly once regardless of Alpine init timing.
let _componentsInitDone = false;
function _componentsInit() {
  if (_componentsInitDone) return;
  _componentsInitDone = true;
  registerStores();
  initAuth();
}
document.addEventListener('alpine:init', _componentsInit);
if (window.Alpine) _componentsInit();

// ─── Nav HTML ────────────────────────────────────────────────────────────────

const navHTML = `
<div
  x-data="{
    navOpen: false,
    scrolled: false,
    searchOpen: false,
    userDropOpen: false,
    searchQuery: '',
    suggestions: [],
    _searchTimer: null,
    init() {
      window.addEventListener('scroll', () => {
        this.scrolled = window.scrollY > 80;
      }, { passive: true });
    },
    async onSearchInput() {
      if (this.searchQuery.length < 2) { this.suggestions = []; return; }
      if (typeof window.searchProducts !== 'function') return;
      clearTimeout(this._searchTimer);
      this._searchTimer = setTimeout(async () => {
        const { data } = await window.searchProducts(this.searchQuery);
        this.suggestions = data || [];
      }, 300);
    },
    goToSearch() {
      if (this.searchQuery.trim()) {
        window.location.href = '/shop.html?search=' + encodeURIComponent(this.searchQuery.trim());
      }
    },
    goToProduct(slug) {
      window.location.href = '/product.html?slug=' + slug;
      this.searchOpen = false;
      this.suggestions = [];
      this.searchQuery = '';
    }
  }"
>
  <nav
    :class="scrolled ? 'shadow-sm' : ''"
    class="fixed top-0 left-0 right-0 z-[100] flex items-center justify-between px-6 lg:px-12 py-5 transition-all duration-300 bg-beige/92 backdrop-blur-md border-b border-sage/20"
    role="navigation"
    aria-label="Main navigation"
  >
    <!-- Logo -->
    <a href="/index.html" class="font-display font-bold text-2xl tracking-widest text-charcoal hover:text-rose transition-colors no-underline flex items-center gap-1">
      ELV<svg class="inline w-6 h-6 -mt-0.5" viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="3" fill="currentColor" opacity="0.7"/><circle cx="12" cy="5" r="1.5" fill="currentColor" opacity="0.4"/><circle cx="12" cy="19" r="1.5" fill="currentColor" opacity="0.4"/><circle cx="5" cy="12" r="1.5" fill="currentColor" opacity="0.4"/><circle cx="19" cy="12" r="1.5" fill="currentColor" opacity="0.4"/></svg>RA
    </a>

    <!-- Desktop nav links -->
    <ul class="hidden lg:flex gap-9 list-none m-0 p-0 items-center">
      <li><a href="/index.html" data-page="/index.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal hover:text-rose transition-colors no-underline">Home</a></li>
      <li><a href="/shop.html" data-page="/shop.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal hover:text-rose transition-colors no-underline">Shop</a></li>
      <li><a href="/lookbook.html" data-page="/lookbook.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal hover:text-rose transition-colors no-underline">Lookbook</a></li>
      <li><a href="/about.html" data-page="/about.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal hover:text-rose transition-colors no-underline">About</a></li>
      <li><a href="/contact.html" data-page="/contact.html" class="nav-link text-[12px] font-medium tracking-[2px] uppercase text-charcoal hover:text-rose transition-colors no-underline">Contact</a></li>
    </ul>

    <!-- Nav actions -->
    <div class="flex items-center gap-3">
      <!-- Search -->
      <div class="relative" @click.outside="searchOpen = false; suggestions = []">
        <button
          @click="searchOpen = !searchOpen; if (searchOpen) $nextTick(() => $refs.searchInput && $refs.searchInput.focus())"
          aria-label="Search"
          class="w-11 h-11 flex items-center justify-center text-charcoal hover:text-rose transition-colors"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <circle cx="11" cy="11" r="7"/><path d="M21 21l-4.35-4.35" stroke-linecap="round"/>
          </svg>
        </button>

        <!-- Expand search input + autosuggest -->
        <div
          x-show="searchOpen"
          x-transition:enter="transition ease-out duration-200"
          x-transition:enter-start="opacity-0 scale-95"
          x-transition:enter-end="opacity-100 scale-100"
          class="absolute right-0 top-full mt-2 w-72 z-[200]"
          style="display:none;"
        >
          <input
            x-ref="searchInput"
            type="search"
            x-model="searchQuery"
            @input="onSearchInput()"
            @keydown.enter.prevent="goToSearch()"
            @keydown.escape="searchOpen = false; suggestions = []"
            placeholder="Search styles..."
            autocomplete="off"
            aria-label="Search Elvora products"
            class="w-full px-5 py-3 rounded-full border border-sage/30 bg-white text-charcoal text-sm outline-none shadow-md focus:border-sage"
          >

          <!-- Autosuggest results dropdown -->
          <div x-show="suggestions.length > 0" style="display:none;" class="mt-2 bg-white rounded-2xl shadow-lg border border-sage/20 overflow-hidden">
            <template x-for="s in suggestions" :key="s.slug">
              <button @click="goToProduct(s.slug)" class="w-full text-left px-5 py-3 text-sm text-charcoal hover:bg-beige transition-colors" x-text="s.name"></button>
            </template>
          </div>

          <!-- No-results row -->
          <div x-show="suggestions.length === 0 && searchQuery.length >= 2" style="display:none;" class="mt-2 bg-white rounded-2xl shadow-lg border border-sage/20 px-5 py-3 text-sm text-text-muted">No styles found — try a shorter search.</div>
        </div>
      </div>

      <!-- User account — guest state (visible by default, hidden when logged in) -->
      <a x-show="!$store.auth.loggedIn" href="/auth.html" aria-label="Your account" class="w-11 h-11 flex items-center justify-center text-charcoal hover:text-rose transition-colors">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
          <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" stroke-linecap="round"/>
        </svg>
      </a>

      <!-- User account — logged-in state (hidden by default to prevent FOUC) -->
      <div x-show="$store.auth.loggedIn" class="relative" @click.outside="userDropOpen = false" style="display:none;">
        <button
          @click="userDropOpen = !userDropOpen"
          class="nav-user-trigger"
          :aria-expanded="userDropOpen"
          aria-label="Account menu"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" stroke-linecap="round"/>
          </svg>
          <span class="nav-user-name" x-text="$store.auth.user?.user_metadata?.first_name || 'Account'"></span>
        </button>
        <div x-show="userDropOpen" class="nav-dropdown" style="display:none;">
          <a href="/account.html" class="nav-dropdown-item">My Account</a>
          <a href="/account.html#wishlist" class="nav-dropdown-item">Wishlist</a>
          <a href="/style-history.html" class="nav-dropdown-item">Riwayat Style Match</a>
          <div class="nav-dropdown-divider"></div>
          <button @click="window.elvoraSignOut().then(() => { $store.auth.user = null; $store.auth.loggedIn = false; window.location.href='/index.html'; }).catch(err => { console.error('[auth] sign out failed', err); })" class="nav-dropdown-item danger">Sign Out</button>
        </div>
      </div>

      <!-- Cart bag -->
      <button @click="$store.cart.openDrawer()" aria-label="Open shopping bag" class="w-11 h-11 flex items-center justify-center text-charcoal hover:text-rose transition-colors relative" type="button">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke-linecap="round"/><line x1="3" y1="6" x2="21" y2="6"/>
          <path d="M16 10a4 4 0 01-8 0" stroke-linecap="round"/>
        </svg>
        <span x-show="$store.cart.count > 0" x-text="$store.cart.count" class="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose text-white text-[9px] flex items-center justify-center font-semibold" style="display:none;"></span>
      </button>

      <!-- Mobile hamburger -->
      <button @click="navOpen = true" aria-label="Open navigation menu" class="w-11 h-11 flex items-center justify-center text-charcoal lg:hidden">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
          <line x1="4" y1="6" x2="20" y2="6" stroke-linecap="round"/>
          <line x1="4" y1="12" x2="20" y2="12" stroke-linecap="round"/>
          <line x1="4" y1="18" x2="20" y2="18" stroke-linecap="round"/>
        </svg>
      </button>
    </div>
  </nav>

  <!-- Mobile drawer — sibling of nav, outside backdrop-filter context -->
  <div
    x-show="navOpen"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="translate-x-full"
    x-transition:enter-end="translate-x-0"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="translate-x-0"
    x-transition:leave-end="translate-x-full"
    @keydown.escape.window="navOpen = false"
    class="fixed inset-y-0 right-0 w-72 z-[200] flex flex-col p-8"
    style="display:none; background-color:#2E2E2E;"
  >
    <button @click="navOpen = false" aria-label="Close navigation menu" class="self-end mb-8 text-white hover:text-rose transition-colors">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
        <line x1="18" y1="6" x2="6" y2="18" stroke-linecap="round"/>
        <line x1="6" y1="6" x2="18" y2="18" stroke-linecap="round"/>
      </svg>
    </button>
    <ul class="list-none m-0 p-0 flex flex-col gap-6">
      <li><a href="/index.html" class="text-white text-base tracking-widest uppercase hover:text-rose transition-colors no-underline">Home</a></li>
      <li><a href="/shop.html" class="text-white text-base tracking-widest uppercase hover:text-rose transition-colors no-underline">Shop</a></li>
      <li><a href="/lookbook.html" class="text-white text-base tracking-widest uppercase hover:text-rose transition-colors no-underline">Lookbook</a></li>
      <li><a href="/about.html" class="text-white text-base tracking-widest uppercase hover:text-rose transition-colors no-underline">About</a></li>
      <li><a href="/contact.html" class="text-white text-base tracking-widest uppercase hover:text-rose transition-colors no-underline">Contact</a></li>
    </ul>
    <div class="mt-8 flex items-center gap-4">
      <!-- Mobile — guest account link -->
      <a x-show="!$store.auth.loggedIn" href="/auth.html" aria-label="Your account" class="w-11 h-11 flex items-center justify-center text-white hover:text-rose transition-colors">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" stroke-linecap="round"/></svg>
      </a>
      <!-- Mobile — logged-in account link (no dropdown, direct link) -->
      <a x-show="$store.auth.loggedIn" href="/account.html" aria-label="My account" class="flex items-center gap-2 text-white hover:text-rose transition-colors" style="display:none;">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" stroke-linecap="round"/></svg>
        <span class="text-sm tracking-widest uppercase" x-text="$store.auth.user?.user_metadata?.first_name || 'Account'"></span>
      </a>
      <button @click="$store.cart.openDrawer()" aria-label="Open shopping bag" class="w-11 h-11 flex items-center justify-center text-white hover:text-rose transition-colors" type="button">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke-linecap="round"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 01-8 0" stroke-linecap="round"/></svg>
      </button>
    </div>
  </div>

  <!-- Backdrop — sibling of nav, outside backdrop-filter context -->
  <div
    x-show="navOpen"
    @click="navOpen = false"
    class="fixed inset-0 z-[150]"
    style="display:none; background-color:rgba(46,46,46,0.5);"
  ></div>
</div>
`;

// ─── Footer HTML ──────────────────────────────────────────────────────────────

const footerHTML = `
<footer class="bg-charcoal text-white pt-[72px] pb-10">
  <div class="max-w-[1280px] mx-auto px-8 md:px-16">
    <div class="grid grid-cols-1 md:grid-cols-4 gap-12 mb-16">
      <!-- Brand column -->
      <div class="md:col-span-1">
        <p class="font-display font-bold text-xl tracking-widest mb-4">ELVORA</p>
        <p class="text-sm text-white/60 leading-relaxed font-light mb-6">Where movement meets elegance. Premium activewear for the modern woman.</p>
        <div class="flex gap-3">
          <a href="https://instagram.com/elvorastudio" target="_blank" rel="noopener noreferrer" aria-label="Instagram" class="w-10 h-10 rounded-full border border-white/20 flex items-center justify-center text-white/60 hover:text-rose hover:border-rose transition-colors">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
          </a>
          <a href="#" aria-label="Twitter / X" class="w-10 h-10 rounded-full border border-white/20 flex items-center justify-center text-white/60 hover:text-rose hover:border-rose transition-colors">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
          </a>
          <a href="#" aria-label="Pinterest" class="w-10 h-10 rounded-full border border-white/20 flex items-center justify-center text-white/60 hover:text-rose hover:border-rose transition-colors">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 0C5.373 0 0 5.373 0 12c0 5.084 3.163 9.426 7.627 11.174-.105-.949-.2-2.405.042-3.441.218-.937 1.407-5.965 1.407-5.965s-.359-.719-.359-1.782c0-1.668.967-2.914 2.171-2.914 1.023 0 1.518.769 1.518 1.69 0 1.029-.655 2.568-.994 3.995-.283 1.194.599 2.169 1.777 2.169 2.133 0 3.772-2.249 3.772-5.495 0-2.873-2.064-4.882-5.012-4.882-3.414 0-5.418 2.561-5.418 5.207 0 1.031.397 2.138.893 2.738a.36.36 0 01.083.345l-.333 1.36c-.053.22-.174.267-.402.161-1.499-.698-2.436-2.889-2.436-4.649 0-3.785 2.75-7.262 7.929-7.262 4.163 0 7.398 2.967 7.398 6.931 0 4.136-2.607 7.464-6.227 7.464-1.216 0-2.359-.632-2.75-1.378l-.748 2.853c-.271 1.043-1.002 2.35-1.492 3.146C9.57 23.812 10.763 24 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0z"/></svg>
          </a>
        </div>
      </div>

      <!-- Shop links -->
      <div>
        <h3 class="text-[11px] tracking-[4px] uppercase text-white font-medium mb-6">SHOP</h3>
        <ul class="list-none m-0 p-0 flex flex-col gap-3">
          <li><a href="/shop.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">All Products</a></li>
          <li><a href="/shop.html?category=leggings" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Leggings</a></li>
          <li><a href="/shop.html?category=jackets" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Jackets</a></li>
          <li><a href="/shop.html?category=tops" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Tops</a></li>
          <li><a href="/shop.html?category=hijab" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Sport Hijab</a></li>
          <li><a href="/shop.html?collection=run-era" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Run Era</a></li>
          <li><a href="/shop.html?collection=pace-mode" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Pace Mode</a></li>
          <li><a href="/shop.html?collection=runners-high" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Runner's High</a></li>
        </ul>
      </div>

      <!-- Help links -->
      <div>
        <h3 class="text-[11px] tracking-[4px] uppercase text-white font-medium mb-6">HELP</h3>
        <ul class="list-none m-0 p-0 flex flex-col gap-3">
          <li><a href="/contact.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Size Guide</a></li>
          <li><a href="/contact.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">FAQ</a></li>
          <li><a href="/contact.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Shipping &amp; Returns</a></li>
          <li><a href="/contact.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Contact</a></li>
        </ul>
      </div>

      <!-- Brand links -->
      <div>
        <h3 class="text-[11px] tracking-[4px] uppercase text-white font-medium mb-6">BRAND</h3>
        <ul class="list-none m-0 p-0 flex flex-col gap-3">
          <li><a href="/about.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Our Story</a></li>
          <li><a href="/lookbook.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Lookbook</a></li>
          <li><a href="/style-match.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Style Match</a></li>
          <li><a href="/contact.html" class="text-sm text-white/45 hover:text-rose transition-colors font-light no-underline">Careers</a></li>
        </ul>
      </div>
    </div>

    <!-- Bottom row -->
    <div class="border-t border-white/10 pt-8 flex flex-col lg:flex-row items-center justify-between gap-4">
      <p class="text-sm text-white/30">© 2026 Elvora. All rights reserved.</p>
      <div class="flex gap-6">
        <a href="#" class="text-sm text-white/30 hover:text-rose transition-colors no-underline">Privacy Policy</a>
        <a href="#" class="text-sm text-white/30 hover:text-rose transition-colors no-underline">Terms</a>
      </div>
    </div>
  </div>
</footer>
`;

// ─── Cart Drawer HTML ─────────────────────────────────────────────────────────

const cartDrawerHTML = `
<div id="cart-drawer-root">
  <!-- Backdrop -->
  <div
    x-show="$store.cart.cartDrawerOpen"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0"
    @click="$store.cart.closeDrawer()"
    class="cart-drawer-backdrop"
    style="display:none;"
    aria-hidden="true"
  ></div>

  <!-- Drawer panel -->
  <div
    x-show="$store.cart.cartDrawerOpen"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="translate-x-full opacity-0"
    x-transition:enter-end="translate-x-0 opacity-100"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="translate-x-0 opacity-100"
    x-transition:leave-end="translate-x-full opacity-0"
    @keydown.escape.window="$store.cart.closeDrawer()"
    class="cart-drawer"
    role="dialog"
    aria-modal="true"
    aria-label="Shopping bag"
    style="display:none;"
  >
    <!-- Header -->
    <div class="cart-drawer-header">
      <h2 class="cart-drawer-title">Your Bag</h2>
      <button
        @click="$store.cart.closeDrawer()"
        class="cart-drawer-close"
        aria-label="Close shopping bag"
      >
        <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
          <line x1="18" y1="6" x2="6" y2="18" stroke-linecap="round"/>
          <line x1="6" y1="6" x2="18" y2="18" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <!-- Body -->
    <div class="cart-drawer-body">

      <!-- Empty state -->
      <div
        x-show="$store.cart.items.length === 0"
        class="cart-drawer-empty"
        style="display:none;"
      >
        <svg width="48" height="48" fill="none" stroke="currentColor" stroke-width="1" viewBox="0 0 24 24" style="color:rgba(168,191,163,0.5);" aria-hidden="true">
          <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke-linecap="round"/>
          <line x1="3" y1="6" x2="21" y2="6"/>
          <path d="M16 10a4 4 0 01-8 0" stroke-linecap="round"/>
        </svg>
        <p style="font-size:14px;color:var(--text-muted);font-family:var(--font-body);">Your bag is empty</p>
        <a
          href="/shop.html"
          @click="$store.cart.closeDrawer()"
          class="btn-primary"
          style="padding:12px 28px;font-size:11px;"
        >Shop Now</a>
      </div>

      <!-- Items list -->
      <template x-if="$store.cart.items.length > 0">
        <div>
          <template x-for="item in $store.cart.items" :key="item.key">
            <div class="cart-drawer-item">
              <!-- Thumbnail -->
              <template x-if="item.image">
                <img :src="item.image" :alt="item.name" class="cart-drawer-thumb" loading="lazy">
              </template>
              <template x-if="!item.image">
                <div class="cart-drawer-thumb"></div>
              </template>

              <!-- Item info -->
              <div class="cart-drawer-item-info">
                <p class="cart-drawer-item-name" x-text="item.name"></p>
                <p class="cart-drawer-item-variant" x-text="[item.colour, item.size].filter(Boolean).join(' / ')"></p>
                <p class="cart-drawer-item-price" x-text="'Rp ' + (item.price * item.qty).toLocaleString('id-ID')"></p>

                <!-- Qty stepper -->
                <div class="cart-qty-stepper">
                  <button
                    @click="$store.cart.setQty(item.key, item.qty - 1)"
                    class="cart-qty-btn"
                    :aria-label="'Decrease quantity of ' + item.name"
                  >−</button>
                  <span class="cart-qty-display" x-text="item.qty"></span>
                  <button
                    @click="$store.cart.setQty(item.key, item.qty + 1)"
                    class="cart-qty-btn"
                    :aria-label="'Increase quantity of ' + item.name"
                  >+</button>
                </div>

                <button
                  @click="$store.cart.remove(item.key)"
                  class="cart-drawer-item-remove"
                  :aria-label="'Remove ' + item.name + ' from bag'"
                >Remove</button>
              </div>
            </div>
          </template>
        </div>
      </template>

    </div>

    <!-- Footer (only shown when items exist) -->
    <div x-show="$store.cart.items.length > 0" class="cart-drawer-footer" style="display:none;">
      <div class="cart-drawer-subtotal-row">
        <span style="font-size:12px;letter-spacing:2px;text-transform:uppercase;color:var(--text-muted);">Subtotal</span>
        <span style="font-size:16px;font-weight:600;" x-text="$store.cart.totalFormatted"></span>
      </div>
      <p style="font-size:11px;text-align:center;color:var(--sage);letter-spacing:1px;text-transform:uppercase;">Free Shipping</p>
      <a
        href="/checkout.html"
        @click="$store.cart.closeDrawer()"
        class="btn-primary"
        style="text-align:center;width:100%;box-sizing:border-box;"
        aria-label="Proceed to checkout"
      >Checkout</a>
      <a
        href="/cart.html"
        @click="$store.cart.closeDrawer()"
        class="view-all"
        style="text-align:center;display:block;"
        aria-label="View full cart"
      >View Full Bag</a>
    </div>
  </div>
</div>
`;

// ─── Inject nav and footer ────────────────────────────────────────────────────

const navRoot = document.getElementById('nav-root');
const footerRoot = document.getElementById('footer-root');

if (navRoot) {
  navRoot.innerHTML = navHTML;
  if (window.Alpine) Alpine.initTree(navRoot);
}
if (footerRoot) {
  footerRoot.innerHTML = footerHTML;
  if (window.Alpine) Alpine.initTree(footerRoot);
}

// ─── Cart drawer injection ────────────────────────────────────────────────────
const cartDrawerRoot = document.createElement('div');
cartDrawerRoot.innerHTML = cartDrawerHTML;
document.body.appendChild(cartDrawerRoot);
if (window.Alpine) Alpine.initTree(cartDrawerRoot);

// ─── Active nav link detection ────────────────────────────────────────────────

const currentPath = window.location.pathname;
document.querySelectorAll('[data-page]').forEach(link => {
  const href = link.getAttribute('href');
  const isHome = href === '/index.html' && (currentPath === '/' || currentPath === '/index.html');
  const isActive = isHome || href === currentPath;
  if (isActive) link.classList.add('text-rose');
});

// Signal that all ES modules have run and window.getProducts / window.supabase are ready.
// Alpine's defer CDN script runs before modules, so pages with inline x-data that call
// window.getProducts must wait for this event before fetching data.
window.dispatchEvent(new CustomEvent('elvora:ready'));
