#!/usr/bin/env bash
# rf_runtime_layout_check.sh - sanity check RobotForest runtime layout
#
# NOTE:
#   - Core dirs (bin, dxvk, vkd3d, wine32, wine64, prefix, x86_64-linux, i386-linux)
#     are REQUIRED.
#   - proton/ is OPTIONAL (present in desktop bundles, often omitted in Termux-only
#     runtime for RobotForest APK embedding).

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

# Optional proton/ (present in some bundles, not required for Termux runtime)
if [ -d "$ROOT/proton" ]; then
  echo "[rf] OPTIONAL OK: proton/ present"
else
  echo "[rf] OPTIONAL: proton/ not present (this is fine for APK-only Termux runtime)"
fi
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
