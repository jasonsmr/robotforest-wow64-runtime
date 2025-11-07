#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail
ARCHIVE="${1:-}"
if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo "Usage: $0 /path/to/ci-workflows-golden-*.tar.gz" >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
tar -C "$ROOT" -xzf "$ARCHIVE"
echo "Restored CI workflows from $ARCHIVE"
