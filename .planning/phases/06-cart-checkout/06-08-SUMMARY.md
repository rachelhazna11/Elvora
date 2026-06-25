---
phase: 06-cart-checkout
plan: 06-08
subsystem: checkout
tags: [validation, forms, payment, alpine]
requires: []
provides: [checkout-step1-required-fields, checkout-payment-validation]
affects: [checkout.html]
tech_stack:
  added: []
  patterns: [alpine-x-model, alpine-errors-object, alpine-x-show-errors]
key_files:
  modified: [checkout.html]
decisions:
  - validatePayment() uses errorMsg (global) not errors object — consistent with placeOrder error display pattern
  - Card fields use labels with * marker — mirrors Step 1 required field convention
  - maxlength on card inputs (19 for number, 5 for expiry, 4 for CVV) — basic UX guardrail, no format enforcement per MVP scope
metrics:
  duration_minutes: 12
  completed: "2026-06-17T15:56:11Z"
  tasks_completed: 6
  files_modified: 1
---

# Phase 06 Plan 08: Fix Checkout Validation — Required Province, Postal Code, Phone + Payment Fields Summary

**One-liner:** Province, Postal Code, and Phone made required in Step 1; card inputs converted from readonly to editable x-model fields with validatePayment() guard on Place Order.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add province/postalCode/phone to validateStep1() | 9a4620a | checkout.html |
| 2 | Province * label and error binding | 292e8de | checkout.html |
| 3 | Postal Code * and Phone * labels with error bindings | 3ca8178 | checkout.html |
| 4 | (combined with Task 3) | — | — |
| 5 | cardNumber/expiry/cvv state + validatePayment() + placeOrder guard | 5f8d018 | checkout.html |
| 6 | Replace readonly card inputs with editable x-model fields + live card visual | d4427a3 | checkout.html |

## What Was Built

### Step 1 Validation Fixes
- `validateStep1()` now checks `province`, `postalCode`, and `phone` after `city`
- All three fields produce error messages in the `errors` object, blocking step advance
- HTML labels updated: `Province *`, `Postal Code *`, `Phone *`
- Each input gets `:class="{ 'error': errors.X }"` Alpine binding
- Each input gets `<p x-show="errors.X" x-text="errors.X" class="checkout-field-error">` error paragraph

### Step 3 Payment Fixes
- `cardNumber`, `expiry`, `cvv` state fields added to `checkoutData()` return object
- `validatePayment()` method added — checks each field in order, sets `errorMsg` on first failure
- `placeOrder()` calls `validatePayment()` at start and returns early if invalid
- Card Number input: `x-model="cardNumber"`, `placeholder="1234 5678 9012 3456"`, `maxlength="19"`, editable
- Expiry input: `x-model="expiry"`, `placeholder="MM/YY"`, `maxlength="5"`, editable
- CVV input: `x-model="cvv"`, `placeholder="123"`, `maxlength="4"`, editable
- Mock card visual number: `x-text="cardNumber || '•••• •••• •••• ••••'"` — reflects typed value live

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None that affect plan goal. Payment is intentionally placeholder per CLAUDE.md ("Payments: Placeholder architecture only").

## Self-Check

- [x] Province, Postal Code, Phone required in validateStep1() — errors block step advance
- [x] Labels show * for all three newly required fields
- [x] Error paragraphs wired with x-show/x-text to errors object
- [x] Card inputs editable (no readonly attribute)
- [x] cardNumber, expiry, cvv bound via x-model
- [x] validatePayment() called at start of placeOrder()
- [x] Mock card visual reflects typed card number

## Self-Check: PASSED
