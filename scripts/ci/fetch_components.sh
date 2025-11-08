#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGING="$ROOT/staging"
mkdir -p "$STAGING"

# Expect pins via env
: "${PROTON_TAG:?missing PROTON_TAG}"
: "${DXVK_TAG:?missing DXVK_TAG}"
: "${VKD3D_TAG:?missing VKD3D_TAG}"

cd "$STAGING"

fetch_tar() {
  local url="$1" out="$2"
  if [[ ! -f "$out" ]]; then
    echo "[fetch] $url -> $out"
    aria2c -x16 -s16 -k1M -o "$(basename "$out")" "$url" || curl -fL "$url" -o "$out"
  else
    echo "[cache] $out exists"
  fi
}

# Proton GE
fetch_tar \
  "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_TAG}/Proton-${PROTON_TAG}.tar.gz" \
  "proton.tar.gz"

# DXVK
fetch_tar \
  "https://github.com/doitsujin/dxvk/releases/download/${DXVK_TAG}/dxvk-${DXVK_TAG}.tar.gz" \
  "dxvk.tar.gz"

# VKD3D-Proton
fetch_tar \
  "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/${VKD3D_TAG}/vkd3d-proton-${VKD3D_TAG}.tar.zst" \
  "vkd3d.tar.zst"

echo "[done] staged tarballs in $STAGING"
