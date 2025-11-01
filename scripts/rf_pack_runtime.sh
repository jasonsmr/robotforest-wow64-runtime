#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/android/robotforest-wow64-runtime"
STAGE="$ROOT/staging/rf_runtime"
DIST="$ROOT/dist"

mkdir -p "$DIST"

# friendly stamp
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$DIST/robotforest-wow64-runtime-$STAMP.zip"

cd "$STAGE"
# Exclude obvious junk if present
zip -r "$OUT" . -x '*/.git/*' '*/__pycache__/*' >/dev/null

echo "[pack] wrote $OUT"
