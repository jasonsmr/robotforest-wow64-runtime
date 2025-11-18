#!/usr/bin/env bash
# rf_verify_runtime.sh — verify rf-runtime-* archive structure
# Works both on Termux (no /tmp) and on GitHub Ubuntu runners.

set -Eeuo pipefail

trap 'echo "[verify] ERROR at line ${LINENO}" >&2' ERR

ARCHIVE="${1:-}"

if [[ -z "${ARCHIVE}" ]]; then
  echo "usage: $0 dist/rf-runtime-*.tar.zst[.sha256]" >&2
  exit 1
fi

# Normalize path if possible
if command -v realpath >/dev/null 2>&1; then
  ARCHIVE="$(realpath "${ARCHIVE}")"
fi

if [[ ! -e "${ARCHIVE}" ]]; then
  echo "[verify] ERROR: archive or sha256 file not found: ${ARCHIVE}" >&2
  exit 1
fi

# 1) Handle outer sha256
case "${ARCHIVE}" in
  *.sha256)
    echo "[verify] checking sha256 (explicit): ${ARCHIVE}"
    (
      cd "$(dirname "${ARCHIVE}")"
      sha256sum -c "$(basename "${ARCHIVE}")"
    )
    ARCHIVE="${ARCHIVE%.sha256}"
    ;;
  *)
    SHA_SIDE="${ARCHIVE}.sha256"
    if [[ -f "${SHA_SIDE}" ]]; then
      echo "[verify] checking sha256 (sidecar): ${SHA_SIDE}"
      (
        cd "$(dirname "${SHA_SIDE}")"
        sha256sum -c "$(basename "${SHA_SIDE}")"
      )
    else
      echo "[verify] no sidecar .sha256 found; skipping outer checksum"
    fi
    ;;
esac

if [[ ! -f "${ARCHIVE}" ]]; then
  echo "[verify] ERROR: archive not found after sha256 check: ${ARCHIVE}" >&2
  exit 1
fi

# 2) Choose a temp root that works on Termux *and* CI
BASE_TMP="${TMPDIR:-${TMP:-${HOME}/tmp}}"
mkdir -p "${BASE_TMP}"

WORKDIR="$(mktemp -d "${BASE_TMP%/}/rf_verify.XXXXXX")"
echo "[verify] extracting archive into: ${WORKDIR}"

cleanup() {
  rm -rf "${WORKDIR}"
}
trap cleanup EXIT

tar --use-compress-program="zstd --long=31 -d" \
    -xf "${ARCHIVE}" \
    -C "${WORKDIR}"

# 3) Locate runtime root
# We support BOTH layouts:
#   (A) WORKDIR/rf_runtime/{bin, wine64, ...}
#   (B) WORKDIR/{bin, wine64, ...} (no rf_runtime prefix)
if [[ -d "${WORKDIR}/rf_runtime" ]]; then
  RUNTIME_ROOT="${WORKDIR}/rf_runtime"
else
  # Prefer directory that owns bin/wine64.sh
  WINE64_PATH="$(
    find "${WORKDIR}" -maxdepth 6 -type f -name 'wine64.sh' -print 2>/dev/null | head -n1 || true
  )"
  if [[ -n "${WINE64_PATH}" ]]; then
    # .../rf_runtime/bin/wine64.sh -> rf_runtime
    # .../bin/wine64.sh           -> WORKDIR
    RUNTIME_ROOT="$(dirname "$(dirname "${WINE64_PATH}")")"
  else
    # Fallback: parent of first bin/ directory we see
    BIN_DIR="$(
      find "${WORKDIR}" -maxdepth 4 -type d -name 'bin' -print 2>/dev/null | head -n1 || true
    )"
    if [[ -n "${BIN_DIR}" ]]; then
      RUNTIME_ROOT="$(dirname "${BIN_DIR}")"
    else
      echo "[verify] ERROR: could not locate runtime root (no rf_runtime dir or bin/ found)" >&2
      exit 1
    fi
  fi
fi

echo "[verify] runtime root: ${RUNTIME_ROOT}"

# 4) Helper for checks
check_file() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    echo "ok ${path}"
    return 0
  else
    echo "MISS ${path}"
    return 1
  fi
}

check_dir() {
  local path="$1"
  if [[ -d "${path}" ]]; then
    echo "ok ${path}"
    return 0
  else
    echo "MISS ${path}"
    return 1
  fi
}

# 5) Structural checks
WRAP_BAD=0
X64_BAD=0
X86_BAD=0
WINE_BAD=0
VK_BAD=0

echo "==[ wrappers ]=="
for f in wine64.sh wine32on64.sh steam-win.sh; do
  check_file "${RUNTIME_ROOT}/bin/${f}" || WRAP_BAD=1
done

echo "==[ x86_64 sysroot ]=="
check_file "${RUNTIME_ROOT}/x86_64-linux/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" || X64_BAD=1
check_file "${RUNTIME_ROOT}/x86_64-linux/lib/x86_64-linux-gnu/libc.so.6"            || X64_BAD=1

echo "==[ i386 sysroot ]=="
check_file "${RUNTIME_ROOT}/i386-linux/lib/i386-linux-gnu/ld-linux.so.2" || X86_BAD=1
check_file "${RUNTIME_ROOT}/i386-linux/lib/i386-linux-gnu/libc.so.6"      || X86_BAD=1

echo "==[ wine trees ]=="
for d in wine64 wine32; do
  check_dir "${RUNTIME_ROOT}/${d}" || WINE_BAD=1
done

echo "==[ dxvk/vkd3d ]=="
for d in dxvk/x64 dxvk/x86 vkd3d/x64 vkd3d/x86; do
  check_dir "${RUNTIME_ROOT}/${d}" || VK_BAD=1
done

# 6) Result policy
STRICT="${RF_STRICT_WINE:-1}"  # default STRICT=1 for CI

if [[ "${WRAP_BAD}${X64_BAD}${X86_BAD}${WINE_BAD}${VK_BAD}" == "00000" ]]; then
  echo "[verify] OK"
  exit 0
fi

if [[ "${STRICT}" == "1" ]]; then
  echo "[verify] FAIL: missing components (see MISS lines); STRICT mode" >&2
  exit 1
else
  echo "[verify] WARN: missing components (see MISS lines); RF_STRICT_WINE!=1 so allowing" >&2
  exit 0
fi
