#!/usr/bin/env bash
# scripts/rf_runtime_import_local_stub.sh
#
# Import a locally-built rf-runtime-dev.tar.zst into the Android runtime tree.
# This is meant for *developer* workflows, not CI:
#   - You build rf-runtime-dev.tar.zst on host (or on-device, like you just did).
#   - You run this script to overlay it into ~/.local/share/robotforest/runtime.
#
# Usage:
#   scripts/rf_runtime_import_local_stub.sh /path/to/rf-runtime-dev.tar.zst
#   RF_LOCAL_STUB=/path/to/rf-runtime-dev.tar.zst scripts/rf_runtime_import_local_stub.sh

set -euo pipefail

ARCHIVE="${1:-${RF_LOCAL_STUB:-}}"

if [ -z "${ARCHIVE}" ]; then
  echo "[rf/local-import] ERROR: no archive specified."
  echo "[rf/local-import] Usage:"
  echo "  scripts/rf_runtime_import_local_stub.sh /path/to/rf-runtime-dev.tar.zst"
  echo "  RF_LOCAL_STUB=/path/to/rf-runtime-dev.tar.zst scripts/rf_runtime_import_local_stub.sh"
  exit 1
fi

if [ ! -f "$ARCHIVE" ]; then
  echo "[rf/local-import] ERROR: archive not found: $ARCHIVE"
  exit 1
fi

RUNTIME_REAL="${RF_RUNTIME_ROOT:-"$HOME/.local/share/robotforest/runtime"}"
RUNTIME_STUB="$HOME/.local/share/robotforest/runtime-stub-import"

echo "[rf/local-import] Using:"
echo "  ARCHIVE      = $ARCHIVE"
echo "  RUNTIME_REAL = $RUNTIME_REAL"
echo "  RUNTIME_STUB = $RUNTIME_STUB"
echo

# 1) Fresh temp area
rm -rf "$RUNTIME_STUB"
mkdir -p "$RUNTIME_STUB"

echo "[rf/local-import] Extracting archive into temp area..."
zstd -d -c "$ARCHIVE" | tar -C "$RUNTIME_STUB" -xvf -
echo

# 2) Overlay onto real runtime (NO delete; keeps rf_env.sh, MANIFEST, etc.)
echo "[rf/local-import] Overlaying stub tree into real runtime..."
mkdir -p "$RUNTIME_REAL"
rsync -a "$RUNTIME_STUB"/ "$RUNTIME_REAL"/

echo
echo "[rf/local-import] Layout after import (depth <= 2):"
find "$RUNTIME_REAL" -maxdepth 2 -type d | sed "s|$HOME||"

echo
echo "[rf/local-import] Done. You can now sanity-check with:"
echo "  cd \"$RUNTIME_REAL\""
echo "  ./rf_runtime_layout_check.sh"
echo "  . ./rf_env.sh"
echo "  wine64-rf --version"
echo "  wine32on64-rf --version"
