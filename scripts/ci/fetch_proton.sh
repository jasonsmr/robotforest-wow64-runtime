#!/usr/bin/env bash
set -euo pipefail

STAGE="$(cd "$(dirname "$0")/.." && pwd)/staging"
mkdir -p "$STAGE"
PROTON_TARBALL="${PROTON_TARBALL:-$STAGE/proton.tar.gz}"
# Pin a known Proton-GE release; override with PROTON_URL if you want a different one
PROTON_URL="${PROTON_URL:-https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-10/GE-Proton9-10.tar.gz}"

# If already present and non-empty, keep it
if [ -s "$PROTON_TARBALL" ]; then
  echo "[proton] tarball already present: $PROTON_TARBALL"
  exit 0
fi

TMP_DL="${PROTON_TARBALL}.part"

echo "[proton] HEAD $PROTON_URL (checking size/availability)"
# Some CDNs don’t give Content-Length, so this may be empty—non-fatal
LEN="$(curl -fsIL "$PROTON_URL" | awk -F': ' 'tolower($1)=="content-length"{print $2}' | tr -d '\r')"
[ -n "${LEN:-}" ] && echo "[proton] remote size: $LEN bytes" || echo "[proton] size unknown (server didn’t send Content-Length)"

# Make sure we have room (quick 1GB guard; adjust if needed)
REQ=$(( 1024*1024*1024 ))
AVAIL="$(df -Pk "$STAGE" | awk 'NR==2{print $4*1024}')"
if [ "$AVAIL" -lt "$REQ" ]; then
  echo "[proton] WARNING: low free space in $STAGE ($(printf "%'d" "$AVAIL") bytes). Continue anyway…" >&2
fi

echo "[proton] downloading -> $TMP_DL (resume enabled)"
# --continue-at - = resume, --retry-all-errors is curl>=7.71; fallback is fine if older
curl -fL --retry 5 --retry-delay 3 --continue-at - \
  --speed-time 60 --speed-limit 10240 \
  -o "$TMP_DL" "$PROTON_URL"

# Move into place atomically
mv -f "$TMP_DL" "$PROTON_TARBALL"
chmod 0644 "$PROTON_TARBALL"
echo "[proton] saved: $PROTON_TARBALL"
