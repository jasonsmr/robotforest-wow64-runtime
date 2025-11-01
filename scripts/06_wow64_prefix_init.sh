#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
ENV_FILE="${ENV_FILE:-$STAGE/rf_env.sh}"
PREFIX="${WINEPREFIX:-$STAGE/prefix}"

# shellcheck source=/dev/null
. "$ENV_FILE"

# Require wine binaries
W64="${WINE64_BIN:-$(command -v wine64 || true)}"
W32="${WINE32_BIN:-$(command -v wine || true)}"

if [[ -z "$W64" || -z "$W32" ]]; then
  echo "[error] Need both wine64 and wine (32-bit). Set WINE64_BIN and WINE32_BIN in $ENV_FILE." >&2
  exit 2
fi

export WINEPREFIX="$PREFIX"
export WINEARCH=win64
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-d3d9,dxgi,d3d10core,d3d11,d3d12,d3d12core=n,b}"

echo "[init] wine64 wineboot -u (64-bit half)…"
"$W64" wineboot -u

echo "[init] wine (32-bit) into same prefix to complete WoW64…"
"$W32" wineboot -u

# Minimal sanity files/folders
need() { [[ -e "$1" ]] || { echo "[FAIL] missing: $1"; exit 1; }; }
need "$PREFIX/drive_c/windows/system32"
need "$PREFIX/drive_c/windows/syswow64"

# Optional toggles that are generally safe on Android
# Disable NVAPI (some games crash if DXVK tries to talk to nonexistent NV driver)
reg_nvapi="$(mktemp)"
cat >"$reg_nvapi"<<'REG'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"nvapi"="disabled"
"nvapi64"="disabled"
REG
"$W64" regedit /S "$reg_nvapi" || true
rm -f "$reg_nvapi"

echo "[ok] WoW64 prefix ready:"
echo "     WINEPREFIX=$WINEPREFIX"
echo "     wine64: $($W64 --version)"
echo "     wine32: $($W32 --version)"
