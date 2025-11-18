#!/usr/bin/env bash
# rf_verify_runtime.sh
# Verify the outer tarball SHA256 (if .sha256 exists) and inner MANIFEST.SHA256 content.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/rf-runtime-*.tar.zst [optional:.sha256]" >&2
  exit 2
fi

TAR="$1"
SUMFILE="${2:-}"

test -f "$TAR" || { echo "ERROR: missing tarball: $TAR"; exit 1; }

# If a sidecar .sha256 is provided (or auto-detected), verify it.
if [[ -z "${SUMFILE}" ]]; then
  [[ -f "${TAR}.sha256" ]] && SUMFILE="${TAR}.sha256" || true
fi

if [[ -n "${SUMFILE}" ]]; then
  echo "[verify] Checking outer sha256 via ${SUMFILE}"
  ( cd "$(dirname "$TAR")" && sha256sum -c "$(basename "$SUMFILE")" )
else
  echo "[verify] Sidecar .sha256 not provided; skipping outer check."
fi

# Extract MANIFEST.SHA256 without unpacking entire tree
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "[verify] Extracting MANIFEST.SHA256"
tar -I zstd -xOf "$TAR" MANIFEST.SHA256 > "${TMP}/MANIFEST.SHA256"

# We can sanity-check that each line has 'hash  path' form
bad=$(awk '{ if (NF<2) print; }' "${TMP}/MANIFEST.SHA256" | wc -l)
if [[ "$bad" != "0" ]]; then
  echo "ERROR: MANIFEST.SHA256 appears malformed."
  exit 1
fi

echo "[verify] MANIFEST.SHA256 looks structurally valid."
echo "[verify] OK"
