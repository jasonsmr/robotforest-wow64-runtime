#!/usr/bin/env bash
set -euo pipefail

: "${TMP:=${HOME}/tmp}"
WORK="${TMP}/rf-sandbot-$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

MODE="${SANDBOT_MODE:-offline}"   # offline|online
ZIP="${1:-}"

log(){ echo "[$(date +%H:%M:%S)] $*"; }

if [[ "$MODE" == "offline" ]]; then
  log "Offline mode smoke: verify runtime zip + launcher"
  if [[ -z "$ZIP" ]]; then
    ZIP="$(ls -1 ./dist/robotforest-wow64-runtime-*.zip | head -n1 || true)"
  fi
  [[ -f "$ZIP" ]] || { echo "no runtime zip found" >&2; exit 1; }
  unzip -q "$ZIP" -d "$WORK"
  bash "$WORK/rootfs/bin/rf-runtime-env"
  log "Offline smoke OK."
  exit 0
fi

if [[ "$MODE" == "online" ]]; then
  log "Online mode: minimal SteamCMD bootstrap (anonymous)"
  pushd "$WORK" >/dev/null
  # Use Ubuntu steamcmd: require network; keep this opt-in
  sudo apt-get update
  sudo apt-get install -y steamcmd
  steamcmd +login anonymous +app_info_update 1 +app_info_print 480 +quit
  popd >/dev/null
  log "SteamCMD smoke OK."
fi
