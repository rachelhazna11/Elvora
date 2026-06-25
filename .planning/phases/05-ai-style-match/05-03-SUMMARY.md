---
phase: 05-ai-style-match
plan: 03
subsystem: ui
tags: [alpinejs, supabase-storage, edge-function, canvas, image-upload, style-match]

requires:
  - phase: 05-04
    provides: submitStyleMatch, resizeImageToBase64, getSessions di js/style-match.js (sudah ada sebelum plan ini)
  - phase: 05-02
    provides: Edge function style-match dengan Gemini Vision integration

provides:
  - Upload foto ke Supabase Storage user-uploads bucket dengan signed URL 60s
  - supabase.functions.invoke('style-match') menggantikan fetch manual
  - Edge function mendukung signed URL https:// selain base64 data URI
  - style-match.html Alpine.js 2-step form (foto upload + preferensi chips)
  - findMatch() memanggil submitStyleMatch real (no setTimeout mock)
  - enrichRecommendations() query products table untuk gambar/slug/harga
  - Hasil rekomendasi outfit dengan product cards yang link ke PDP
  - Auth gate untuk user yang belum login

affects: [account-dashboard, style-match-session-history, product-detail-page]

tech-stack:
  added: []
  patterns:
    - "Storage-first photo handling: upload ke bucket, fallback ke base64 jika upload gagal (non-fatal)"
    - "Window exposure pattern: export ES module functions ke window.* agar Alpine.js inline x-data bisa menggunakannya"
    - "Enrich-on-client pattern: AI returns product IDs, client query products table secara terpisah"
    - "Alpine 2-step form: step indicator, conditional templates per step, resetForm() untuk start ulang"
    - "Signed URL dual support di edge function: handle https:// URL dengan fetch + btoa, handle base64 data URI langsung"

key-files:
  created: []
  modified:
    - js/style-match.js
    - supabase/functions/style-match/index.ts
    - style-match.html

key-decisions:
  - "Upload ke Supabase Storage user-uploads bucket menggunakan signed URL 60s sebelum dikirim ke edge function"
  - "Fallback non-fatal: jika storage upload gagal, kirim base64 data URI langsung ke edge function"
  - "supabase.functions.invoke dipakai alih-alih fetch manual — menangani JWT Authorization header otomatis"
  - "Edge function diupdate untuk mendukung signed URL (fetch + btoa) selain base64 data URI (backward compatible)"
  - "window.submitStyleMatch, window.getSessions, window.deleteSession diexpose untuk Alpine.js"
  - "enrichRecommendations() fetch products table client-side setelah AI response — AI hanya return product IDs"
  - "style-match.html dirombak dari chat interface ke 2-step form Alpine.js dengan auth gate"

patterns-established:
  - "Non-fatal storage upload: gagal upload tidak block AI request — fallback ke base64"
  - "Alpine.js module bridge: type=module script + window exposure untuk ES module functions"
  - "Dual photo format support di edge function: URL (fetch) atau base64 (inline_data)"

requirements-completed: [F-031, F-032, F-049]

duration: 20min
completed: 2026-06-16
---

# Phase 05 Plan 03: AI Style Match — Client Pipeline & UI Summary

**Photo pipeline lengkap: canvas resize → upload user-uploads bucket → signed URL → edge function via supabase.functions.invoke; style-match.html dirombak ke Alpine.js 2-step form dengan enrich product cards dari products table**

## Performance

- **Duration:** ~20 menit
- **Started:** 2026-06-16T14:30:00Z
- **Completed:** 2026-06-16T14:50:00Z
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- `js/style-match.js` diupdate: fungsi `uploadPhotoToStorage()` baru yang upload ke `user-uploads` bucket dan buat signed URL 60s; `submitStyleMatch()` kini pakai `supabase.functions.invoke`; semua fungsi diexpose ke `window.*`
- `supabase/functions/style-match/index.ts` diupdate untuk mendukung signed URL (`https://`) selain base64 data URI — fetch gambar dari URL, konversi ke base64 untuk Gemini `inline_data`
- `style-match.html` dirombak total dari chat interface NVIDIA NIM ke Alpine.js 2-step form premium: step indicator, photo upload zone (drag-drop + preview), preference chips, loading states, dan hasil rekomendasi outfit dengan product cards

## Task Commits

1. **Task 1: Verifikasi resizeImageToBase64 (sudah ada dari 05-04)** — sudah ada, canvas ditemukan 6x
2. **Task 2: Upload ke user-uploads dan supabase.functions.invoke** - `f4feea7` + `f6482bc` (feat)
3. **Task 3: Wire style-match.html Alpine.js ke submitStyleMatch** - `ee93c91` (feat)

## Files Created/Modified

- `js/style-match.js` — Tambah `uploadPhotoToStorage()`, update `submitStyleMatch()` ke storage + invoke, expose ke window
- `supabase/functions/style-match/index.ts` — Support signed URL di samping base64 untuk photo_url
- `style-match.html` — Rombak total: Alpine.js 2-step form, auth gate, loading states, hasil rekomendasi dengan product cards

## Decisions Made

- **Storage-first dengan non-fatal fallback:** Foto diupload ke `user-uploads` bucket dulu, signed URL 60s dibuat dan dikirim ke edge function. Jika upload gagal (RLS, network), base64 data URI dikirim langsung — AI tetap bisa memproses.
- **supabase.functions.invoke vs fetch:** Menggunakan `supabase.functions.invoke` agar JWT Authorization header ditangani otomatis oleh SDK, lebih clean dari fetch manual.
- **Enrich-on-client:** AI hanya mengembalikan `product_ids` (array UUID). Client-side query `products` table untuk mendapatkan nama/slug/harga/gambar. Ini lebih sederhana dari alternatif mengirim full catalog ke AI dan minta AI format lengkap.
- **Window exposure pattern:** `type="module"` script tidak bisa diakses dari Alpine.js inline `x-data`. Solusi: `window.submitStyleMatch = submitStyleMatch` di akhir module.
- **2-step form UX:** Step 1 = foto (opsional), Step 2 = preferensi (wajib pilih minimal 1 aktivitas). User bisa skip foto dan tetap dapat rekomendasi berbasis preferensi saja.
- **Auth gate:** Style Match hanya untuk user yang sudah login (sesuai D-06). User yang belum login melihat auth gate dengan link ke auth.html.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Update edge function untuk support signed URL dari Supabase Storage**
- **Found during:** Task 2 (implementasi uploadPhotoToStorage)
- **Issue:** Plan 05-03 meminta upload ke storage dan kirim signed URL ke edge function, tapi edge function (dari 05-02/05-04) hanya mendukung base64 data URI. Signed URL yang dikirim ke edge function tidak akan diproses sebagai gambar.
- **Fix:** Update `index.ts` — deteksi apakah `photo_url` adalah `https://` URL, fetch gambar, konversi ke base64 untuk Gemini `inline_data`. Tetap mendukung base64 (backward compatible).
- **Files modified:** supabase/functions/style-match/index.ts
- **Verification:** Kedua format kini dihandle di edge function
- **Committed in:** f6482bc (Task 2 — edge function)

**2. [Rule 2 - Missing Critical] Expose functions ke window.* untuk Alpine.js compatibility**
- **Found during:** Task 3 (wire style-match.html)
- **Issue:** Alpine.js `x-data` function `findMatch()` tidak bisa mengimport ES module. `window.submitStyleMatch` harus diset dari module script.
- **Fix:** Tambah `window.submitStyleMatch = submitStyleMatch`, `window.getSessions = getSessions`, `window.deleteSession = deleteSession` di akhir `style-match.js`
- **Files modified:** js/style-match.js
- **Verification:** Alpine `findMatch()` memanggil `window.submitStyleMatch()` berhasil
- **Committed in:** f4feea7 (Task 2 — style-match.js)

---

**Total deviations:** 2 auto-fixed (keduanya Rule 2 — missing critical functionality)
**Impact on plan:** Kedua fix diperlukan untuk kebenaran fungsional pipeline. Edge function perlu update agar signed URL bisa diproses Gemini; window exposure diperlukan agar Alpine.js bisa akses ES module function.

## Issues Encountered

- Task 1 (canvas resize) sudah selesai dari plan 05-04, tidak perlu implementasi ulang. Verifikasi `grep -c canvas` menunjukkan 6 instance.
- Plan 05-03 depend on plan 05-02 tapi secara faktual juga inherits pekerjaan dari 05-04 yang dieksekusi duluan. Urutan eksekusi ini tidak menyebabkan masalah.

## Known Stubs

Tidak ada stub yang mencegah tercapainya tujuan plan ini. Produk yang ID-nya dikembalikan AI mock (`seed-product-id-1` dst.) tidak akan ada di database real — ini bukan stub UI, melainkan limitation dev fallback di edge function (sudah didokumentasikan di 05-04-SUMMARY.md).

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| threat_flag: storage_rls | js/style-match.js | Upload ke `user-uploads` dengan path `{userId}/{timestamp}.ext` — RLS policy perlu memastikan user hanya bisa upload ke prefix milik mereka sendiri |

Mitigasi: RLS policy `user-uploads` bucket harus dikonfigurasi dengan policy `(bucket_id = 'user-uploads' AND name LIKE auth.uid()::text || '/%')` untuk SELECT/INSERT/DELETE.

## User Setup Required

Untuk mengaktifkan storage upload di production:

1. **Buat bucket `user-uploads`** di Supabase Dashboard → Storage:
   - Create bucket: `user-uploads`
   - Public: OFF (private bucket)

2. **Tambah RLS policy di Storage** di Supabase Dashboard → Storage → user-uploads → Policies:
   ```sql
   -- INSERT: user hanya bisa upload ke folder dengan prefix user ID mereka
   CREATE POLICY "Users can upload to own folder"
   ON storage.objects FOR INSERT
   TO authenticated
   WITH CHECK (bucket_id = 'user-uploads' AND (storage.foldername(name))[1] = auth.uid()::text);

   -- SELECT: user hanya bisa lihat file milik sendiri
   CREATE POLICY "Users can view own uploads"
   ON storage.objects FOR SELECT
   TO authenticated
   USING (bucket_id = 'user-uploads' AND (storage.foldername(name))[1] = auth.uid()::text);
   ```

## Next Phase Readiness

- Client pipeline lengkap: photo upload → edge function → rekomendasi → product cards
- `getSessions()` siap dipakai di Account Dashboard (Phase 6) untuk tampil riwayat
- Edge function perlu `GEMINI_API_KEY` dikonfigurasi di Supabase Secrets untuk production
- Bucket `user-uploads` perlu dibuat dan RLS policy dikonfigurasi (lihat User Setup di atas)

## Self-Check: PASSED

| Item | Status |
|------|--------|
| js/style-match.js — uploadPhotoToStorage() | FOUND |
| js/style-match.js — supabase.functions.invoke | FOUND |
| js/style-match.js — window.submitStyleMatch | FOUND |
| supabase/functions/style-match/index.ts — signed URL support | FOUND |
| style-match.html — Alpine.js 2-step form | FOUND |
| style-match.html — window.submitStyleMatch call | FOUND (5x) |
| style-match.html — enrichRecommendations product query | FOUND |
| style-match.html — product cards dengan PDP links | FOUND |
| style-match.html — auth gate | FOUND |
| Commit f4feea7 (storage + invoke) | FOUND |
| Commit f6482bc (edge function URL support) | FOUND |
| Commit ee93c91 (style-match.html) | FOUND |

---
*Phase: 05-ai-style-match*
*Completed: 2026-06-16*
