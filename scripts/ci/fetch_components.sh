#!/usr/bin/env bash
# fetch_components.sh
# Verifies (and optionally downloads) runtime components pinned in scripts/ci/pins.env
# Supports special-casing STEAMCMD_WIN_ZIP -> overlay wine64/drive_c/steamcmd placement.
# Usage:
#   scripts/ci/fetch_components.sh --verify-only
#   scripts/ci/fetch_components.sh --fetch

set -euo pipefail

mode="${1:---verify-only}"
root="$(CDPATH= cd -- "$(dirname -- "$0")"/../.. && pwd)"
pins="${root}/scripts/ci/pins.env"
out="${root}/staging/downloads"
steam_win_dir="${root}/staging/overlay/runtime/wine64/drive_c/steamcmd"

mkdir -p "${out}" "${steam_win_dir}"

if [[ ! -f "${pins}" ]]; then
  echo "ERROR: pins file missing: ${pins}" >&2
  exit 1
fi

redl() {
  # curl with retries, fail closed
  curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors -o "$1" "$2"
}

sha_ok() {
  local file="$1" want="$2"
  local have
  have="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$have" == "$want" ]]
}

fail=0
while IFS= read -r line; do
  # skip blanks/comments
  [[ -z "${line}" || "${line}" =~ ^# ]] && continue

  IFS='|' read -r name url sha <<<"${line}"

  if [[ -z "${name}" || -z "${url}" || -z "${sha}" ]]; then
    echo "ERROR: malformed pin line: ${line}" >&2
    fail=1
    continue
  fi

  tgt="${out}/${name}"

  if [[ "${mode}" == "--fetch" ]]; then
    echo ">> FETCH ${name}"
    redl "${tgt}" "${url}"
  else
    echo ">> VERIFY (no fetch) ${name}"
  fi

  if [[ -f "${tgt}" ]]; then
    if ! sha_ok "${tgt}" "${sha}"; then
      echo "ERROR: sha256 mismatch for ${name}"
      echo " expected: ${sha}"
      echo "   actual: $(sha256sum "$tgt" | awk '{print $1}')"
      fail=1
      continue
    fi
    echo "OK: ${name} sha256 verified"

    # Special handling: Windows SteamCMD => unpack into overlay prefix
    case "${name}" in
      STEAMCMD_WIN_ZIP|STEAMCMD_WIN*)
        echo ">> Unpacking Windows SteamCMD into overlay wine64 prefix"
        # remove old content except placeholder
        find "${steam_win_dir}" -mindepth 1 -not -name 'placeholder.txt' -exec rm -rf {} +
        unzip -q "${tgt}" -d "${steam_win_dir}"
        ;;
    esac

  else
    echo "WARN: ${tgt} is missing (run with --fetch to download)"
  fi

done < "${pins}"

exit "${fail}"
