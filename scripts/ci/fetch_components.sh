#!/usr/bin/env bash
set -euo pipefail

# ===== Versions (can be overridden by env or workflow inputs) =====
PROTON_TAG="${PROTON_TAG:-GE-Proton10-9}"
DXVK_TAG="${DXVK_TAG:-v2.4}"
VKD3D_TAG="${VKD3D_TAG:-v2.13}"

ROOT="$(pwd)"
STAGE="$ROOT/staging"
RUNTIME="$STAGE/runtime"

mkdir -p "$RUNTIME"/{proton,dxvk,vkd3d,bin,box,scripts,prefixes}

echo "[ci] Fetching components -> $RUNTIME"

# ----- Proton-GE -----
echo "[ci] Proton-GE: $PROTON_TAG"
curl -fsSL -o "$STAGE/proton.tar.gz" "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$PROTON_TAG/Proton-$PROTON_TAG.tar.gz"
mkdir -p "$RUNTIME/proton"
tar -xzf "$STAGE/proton.tar.gz" -C "$RUNTIME/proton" --strip-components=1

# ----- DXVK -----
echo "[ci] DXVK: $DXVK_TAG"
curl -fsSL -o "$STAGE/dxvk.tar.gz" "https://github.com/doitsujin/dxvk/releases/download/$DXVK_TAG/dxvk-$DXVK_TAG.tar.gz"
mkdir -p "$RUNTIME/dxvk"
tar -xzf "$STAGE/dxvk.tar.gz" -C "$RUNTIME/dxvk" --strip-components=1

# ----- vkd3d-proton -----
echo "[ci] vkd3d-proton: $VKD3D_TAG"
curl -fsSL -o "$STAGE/vkd3d.tar.zst" "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/$VKD3D_TAG/vkd3d-proton-$VKD3D_TAG.tar.zst"
mkdir -p "$RUNTIME/vkd3d"
unzstd -c "$STAGE/vkd3d.tar.zst" | tar -x -C "$RUNTIME/vkd3d" --strip-components=1

# ----- Launch script -----
cat > "$RUNTIME/scripts/steam-run.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

# Root of runtime (this script is at runtime/scripts/steam-run.sh)
RUNTIME_DIR="$(cd "$(dirname "$0")/.." && pwd)"

export BOX64_DYNAREC=1
export BOX64_LOG=0
export BOX64_LD_LIBRARY_PATH="${RUNTIME_DIR}/proton/files/lib64:${RUNTIME_DIR}/proton/files/lib:${RUNTIME_DIR}/dxvk/x64:${RUNTIME_DIR}/vkd3d/x64"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${RUNTIME_DIR}/proton"
export STEAM_COMPAT_DATA_PATH="${RUNTIME_DIR}/prefixes/proton"

# Vulkan ICD (Turnip on Adreno)
if [ -f "${RUNTIME_DIR}/icd/turnip_icd.json" ]; then
  export VK_ICD_FILENAMES="${RUNTIME_DIR}/icd/turnip_icd.json"
fi

# Prefer Proton wine64
WINE64="${RUNTIME_DIR}/proton/dist/bin/wine64"
[ -x "$WINE64" ] || { echo "[err] wine64 not found in Proton dist"; exit 2; }

# If run with a Windows EXE, use Proton directly
if [ $# -gt 0 ]; then
  exec "$WINE64" "$@"
fi

echo "[steam-run] No arguments: you can call this with a game EXE, e.g.:"
echo "  runtime/scripts/steam-run.sh 'C:/path/to/Game.exe'"
SH
chmod +x "$RUNTIME/scripts/steam-run.sh"

# Optional: seed an empty Proton prefix (saves a little time later)
mkdir -p "$RUNTIME/prefixes/proton"

echo "[ci] Components fetched + launcher written."
