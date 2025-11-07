#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${TMP:-/data/data/com.termux/files/home/tmp}/ci-workflows-golden-${STAMP}.tar.gz"

tar -C "$(git rev-parse --show-toplevel)" -czf "$OUT" \
  .github/workflows

echo "Saved golden archive: $OUT"
