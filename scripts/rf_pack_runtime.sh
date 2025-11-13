#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.."; pwd)"
STAGE="$REPO/staging"
ROOT="$STAGE/rf_runtime"
OUT="$REPO/dist"

mkdir -p "$OUT"

# Derive TAG
TAG="${RF_TAG:-${GITHUB_REF_NAME:-dev}}"
DATE="$(date +%Y%m%d-%H%M%S)"
BASE="rf-runtime-${TAG}"

# Sanity: wrappers must exist (or at least warn)
strict="${RF_STRICT_WINE:-0}"

check_or_warn() {
  local msg="$1" path="$2" kind="${3:-file}"
  if [[ "$kind" == "file" ]]; then
    if [[ ! -f "$path" && ! -x "$path" ]]; then
      echo "[warn] $msg: $path" >&2
      (( strict == 1 )) && return 1 || return 0
    fi
  else
    if [[ ! -d "$path" ]]; then
      echo "[warn] $msg: $path" >&2
      (( strict == 1 )) && return 1 || return 0
    fi
  fi
  return 0
}

# Basic wrapper checks (do not abort unless RF_STRICT_WINE=1)
check_or_warn "missing wine64 wrapper"     "$ROOT/bin/wine64.sh"      file || exit 2
check_or_warn "missing wine32on64 wrapper" "$ROOT/bin/wine32on64.sh"  file || exit 2
check_or_warn "missing steam-win wrapper"  "$ROOT/bin/steam-win.sh"   file || exit 2

# 1) tar.zst
TAR="$OUT/${BASE}.tar.zst"
echo "[pack] ${TAR}"
tar -C "$STAGE" -I 'zstd --long=31 -19' -cf "$TAR" rf_runtime
(
  cd "$OUT" && sha256sum "$(basename "$TAR")" > "$(basename "$TAR").sha256"
)

# 2) zip
ZIP="$OUT/${BASE}.zip"
echo "[pack] ${ZIP}"
cd "$STAGE"
zip -q -r "$ZIP" rf_runtime
cd - >/dev/null
(
  cd "$OUT" && sha256sum "$(basename "$ZIP")" > "$(basename "$ZIP").sha256"
)

echo "[ok] built:"
ls -lh "$TAR" "$TAR.sha256" "$ZIP" "$ZIP.sha256"

# --- sanity checks: ensure wine payloads exist (soft by default) ---
wine_strict_fail=0

if ! check_or_warn "missing wine64 tree" "$ROOT/wine64" dir; then
  wine_strict_fail=1
fi
if ! check_or_warn "missing wine32 tree" "$ROOT/wine32" dir; then
  wine_strict_fail=1
fi
if [[ -d "$ROOT/wine64" && ! -f "$ROOT/wine64/wine64" ]]; then
  echo "[warn] missing wine64 loader in $ROOT/wine64" >&2
  ls -la "$ROOT/wine64" || true
  (( strict == 1 )) && wine_strict_fail=1
fi

if (( wine_strict_fail == 1 )); then
  echo "[warn] Wine payload incomplete; RF_STRICT_WINE=1 would fail here." >&2
fi

exit 0
