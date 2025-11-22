#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# RobotForest Wine32 build scaffolding (Path A, WoW64 side)
# -----------------------------------------------------------------------------
# This script does NOT actually build Wine yet.
# It defines canonical paths for the 32-bit WoW64 side that will live in
# staging/rf_runtime/wine32.
# -----------------------------------------------------------------------------

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNTIME_STAGE="$ROOT/staging/rf_runtime"

WINE32_PREFIX="$RUNTIME_STAGE/wine32"

SRC_ROOT="${SRC_ROOT:-$HOME/src}"
BUILD_ROOT="${BUILD_ROOT:-$HOME/build}"

WINE32_SRC="${WINE32_SRC:-$SRC_ROOT/wine32-src}"
WINE32_BUILD="${WINE32_BUILD:-$BUILD_ROOT/wine32-build}"

echo "[wine32] RobotForest Wine32 scaffolding"
echo "  ROOT          = $ROOT"
echo "  RUNTIME_STAGE = $RUNTIME_STAGE"
echo "  WINE32_PREFIX = $WINE32_PREFIX"
echo "  WINE32_SRC    = $WINE32_SRC"
echo "  WINE32_BUILD  = $WINE32_BUILD"
echo

for d in "$RUNTIME_STAGE" "$RUNTIME_STAGE/bin" "$RUNTIME_STAGE/i386-linux"; do
  if [ ! -d "$d" ]; then
    echo "[wine32][ERROR] Missing required directory: $d"
    exit 1
  fi
done

if [ ! -d "$WINE32_PREFIX" ]; then
  echo "[wine32] Creating wine32/ prefix: $WINE32_PREFIX"
  mkdir -p "$WINE32_PREFIX"/bin
fi

echo "[wine32] Current wine32/ contents (top-level):"
ls -1 "$WINE32_PREFIX" || echo "  (empty)"
echo

mkdir -p "$WINE32_SRC" "$WINE32_BUILD"

echo "[wine32] Source directory prepared: $WINE32_SRC"
echo "[wine32] Build directory prepared:  $WINE32_BUILD"
echo

cat << 'BUILD_NOTES'
[wine32] BUILD STEPS (NOT RUN YET):

  # 1) Populate WINE32_SRC with a WoW64-capable Wine tree that matches wine64.
  #      git clone <same wine/proton repo> "$WINE32_SRC"
  #
  # 2) Enter the build dir:
  #      cd "$WINE32_BUILD"
  #
  # 3) Configure 32-bit Wine (example only):
  #      ../configure \
  #        --with-wine64="$WINE64_BUILD_OR_PREFIX" \
  #        --prefix="$WINE32_PREFIX" \
  #        <32-bit toolchain flags>
  #
  # 4) Build and install:
  #      make -j$(nproc)
  #      make install
  #
  # 5) After install, wine32/bin/ should contain:
  #      - wine
  #      - wineserver (possibly shared with wine64)
  #
  # RF runtime contract expects:
  #   - wine32/bin/ populated for WoW64
  #   - wine32on64.sh in bin/ can find and drive this tree
BUILD_NOTES

echo
echo "[wine32] Done (scaffolding only)."
