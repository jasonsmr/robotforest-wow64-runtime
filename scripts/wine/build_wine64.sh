#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# RobotForest Wine64 build scaffolding (Path A)
# -----------------------------------------------------------------------------
# This script does NOT actually build Wine yet.
# It defines the canonical paths / layout we will use for 64-bit Wine/Proton
# and performs basic sanity checks.
#
# Later, we will fill in the "BUILD STEPS" section with real configure/make
# commands, depending on whether we build in Termux+glibc, proot, or a host PC.
# -----------------------------------------------------------------------------

# Repo root: scripts/wine/ -> .. (scripts) -> .. (repo root)
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Canonical runtime staging root (what RF Release packs)
RUNTIME_STAGE="$ROOT/staging/rf_runtime"

# 64-bit Wine install prefix inside runtime
WINE64_PREFIX="$RUNTIME_STAGE/wine64"

# Convention for source+build roots (you can change these later)
# e.g. /data/data/com.termux/files/home/src/wine64
SRC_ROOT="${SRC_ROOT:-$HOME/src}"
BUILD_ROOT="${BUILD_ROOT:-$HOME/build}"

WINE64_SRC="${WINE64_SRC:-$SRC_ROOT/wine64-src}"
WINE64_BUILD="${WINE64_BUILD:-$BUILD_ROOT/wine64-build}"

echo "[wine64] RobotForest Wine64 scaffolding"
echo "  ROOT          = $ROOT"
echo "  RUNTIME_STAGE = $RUNTIME_STAGE"
echo "  WINE64_PREFIX = $WINE64_PREFIX"
echo "  WINE64_SRC    = $WINE64_SRC"
echo "  WINE64_BUILD  = $WINE64_BUILD"
echo

# Sanity checks for staging layout
for d in "$RUNTIME_STAGE" "$RUNTIME_STAGE/bin" "$RUNTIME_STAGE/x86_64-linux"; do
  if [ ! -d "$d" ]; then
    echo "[wine64][ERROR] Missing required directory: $d"
    exit 1
  fi
done

# Ensure wine64/ exists (installer / layout checker rely on it existing)
if [ ! -d "$WINE64_PREFIX" ]; then
  echo "[wine64] Creating wine64/ prefix: $WINE64_PREFIX"
  mkdir -p "$WINE64_PREFIX"/bin
fi

echo "[wine64] Current wine64/ contents (top-level):"
ls -1 "$WINE64_PREFIX" || echo "  (empty)"
echo

# Prepare source+build dirs (no git clone here, just mkdir)
mkdir -p "$WINE64_SRC" "$WINE64_BUILD"

echo "[wine64] Source directory prepared: $WINE64_SRC"
echo "[wine64] Build directory prepared:  $WINE64_BUILD"
echo

cat << 'BUILD_NOTES'
[wine64] BUILD STEPS (NOT RUN YET):

  # Example outline (to be adapted to your actual environment):
  #
  # 1) Populate WINE64_SRC with your chosen Wine/Proton tree, e.g.:
  #      git clone https://github.com/ValveSoftware/wine.git "$WINE64_SRC"
  #    or copy from your existing Fizban/proton trees.
  #
  # 2) Enter the build dir:
  #      cd "$WINE64_BUILD"
  #
  # 3) Configure (example, not final):
  #      ../configure \
  #        --enable-win64 \
  #        --prefix="$WINE64_PREFIX" \
  #        <toolchain flags, CC/CXX, etc.>
  #
  # 4) Build and install:
  #      make -j$(nproc)
  #      make install
  #
  # 5) After install, wine64/bin/ should contain:
  #      - wine64
  #      - wineserver
  #      - helper binaries/dlls as needed
  #
  # 6) Re-run rf_runtime_layout_check.sh to confirm:
  #      ./staging/rf_runtime/rf_runtime_layout_check.sh
  #
  # RF runtime contract expects:
  #   - wine64/bin/ populated with Wine64 entry points
  #   - box64 & steam scripts in bin/ can find and use WINE64_PREFIX
BUILD_NOTES

echo
echo "[wine64] Done (scaffolding only)."
