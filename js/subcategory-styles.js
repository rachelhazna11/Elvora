/**
 * subcategory-styles.js
 * Authoritative source of truth for Elvora lookbook sub-category styling.
 * Consumed by Phase 3 PLP filter UI and Phase 5 AI Style Match.
 *
 * Each entry defines the visual identity, color palette, and styling direction
 * for one of the 15 named sub-categories across 5 activity categories.
 *
 * Usage:
 *   import { SUBCATEGORY_STYLES, getSubcategoryBySlug } from './js/subcategory-styles.js';
 */

export const SUBCATEGORY_STYLES = [

  // ── PADEL ──────────────────────────────────────────────────────────────────

  {
    slug: 'matcha-babe',
    name: 'Matcha Babe',
    category: 'padel',
    tones: ['matcha green', 'muted sage', 'soft ivory', 'warm cream'],
    aesthetic: 'clean, premium, sporty elegance',
    direction: 'elevated padel club look, soft luxury activewear',
    outfitFeel: 'sage sports bra + ivory skirt + cream layer',
    lookbookImage: null,
  },
  {
    slug: 'court-crush',
    name: 'Court Crush',
    category: 'padel',
    tones: ['charcoal', 'ivory', 'soft neutrals', 'subtle contrast'],
    aesthetic: 'confident, polished, fashion-forward',
    direction: 'premium courtwear with feminine confidence',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'rally-ready',
    name: 'Rally Ready',
    category: 'padel',
    tones: ['performance neutrals', 'stone', 'black', 'muted green'],
    aesthetic: 'active, athletic, elevated sport functionality',
    direction: 'modern competitive padel energy',
    outfitFeel: null,
    lookbookImage: null,
  },

  // ── PILATES ────────────────────────────────────────────────────────────────

  {
    slug: 'soft-flow',
    name: 'Soft Flow',
    category: 'pilates',
    tones: ['warm neutrals', 'ivory', 'soft sage', 'stone'],
    aesthetic: 'calm, feminine, wellness-focused',
    direction: 'graceful studio luxury',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'main-character',
    name: 'Main Character',
    category: 'pilates',
    tones: ['elegant monochrome', 'charcoal', 'cream', 'muted earth tones'],
    aesthetic: 'refined, fashion-editorial, confident',
    direction: 'luxury pilates muse',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'studio-muse',
    name: 'Studio Muse',
    category: 'pilates',
    tones: ['soft beige', 'muted neutrals', 'premium basics'],
    aesthetic: 'minimalist quiet luxury',
    direction: 'premium studio uniform',
    outfitFeel: null,
    lookbookImage: null,
  },

  // ── TENNIS ─────────────────────────────────────────────────────────────────

  {
    slug: 'love-match',
    name: 'Love Match',
    category: 'tennis',
    tones: ['ivory', 'soft green', 'clean whites'],
    aesthetic: 'romantic luxury tennis aesthetic',
    direction: 'premium country-club elegance',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'ace-energy',
    name: 'Ace Energy',
    category: 'tennis',
    tones: ['sharper contrast neutrals', 'charcoal', 'white', 'muted green'],
    aesthetic: 'energetic, confident, elevated athleticism',
    direction: 'modern performance-luxury',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'court-girl',
    name: 'Court Girl',
    category: 'tennis',
    tones: ['feminine neutrals', 'ivory', 'soft cream', 'muted sage'],
    aesthetic: 'chic, fashion-forward, feminine but premium',
    direction: 'luxury tennis lifestyle',
    outfitFeel: null,
    lookbookImage: null,
  },

  // ── TRAINING ───────────────────────────────────────────────────────────────
  // Note: category is 'training' here to match the PLP filter key.
  // The original subcategory-styles.js used 'gym' — updated to 'training'
  // to align with ACTIVITY_TOP_SLUGS key in products.js.

  {
    slug: 'power-mood',
    name: 'Power Mood',
    category: 'training',
    tones: ['charcoal', 'black', 'muted earth tones'],
    aesthetic: 'strong, sleek, premium performance',
    direction: 'elevated training wear',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'built-different',
    name: 'Built Different',
    category: 'training',
    tones: ['monochrome neutrals', 'deep charcoal', 'cream contrast'],
    aesthetic: 'bold, modern, disciplined',
    direction: 'high-performance luxury gym wear',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'hot-girl-lift',
    name: 'Hot Girl Lift',
    category: 'training',
    tones: ['soft neutrals', 'warm beige', 'muted sage accents'],
    aesthetic: 'confident, fashion-forward gym aesthetic',
    direction: 'premium feminine strength',
    outfitFeel: null,
    lookbookImage: null,
  },

  // ── RUNNING ────────────────────────────────────────────────────────────────

  {
    slug: 'run-era',
    name: 'Run Era',
    category: 'running',
    tones: ['fresh neutrals', 'ivory', 'muted green'],
    aesthetic: 'energetic wellness lifestyle',
    direction: 'elevated everyday running',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'pace-mode',
    name: 'Pace Mode',
    category: 'running',
    tones: ['performance neutrals', 'charcoal', 'stone'],
    aesthetic: 'focused, sporty, modern',
    direction: 'technical luxury activewear',
    outfitFeel: null,
    lookbookImage: null,
  },
  {
    slug: 'runners-high',
    name: "Runner's High",
    category: 'running',
    tones: ['soft neutrals', 'fresh contrast'],
    aesthetic: 'effortless, wellness-driven, premium movement',
    direction: 'luxury active lifestyle',
    outfitFeel: null,
    lookbookImage: null,
  },

];

/** Look up a single sub-category by its URL slug. Returns undefined if not found. */
export function getSubcategoryBySlug(slug) {
  return SUBCATEGORY_STYLES.find(s => s.slug === slug);
}

/** Return all sub-categories for a given activity category. */
export function getSubcategoriesByActivity(category) {
  return SUBCATEGORY_STYLES.filter(s => s.category === category);
}

// Expose to window for Alpine x-data access.
window.SUBCATEGORY_STYLES = SUBCATEGORY_STYLES;

export default SUBCATEGORY_STYLES;
