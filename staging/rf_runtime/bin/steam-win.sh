#!/system/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/.."; pwd)"
BIN="$ROOT/bin"
STEAM_HOME="$ROOT/steam"
WINE="$BIN/wine64.sh"
mkdir -p "$STEAM_HOME"
if [ ! -f "$STEAM_HOME/Steam.exe" ]; then
  if [ ! -f "$STEAM_HOME/SteamSetup.exe" ]; then
    echo "Missing SteamSetup.exe in $STEAM_HOME"
    exit 1
  fi
  exec "$WINE" "$STEAM_HOME/SteamSetup.exe"
fi
exec "$WINE" "$STEAM_HOME/Steam.exe" "-console"
