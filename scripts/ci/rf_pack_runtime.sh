#!/usr/bin/env bash
# rf_pack_runtime.sh
# Assemble a reproducible runtime bundle from staging/downloads + local overlays.
# Output: dist/rf-runtime-<date>-<shortsha>.tar.zst and matching .sha256

set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")"/.. && pwd)"
DL="${ROOT}/staging/downloads"
OVERLAY="${ROOT}/staging/overlay"   # optional: anything here is copied into runtime/
BUILD="${ROOT}/staging/build/runtime"
DIST="${ROOT}/dist"

mkdir -p "${BUILD}" "${DIST}"

# Clean previous build dir but keep DIST
rm -rf "${BUILD:?}"/*
mkdir -p "${BUILD}"

echo "[pack] Using downloads from: ${DL}"
test -d "${DL}" || { echo "ERROR: ${DL} missing. Run scripts/ci/fetch_components.sh --fetch first."; exit 1; }

# If you haven't pinned anything yet, fail fast.
shopt -s nullglob
artifacts=("${DL}"/*)
if (( ${#artifacts[@]} == 0 )); then
  echo "ERROR: no downloaded artifacts found in ${DL}"
  exit 1
fi

unpack_one() {
  local f="$1"
  case "$f" in
    *.tar.zst|*.tar.xz|*.tar.gz) tar -xf "$f" -C "${BUILD}";;
    *.zip) unzip -q "$f" -d "${BUILD}";;
    *) echo "WARN: skipping unknown archive type: $f";;
  esac
}

echo "[pack] Unpacking artifacts…"
for f in "${DL}"/*; do
  echo "  -> $f"
  unpack_one "$f"
done

# Optional overlay (your extra scripts/configs)
if [[ -d "${OVERLAY}" ]]; then
  echo "[pack] Applying overlay from ${OVERLAY}"
  rsync -a --delete "${OVERLAY}/" "${BUILD}/"
fi

# Standardize layout root under "runtime/"
if [[ ! -d "${BUILD}/runtime" ]]; then
  echo "[pack] Normalizing layout under runtime/"
  mkdir -p "${BUILD}/runtime"
  shopt -s dotglob
  for item in "${BUILD}"/*; do
    [[ "$(basename "$item")" == "runtime" ]] && continue
    mv "$item" "${BUILD}/runtime/" || true
  done
  shopt -u dotglob
fi

# Create MANIFEST.SHA256 (deterministic order)
echo "[pack] Writing MANIFEST.SHA256"
( cd "${BUILD}/runtime" && LC_ALL=C find . -type f -print0 | sort -z | xargs -0 sha256sum ) > "${BUILD}/MANIFEST.SHA256"

# Stamp and pack
DATE="$(date -u +%Y%m%d)"
GIT_SHA="$(git -C "${ROOT}" rev-parse --short=8 HEAD || echo nogit)"
OUT="${DIST}/rf-runtime-${DATE}-${GIT_SHA}.tar.zst"

echo "[pack] Creating ${OUT}"
( cd "${BUILD}" && tar --sort=name --mtime='UTC 2020-01-01' --owner=0 --group=0 --numeric-owner \
     -I 'zstd -19 --long=31' -cf "${OUT}" MANIFEST.SHA256 runtime )

echo "[pack] Creating ${OUT}.sha256"
( cd "${DIST}" && sha256sum "$(basename "${OUT}")" > "${OUT}.sha256" )

echo "[pack] Done:"
ls -lh "${OUT}" "${OUT}.sha256"
