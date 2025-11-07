#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
ARCHIVE="${1:-}"
if [[ -z "${ARCHIVE}" ]]; then
  # pick the newest in $TMP
  ARCHIVE="$(ls -1 ${TMP:-/tmp}/ci-workflows-golden-*.tar.gz | tail -n1)"
fi
[[ -f "$ARCHIVE" ]] || { echo "Archive not found: $ARCHIVE" >&2; exit 1; }

tar -C "$ROOT" -xzf "$ARCHIVE"
git -C "$ROOT" add .github/workflows scripts/ci/fetch_components.sh scripts/rf_pack_runtime.sh
git -C "$ROOT" commit -m "ci: restore golden baseline from $(basename "$ARCHIVE")"
