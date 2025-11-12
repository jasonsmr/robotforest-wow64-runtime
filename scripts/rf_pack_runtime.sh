#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.."; pwd)"
STAGE="$REPO/staging"
ROOT="$STAGE/rf_runtime"
OUT="$REPO/dist"
mkdir -p "$OUT"

# Derive TAG
TAG="${RF_TAG:-${GITHUB_REF_NAME:-dev}}"
DATE="$(date +%Y%m%d-%H%M%S)"
BASE="rf-runtime-${TAG}"

# Sanity: wrappers must exist
test -x "$ROOT/bin/wine64.sh"
test -x "$ROOT/bin/wine32on64.sh"
test -x "$ROOT/bin/steam-win.sh"

# 1) tar.zst
TAR="$OUT/${BASE}.tar.zst"
echo "[pack] ${TAR}"
tar -C "$STAGE" -I 'zstd --long=31 -19' -cf "$TAR" rf_runtime
( cd "$OUT" && sha256sum "$(basename "$TAR")" > "$(basename "$TAR").sha256" )

# 2) zip
ZIP="$OUT/${BASE}.zip"
echo "[pack] ${ZIP}"
cd "$STAGE"
zip -q -r "$ZIP" rf_runtime
cd - >/dev/null
( cd "$OUT" && sha256sum "$(basename "$ZIP")" > "$(basename "$ZIP").sha256" )

echo "[ok] built:"
ls -lh "$TAR" "$TAR.sha256" "$ZIP" "$ZIP.sha256"
