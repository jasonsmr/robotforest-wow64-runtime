#!/usr/bin/env bash
# scripts/get_latest_runtime.sh
#
# Fetch the latest rf-runtime-dev release from GitHub, verify it, and extract
# into a local runtime root.
#
# Env overrides:
#   RF_RUNTIME_TAG   - explicit release tag (otherwise use latest)
#   RF_RUNTIME_ROOT  - where to extract (default: $HOME/rf_runtime)
#
# This script assumes rf-runtime-dev.tar.zst was created by scripts/rf_pack_runtime.sh
# using Termux-safe zstd settings (no --long=31).

set -euo pipefail

OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"

TAG="${RF_RUNTIME_TAG:-}"
DEST_ROOT="${RF_RUNTIME_ROOT:-"$HOME/rf_runtime"}"

WORKDIR="${PWD}"
TMPDIR="${WORKDIR}/_rf_latest_tmp"

mkdir -p "$TMPDIR"

###############################################################################
# Resolve release tag
###############################################################################
if [ -z "$TAG" ]; then
  echo "[rf] Fetching latest release tag from GitHub..."
  # Avoid jq dependency; use grep/sed to pull tag_name
  TAG="$(
    curl -fsSL "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" \
      | grep '"tag_name"' \
      | head -n1 \
      | sed 's/.*"tag_name": *"//; s/".*//'
  )" || TAG=""

  if [ -z "$TAG" ]; then
    echo "[rf] ERROR: could not resolve latest release tag."
    exit 1
  fi
fi

echo "[rf] Using release tag: $TAG"
echo

BASE_URL="https://github.com/${OWNER}/${REPO}/releases/download/${TAG}"
TAR_NAME="rf-runtime-dev.tar.zst"
SHA_NAME="rf-runtime-dev.tar.zst.sha256"

TAR_PATH="${TMPDIR}/${TAR_NAME}"
SHA_PATH="${TMPDIR}/${SHA_NAME}"

###############################################################################
# Download artifacts
###############################################################################
echo "[rf] Downloading ${TAR_NAME}..."
curl -fL "${BASE_URL}/${TAR_NAME}" -o "$TAR_PATH"

echo "[rf] Downloading ${SHA_NAME}..."
curl -fL "${BASE_URL}/${SHA_NAME}" -o "$SHA_PATH"

###############################################################################
# Verify sha256
###############################################################################
echo "[rf] Verifying sha256..."
(
  cd "$TMPDIR"
  sha256sum -c "$SHA_NAME"
)
echo "[rf] sha256 OK"

###############################################################################
# Extract into DEST_ROOT
###############################################################################
echo "[rf] Extracting into: ${DEST_ROOT}"

mkdir -p "$DEST_ROOT"

# Use plain Termux-safe zstd; packer MUST NOT use --long=31.
if ! zstd -d -c "$TAR_PATH" | tar -C "$DEST_ROOT" -xvf -; then
  echo
  echo "[rf] ERROR: failed to extract rf-runtime-dev.tar.zst"
  echo "[rf] If you see 'Window size larger than maximum', the release was"
  echo "[rf] built with an oversized zstd window. Update to a newer release"
  echo "[rf] or rebuild rf-runtime-dev with scripts/rf_pack_runtime.sh."
  exit 1
fi

echo
echo "[rf] Extraction complete. Runtime layout (depth <= 2):"
find "$DEST_ROOT" -maxdepth 2 -type d | sed "s|$HOME||"

echo
echo "[rf] Done."
