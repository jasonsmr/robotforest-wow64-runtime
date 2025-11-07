#!/usr/bin/env bash
set -euo pipefail

# ===== Versions (overridable via env) =====
PROTON_TAG="${PROTON_TAG:-GE-Proton10-9}"
DXVK_TAG="${DXVK_TAG:-v2.4}"
VKD3D_TAG="${VKD3D_TAG:-v2.13}"

ROOT="$(pwd)"
STAGE="$ROOT/staging"
RUNTIME="$STAGE/runtime"

mkdir -p "$RUNTIME"/{proton,dxvk,vkd3d,bin,box,scripts,prefixes,icd}
echo "[ci] Fetching components -> $RUNTIME"
echo "[ci] Tags: PROTON=$PROTON_TAG DXVK=$DXVK_TAG VKD3D=$VKD3D_TAG"

dl() {
  # dl <url> <out>
  local url="$1" out="$2"
  if command -v aria2c >/dev/null 2>&1; then
    aria2c -x 8 -s 8 -k1M -o "$(basename "$out")" -d "$(dirname "$out")" "$url"
  else
    curl -fL --retry 5 --retry-delay 2 --retry-all-errors -o "$out" "$url"
  fi
}

untar_gz() {
  # untar_gz <tar.gz> <dest> <strip>
  local tgz="$1" dest="$2" strip="${3:-0}"
  mkdir -p "$dest"
  if command -v pv >/dev/null 2>&1; then
    pv "$tgz" | tar -xz -C "$dest" --strip-components="$strip"
  else
    tar -xzf "$tgz" -C "$dest" --strip-components="$strip"
  fi
}

untar_zst() {
  # untar_zst <tar.zst> <dest> <strip>
  local tzst="$1" dest="$2" strip="${3:-0}"
  mkdir -p "$dest"
  if command -v pv >/dev/null 2>&1; then
    pv "$tzst" | unzstd -c | tar -x -C "$dest" --strip-components="$strip"
  else
    unzstd -c "$tzst" | tar -x -C "$dest" --strip-components="$strip"
  fi
}

mkdir -p "$STAGE"

echo "::group::Proton $PROTON_TAG"
[ -f "$STAGE/proton.tar.gz" ] || dl "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$PROTON_TAG/Proton-$PROTON_TAG.tar.gz" "$STAGE/proton.tar.gz"
rm -rf "$RUNTIME/proton"
untar_gz "$STAGE/proton.tar.gz" "$RUNTIME/proton" 1
echo "::endgroup::"

echo "::group::DXVK $DXVK_TAG"
[ -f "$STAGE/dxvk.tar.gz" ] || dl "https://github.com/doitsujin/dxvk/releases/download/$DXVK_TAG/dxvk-$DXVK_TAG.tar.gz" "$STAGE/dxvk.tar.gz"
rm -rf "$RUNTIME/dxvk"
untar_gz "$STAGE/dxvk.tar.gz" "$RUNTIME/dxvk" 1
echo "::endgroup::"

echo "::group::vkd3d-proton $VKD3D_TAG"
[ -f "$STAGE/vkd3d.tar.zst" ] || dl "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/$VKD3D_TAG/vkd3d-proton-$VKD3D_TAG.tar.zst" "$STAGE/vkd3d.tar.zst"
rm -rf "$RUNTIME/vkd3d"
untar_zst "$STAGE/vkd3d.tar.zst" "$RUNTIME/vkd3d" 1
echo "::endgroup::"

# Optional Turnip ICD placeholder (Android Adreno)
cat > "$RUNTIME/icd/turnip_icd.json" <<'JSON'
{
  "file_format_version": "1.0.0",
  "ICD": { "library_path": "libvulkan_freedreno.so", "api_version": "1.3.285" }
}
JSON

# Launcher
mkdir -p "$RUNTIME/scripts" "$RUNTIME/prefixes/proton"
cat > "$RUNTIME/scripts/steam-run.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
RUNTIME_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export BOX64_DYNAREC=1
export BOX64_LOG=0
export BOX64_LD_LIBRARY_PATH="${RUNTIME_DIR}/proton/files/lib64:${RUNTIME_DIR}/proton/files/lib:${RUNTIME_DIR}/dxvk/x64:${RUNTIME_DIR}/vkd3d/x64"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${RUNTIME_DIR}/proton"
export STEAM_COMPAT_DATA_PATH="${RUNTIME_DIR}/prefixes/proton"
if [ -f "${RUNTIME_DIR}/icd/turnip_icd.json" ]; then
  export VK_ICD_FILENAMES="${RUNTIME_DIR}/icd/turnip_icd.json"
fi
WINE64="${RUNTIME_DIR}/proton/dist/bin/wine64"
[ -x "$WINE64" ] || { echo "[err] wine64 not found in Proton dist"; exit 2; }
if [ $# -gt 0 ]; then
  exec "$WINE64" "$@"
fi
echo "[steam-run] Usage: runtime/scripts/steam-run.sh 'C:/path/to/Game.exe'"
SH
chmod +x "$RUNTIME/scripts/steam-run.sh"

echo "[ci] Components fetched + launcher written."
