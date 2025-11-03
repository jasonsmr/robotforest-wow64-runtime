set -euo pipefail
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

# Helpers
extract_zst() {
  # Usage: extract_zst <archive.zst> <destdir>
  set -euo pipefail
  in="$1"; out="$2"
  mkdir -p "$out"
  # robust: do not assume tar --zstd; use unzstd | tar -x
  command -v unzstd >/dev/null 2>&1 || { echo >&2 "[err] zstd not present"; exit 1; }
  unzstd -c "$in" | tar -x -C "$out"
}
