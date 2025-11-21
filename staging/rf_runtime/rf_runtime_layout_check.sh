#!/usr/bin/env bash
# rf_runtime_layout_check.sh - sanity check RobotForest runtime layout

set -euo pipefail

# Determine runtime root:
# - Prefer RF_RUNTIME_ROOT if set
# - Otherwise use the directory of this script
if [ -n "${RF_RUNTIME_ROOT:-}" ]; then
  ROOT="$RF_RUNTIME_ROOT"
else
  _rf_src="${BASH_SOURCE[0]:-$0}"
  ROOT="$(cd "$(dirname "$_rf_src")" && pwd)"
fi

echo "[rf] Runtime layout check for RobotForest"
echo "[rf] RF_RUNTIME_ROOT = $ROOT"
echo

echo "[rf] Top-level entries:"
ls -1 "$ROOT"
echo

# Required top-level dirs
required_dirs=(
  bin
  dxvk
  vkd3d
  wine32
  wine64
  prefix
  proton
  x86_64-linux
  i386-linux
)

for d in "${required_dirs[@]}"; do
  if [ -d "$ROOT/$d" ]; then
    echo "[rf] OK: $d/"
  else
    echo "[rf] MISSING: $d/" >&2
  fi
done
echo

# Show a quick view of bin/
if [ -d "$ROOT/bin" ]; then
  echo "[rf] bin/ contents (first 20):"
  (cd "$ROOT/bin" && ls -1 | head -n 20)
  echo
fi

# Show wine placeholders if present
if [ -d "$ROOT/wine32" ]; then
  echo "[wine32]"
  (cd "$ROOT/wine32" && ls -1)
  echo
fi

if [ -d "$ROOT/wine64" ]; then
  echo "[wine64]"
  (cd "$ROOT/wine64" && ls -1)
  echo
fi

echo "[rf] Done."
