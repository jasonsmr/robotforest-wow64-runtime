# ~/android/robotforest-wow64-runtime/scripts/ci/fetch_components.sh
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT/scripts/ci/pins.env"

mkdir -p "$ROOT/staging"

# Proton-GE
if [[ ! -f "$ROOT/staging/proton.tar.gz" ]]; then
  echo "[fetch] Proton-GE $PROTON_TAG"
  curl -fL "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_TAG}/Proton-${PROTON_TAG}.tar.gz" \
    -o "$ROOT/staging/proton.tar.gz"
fi

# DXVK
if [[ ! -f "$ROOT/staging/dxvk.tar.gz" ]]; then
  echo "[fetch] DXVK $DXVK_TAG"
  curl -fL "https://github.com/doitsujin/dxvk/releases/download/${DXVK_TAG}/dxvk-${DXVK_TAG}.tar.gz" \
    -o "$ROOT/staging/dxvk.tar.gz"
fi

# vkd3d-proton
if [[ ! -f "$ROOT/staging/vkd3d.tar.zst" ]]; then
  echo "[fetch] vkd3d-proton $VKD3D_TAG"
  curl -fL "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/${VKD3D_TAG}/vkd3d-proton-${VKD3D_TAG}.tar.zst" \
    -o "$ROOT/staging/vkd3d.tar.zst"
fi

echo "[fetch] done"
