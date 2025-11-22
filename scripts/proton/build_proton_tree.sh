#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# RobotForest Proton layout scaffolding (Path A)
# -----------------------------------------------------------------------------
# This does NOT build Proton. It only reserves a versioned layout under
# staging/rf_runtime/proton/.
# -----------------------------------------------------------------------------

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNTIME_STAGE="$ROOT/staging/rf_runtime"

PROTON_ROOT="$RUNTIME_STAGE/proton"

# Logical Proton "version tag" (e.g. proton-ge-9-15)
PROTON_TAG="${PROTON_TAG:-dev-local}"

PROTON_PREFIX="$PROTON_ROOT/$PROTON_TAG"

echo "[proton] RobotForest Proton scaffolding"
echo "  ROOT          = $ROOT"
echo "  RUNTIME_STAGE = $RUNTIME_STAGE"
echo "  PROTON_ROOT   = $PROTON_ROOT"
echo "  PROTON_TAG    = $PROTON_TAG"
echo "  PROTON_PREFIX = $PROTON_PREFIX"
echo

mkdir -p "$PROTON_PREFIX"

# Drop a marker so layout checker / humans see what's going on
if [ ! -f "$PROTON_PREFIX/README.rf-proton" ]; then
  cat > "$PROTON_PREFIX/README.rf-proton" << 'MARK'
This is a RobotForest Proton tree.

Contract:
  - This directory represents a Proton build identified by PROTON_TAG.
  - It may contain:
      dist/       → Proton "dist" tree (like Steam's common/Proton dist)
      wine64/     → symlink or copy of Wine64 tree used by this Proton
      wine32/     → symlink or copy of Wine32 tree used by this Proton
      files/      → Proton-based helper scripts / tools
MARK
fi

echo "[proton] Contents of $PROTON_PREFIX:"
ls -1 "$PROTON_PREFIX"

echo
echo "[proton] Done (layout only)."
