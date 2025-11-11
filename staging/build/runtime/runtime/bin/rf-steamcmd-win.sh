#!/usr/bin/env bash
# Launch Windows SteamCMD under Wine (via Box64). No GUI; headless smoke capable.

set -euo pipefail

RUNTIME_DIR="$(CDPATH= cd -- "$(dirname -- "$0")"/.. && pwd)"
source "${RUNTIME_DIR}/rf-env.sh"

STEAMC="${WINEPREFIX}/drive_c/steamcmd/steamcmd.exe"
if [[ ! -f "${STEAMC}" ]]; then
  echo "[rf-steamcmd-win] Missing ${STEAMC}"
  echo "[rf-steamcmd-win] Did you pack pins for SteamCMD Windows zip?"
  exit 2
fi

# Prefer box64 in PATH if present; fallback to plain wine if runner already has it (shouldn’t in APK).
BOX64="$(command -v box64 || true)"
WINE64="$(command -v wine64 || true)"

if [[ -x "${BOX64}" ]]; then
  echo "[rf-steamcmd-win] Using Box64 + Wine64"
  exec box64 wine64 "${STEAMC}" "$@"
elif [[ -n "${WINE64}" ]]; then
  echo "[rf-steamcmd-win] Using host wine64 (CI case only)"
  exec wine64 "${STEAMC}" "$@"
else
  echo "[rf-steamcmd-win] No box64/wine64 found in PATH"
  exit 3
fi
