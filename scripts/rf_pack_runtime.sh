#!/usr/bin/env bash
set -euo pipefail

# If RF_TAG (or GITHUB_REF_NAME) looks like vX.Y.Z, use it; else fall back to timestamp.
TAG="${RF_TAG:-${GITHUB_REF_NAME:-}}"
if [[ "${TAG:-}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  BASENAME="robotforest-wow64-runtime-${TAG}.zip"
else
  stamp="$(date -u +%Y%m%d-%H%M%S)"
  BASENAME="robotforest-wow64-runtime-${stamp}.zip"
fi

ROOT="$(pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
OUT="$DIST/$BASENAME"

echo "[pack] assembling -> $OUT"
# Include whatever your runtime needs:
zip -r9 "$OUT" \
  scripts/ \
  staging/ \
  README.md 2>/dev/null || true

echo "[pack] wrote $OUT"
ls -l "$DIST"
