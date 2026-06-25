---
status: testing
phase: 03-product-catalog
source:
  - 03-01-SUMMARY.md
  - 03-02-SUMMARY.md
  - 03-03-SUMMARY.md
  - 03-04-SUMMARY.md
  - 03-05-SUMMARY.md
started: "2026-06-14T09:00:00Z"
updated: "2026-06-14T09:00:00Z"
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 7
name: Add-to-cart stub shows toast notification
expected: |
  On /shop.html, click the "Add to Bag" button on any product card.
  A charcoal/dark toast notification briefly appears confirming the action.
  No page navigation occurs.
awaiting: user response

## Tests

### 1. PLP loads products from Supabase
expected: Open /shop.html in the browser. While loading, 6 skeleton shimmer cards appear. After a moment they are replaced by real product cards (images, names, prices) pulled from Supabase. No hardcoded placeholder content remains.
result: issue
reported: "Yes, the content does appear, but you have to press the class category button for the card item to appear. However, if you go from the home screen to the /shop.html page, the content doesn't automatically appear."
severity: major

### 2. Activity filter tabs filter the grid
expected: On /shop.html, click the "Padel" activity tab. The product grid updates to show only Padel-category products. Click "Tennis" — grid updates to Tennis products. Click "All" — all products reappear. Each tab highlights as active when selected.
result: issue
reported: "Yes, but in the padel category there are also tennis products."
severity: major

### 3. Sub-category pills appear and filter
expected: With an activity tab selected (e.g. "Padel"), a row of sub-category pills appears below the tabs (e.g. "The Padel Edit", "Ace Ready", etc.). Clicking a pill filters further. Clicking the same pill again clears it. Pills are hidden when "All" activity is selected.
result: issue
reported: "Sub-category pills are a feature only at LOOKBOOK, not on shop.html PLP."
severity: major

### 4. Sort selector changes product order
expected: On /shop.html, change the sort dropdown from "New Arrivals" to "Price: High to Low". The grid re-renders with the most expensive products first. Changing to "Price: Low to High" reverses that order.
result: pass

### 5. URL syncs with active filters
expected: After selecting activity "Pilates" and sort "Price: Low to High", the browser URL updates (e.g. ?category=pilates&sort=price-asc) without a full page reload. Copying and pasting that URL into a new tab restores the same filters automatically.
result: pass

### 6. Colour swatch hover swaps product card image
expected: On a product card in the grid that has multiple colour variants, hovering over a colour dot (swatch) changes the product card's main image to show that colour. Moving off reverts it. Clicking a swatch pins that colour.
result: pass

### 7. Add-to-cart stub shows toast notification
expected: On /shop.html, click the "Add to Bag" button on any product card. A charcoal/dark toast notification briefly appears at the bottom-right of the screen confirming the action. No page navigation occurs.
result: [pending]

### 8. Empty state appears for no-match search
expected: On /shop.html, type a nonsense search term (e.g. "xyzzzz") into the sort/filter area or navigate to ?search=xyzzzz. The product grid shows an empty state message (not a blank screen) with a "Browse All Styles" call-to-action link.
result: [pending]

### 9. Nav search expands and shows autosuggest
expected: Click the search icon in the navigation bar on any page. An animated input field expands. Type 2 or more characters (e.g. "bra"). After a brief pause, a dropdown of matching product names appears. Clicking outside the search area collapses it.
result: [pending]

### 10. Search navigates correctly
expected: In the expanded nav search, type "sport" and press Enter. The browser navigates to /shop.html?search=sport and the grid shows matching products. Alternatively, click a suggestion from the autosuggest dropdown — it navigates directly to that product's detail page.
result: [pending]

### 11. PDP loads from URL slug
expected: From /shop.html, click any product card. The browser navigates to /product.html?slug=<product-slug>. The product detail page loads with the correct product name, images, price, colour swatches, and size options pulled from Supabase — no hardcoded placeholder content.
result: [pending]

### 12. Swiper gallery + thumbnail sync
expected: On /product.html, the main product image is displayed in a large gallery. Below it are 4 thumbnail images. Clicking a thumbnail advances the main gallery to that image. Swiping/dragging the main image also moves between images.
result: [pending]

### 13. Colour swatch syncs gallery to that colour
expected: On /product.html, click a colour swatch. The main gallery slides to the first image for that colour variant. The swatch shows an active outline ring. Clicking a different swatch moves the gallery to that colour's images.
result: [pending]

### 14. Sticky ATC bar appears on scroll
expected: On /product.html, scroll down past the main "Add to Bag" button. A sticky bar slides up from the bottom of the screen showing the product name, selected colour/size, price, and a compact "Add to Bag" button. Scrolling back up to the main button hides the sticky bar.
result: [pending]

### 15. Size guide modal opens with focus trap
expected: On /product.html, click the "Size Guide" link. A modal overlay appears with a size chart (XS through XL with Bust/Waist/Hips measurements). Tab key cycles only within the modal. Pressing Escape or clicking outside the modal closes it and returns focus to the Size Guide link.
result: [pending]

### 16. Fabric & Care accordion
expected: On /product.html, there is a "Fabric Details" and a "Care Instructions" accordion section below the purchase area. Clicking a section heading expands it to reveal the content. Clicking again collapses it. Both can be open at the same time.
result: [pending]

### 17. Complete the Look pairings
expected: On a product detail page that has pairings seeded (most products should), a "Complete the Look" section appears below the main product info. It shows 1–4 paired product cards with image, name, and price. Clicking a card navigates to that product's PDP.
result: [pending]

### 18. You Might Also Love related products
expected: On /product.html, a "You Might Also Love" section shows products from the same category (4 cards on desktop, 2 on mobile). Clicking a card navigates to that product's detail page.
result: [pending]

### 19. Customer reviews with aggregate rating
expected: On /product.html, a "What Our Community Says" section shows the overall star rating (large number + stars) and individual review cards with reviewer name, date, star rating, fit badge (True to Size / Runs Small / Runs Large), and review text. The aggregate rating reflects all reviews, not just the visible ones.
result: [pending]

### 20. Load More Reviews
expected: If a product has more than 5 reviews, only the first 5 are shown initially and a "Load More Reviews" button appears below. Clicking it loads the next batch of reviews and appends them below the existing ones. The button disappears once all reviews are shown.
result: [pending]

## Summary

total: 20
passed: 3
issues: 3
skipped: 0
blocked: 0
pending: 14

## Gaps

- truth: "PLP product grid auto-loads on page open without requiring user interaction"
  status: failed
  reason: "User reported: products only appear after clicking a category/activity tab button; navigating directly to /shop.html shows no products"
  severity: major
  test: 1
  artifacts: []
  missing: []

- truth: "Sub-category pills appear on /shop.html PLP below activity tabs when a specific activity is selected"
  status: failed
  reason: "User reported: sub-category pills only exist on the Lookbook page, not on shop.html"
  severity: major
  test: 3
  artifacts: []
  missing: []

- truth: "Padel activity tab shows only Padel products, not products from other activities"
  status: failed
  reason: "User reported: Padel category also shows tennis products — activity filter not isolating correctly"
  severity: major
  test: 2
  artifacts: []
  missing: []
