#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
WF_DIR="$REPO_ROOT/.github/workflows"
BK_DIR="$REPO_ROOT/tools/ci-backups"
mkdir -p "$BK_DIR"

ts() { date -u +"%Y%m%dT%H%M%SZ"; }

cmd="${1:-}"
case "$cmd" in
  snapshot)
    stamp="$(ts)"
    tarball="$BK_DIR/ci-workflows-$stamp.tar.gz"
    tar -C "$WF_DIR" -czf "$tarball" manual-release.yml release-core.yml
    echo "Saved snapshot: $tarball"
    ;;

  restore)
    tgz="${2:-}"
    if [[ -z "$tgz" || ! -f "$tgz" ]]; then
      echo "Usage: $0 restore tools/ci-backups/ci-workflows-<stamp>.tar.gz" >&2
      exit 2
    fi
    tar -C "$WF_DIR" -xzf "$tgz"
    echo "Restored workflows from: $tgz"
    git add .github/workflows/{manual-release.yml,release-core.yml}
    git commit -m "restore: workflows from $tgz"
    ;;

  show)
    echo "# manual-release.yml"
    sed -n '1,200p' "$WF_DIR/manual-release.yml"
    echo
    echo "# release-core.yml"
    sed -n '1,200p' "$WF_DIR/release-core.yml"
    ;;

  *)
    cat <<'USAGE' >&2
Usage:
  tools/ci_snapshot.sh snapshot
  tools/ci_snapshot.sh restore tools/ci-backups/ci-workflows-<stamp>.tar.gz
  tools/ci_snapshot.sh show
USAGE
    exit 1
    ;;
esac
