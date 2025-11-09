#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"

ZIP="${1:-}"
[[ -z "$ZIP" ]] && ZIP="$(ls -1 "${DIST}"/robotforest-wow64-runtime-*.zip | head -n1 || true)"
[[ -f "$ZIP" ]] || { echo "ZIP not found" >&2; exit 1; }

echo "Verifying: $ZIP"
unzip -l "$ZIP" | sed -n '1,200p'

# Minimal expectations
req=(
  "rootfs/"
  "rootfs/bin/rf-runtime-env"
)
for p in "${req[@]}"; do
  unzip -l "$ZIP" | grep -qE "[[:space:]]${p}$" || { echo "Missing ${p}" >&2; exit 1; }
done

echo "Verification OK."
