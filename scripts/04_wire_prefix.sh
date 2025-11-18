#!/usr/bin/env bash
set -euo pipefail

# --- Paths (edit if you moved the project) ---
ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"

DXVK64="${DXVK64:-$STAGE/dxvk/x64}"
DXVK86="${DXVK86:-$STAGE/dxvk/x86}"
VKD364="${VKD364:-$STAGE/vkd3d/x64}"
VKD386="${VKD386:-$STAGE/vkd3d/x86}"

# If you later drop Wine payloads here, point these at the binaries:
#   WINE64_BIN="$STAGE/wine64/bin/wine64"
#   WINE32_BIN="$STAGE/wine32/bin/wine"
WINE64_BIN="${WINE64_BIN:-}"
WINE32_BIN="${WINE32_BIN:-}"

# Allow passing a custom prefix on the CLI; default to staging prefix.
PREFIX="${1:-$STAGE/prefix}"

# --- Create prefix skeleton (no Wine required) ---
sys32="$PREFIX/drive_c/windows/system32"     # 64-bit DLL dir on WoW64
wow64="$PREFIX/drive_c/windows/syswow64"     # 32-bit DLL dir on WoW64
mkdir -p "$sys32" "$wow64"

# --- Copy DXVK + VKD3D DLLs into the prefix ---
copy_set() {
  local src="$1" dst="$2"; shift 2
  for f in "$@"; do
    if [[ -f "$src/$f" ]]; then
      cp -f "$src/$f" "$dst/$f"
    else
      echo "[warn] missing $src/$f"
    fi
  done
}

# 64-bit set -> system32
copy_set "$DXVK64" "$sys32" d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
copy_set "$VKD364" "$sys32" d3d12.dll d3d12core.dll

# 32-bit set -> syswow64
copy_set "$DXVK86" "$wow64" d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
copy_set "$VKD386" "$wow64" d3d12.dll d3d12core.dll

# --- Write a minimal dxvk.conf (optional) ---
DXVK_CONF="$PREFIX/dxvk.conf"
cat >"$DXVK_CONF"<<'CONF'
# Keep HUD off by default (flip to 1 for debugging)
dxvk.hud = 0
# Avoid excessive state cache stalls on slow storage
dxvk.enableStateCache = true
CONF

# --- Env file you can source in shells/scripts ---
ENV_FILE="$STAGE/rf_env.sh"
cat >"$ENV_FILE"<<ENV
# Source this:  . "$ENV_FILE"
export WINEPREFIX="$PREFIX"

# Prefer native (DXVK/vkd3d-proton) over builtin d3d* & dxgi
export WINEDLLOVERRIDES="d3d9,dxgi,d3d10core,d3d11,d3d12,d3d12core=n,b"

# Point DXVK to its config (optional)
export DXVK_CONFIG_FILE="$DXVK_CONF"

# Keep HUD quiet unless debugging; flip to "1" if needed
export DXVK_HUD="${DXVK_HUD:-0}"

# If you later provide Wine payloads, uncomment and adjust:
# export PATH="$STAGE/wine64/bin:$STAGE/wine32/bin:\$PATH"
ENV

# --- Friendly summary ---
echo "[ok] Wired DXVK + vkd3d-proton into:"
echo "     64-bit -> $sys32"
echo "     32-bit -> $wow64"
echo "[ok] Wrote env file: $ENV_FILE"
echo "[ok] Wrote DXVK config: $DXVK_CONF"

# --- Optional smoke checks if Wine is available ---
have_any=0
if [[ -n "$WINE64_BIN" && -x "$WINE64_BIN" ]]; then
  have_any=1
  echo "[check] wine64 --version"
  WINEPREFIX="$PREFIX" "$WINE64_BIN" --version || true
fi
if [[ -n "$WINE32_BIN" && -x "$WINE32_BIN" ]]; then
  have_any=1
  echo "[check] wine (32-bit) --version"
  WINEPREFIX="$PREFIX" "$WINE32_BIN" --version || true
fi

if [[ "$have_any" -eq 0 ]]; then
  echo "[info] Wine payloads not present. Skipping smoke tests."
  echo "       Later, set WINE64_BIN/WINE32_BIN and rerun this script."
fi

echo "[summary] PREFIX: $PREFIX"
echo "[summary] To use:  . \"$ENV_FILE\"   # (dot-space to source)"
