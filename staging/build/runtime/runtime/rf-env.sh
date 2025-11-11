#!/usr/bin/env bash
# rf-env.sh — baseline environment for RobotForest WOW64 runtime

set -euo pipefail

# Resolve runtime root (this script should live directly under runtime/)
RUNTIME_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Prepend our bin-ish locations if they exist
prepend_if_dir() {
  [[ -d "$1" ]] && PATH="$1:$PATH"
}

prepend_if_dir "$RUNTIME_DIR/bin"
prepend_if_dir "$RUNTIME_DIR/box64"
prepend_if_dir "$RUNTIME_DIR/wine64"
prepend_if_dir "$RUNTIME_DIR/dxvk"

export PATH
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mshtml=d"
export WINEDEBUG="-all"
export WINEPREFIX="${RUNTIME_DIR}/wine64"
export STEAMDIR="${RUNTIME_DIR}/wine64/drive_c/steamcmd"

# Useful knobs; toggle per-title via launchers:
export PROTON_USE_WINED3D=0
export PROTON_NO_ESYNC=1
export PROTON_NO_FSYNC=1
export DXVK_HUD=0

echo "[rf-env] runtime: ${RUNTIME_DIR}"
echo "[rf-env] PATH:    ${PATH}"
echo "[rf-env] prefix:  ${WINEPREFIX}"
