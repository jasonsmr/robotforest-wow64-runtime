# ~/android/robotforest-wow64-runtime/scripts/sandbot/rf-sandbot.sh
#!/usr/bin/env bash
set -euo pipefail

# Resolve runtime root (script may be invoked from anywhere)
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SDIR/../.." && pwd)"

TOOLS="$ROOT/tools"
RUNTIME="$ROOT/runtime"
PROTON="$RUNTIME/proton"       # symlink created by packer
STEAMDIR="$ROOT/steam"         # where steamcmd will live and install content
STEAMCMD="$TOOLS/steamcmd/steamcmd.sh"

mkdir -p "$TOOLS" "$STEAMDIR"

usage() {
  cat <<EOF
rf-sandbot.sh — Steam helper

Subcommands:
  login                    -> prompts or uses env STEAM_USERNAME / STEAM_PASSWORD (/ STEAM_GUARD_CODE)
  list                     -> prints owned apps (app id and name)
  install <appid>         -> installs game to $STEAMDIR/steamapps
  run <appid> [exe_rel]   -> runs installed app via Proton; exe_rel is relative exe path under game dir
  where <appid>           -> prints resolved game content path

Env (optional):
  STEAM_USERNAME, STEAM_PASSWORD, STEAM_GUARD_CODE
  STEAM_FORCE_CLI_LOGIN=1  -> force interactive prompt even if env present
EOF
}

need_steamcmd() {
  if [[ ! -x "$STEAMCMD" ]]; then
    echo "[steamcmd] downloading…"
    mkdir -p "$TOOLS/steamcmd"
    curl -fL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
      -o "$TOOLS/steamcmd/steamcmd_linux.tar.gz"
    (cd "$TOOLS/steamcmd" && tar -xf steamcmd_linux.tar.gz)
  fi
}

steam_login() {
  need_steamcmd
  local u="${STEAM_USERNAME:-}"
  local p="${STEAM_PASSWORD:-}"
  local g="${STEAM_GUARD_CODE:-}"

  if [[ -z "${STEAM_FORCE_CLI_LOGIN:-}" && -n "$u" && -n "$p" ]]; then
    echo "[login] using env creds for $u"
    # Guard code passed via '+set_steam_guard_code'
    "$STEAMCMD" +login "$u" "$p" ${g:+ "+set_steam_guard_code" "$g"} +quit
  else
    echo "[login] interactive"
    "$STEAMCMD"
  fi
}

steam_list() {
  need_steamcmd
  echo "[list] owned apps (requires prior login)"
  "$STEAMCMD" +login "${STEAM_USERNAME:-anonymous}" ${STEAM_PASSWORD:+ "$STEAM_PASSWORD"} +app_info_print 0 +quit | \
    sed -n 's/^\s\+"\([0-9]\+\)".*$/\1/p' | head -n 200
  echo "Tip: For a readable list, consider 'steamctl' or web APIs later."
}

steam_install() {
  local appid="$1"
  [[ -n "$appid" ]] || { echo "usage: install <appid>"; exit 2; }
  need_steamcmd
  echo "[install] appid=$appid"
  "$STEAMCMD" +login "$STEAM_USERNAME" "$STEAM_PASSWORD" ${STEAM_GUARD_CODE:+ "+set_steam_guard_code" "$STEAM_GUARD_CODE"} \
             +force_install_dir "$STEAMDIR/steamapps/common/$appid" \
             +app_update "$appid" validate +quit
}

game_path() {
  local appid="$1"
  local d="$STEAMDIR/steamapps/common/$appid"
  [[ -d "$d" ]] || { echo ""; return 1; }
  echo "$d"
}

steam_run() {
  local appid="$1"; shift || true
  local rel="${1:-}"

  local dir
  dir="$(game_path "$appid")" || { echo "Game not installed: $appid"; exit 3; }

  # Proton env wiring
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$ROOT"
  export STEAM_COMPAT_DATA_PATH="$ROOT/compatdata/$appid"
  mkdir -p "$STEAM_COMPAT_DATA_PATH"

  # Guess exe if not provided (basic heuristic)
  local exe
  if [[ -n "$rel" ]]; then
    exe="$dir/$rel"
  else
    exe="$(find "$dir" -maxdepth 2 -type f -iname "*.exe" | head -n1 || true)"
  fi

  [[ -n "$exe" && -f "$exe" ]] || { echo "Could not find a .exe. Provide rel path: rf-sandbot.sh run $appid <path/to/Game.exe>"; exit 4; }

  echo "[run] $exe via Proton"
  # Proton's entry point
  "$PROTON/proton" run "$exe"
}

case "${1:-}" in
  login)   steam_login ;;
  list)    steam_list ;;
  install) shift; steam_install "${1:-}" ;;
  where)   shift; game_path "${1:-}" ;;
  run)     shift; steam_run "${1:-}" "${2:-}" ;;
  ""|-h|--help) usage ;;
  *) echo "unknown command: $1"; usage; exit 1 ;;
esac
