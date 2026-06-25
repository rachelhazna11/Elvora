// js/cart.js
// Cart implementation using localStorage for guest users.
// Alpine.store('cart') is the single source of truth for UI reactivity.
// On page load, restores cart from localStorage.

import { supabase } from './supabase.js';

const STORAGE_KEY = 'elvora_cart';

async function getAuthUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

async function supabaseUpsertItem(userId, variantId, productId, qty) {
  if (!variantId) return;
  await supabase.from('cart_items').upsert(
    { user_id: userId, variant_id: variantId, product_id: productId, quantity: qty },
    { onConflict: 'user_id,variant_id' }
  );
}

async function supabaseDeleteItem(userId, variantId) {
  if (!variantId) return;
  await supabase.from('cart_items').delete().eq('user_id', userId).eq('variant_id', variantId);
}

export function loadFromStorage() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
  } catch {
    return [];
  }
}

function saveToStorage(items) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
}

// Initialize Alpine store with persisted cart
function initCartStore() {
  if (!window.Alpine) return;

  const savedItems = loadFromStorage();

  Alpine.store('cart', {
    items: savedItems,
    get count() {
      return this.items.reduce((n, i) => n + i.qty, 0);
    },
    get total() {
      return this.items.reduce((t, i) => t + i.price * i.qty, 0);
    },
    get totalFormatted() {
      return 'Rp ' + this.total.toLocaleString('id-ID');
    },

    add({ productId, variantId = null, name, slug, price, image = '', colour = '', size = '' }) {
      const key = `${productId}|${variantId || ''}|${size}`;
      const existing = this.items.find(i => i.key === key);
      if (existing) {
        existing.qty += 1;
      } else {
        this.items.push({ key, productId, variantId, name, slug, price, image, colour, size, qty: 1 });
      }
      saveToStorage(this.items);
      const newQty = existing ? existing.qty : 1;
      getAuthUser().then(user => { if (user) supabaseUpsertItem(user.id, variantId, productId, newQty); });
    },

    remove(key) {
      const item = this.items.find(i => i.key === key);
      this.items = this.items.filter(i => i.key !== key);
      saveToStorage(this.items);
      if (item?.variantId) getAuthUser().then(user => { if (user) supabaseDeleteItem(user.id, item.variantId); });
    },

    setQty(key, qty) {
      if (qty <= 0) { this.remove(key); return; }
      const item = this.items.find(i => i.key === key);
      if (item) {
        item.qty = qty;
        saveToStorage(this.items);
        if (item.variantId) getAuthUser().then(user => { if (user) supabaseUpsertItem(user.id, item.variantId, item.productId, qty); });
      }
    },

    clear() {
      this.items = [];
      saveToStorage([]);
    },

    cartDrawerOpen: false,
    openDrawer() { this.cartDrawerOpen = true; },
    closeDrawer() { this.cartDrawerOpen = false; },
  });
}

export async function mergeGuestCartToSupabase(user) {
  const localItems = loadFromStorage();

  if (!localItems.length) {
    await loadCartFromSupabase(user.id);
    return;
  }

  const upsertRows = localItems
    .filter(item => item.variantId)
    .map(item => ({
      user_id: user.id,
      product_id: item.productId,
      variant_id: item.variantId,
      quantity: item.qty,
    }));

  if (upsertRows.length) {
    const { data: existing } = await supabase
      .from('cart_items')
      .select('id, variant_id, quantity')
      .eq('user_id', user.id);

    const existingMap = new Map(
      (existing || []).map(row => [row.variant_id, row])
    );

    const merged = upsertRows.map(row => {
      const existingRow = existingMap.get(row.variant_id);
      return existingRow
        ? { ...row, id: existingRow.id, quantity: existingRow.quantity + row.quantity }
        : row;
    });

    await supabase
      .from('cart_items')
      .upsert(merged, { onConflict: 'user_id,variant_id' });
  }

  await loadCartFromSupabase(user.id);
}

export async function loadCartFromSupabase(userId) {
  const { data: rows, error } = await supabase
    .from('cart_items')
    .select(`
      id,
      quantity,
      product_id,
      variant_id,
      product_variants ( id, colour, size ),
      products (
        id, name, slug, base_price,
        product_images ( url, display_order )
      )
    `)
    .eq('user_id', userId);

  if (error) {
    console.warn('[cart] loadCartFromSupabase error:', error.message);
    return;
  }

  const items = (rows || []).map(row => {
    const variant = row.product_variants;
    const product = row.products;
    const images = [...(product?.product_images || [])].sort((a, b) => a.display_order - b.display_order);
    const image = images[0]?.url || '';
    const colour = variant?.colour || '';
    const size = variant?.size || '';
    const key = `${product?.id}|${row.variant_id || ''}|${size}`;
    return {
      key,
      productId: product?.id,
      variantId: row.variant_id,
      name: product?.name || '',
      slug: product?.slug || '',
      price: product?.base_price || 0,
      image,
      colour,
      size,
      qty: row.quantity,
    };
  });

  if (window.Alpine && Alpine.store('cart')) {
    Alpine.store('cart').items = items;
  }
  localStorage.setItem('elvora_cart', JSON.stringify(items));
}

// Re-init if Alpine already running, else wait for alpine:init
document.addEventListener('alpine:init', initCartStore);
if (window.Alpine) initCartStore();
