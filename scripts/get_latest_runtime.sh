#!/usr/bin/env bash

# scripts/get_latest_runtime.sh
#
set -euo pipefail

REPO_OWNER="jasonsmr"
REPO_NAME="robotforest-wow64-runtime"

TAG=""
DEST="${HOME}/rf_runtime"
ASSET_KIND="tar.zst"  # or "zip"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --dest DIR        Destination directory for the runtime (default: \$HOME/rf_runtime)
  --tag TAG         Use a specific GitHub release tag (default: latest)
  --asset KIND      Asset type: tar.zst | zip (default: tar.zst)
  -h, --help        Show this help

Examples:
  # Get latest release, extract into ~/rf_runtime
  $(basename "$0")

  # Get a specific tag
  $(basename "$0") --tag main-20251119-053842 --dest ~/rf_runtime_test

  # Use the zip asset instead of tar.zst
  $(basename "$0") --asset zip
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      DEST="$2"; shift 2;;
    --tag)
      TAG="$2"; shift 2;;
    --asset)
      ASSET_KIND="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1;;
  esac
done

case "$ASSET_KIND" in
  tar.zst) ASSET_NAME="rf-runtime-dev.tar.zst" ;;
  zip)     ASSET_NAME="rf-runtime-dev.zip" ;;
  *)
    echo "Invalid --asset value: ${ASSET_KIND} (expected tar.zst or zip)" >&2
    exit 1
    ;;
esac

mkdir -p "$DEST"
cd "$DEST"

if [[ -z "${TAG}" ]]; then
  echo "[rf] Fetching latest release tag from GitHub..."
  if command -v jq >/dev/null 2>&1; then
    TAG="$(curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" | jq -r '.tag_name')"
  else
    TAG="$(curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" \
      | grep -m1 '"tag_name":' \
      | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
  fi
fi

if [[ -z "${TAG}" || "${TAG}" == "null" ]]; then
  echo "[rf] ERROR: Failed to determine release tag" >&2
  exit 1
fi

echo "[rf] Using release tag: ${TAG}"
BASE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${TAG}"

ASSET_URL="${BASE_URL}/${ASSET_NAME}"
SHA_URL="${ASSET_URL}.sha256"

echo "[rf] Downloading ${ASSET_NAME}..."
curl -fL "${ASSET_URL}" -o "${ASSET_NAME}.tmp"

echo "[rf] Downloading ${ASSET_NAME}.sha256..."
curl -fL "${SHA_URL}" -o "${ASSET_NAME}.sha256.tmp"

mv "${ASSET_NAME}.tmp" "${ASSET_NAME}"
mv "${ASSET_NAME}.sha256.tmp" "${ASSET_NAME}.sha256"

echo "[rf] Verifying sha256..."
# The .sha256 file is of the form: "<hash>  <filename>"
if ! sha256sum -c "${ASSET_NAME}.sha256"; then
  echo "[rf] ERROR: sha256 verification FAILED" >&2
  exit 1
fi
echo "[rf] sha256 OK"

echo "[rf] Extracting into: ${DEST}"
case "$ASSET_KIND" in
  tar.zst)
    if tar --help 2>&1 | grep -q -- '-I program'; then
      tar -I zstd -xvf "${ASSET_NAME}"
    else
      # fallback: zstd -d then tar
      zstd -d -f "${ASSET_NAME}" -o "rf-runtime-dev.tar"
      tar -xvf "rf-runtime-dev.tar"
      rm -f "rf-runtime-dev.tar"
    fi
    ;;
  zip)
    unzip -o "${ASSET_NAME}"
    ;;
esac

echo "[rf] Done."
echo "[rf] Runtime contents should now be under: ${DEST}"
echo "[rf] e.g. you should see bin/wine64.sh, bin/wine32on64.sh, bin/steam-win.sh"
