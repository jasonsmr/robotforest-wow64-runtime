#!/usr/bin/env bash
set -euo pipefail

# ===== Versions (overridable by env) =====
PROTON_TAG="${PROTON_TAG:-GE-Proton10-9}"
DXVK_TAG="${DXVK_TAG:-v2.4}"
VKD3D_TAG="${VKD3D_TAG:-v2.13}"

ROOT="$(pwd)"
STAGE="$ROOT/staging"
RUNTIME="$STAGE/runtime"
mkdir -p "$RUNTIME"/{proton,dxvk,vkd3d,bin,box,scripts,prefixes,icd}

echo "::group::[ci] Environment"
echo "PROTON_TAG=$PROTON_TAG"
echo "DXVK_TAG=$DXVK_TAG"
echo "VKD3D_TAG=$VKD3D_TAG"
echo "::endgroup::"

# Helpers
fetch() {
  # $1: URL, $2: output path
  local url="$1" out="$2"
  echo "[ci/fetch] $url -> $out"
  # Prefer aria2c if present (parallel, fast); fallback to curl with retries.
  if command -v aria2c >/dev/null 2>&1; then
    aria2c -x16 -s16 -k1M --allow-overwrite=true -o "$(basename "$out")" -d "$(dirname "$out")" "$url"
  else
    curl -fL --retry 8 --retry-all-errors --retry-max-time 600 \
         -H 'User-Agent: rf-runtime-ci (+https://github.com/jasonsmr/robotforest-wow64-runtime)' \
         -o "$out" "$url"
  fi
  ls -lh "$out" || true
}

untar_gz() {
  # $1: tar.gz, $2: dst, $3: strip
  local tgz="$1" dst="$2" strip="${3:-1}"
  mkdir -p "$dst"
  tar -xzf "$tgz" -C "$dst" --strip-components="$strip"
}

untar_zst() {
  # $1: tar.zst, $2: dst, $3: strip
  local tz="$1" dst="$2" strip="${3:-1}"
  mkdir -p "$dst"
  unzstd -c "$tz" | tar -x -C "$dst" --strip-components="$strip"
}

echo "::group::[ci] Fetch Proton-GE"
# Proton-GE release asset is named Proton-<tag>.tar.gz where <tag> looks like GE-Proton10-9
# Primary
PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_TAG}/Proton-${PROTON_TAG}.tar.gz"
fetch "$PROTON_URL" "$STAGE/proton.tar.gz"
untar_gz "$STAGE/proton.tar.gz" "$RUNTIME/proton" 1
echo "::endgroup::"

echo "::group::[ci] Fetch DXVK"
DXVK_URL="https://github.com/doitsujin/dxvk/releases/download/${DXVK_TAG}/dxvk-${DXVK_TAG}.tar.gz"
fetch "$DXVK_URL" "$STAGE/dxvk.tar.gz"
untar_gz "$STAGE/dxvk.tar.gz" "$RUNTIME/dxvk" 1
echo "::endgroup::"

echo "::group::[ci] Fetch vkd3d-proton"
VKD3D_URL="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/${VKD3D_TAG}/vkd3d-proton-${VKD3D_TAG}.tar.zst"
fetch "$VKD3D_URL" "$STAGE/vkd3d.tar.zst"
untar_zst "$STAGE/vkd3d.tar.zst" "$RUNTIME/vkd3d" 1
echo "::endgroup::"

# Optional: write Turnip ICD placeholder if your app wants to override VK_ICD_FILENAMES
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
