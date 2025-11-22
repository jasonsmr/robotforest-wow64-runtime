#!/system/bin/sh
set -e

ARCHIVE="$1"
TARGET="$2"

if [ -z "$ARCHIVE" ] || [ -z "$TARGET" ]; then
  echo "[rf] Usage: rf_install_runtime.sh <archive> <target>"
  exit 1
fi

mkdir -p "$TARGET"

# Extract with zstd-friendly tar
tar --zstd -C "$TARGET" -xf "$ARCHIVE"

echo "[rf] Installed runtime to $TARGET"
