#!/usr/bin/env bash
# sandbot_smoke.sh
# CI-friendly SteamCMD smoke using the Linux SteamCMD client (no large downloads).
# Usage: scripts/ci/sandbot_smoke.sh

set -euo pipefail

_here="$(CDPATH= cd -- "$(dirname -- "$0")"/../.. && pwd)"
log="$PWD/sandbot_smoke.log"

echo "[sandbot] repo root: ${_here}"
echo "[sandbot] log file : ${log}"

work="${HOME}/steamcmd"
mkdir -p "${work}"
cd "${work}"

if [[ ! -x ./steamcmd.sh ]]; then
  echo "[sandbot] fetching steamcmd_linux.tar.gz"
  curl -L -o steamcmd_linux.tar.gz \
    "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
  tar -xzf steamcmd_linux.tar.gz
fi

echo "[sandbot] running smoke (anonymous, app 480 info) ..."
set +e
./steamcmd.sh +login anonymous +app_info_update 1 +app_status 480 +quit | tee "${log}"
ec=$?
set -e

echo "[sandbot] exit code: ${ec}"
grep -E "Connecting anonymously|Already logged in" "${log}" >/dev/null
echo "[sandbot] PASS: SteamCMD started and login flow visible."
