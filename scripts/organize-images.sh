#!/usr/bin/env bash
# Salin gambar dari folder images/ yang flat ke sub-folder per produk.
# Jalankan dari root project: bash scripts/organize-images.sh
set -euo pipefail

SRC="./images"

copy() {
  local src="$SRC/$1"
  local dest_dir="$SRC/$2"
  mkdir -p "$dest_dir"
  if [ -f "$src" ]; then
    cp "$src" "$dest_dir/"
    echo "  copied: $1 → $2/"
  else
    echo "  MISSING: $src"
  fi
}

echo "=== Mengorganisir gambar ke sub-folder produk ==="

echo ""
echo "P01 — Contour Seam Legging"
copy "gym 5.jpg"   "01-contour-seam-legging"
copy "gym 7.jpg"   "01-contour-seam-legging"

echo ""
echo "P02 — Court Racerback Bra"
copy "tenis 6.jpg" "02-court-racerback-bra"
copy "tenis 8.jpg" "02-court-racerback-bra"

echo ""
echo "P03 — Twist Ease Long Sleeve"
copy "gym 1.jpg"   "03-twist-ease-long-sleeve"
copy "gym 3.jpg"   "03-twist-ease-long-sleeve"

echo ""
echo "P04 — Kinetic Crop Tee"
copy "gym 2.jpg"   "04-kinetic-crop-tee"
copy "gym 4.jpg"   "04-kinetic-crop-tee"

echo ""
echo "P05 — Active Flow Tunic"
copy "lari 3.jpg"  "05-active-flow-tunic"
copy "lari 4.jpg"  "05-active-flow-tunic"

echo ""
echo "P06 — Swift Crop Long Sleeve"
copy "lari 1.jpg"  "06-swift-crop-long-sleeve"

echo ""
echo "P07 — Motion Marl Hoodie"
copy "gym 6.jpg"   "07-motion-marl-hoodie"
copy "gym 8.jpg"   "07-motion-marl-hoodie"

echo ""
echo "P08 — Revive Half-Zip"
copy "lari 2.jpg"  "08-revive-half-zip"
copy "tenis 2.jpg" "08-revive-half-zip"

echo ""
echo "P09 — Shell Run Jacket"
copy "lari 6.jpg"  "09-shell-run-jacket"
copy "lari 8.jpg"  "09-shell-run-jacket"
copy "tenis 1.jpg" "09-shell-run-jacket"

echo ""
echo "P10 — Pace Running Shorts"
copy "lari 7.jpg"  "10-pace-running-shorts"

echo ""
echo "P11 — Soft Day Wide-Leg Set"
copy "lari 5.jpg"  "11-soft-day-wide-leg-set"

echo ""
echo "P12 — Polo Court Set"
copy "padel 4.jpg" "12-polo-court-set"
copy "padel 5.jpg" "12-polo-court-set"

echo ""
echo "P13 — Grand Slam Court Dress"
copy "padel 1.jpg" "13-grand-slam-court-dress"
copy "padel 2.jpg" "13-grand-slam-court-dress"

echo ""
echo "P14 — Rally Pleated Court Skirt"
copy "padel 3.jpg" "14-rally-pleated-court-skirt"
copy "tenis 5.jpg" "14-rally-pleated-court-skirt"
copy "tenis 7.jpg" "14-rally-pleated-court-skirt"

echo ""
echo "P15 — Ace Tennis Dress"
copy "padel 6.jpg" "15-ace-tennis-dress"
copy "padel 7.jpg" "15-ace-tennis-dress"
copy "padel 8.jpg" "15-ace-tennis-dress"
copy "tenis 3.jpg" "15-ace-tennis-dress"
copy "tenis 4.jpg" "15-ace-tennis-dress"

echo ""
echo "=== Selesai! ==="
echo "Sub-folder yang dibuat:"
ls "$SRC" | grep -E "^[0-9]" | sed 's/^/  /'
