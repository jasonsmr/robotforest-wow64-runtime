#!/usr/bin/env bash
set -euo pipefail

RUNTIME_ZIP="${1:-}"
[[ -n "$RUNTIME_ZIP" && -f "$RUNTIME_ZIP" ]] || { echo "Usage: $0 /path/to/robotforest-wow64-runtime-<tag>.zip" >&2; exit 2; }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
unzip -q "$RUNTIME_ZIP" -d "$workdir"

root="$workdir"/robotforest-wow64-runtime
[[ -d "$root" ]] || root="$workdir"/*robotforest-wow64-runtime* || true
[[ -d "$root" ]] || { echo "ERR: runtime root not found in zip" >&2; exit 1; }

fail=0
req_bins=(
  "bin/box64"
  "bin/wine"
  "bin/wine64"
)
for b in "${req_bins[@]}"; do
  [[ -x "$root/$b" ]] || { echo "MISS: $b" >&2; fail=1; }
done

# Proton/DXVK/VKD3D presence (names are flexible, just prove we have them)
ls -1 "$root"/proton*  >/dev/null 2>&1 || { echo "MISS: proton payload" >&2; fail=1; }
ls -1 "$root"/dxvk*    >/dev/null 2>&1 || { echo "MISS: dxvk payload"   >&2; fail=1; }
ls -1 "$root"/vkd3d*   >/dev/null 2>&1 || { echo "MISS: vkd3d payload"  >&2; fail=1; }

# Structure sanity
[[ -d "$root"/prefix ]] || { echo "MISS: prefix/ (wine prefix seed)" >&2; fail=1; }

# Quick version echoes (don’t fail the build on these)
if [[ -x "$root/bin/box64" ]]; then "$root/bin/box64" -v || true; fi
if [[ -x "$root/bin/wine64" ]]; then "$root/bin/wine64" --version || true; fi
if [[ -x "$root/bin/wine"   ]]; then "$root/bin/wine"   --version || true; fi

exit $fail
