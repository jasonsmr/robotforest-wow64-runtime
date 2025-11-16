#!/usr/bin/env bash
# Minimal, conservative install driver for SteamCMD + runtime sanity on device.
set -euo pipefail

# Inputs
RUNTIME_ZIP="${1:-robotforest-wow64-runtime.zip}"
APPID="${APPID:-480}"             # change as needed
STEAM_USER="${STEAM_USER:-}"      # optional (anonymous if empty)
STEAM_PASS="${STEAM_PASS:-}"      # optional

# Paths
HOME_DIR="${HOME:?}"
RF_DIR="$HOME_DIR/.robotforest/runtime"
STEAM_DIR="$HOME_DIR/.robotforest/steam"
mkdir -p "$RF_DIR" "$STEAM_DIR"

# Unpack runtime if needed
if [[ ! -d "$RF_DIR/root" ]]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  unzip -q "$RUNTIME_ZIP" -d "$tmp"
  src="$(find "$tmp" -maxdepth 1 -type d -name "robotforest-wow64-runtime*" | head -n1)"
  [[ -d "$src" ]] || { echo "Runtime unpack failed"; exit 1; }
  mkdir -p "$RF_DIR"; cp -a "$src" "$RF_DIR/root"
fi

export RFROOT="$RF_DIR/root"
export PATH="$RFROOT/bin:$PATH"
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="

echo "[sandbot] box64 -v";  "$RFROOT/bin/box64" -v || true
echo "[sandbot] wine64 --version"; "$RFROOT/bin/wine64" --version || true

# Get SteamCMD (Windows)
SCZIP="$STEAM_DIR/steamcmd.zip"
if [[ ! -f "$SCZIP" ]]; then
  echo "[sandbot] fetching steamcmd.zip…"
  aria2c -q -d "$STEAM_DIR" -o steamcmd.zip "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
fi
if [[ ! -d "$STEAM_DIR/steamcmd" ]]; then
  mkdir -p "$STEAM_DIR/steamcmd"
  (cd "$STEAM_DIR/steamcmd" && unzip -q ../steamcmd.zip)
fi

# Prefer 32-bit wine thunk for steamcmd.exe; WoW64 should route correctly.
STEAMCMD_EXE="$STEAM_DIR/steamcmd/steamcmd.exe"
export WINEPREFIX="$RF_DIR/prefix"
mkdir -p "$WINEPREFIX"

LOGIN_ARGS="+login anonymous"
if [[ -n "$STEAM_USER" && -n "$STEAM_PASS" ]]; then
  LOGIN_ARGS="+login \"$STEAM_USER\" \"$STEAM_PASS\""
fi

echo "[sandbot] updating SteamCMD metadata…"
"$RFROOT/bin/wine" "$STEAMCMD_EXE" +@ShutdownOnFailedCommand 1 +force_install_dir "$STEAM_DIR/apps/$APPID" \
  $LOGIN_ARGS +app_info_update 1 +quit || true

# Optional install (requires credentials for most apps)
if [[ -n "${INSTALL_APPID:-}" ]]; then
  echo "[sandbot] installing appid ${INSTALL_APPID}…"
  "$RFROOT/bin/wine" "$STEAMCMD_EXE" +@ShutdownOnFailedCommand 1 +force_install_dir "$STEAM_DIR/apps/${INSTALL_APPID}" \
    $LOGIN_ARGS +app_update "${INSTALL_APPID}" validate +quit || true
fi

echo "[sandbot] done."
