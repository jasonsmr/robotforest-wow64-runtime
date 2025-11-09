#!/usr/bin/env bash
set -euo pipefail

: "${TMP:=${HOME}/tmp}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGING="${ROOT}/staging"
mkdir -p "$STAGING" "$TMP"

# shellcheck disable=SC1091
source "${ROOT}/scripts/ci/pins.env"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1" >&2; exit 1; }; }
need aria2c; need sha256sum || true; need jq || true; need file || true

dl() { # url out
  local url="$1" out="$2"
  if [[ ! -s "$out" ]]; then
    aria2c -x16 -s16 -k1M -o "$(basename "$out")" -d "$(dirname "$out")" "$url"
  fi
}

verify_sha() { # file expected
  local f="$1" expected="${2:-}"
  [[ -z "$expected" ]] && return 0
  echo "${expected}  ${f}" | sha256sum -c -
}

# Proton
P_TGZ="${STAGING}/proton.tar.gz"
dl "$PROTON_URL" "$P_TGZ"
verify_sha "$P_TGZ" "$PROTON_SHA256"

# DXVK
D_TGZ="${STAGING}/dxvk.tar.gz"
dl "$DXVK_URL" "$D_TGZ"
verify_sha "$D_TGZ" "$DXVK_SHA256"

# vkd3d-proton
V_ZST="${STAGING}/vkd3d.tar.zst"
dl "$VKD3D_URL" "$V_ZST"
verify_sha "$V_ZST" "$VKD3D_SHA256"

echo "Fetched components:"
ls -lh "$STAGING"
