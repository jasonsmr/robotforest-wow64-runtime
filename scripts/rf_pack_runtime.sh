#!/usr/bin/env bash
set -euo pipefail

# Simple, CI-safe packer that writes one zip into ./dist/
# Assumptions:
# - All inputs we need already live in this repo (scripts/, staging/, etc.)
# - No Android-specific paths; only standard Ubuntu tools are used.

ROOT="$(pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"

stamp="$(date -u +%Y%m%d-%H%M%S)"
out="$DIST/robotforest-wow64-runtime-${stamp}.zip"

echo "[pack] assembling -> $out"
# Add whatever you need into the zip. Keep it explicit and stable.
# If you need to include a prepared staging/ prefix, zip it as well.
zip -r9 "$out" \
  scripts/ \
  staging/ \
  README.md 2>/dev/null || true

echo "[pack] wrote $out"
ls -l "$DIST"
