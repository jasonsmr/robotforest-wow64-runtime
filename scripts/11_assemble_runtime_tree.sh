#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
OUT="${OUT:-$ROOT/dist}"
NAME="rf_runtime-$(date +%Y%m%d-%H%M%S).tar.zst"

mkdir -p "$OUT"
cd "$STAGE"

# prune caches/logs if any
rm -rf ./prefix/drive_c/users/*/Temp || true
rm -rf ./prefix/drive_c/ProgramData/Package Cache || true

echo "[pack] ${OUT}/${NAME}"
tar --owner=0 --group=0 -I "zstd -19 --long=31" -cf "${OUT}/${NAME}" .

echo "[ok] wrote ${OUT}/${NAME}"
