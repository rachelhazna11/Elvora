# Phase 4: Auth + Customer Account - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 04-auth-customer-account
**Areas discussed:** Auth page layout, Nav logged-in state, Account dashboard sections, Wishlist heart icon guest behavior

---

## Auth Page Layout

### Q1: Form organization
| Option | Description | Selected |
|--------|-------------|----------|
| Single page, tab toggle | auth.html has Sign In + Create Account tabs; Alpine x-show; ?tab= deep-link | ✓ |
| Two separate pages | auth.html = sign in only, signup.html = registration only | |
| Single page, stacked | Both forms visible, scroll to navigate | |

**User's choice:** Single page, tab toggle

### Q2: Redirect after auth
| Option | Description | Selected |
|--------|-------------|----------|
| Always redirect to account.html | Simple, predictable, every auth → dashboard | ✓ |
| Redirect to previous page | Store referrer, return after auth | |
| Stay on auth.html, show success | Let user navigate themselves | |

**User's choice:** Always redirect to account.html

### Q3: Visual style
| Option | Description | Selected |
|--------|-------------|----------|
| Editorial split layout | Left: full-height brand image + tagline; Right: clean form | ✓ |
| Minimal centered card | White card on cream background | |
| Full-bleed hero with overlay form | Lifestyle bg + frosted-glass card | |

**User's choice:** Editorial split layout

---

## Nav Logged-In State

### Q1: Account area when logged in
| Option | Description | Selected |
|--------|-------------|----------|
| Icon + first name, dropdown on click | Person icon + name; dropdown: My Account, Wishlist, Sign Out | ✓ |
| Icon changes, links to account.html | Filled icon, direct link to account, no dropdown | |
| Shows 'Account' text + logout link | Text links, minimal | |

**User's choice:** Icon + first name, dropdown on click

### Q2: Auth state initialization location
| Option | Description | Selected |
|--------|-------------|----------|
| In js/components.js (getUser + onAuthStateChange) | Runs on every page automatically; single source of truth | ✓ |
| In js/auth.js, export initAuth() per page | Explicit per-page import | |
| You decide | Claude picks based on existing patterns | |

**User's choice:** In js/components.js

### Q3: Wishlist icon in nav
| Option | Description | Selected |
|--------|-------------|----------|
| Wishlist only in account dashboard | No nav icon; access via account | ✓ |
| Add heart icon to nav when logged in | Heart icon in nav right linking to account#wishlist | |

**User's choice:** Wishlist only in account dashboard

---

## Account Dashboard Sections

### Q1: Dashboard structure
| Option | Description | Selected |
|--------|-------------|----------|
| 3 sections: Profile, Wishlist, Style Preferences (sidebar tabs) | Left sidebar + right content; Alpine tab switching | ✓ |
| 2 sections: Wishlist + Profile only | Simpler; defer preferences to Phase 5 | |
| Single scrolling page | All sections stacked vertically | |

**User's choice:** 3 sections with sidebar tab navigation

### Q2: Profile editing scope
| Option | Description | Selected |
|--------|-------------|----------|
| View + edit first/last name; display-only email | Name → user_profiles; email display-only | ✓ |
| View + edit everything including password | Full profile + password change form | |
| Display only — no editing | Read-only, editing deferred to v2 | |

**User's choice:** View + edit first/last name; display-only email

### Q3: Style Preferences section
| Option | Description | Selected |
|--------|-------------|----------|
| Editable preference form (4 fields, saves to user_profiles) | Works standalone; Phase 5 reads as pre-fills | ✓ |
| Read-only placeholder section | "Preferences appear after first Style Match" | |
| Skip preferences in Phase 4 | Phase 5 adds preferences to style-match.html directly | |

**User's choice:** Editable preference form (activity, fit, aesthetic, colour)

---

## Wishlist Heart Icon: Guest Behavior

### Q1: Guest clicks heart
| Option | Description | Selected |
|--------|-------------|----------|
| Toast + redirect to auth.html | Toastify toast → navigate after 2s (or immediate on click) | ✓ |
| Inline prompt tooltip | Popover near icon, user controls navigation | |
| Silent redirect to auth.html | Immediate redirect, no toast | |

**User's choice:** Toast + redirect to auth.html

### Q2: Logged-in toggle behavior
| Option | Description | Selected |
|--------|-------------|----------|
| Optimistic UI (fill instantly, sync in background) | Heart fills instantly; Supabase call fires async; revert on error | ✓ |
| Wait for Supabase, then update icon | Loading spinner; then update | |
| You decide | Claude picks based on cart store pattern | |

**User's choice:** Optimistic UI

### Q3: Initial wishlist state on page load
| Option | Description | Selected |
|--------|-------------|----------|
| Fetch all wishlist IDs on page load, compare in Alpine | Single query; Set lookup per card | ✓ |
| Check per-product on render | N queries for N cards | |
| Only show fill state on Wishlist page | Hearts always empty on PLP/PDP | |

**User's choice:** Fetch all wishlist IDs on page load

---

## Claude's Discretion

None — user made all selections without deferring to Claude.

## Deferred Ideas

- Change password form → v2 or post-assessment polish
- Avatar upload → Phase 7 (admin panel) or v2
- Order history → deferred to v2 per STATE.md
- Email change → out of scope for assessment (requires Supabase email verification flow)
- Social auth (Google, Apple) → not in ROADMAP
- Wishlist icon in nav → decided against (D-06)
