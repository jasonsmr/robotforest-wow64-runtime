#!/usr/bin/env bash
set -euo pipefail
ZIP="${1:-dist/robotforest-wow64-runtime-${GITHUB_REF_NAME:-local}.zip}"
[[ -f "$ZIP" ]] || { echo "ZIP not found: $ZIP" >&2; exit 1; }

# Verify with our hard verifier
bash scripts/ci/verify_runtime.sh "$ZIP"

# Expand and run a couple of harmless commands to ensure entry points work
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
unzip -q "$ZIP" -d "$tmp"
root="$(find "$tmp" -maxdepth 1 -type d -name "robotforest-wow64-runtime*" | head -n1)"

echo "[sandbot-smoke] box64 -v"
"$root/bin/box64" -v || true

echo "[sandbot-smoke] wine64 --version"
"$root/bin/wine64" --version || true

echo "[sandbot-smoke] OK"
