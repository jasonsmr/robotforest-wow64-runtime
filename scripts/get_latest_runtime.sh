#!/usr/bin/env bash
# scripts/get_latest_runtime.sh
#
# Fetch and unpack the latest rf-runtime-dev release from GitHub.
# Primary path: rf-runtime-dev.tar.zst
# Termux-safe fallback: rf-runtime-dev.zip if tar.zst fails (e.g. window too large)

set -euo pipefail

OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"

ASSET_TAR="rf-runtime-dev.tar.zst"
ASSET_ZIP="rf-runtime-dev.zip"

# Where to put the unpacked runtime on this machine
RUNTIME_ROOT="${RF_RUNTIME_ROOT:-"$HOME/rf_runtime"}"

# Repo root (for temp dir)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$ROOT/_rf_latest_tmp"

mkdir -p "$TMPDIR"

# Allow override of the tag from the environment
TAG="${RF_RUNTIME_TAG:-}"

if [ -z "$TAG" ]; then
  echo "[rf] Fetching latest release tag from GitHub..."
  TAG="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
    | sed -n 's/  *\"tag_name\": *\"\(.*\)\",/\1/p' \
    | head -n1)"
  if [ -z "$TAG" ]; then
    echo "[rf] ERROR: Failed to detect latest release tag."
    exit 1
  fi
  echo "[rf] Using release tag: $TAG"
else
  echo "[rf] Using RF_RUNTIME_TAG=$TAG"
fi

BASE_URL="https://github.com/$OWNER/$REPO/releases/download/$TAG"

cd "$TMPDIR"

echo "[rf] Downloading $ASSET_TAR..."
curl -fL -o "$ASSET_TAR" "$BASE_URL/$ASSET_TAR"

echo "[rf] Downloading $ASSET_TAR.sha256..."
curl -fL -o "$ASSET_TAR.sha256" "$BASE_URL/$ASSET_TAR.sha256"

echo "[rf] Verifying sha256 for $ASSET_TAR..."
sha256sum -c "$ASSET_TAR.sha256"

echo "[rf] Extracting tar.zst into: $RUNTIME_ROOT"
rm -rf "$RUNTIME_ROOT"
mkdir -p "$RUNTIME_ROOT"

set +e
zstd -d -c "$ASSET_TAR" | tar -C "$RUNTIME_ROOT" -xvf -
tar_status=$?
set -e

if [ "$tar_status" -ne 0 ]; then
  echo
  echo "[rf] WARNING: failed to extract $ASSET_TAR (status=$tar_status)."
  echo "[rf] This often means the zstd window is too large for Termux."
  echo "[rf] Falling back to $ASSET_ZIP instead..."

  echo "[rf] Downloading $ASSET_ZIP..."
  curl -fL -o "$ASSET_ZIP" "$BASE_URL/$ASSET_ZIP"

  echo "[rf] Downloading $ASSET_ZIP.sha256..."
  curl -fL -o "$ASSET_ZIP.sha256" "$BASE_URL/$ASSET_ZIP.sha256"

  echo "[rf] Verifying sha256 for $ASSET_ZIP..."
  sha256sum -c "$ASSET_ZIP.sha256"

  echo "[rf] Extracting zip into: $RUNTIME_ROOT"
  rm -rf "$RUNTIME_ROOT"
  mkdir -p "$RUNTIME_ROOT"
  unzip -q "$ASSET_ZIP" -d "$RUNTIME_ROOT"
fi

echo
echo "[rf] Runtime download + extract complete."
echo "[rf] Location: $RUNTIME_ROOT"
echo "[rf] You can now run:"
echo "  cd \"$RUNTIME_ROOT\""
echo "  ./rf_runtime_layout_check.sh"
echo "  . ./rf_env.sh"
echo "  box64 -v  # to sanity-check box64"
