// js/products.js
// Product query functions — Supabase data layer for PLP, PDP, search, and categories.
import { supabase } from './supabase.js';

// Activity-to-collection-slug mapping.
// Inlined here (not imported from subcategory-styles.js) to avoid circular dependency.
const ACTIVITY_TOP_SLUGS = {
  padel:    ['padel-edit'],
  pilates:  ['studio-essentials'],
  tennis:   ['love-match', 'ace-energy', 'court-girl'],
  training: ['power-mood', 'built-different', 'hot-girl-lift'],
  running:  ['run-era', 'pace-mode', 'runners-high'],
};

/**
 * Fetch products with optional filtering and sorting.
 * @param {Object} filters
 * @param {string} [filters.category] - Activity category key (padel, pilates, tennis, training, running) or 'all'
 * @param {string} [filters.sub]      - Specific sub-collection slug; overrides category slug lookup
 * @param {string} [filters.sort]     - Sort key: 'price-asc' | 'price-desc' | 'best-sellers' | default new-arrivals
 * @param {string} [filters.search]   - Name search string (ilike)
 * @returns {Promise<{data: Array, error: Object|null}>}
 */
export async function getProducts(filters = {}) {
  const { category, sub, sort, search } = filters;

  let query = supabase
    .from('products')
    .select(`
      id, name, slug, base_price, is_best_seller, created_at,
      product_images (url, alt_text, display_order, colour),
      product_variants (id, colour, colour_hex, size, stock_quantity)
    `)
    .eq('is_active', true);

  if (search) {
    query = query.ilike('name', `%${search}%`);
  }

  if (category && category !== 'all') {
    const slugs = sub ? [sub] : ACTIVITY_TOP_SLUGS[category] || [];
    if (slugs.length > 0) {
      const { data: cols } = await supabase
        .from('collections')
        .select('id')
        .in('slug', slugs);

      const colIds = (cols || []).map(c => c.id);
      if (colIds.length === 0) return { data: [], error: null };

      const { data: cp } = await supabase
        .from('collection_products')
        .select('product_id')
        .in('collection_id', colIds);

      const ids = [...new Set((cp || []).map(r => r.product_id))];
      if (ids.length === 0) return { data: [], error: null };

      query = query.in('id', ids);
    }
  }

  switch (sort) {
    case 'price-asc':
      query = query.order('base_price', { ascending: true });
      break;
    case 'price-desc':
      query = query.order('base_price', { ascending: false });
      break;
    case 'best-sellers':
      query = query
        .order('is_best_seller', { ascending: false })
        .order('created_at', { ascending: false });
      break;
    default:
      query = query.order('created_at', { ascending: false });
  }

  return query;
}

/**
 * Fetch a single product by slug with all nested relations.
 * @param {string} slug - Product slug (from URL ?slug= param)
 * @returns {Promise<Object|null>} Product data or null if not found / inactive
 */
export async function getProduct(slug) {
  // Phase 7 note: For Supabase Storage images use ?width=1200&quality=80;
  // seed images are Unsplash CDN — use ?w=1200&q=80 (per D-11).
  const { data, error } = await supabase
    .from('products')
    .select(`
      id, name, slug, description, base_price, is_best_seller,
      fabric_details, care_instructions, styling_suggestions,
      product_images (id, url, alt_text, display_order, colour),
      product_variants (id, colour, colour_hex, size, stock_quantity),
      categories (name, slug)
    `)
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (error || !data) return null;
  return data;
}

/**
 * Fetch all categories ordered alphabetically.
 * @returns {Promise<{data: Array, error: Object|null}>}
 */
export async function getCategories() {
  return supabase
    .from('categories')
    .select('id, name, slug')
    .order('name', { ascending: true });
}

/**
 * Search products by name with autocomplete results.
 * @param {string} query - Search term (minimum 2 characters)
 * @returns {Promise<{data: Array}>} Up to 6 matching product name/slug pairs
 */
export async function searchProducts(query) {
  if (!query || query.length < 2) return { data: [] };
  return supabase
    .from('products')
    .select('name, slug')
    .ilike('name', `%${query}%`)
    .eq('is_active', true)
    .limit(6);
}

// Expose to window so Alpine inline x-data strings can call these functions.
// Alpine x-data strings run in the global scope — cannot use ES module imports.
window.getProducts    = getProducts;
window.getProduct     = getProduct;
window.getCategories  = getCategories;
window.searchProducts = searchProducts;
