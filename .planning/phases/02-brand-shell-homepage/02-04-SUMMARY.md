# Plan 04 Summary — Live Supabase Sections

**Phase:** 02-brand-shell-homepage
**Plan:** 04
**Wave:** 3
**Status:** Complete
**Executed:** 2026-06-12

## What Was Built

3 additional sections appended to `index.html` `<main>`, completing all 8 homepage sections:

6. **Best Sellers** — Alpine x-data async init fetches `supabase.from('products').select(...).limit(4)`, loading skeleton (4 `animate-pulse` cards), error state with graceful copy, product grid with `<template x-for>`, product cards: image (3:4 aspect), name, price, up to 4 colour swatch dots from `product_variants.color_hex`
7. **Testimonials** — Alpine x-data async init fetches `supabase.from('testimonials').select('*').eq('is_active', true).limit(3)`, loading skeleton (3 pulse cards), testimonial cards: large rose quote mark, italic quote body, author avatar (initial letter, alternating bg) + name + activity label. No star ratings (per F-006).
8. **Newsletter** — Alpine x-data with `submitNewsletter()`: inserts into `newsletter_subscribers`, handles duplicate (error.code '23505') with "You're already part of the inner circle.", generic error with "Something went wrong — please try again.", success state "You're on the list. Welcome to Elvora." Input has `style="font-size: 16px;"` (iOS Safari zoom prevention per Pitfall 3).

`window.supabase = supabase` is set in `js/components.js` so Alpine inline x-data can access the client.

## Verification

- ✅ supabase.from('products') in best sellers x-data
- ✅ supabase.from('testimonials') in testimonials x-data
- ✅ newsletter_subscribers.insert() in newsletter x-data
- ✅ animate-pulse skeleton states in both data sections
- ✅ color_hex swatch binding in best sellers cards
- ✅ error.code '23505' duplicate handling
- ✅ font-size: 16px on newsletter input
- ✅ 8 <section> elements in index.html <main>
- ✅ No star ratings in testimonials (per F-006)
- ✅ Tailwind build: Done, no errors
