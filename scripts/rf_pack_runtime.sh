#!/usr/bin/env bash
# scripts/rf_pack_runtime.sh
#
# Build rf-runtime-dev.{tar.zst,zip} from the staging runtime tree.
#
# Input tree:
#   staging/rf_runtime/
#     bin/
#     dxvk/
#     vkd3d/
#     wine32/
#     wine64/
#     x86_64-linux/
#     i386-linux/
#     prefix/
#     proton/
#
# Outputs:
#   dist/rf-runtime-dev.tar.zst
#   dist/rf-runtime-dev.tar.zst.sha256
#   dist/rf-runtime-dev.zip
#   dist/rf-runtime-dev.zip.sha256
#
# IMPORTANT: This script uses ONLY standard zstd options to keep the window
# size small enough for Termux's zstd to decode. NO --long=31 here.

set -euo pipefail

# Root of the repo
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STAGING="$ROOT/staging/rf_runtime"
DIST="$ROOT/dist"

TAG="${RF_TAG:-dev}"

echo "[rf/pack] Using:"
echo "  ROOT    = $ROOT"
echo "  STAGING = $STAGING"
echo "  DIST    = $DIST"
echo "  RF_TAG  = $TAG"
echo

if [ ! -d "$STAGING" ]; then
  echo "[rf/pack] ERROR: staging tree not found: $STAGING"
  exit 1
fi

mkdir -p "$DIST"

TAR="$DIST/rf-runtime-dev.tar.zst"
ZIP="$DIST/rf-runtime-dev.zip"

# Clean previous outputs
rm -f \
  "$TAR" "$TAR.sha256" \
  "$ZIP" "$ZIP.sha256"

echo "[rf/pack] Staging layout (depth <= 2):"
find "$STAGING" -maxdepth 2 -type d | sed "s|$ROOT||"
echo

###############################################################################
# Build rf-runtime-dev.tar.zst
###############################################################################
echo "[rf/pack] Building $TAR ..."
# NOTE: No --long=31 here; keep window Termux-friendly.
tar -C "$STAGING" -cf - . | zstd -T0 -19 -o "$TAR"

echo "[rf/pack] Computing sha256 for tar.zst ..."
(
  cd "$DIST"
  sha256sum "$(basename "$TAR")" > "$(basename "$TAR").sha256"
)

###############################################################################
# Build rf-runtime-dev.zip
###############################################################################
echo "[rf/pack] Building $ZIP ..."
(
  cd "$STAGING"
  # The archive root is ".", to match tar layout (bin/, dxvk/, etc.).
  zip -9r "$ZIP" .
)

echo "[rf/pack] Computing sha256 for zip ..."
(
  cd "$DIST"
  sha256sum "$(basename "$ZIP")" > "$(basename "$ZIP").sha256"
)

echo
echo "[rf/pack] Done. Artifacts:"
ls -lh "$DIST"/rf-runtime-dev.tar.zst* "$DIST"/rf-runtime-dev.zip* || true
