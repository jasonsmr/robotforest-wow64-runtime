#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
ENV_FILE="${ENV_FILE:-$STAGE/rf_env.sh}"
CACHE="${CACHE:-$STAGE/cache}"
PREFIX="${WINEPREFIX:-$STAGE/prefix}"

# shellcheck source=/dev/null
. "$ENV_FILE"

mkdir -p "$CACHE"

# Steam official installer (override with STEAM_URL if you want)
STEAM_URL="${STEAM_URL:-https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe}"
STEAM_EXE="$CACHE/SteamSetup.exe"

W64="${WINE64_BIN:-$(command -v wine64 || true)}"
W32="${WINE32_BIN:-$(command -v wine || true)}"
if [[ -z "$W32" ]]; then
  echo "[error] Need 32-bit wine (WINE32_BIN). Set it in $ENV_FILE." >&2
  exit 2
fi

export WINEPREFIX="${PREFIX}"
export WINEARCH=win64

# Fetch installer
if [[ ! -s "$STEAM_EXE" ]]; then
  echo "[get] $STEAM_URL"
  curl -fL --retry 3 -o "$STEAM_EXE" "$STEAM_URL"
else
  echo "[skip] Using cached $STEAM_EXE"
fi

# Install (runs the NSIS bootstrapper)
echo "[install] Steam into WoW64 prefix (this may take a moment)…"
"$W32" "$STEAM_EXE" /S || true

# Path where Steam usually lands in WoW64 prefixes
STEAM_DIR="$PREFIX/drive_c/Program Files (x86)/Steam"
STEAM_BIN="$STEAM_DIR/steam.exe"

if [[ ! -f "$STEAM_BIN" ]]; then
  echo "[warn] steam.exe not found yet at:"
  echo "       $STEAM_BIN"
  echo "       If the installer updated itself and re-launched, simply run the launcher below; Steam will finish setup."
fi

# Write launcher
LAUNCH="$STAGE/steam/run_steam.sh"
mkdir -p "$(dirname "$LAUNCH")"
cat >"$LAUNCH"<<'EOF'
#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
ENV_FILE="${ENV_FILE:-$STAGE/rf_env.sh}"
PREFIX="${WINEPREFIX:-$STAGE/prefix}"

# shellcheck source=/dev/null
. "$ENV_FILE"

W64="${WINE64_BIN:-$(command -v wine64 || true)}"
W32="${WINE32_BIN:-$(command -v wine || true)}"

if [[ -z "$W32" ]]; then
  echo "[error] No 32-bit wine found; set WINE32_BIN in $ENV_FILE." >&2
  exit 1
fi

export WINEPREFIX="$PREFIX"
export WINEARCH=win64

# Ensure DXVK/VKD3D overrides remain active
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-d3d9,dxgi,d3d10core,d3d11,d3d12,d3d12core=n,b}"
export DXVK_HUD="${DXVK_HUD:-0}"

# If your rf_env.sh doesn’t already set VK_ICD_FILENAMES, you can export it here.
# export VK_ICD_FILENAMES="${VK_ICD_FILENAMES:-/data/data/com.termux/files/home/.local/share/vulkan/icd.d/freedreno_icd.aarch64.json}"

STEAM_BIN="$PREFIX/drive_c/Program Files (x86)/Steam/steam.exe"

# Helpful flags:
# -no-cef-sandbox : avoids Chromium sandbox issues under Wine
# -silent         : start minimized to tray
# -noshaders     : (optional) can reduce initial compile overhead on low RAM
FLAGS=(-no-cef-sandbox -silent)

# First run sometimes needs an extra kick after bootstrap
exec "$W32" "$STEAM_BIN" "${FLAGS[@]}"
EOF
chmod +x "$LAUNCH"

echo "[ok] Steam bootstrap staged."
echo "[next] 1) Run WoW64 init if you haven’t:  $ROOT/scripts/06_wow64_prefix_init.sh"
echo "       2) Launch Steam:                     $LAUNCH"
