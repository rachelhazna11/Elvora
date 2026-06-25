#!/usr/bin/env node
/**
 * Upload gambar produk dari folder lokal ke Supabase Storage.
 *
 * CARA PAKAI:
 *   node scripts/upload-images.js <folder-gambar> [product_id]
 *
 * Contoh — upload saja, dapatkan URL:
 *   node scripts/upload-images.js ./my-images/
 *
 * Contoh — upload + otomatis insert ke tabel product_images:
 *   node scripts/upload-images.js ./my-images/ c1000000-0000-0000-0000-000000000001
 *
 * Contoh — pakai file mapping (banyak produk sekaligus):
 *   node scripts/upload-images.js --map ./mapping.json
 *
 * FORMAT mapping.json:
 * [
 *   {
 *     "product_id": "c1000000-0000-0000-0000-000000000001",
 *     "folder": "./images/legging-serenity",
 *     "alt_prefix": "Serenity Ribbed Legging"
 *   }
 * ]
 *
 * SETUP:
 *   1. Tambahkan SUPABASE_SERVICE_ROLE_KEY ke file .env
 *   2. npm install @supabase/supabase-js dotenv
 *   3. Jalankan script
 *
 * Gambar yang disupport: .jpg, .jpeg, .png, .webp, .avif
 */

const fs = require('fs');
const path = require('path');

try {
  require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
} catch {
  // dotenv optional — env vars bisa di-set manual
}

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BUCKET = 'product-images';
const SUPPORTED_EXTS = ['.jpg', '.jpeg', '.png', '.webp', '.avif'];

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('ERROR: Set SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY di .env');
  console.error('  SUPABASE_URL=https://xxxxx.supabase.co');
  console.error('  SUPABASE_SERVICE_ROLE_KEY=eyJ...');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

function getPublicUrl(filePath) {
  const { data } = supabase.storage.from(BUCKET).getPublicUrl(filePath);
  return data.publicUrl;
}

function getImageFiles(folder) {
  const abs = path.resolve(folder);
  if (!fs.existsSync(abs)) {
    throw new Error(`Folder tidak ditemukan: ${abs}`);
  }
  return fs
    .readdirSync(abs)
    .filter((f) => SUPPORTED_EXTS.includes(path.extname(f).toLowerCase()))
    .sort()
    .map((f) => path.join(abs, f));
}

async function uploadFile(localPath, storagePath) {
  const buffer = fs.readFileSync(localPath);
  const ext = path.extname(localPath).toLowerCase();
  const mimeMap = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.avif': 'image/avif',
  };

  const { error } = await supabase.storage.from(BUCKET).upload(storagePath, buffer, {
    contentType: mimeMap[ext] ?? 'image/jpeg',
    upsert: true,
  });

  if (error) throw new Error(`Upload gagal (${path.basename(localPath)}): ${error.message}`);
  return getPublicUrl(storagePath);
}

async function insertProductImages(productId, images) {
  const rows = images.map(({ url, alt_text }, i) => ({
    product_id: productId,
    url,
    alt_text,
    display_order: i + 1,
  }));

  const { error: delErr } = await supabase
    .from('product_images')
    .delete()
    .eq('product_id', productId);

  if (delErr) {
    console.warn(`  Warning: gagal hapus gambar lama — ${delErr.message}`);
  }

  const { error } = await supabase.from('product_images').insert(rows);
  if (error) throw new Error(`Insert product_images gagal: ${error.message}`);
}

async function processFolder(folder, productId, altPrefix) {
  const files = getImageFiles(folder);
  if (files.length === 0) {
    console.warn(`  Tidak ada gambar di: ${folder}`);
    return [];
  }

  console.log(`  Ditemukan ${files.length} gambar di ${folder}`);
  const uploaded = [];

  for (const filePath of files) {
    const filename = path.basename(filePath);
    const storagePath = productId ? `${productId}/${filename}` : `misc/${filename}`;

    process.stdout.write(`  Uploading ${filename}... `);
    const url = await uploadFile(filePath, storagePath);
    console.log('OK');

    const idx = files.indexOf(filePath) + 1;
    uploaded.push({
      url,
      alt_text: altPrefix ? `${altPrefix} ${idx}` : filename.replace(/\.[^.]+$/, ''),
    });
  }

  return uploaded;
}

async function main() {
  const args = process.argv.slice(2);

  // Mode: --map ./mapping.json
  if (args[0] === '--map') {
    const mapFile = args[1];
    if (!mapFile || !fs.existsSync(mapFile)) {
      console.error('ERROR: File mapping tidak ditemukan');
      process.exit(1);
    }

    const mapping = JSON.parse(fs.readFileSync(mapFile, 'utf8'));
    console.log(`\nMemproses ${mapping.length} produk dari ${mapFile}\n`);

    for (const entry of mapping) {
      console.log(`\nProduk: ${entry.product_id}`);
      console.log(`Folder: ${entry.folder}`);

      try {
        const uploaded = await processFolder(entry.folder, entry.product_id, entry.alt_prefix ?? '');

        if (entry.product_id && uploaded.length > 0) {
          await insertProductImages(entry.product_id, uploaded);
          console.log(`  Inserted ${uploaded.length} baris ke product_images`);
        }
      } catch (err) {
        console.error(`  GAGAL: ${err.message}`);
      }
    }

    console.log('\nSelesai!');
    return;
  }

  // Mode: <folder> [product_id]
  const folder = args[0];
  const productId = args[1];

  if (!folder) {
    console.log('Cara pakai:');
    console.log('  node scripts/upload-images.js <folder> [product_id]');
    console.log('  node scripts/upload-images.js --map ./mapping.json');
    process.exit(1);
  }

  console.log(`\nUpload dari: ${folder}`);
  if (productId) console.log(`Product ID: ${productId}`);

  try {
    const uploaded = await processFolder(folder, productId, '');

    if (productId && uploaded.length > 0) {
      await insertProductImages(productId, uploaded);
      console.log(`\nInserted ${uploaded.length} gambar ke product_images.`);
    }

    console.log('\nURL hasil upload:');
    uploaded.forEach(({ url }, i) => console.log(`  ${i + 1}. ${url}`));
    console.log('\nSelesai!');
  } catch (err) {
    console.error(`\nGAGAL: ${err.message}`);
    process.exit(1);
  }
}

main();
