#!/usr/bin/env bash
# sandbot_steamrunner.sh
#
# CI-friendly "Runtime Smoke" for robotforest-wow64-runtime.
#
# Mode A: structural-only smoke:
#   - Assumes RF_RUNTIME_ROOT points at an extracted rf_runtime tree, e.g.:
#       bin/
#       x86_64-linux/
#       i386-linux/
#       wine64/
#       wine32/
#       dxvk/
#       vkd3d/
#
#   - Verifies presence of key files/dirs only.
#   - Does NOT:
#       * unzip anything
#       * assume an APK layout
#       * talk to Steam
#       * run wine / SteamCMD
#
# This script must be safe on:
#   - GitHub Actions (Ubuntu)
#   - Termux (Android) when RF_RUNTIME_ROOT is set

set -Eeuo pipefail

trap 'echo "[sandbot] ERROR at line ${LINENO}" >&2' ERR

# -------------------------------------------------------------------
# Resolve RF_RUNTIME_ROOT
# -------------------------------------------------------------------
if [[ -n "${RF_RUNTIME_ROOT:-}" ]]; then
  RUNTIME_ROOT="${RF_RUNTIME_ROOT}"
else
  # Fallback for local manual runs
  RUNTIME_ROOT="${PWD}/rf_runtime"
fi

echo "[sandbot] RF_RUNTIME_ROOT: ${RUNTIME_ROOT}"

if [[ ! -d "${RUNTIME_ROOT}" ]]; then
  echo "[sandbot] ERROR: runtime root does not exist: ${RUNTIME_ROOT}" >&2
  exit 1
fi

# Normalize to absolute path
RUNTIME_ROOT="$(cd "${RUNTIME_ROOT}" && pwd)"
echo "[sandbot] normalized RF_RUNTIME_ROOT: ${RUNTIME_ROOT}"

# -------------------------------------------------------------------
# Required layout for Mode A (structural)
# -------------------------------------------------------------------
declare -a REQUIRED_FILES=(
  "bin/wine64.sh"
  "bin/wine32on64.sh"
  "bin/steam-win.sh"

  "x86_64-linux/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
  "x86_64-linux/lib/x86_64-linux-gnu/libc.so.6"

  "i386-linux/lib/i386-linux-gnu/ld-linux.so.2"
  "i386-linux/lib/i386-linux-gnu/libc.so.6"
)

declare -a REQUIRED_DIRS=(
  "wine64"
  "wine32"
  "dxvk/x64"
  "dxvk/x86"
  "vkd3d/x64"
  "vkd3d/x86"
)

echo "[sandbot] === required files ==="
MISSING=0

for rel in "${REQUIRED_FILES[@]}"; do
  path="${RUNTIME_ROOT}/${rel}"
  if [[ -f "${path}" ]]; then
    echo "[sandbot] ok   ${path}"
  else
    echo "[sandbot] MISS ${path}" >&2
    MISSING=1
  fi
done

echo "[sandbot] === required dirs ==="

for rel in "${REQUIRED_DIRS[@]}"; do
  path="${RUNTIME_ROOT}/${rel}"
  if [[ -d "${path}" ]]; then
    echo "[sandbot] ok   ${path}"
  else
    echo "[sandbot] MISS ${path}" >&2
    MISSING=1
  fi
done

# Optional: enforce executability on wrapper scripts
for rel in "bin/wine64.sh" "bin/wine32on64.sh" "bin/steam-win.sh"; do
  path="${RUNTIME_ROOT}/${rel}"
  if [[ -f "${path}" && ! -x "${path}" ]]; then
    echo "[sandbot] WARN: wrapper not executable, fixing: ${path}"
    chmod +x "${path}" || {
      echo "[sandbot] ERROR: failed to chmod +x ${path}" >&2
      MISSING=1
    }
  fi
done

if [[ "${MISSING}" -ne 0 ]]; then
  echo "[sandbot] FAIL: runtime layout is incomplete" >&2
  exit 1
fi

echo "[sandbot] OK: structural runtime smoke (Mode A) passed."
