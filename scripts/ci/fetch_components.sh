#!/usr/bin/env bash
# fetch_components.sh
# Verifies (and optionally downloads) runtime components pinned in scripts/ci/pins.env
# Usage:
#   scripts/ci/fetch_components.sh --verify-only
#   scripts/ci/fetch_components.sh --fetch

set -euo pipefail

mode="${1:---verify-only}"
root="$(CDPATH= cd -- "$(dirname -- "$0")"/../.. && pwd)"
pins="${root}/scripts/ci/pins.env"
out="${root}/staging/downloads"

if [[ ! -f "${pins}" ]]; then
  echo "ERROR: pins file missing: ${pins}" >&2
  exit 1
fi

mkdir -p "${out}"

fail=0
while IFS= read -r line; do
  # skip blank/comments
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
    curl -L -o "${tgt}" "${url}"
  else
    echo ">> VERIFY (no fetch) ${name}"
  fi

  if [[ -f "${tgt}" ]]; then
    calc="$(sha256sum "${tgt}" | awk '{print $1}')"
    if [[ "${calc}" != "${sha}" ]]; then
      echo "ERROR: sha256 mismatch for ${name}"
      echo " expected: ${sha}"
      echo "   actual: ${calc}"
      fail=1
    else
      echo "OK: ${name} sha256 verified"
    fi
  else
    echo "WARN: ${tgt} is missing (run with --fetch to download)"
  fi

done < "${pins}"

exit "${fail}"
