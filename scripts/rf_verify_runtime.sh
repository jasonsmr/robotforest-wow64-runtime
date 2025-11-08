#!/usr/bin/env bash
set -euo pipefail
DIST_DIR="${1:-dist}"
shopt -s nullglob

fail=0

want=( VERSION.txt bin/rf-sandbot overrides/dxvk overrides/vkd3d proton )
for zip in "$DIST_DIR"/robotforest-wow64-runtime-*.zip; do
  echo "[verify] $zip"
  tmpdir="$(mktemp -d)"
  unzip -q "$zip" -d "$tmpdir"
  root="$tmpdir/robotforest-wow64-runtime"
  for p in "${want[@]}"; do
    if [[ ! -e "$root/$p" ]]; then
      echo "::error file=$zip::missing $p"
      fail=1
    fi
  done
  rm -rf "$tmpdir"
done

exit $fail
