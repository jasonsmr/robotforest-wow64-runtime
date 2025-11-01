#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
ENV_FILE="${ENV_FILE:-$STAGE/rf_env.sh}"

DXVK64="$STAGE/dxvk/x64"; DXVK86="$STAGE/dxvk/x86"
VKD364="$STAGE/vkd3d/x64"; VKD386="$STAGE/vkd3d/x86"

# --- Args ---
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 /path/to/game/dir <Game.exe> [--arch both|x64|x86] [--name launcher.sh]" >&2
  exit 2
fi
GAMEDIR="$(realpath -m "$1")"; shift
EXE="$1"; shift
ARCH="both"; LAUNCHER="run_game.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) ARCH="$2"; shift 2;;
    --name) LAUNCHER="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

mkdir -p "$GAMEDIR"

copy_set() {
  local src="$1" dst="$2"; shift 2
  mkdir -p "$dst"
  for f in "$@"; do
    if [[ -f "$src/$f" ]]; then
      cp -f "$src/$f" "$dst/$f"
    else
      echo "[warn] missing $src/$f"
    fi
  done
}

# Decide where to drop DLLs:
# Most Windows games look for d3d*.dll and dxgi.dll in the game folder next to EXE.
DLLDROP="$GAMEDIR"

case "$ARCH" in
  both)
    copy_set "$DXVK64" "$DLLDROP" d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
    copy_set "$VKD364" "$DLLDROP" d3d12.dll d3d12core.dll
    copy_set "$DXVK86" "$DLLDROP/x86" d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
    copy_set "$VKD386" "$DLLDROP/x86" d3d12.dll d3d12core.dll
    ;;
  x64)
    copy_set "$DXVK64" "$DLLDROP" d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
    copy_set "$VKD364" "$DLLDROP" d3d12.dll d3d12core.dll
    ;;
  x86)
    copy_set "$DXVK86" "$DLLDROP" d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
    copy_set "$VKD386" "$DLLDROP" d3d12.dll d3d12core.dll
    ;;
  *)
    echo "Invalid --arch: $ARCH (use both|x64|x86)"; exit 2;;
esac

# Launcher script
LAUNCH="$GAMEDIR/$LAUNCHER"
cat >"$LAUNCH"<<EOF
#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

# Source runtime env (WINEPREFIX, overrides, DXVK config)
. "$ENV_FILE"

# If you have wine payloads, ensure PATH includes them
# export PATH="\$PATH"

# Force DLL overrides for safety (native dxvk/vkd3d)
export WINEDLLOVERRIDES="\${WINEDLLOVERRIDES:-d3d9,dxgi,d3d10core,d3d11,d3d12,d3d12core=n,b}"

# Optional: disable the HUD; set to 1 if you want debug
export DXVK_HUD="\${DXVK_HUD:-0}"

# Pick wine binary (prefers wine64 if available)
WINE64="\${WINE64_BIN:-\$(command -v wine64 || true)}"
WINE32="\${WINE32_BIN:-\$(command -v wine || true)}"

EXE="$EXE"
DIR="\$(cd "$(dirname "$EXE")" && pwd)"
BASE="\$(basename "$EXE")"

if [[ -n "\$WINE64" ]]; then
  exec "\$WINE64" "\$DIR/\$BASE"
elif [[ -n "\$WINE32" ]]; then
  exec "\$WINE32" "\$DIR/\$BASE"
else
  echo "[error] No wine binaries found. Set WINE64_BIN/WINE32_BIN in $ENV_FILE or PATH." >&2
  exit 1
fi
EOF
chmod +x "$LAUNCH"

echo "[ok] Shim installed at: $GAMEDIR"
echo "[ok] Launcher: $LAUNCH"
echo "[hint] To run:  . \"$ENV_FILE\" && \"$LAUNCH\""
