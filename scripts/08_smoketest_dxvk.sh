#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
ENV_FILE="${ENV_FILE:-$STAGE/rf_env.sh}"
PREFIX="${WINEPREFIX:-$STAGE/prefix}"

# shellcheck source=/dev/null
. "$ENV_FILE"

W64="${WINE64_BIN:-$(command -v wine64 || true)}"
W32="${WINE32_BIN:-$(command -v wine || true)}"

[[ -n "$W64" && -n "$W32" ]] || { echo "[error] Missing WINE64_BIN/WINE32_BIN. Run 00_probe_wine.sh."; exit 2; }

export WINEPREFIX="$PREFIX"
export WINEARCH=win64

echo "== Wine versions =="
echo "wine64: $($W64 --version || echo 'N/A')"
echo "wine32: $($W32 --version || echo 'N/A')"
echo

echo "== Prefix check =="
need() { [[ -e "$1" ]] || { echo "[FAIL] $1"; exit 1; }; }
need "$PREFIX/drive_c/windows/system32"
need "$PREFIX/drive_c/windows/syswow64"
echo "[ok] system32/syswow64 present under: $PREFIX/drive_c/windows"
echo

echo "== DXVK =="
DXVK64="$STAGE/dxvk/x64/d3d11.dll"
DXVK32="$STAGE/dxvk/x86/d3d11.dll"
if [[ -f "$DXVK64" && -f "$DXVK32" ]]; then
  V64="$(strings "$DXVK64" 2>/dev/null | grep -m1 -E '^DXVK .+')" || true
  V32="$(strings "$DXVK32" 2>/dev/null | grep -m1 -E '^DXVK .+')" || true
  echo "[x64] ${V64:-DXVK version not found in strings}"
  echo "[x86] ${V32:-DXVK version not found in strings}"
else
  echo "[warn] DXVK DLLs not found at $STAGE/dxvk/{x64,x86}"
fi
echo

echo "== vkd3d-proton =="
VKD64="$STAGE/vkd3d/x64/d3d12.dll"
VKD32="$STAGE/vkd3d/x86/d3d12.dll"
if [[ -f "$VKD64" && -f "$VKD32" ]]; then
  P64="$(strings "$VKD64" 2>/dev/null | grep -m1 -E 'vkd3d.*proton|VKD3D.*Proton|vkd3d-proton' | head -n1)" || true
  P32="$(strings "$VKD32" 2>/dev/null | grep -m1 -E 'vkd3d.*proton|VKD3D.*Proton|vkd3d-proton' | head -n1)" || true
  echo "[x64] ${P64:-vkd3d-proton version not found in strings}"
  echo "[x86] ${P32:-vkd3d-proton version not found in strings}"
else
  echo "[warn] vkd3d-proton DLLs not found at $STAGE/vkd3d/{x64,x86}"
fi
echo

echo "== Vulkan ICD (if set) =="
if [[ -n "${VK_ICD_FILENAMES:-}" ]]; then
  echo "VK_ICD_FILENAMES=$VK_ICD_FILENAMES"
else
  echo "(not set here; may still be inherited from your environment)"
fi
echo

echo "[summary] Smoke test completed."
