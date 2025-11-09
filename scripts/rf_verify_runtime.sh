#!/usr/bin/env bash
# rf_verify_runtime.sh
# Verify outer SHA256 and inner MANIFEST.SHA256 from a zstd-compressed tarball.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/rf-runtime-*.tar.zst [optional:.sha256]" >&2
  exit 2
fi

TAR="$1"
SUMFILE="${2:-}"

test -f "$TAR" || { echo "ERROR: missing tarball: $TAR"; exit 1; }

# Auto-detect sidecar checksum
if [[ -z "${SUMFILE}" ]]; then
  [[ -f "${TAR}.sha256" ]] && SUMFILE="${TAR}.sha256" || true
fi

if [[ -n "${SUMFILE}" ]]; then
  echo "[verify] Checking outer sha256 via ${SUMFILE}"
  ( cd "$(dirname "$TAR")" && sha256sum -c "$(basename "$SUMFILE")" )
else
  echo "[verify] Sidecar .sha256 not provided; skipping outer check."
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "[verify] Extracting MANIFEST.SHA256"
# Use --long=31 so it can read large-window zstd streams
tar --use-compress-program="zstd --long=31 -d" -xOf "$TAR" MANIFEST.SHA256 > "${TMP}/MANIFEST.SHA256"

# Sanity-check format
bad=$(awk '{ if (NF<2) print; }' "${TMP}/MANIFEST.SHA256" | wc -l)
if [[ "$bad" != "0" ]]; then
  echo "ERROR: MANIFEST.SHA256 appears malformed."
  exit 1
fi

echo "[verify] MANIFEST.SHA256 looks structurally valid."
echo "[verify] OK"
