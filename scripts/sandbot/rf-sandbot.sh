#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   rf-sandbot --runtime-zip /path/to/robotforest-wow64-runtime-<tag>.zip \
#              --appid 9200 \
#              [--username <steam_user>] [--password <steam_pass>] [--dir /games]
#
# Notes:
# - If username/password omitted, uses anonymous (only works for some appids).
# - Requires: bash, unzip, curl or aria2c, tar, gzip, zstd; on desktop Linux with steam deps.

RUNTIME_ZIP=""
APPID=""
STEAM_USER=""
STEAM_PASS=""
GAMES_DIR="${HOME}/Games"
PREFIX_TAG="local"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

die(){ echo "ERR: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime-zip) RUNTIME_ZIP="$2"; shift 2;;
    --appid)       APPID="$2"; shift 2;;
    --username)    STEAM_USER="$2"; shift 2;;
    --password)    STEAM_PASS="$2"; shift 2;;
    --dir)         GAMES_DIR="$2"; shift 2;;
    --prefix-tag)  PREFIX_TAG="$2"; shift 2;;
    *) die "Unknown arg: $1";;
  esac
done

[[ -f "$RUNTIME_ZIP" ]] || die "--runtime-zip not found"
[[ -n "${APPID}" ]]     || die "--appid required"

TAG="$(basename "$RUNTIME_ZIP" | sed -E 's/^robotforest-wow64-runtime-(.+)\.zip$/\1/')"
BASE="${XDG_DATA_HOME:-$HOME/.local/share}/robotforest/${TAG}"
RUNTIME_DIR="$BASE/runtime"
STEAMCMD_DIR="$BASE/steamcmd"
WINEPREFIX="$BASE/prefix-${PREFIX_TAG}"

mkdir -p "$BASE" "$GAMES_DIR"

# Unpack runtime once
if [[ ! -d "$RUNTIME_DIR/robotforest-wow64-runtime" ]]; then
  mkdir -p "$RUNTIME_DIR"
  unzip -q "$RUNTIME_ZIP" -d "$RUNTIME_DIR"
fi

PROTON_DIR="$RUNTIME_DIR/robotforest-wow64-runtime/proton"
[[ -d "$PROTON_DIR" ]] || die "Proton directory missing in runtime"

# SteamCMD bootstrap
if [[ ! -x "$STEAMCMD_DIR/steamcmd.sh" ]]; then
  mkdir -p "$STEAMCMD_DIR"
  cd "$STEAMCMD_DIR"
  if command -v aria2c >/dev/null 2>&1; then
    aria2c -x16 -s16 -k1M "$STEAMCMD_URL" -o steamcmd_linux.tar.gz
  else
    curl -fL "$STEAMCMD_URL" -o steamcmd_linux.tar.gz
  fi
  tar -xzf steamcmd_linux.tar.gz
fi

echo "[info] SteamCMD at $STEAMCMD_DIR"
echo "[info] Proton at $PROTON_DIR"
echo "[info] Prefix at $WINEPREFIX"

# Install/update app
LOGIN_OPTS="+login ${STEAM_USER:-anonymous}"
if [[ -n "$STEAM_USER" && -n "$STEAM_PASS" ]]; then
  LOGIN_OPTS="+login ${STEAM_USER} ${STEAM_PASS}"
fi

"$STEAMCMD_DIR/steamcmd.sh" \
  ${LOGIN_OPTS} \
  +force_install_dir "${GAMES_DIR}/app_${APPID}" \
  +app_update "${APPID}" validate \
  +quit

# Run the app using Proton's wine wrapper
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAMCMD_DIR"   # loose, but ok for local
export STEAM_COMPAT_DATA_PATH="$WINEPREFIX"
export WINEPREFIX="$WINEPREFIX"

# DXVK/VKD3D overrides would be added here if needed per title

GAME_EXE="$(find "${GAMES_DIR}/app_${APPID}" -maxdepth 3 -type f -iname '*.exe' | head -n1 || true)"
[[ -n "$GAME_EXE" ]] || die "Could not locate a .exe in app_${APPID}; please set manually."

echo "[run] ${GAME_EXE}"
exec "${PROTON_DIR}/files/bin/wine" "${GAME_EXE}"
