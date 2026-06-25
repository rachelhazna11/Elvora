---
status: complete
phase: 06-cart-checkout
source: 06-06-SUMMARY.md, 06-07-SUMMARY.md, 06-08-SUMMARY.md
started: 2026-06-18T00:00:00Z
updated: 2026-06-18T00:00:00Z
note: Re-verification run — all 3 UAT gaps confirmed fixed
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Product Page Loads Correctly When Logged In
expected: Login first, then navigate to any product detail page. The page renders the product UI normally — name, images, colour selector, size buttons, "Add to Bag" button. No raw JavaScript code visible as page text. No SyntaxError in console.
result: pass

### 2. Cart Items Persist After Login (No Disappearing)
expected: While logged in, add 1 item to the cart. Navigate away (e.g. to the shop, then back to the product). The item is still in the cart — it has not disappeared. Cart badge count matches.
result: pass

### 3. Checkout Step 1 — Province, Postal Code, Phone Are Required
expected: Go to checkout (add an item first if needed). On Step 1 (Shipping), fill in First Name, Last Name, Address, City, and Email only — leave Province, Postal Code, and Phone blank. Click Next. The step does NOT advance. Error messages appear under the empty required fields.
result: pass

### 4. Checkout Step 3 — Card Fields Are Required Before Placing Order
expected: Complete Steps 1 and 2, then reach Step 3 (Payment). Leave card number, expiry, and CVV blank. Click "Place Order". The order is NOT placed. An error message appears requiring card details to be filled in.
result: pass

### 5. Checkout Step 3 — Card Fields Are Editable
expected: On Step 3 (Payment), click the card number field and type a number (e.g. 4111 1111 1111 1111). The field accepts input. The mock card visual on the page updates to reflect the number you typed.
result: pass

### 6. Google OAuth Profile Saved to Supabase
expected: Sign out if logged in. Sign in using Google ("Continue with Google"). After redirect back to the site, go to your Account page. Your first name, last name, and username should be populated (pulled from your Google account). They are not blank.
note: Requires migration 006_handle_new_user.sql to be applied in Supabase SQL Editor first
result: pass

### 7. Guest Cart Preserved After Google Sign-In
expected: Sign out completely. Add 1–2 items to cart while logged out (guest). Then sign in using Google. After redirect back, check the cart. The items you added as a guest are still there — they were not lost when you signed in.
result: pass

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
