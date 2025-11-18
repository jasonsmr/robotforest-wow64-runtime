#!/usr/bin/env bash
set -euo pipefail

MODE="${SANDBOT_MODE:-A}"

log() {
  printf '[sandbot] %s\n' "$*" >&2
}

warn() {
  printf '[sandbot][WARN] %s\n' "$*" >&2
}

die() {
  printf '[sandbot][ERROR] %s\n' "$*" >&2
  exit 1
}

# --- Resolve RF_RUNTIME_ROOT -------------------------------------------------

if [[ -z "${RF_RUNTIME_ROOT:-}" ]]; then
  die "RF_RUNTIME_ROOT is not set"
fi

RT="$(cd "${RF_RUNTIME_ROOT}" 2>/dev/null && pwd || true)"
if [[ -z "${RT}" || ! -d "${RT}" ]]; then
  die "RF_RUNTIME_ROOT does not point to a directory: ${RF_RUNTIME_ROOT}"
fi

log "RF_RUNTIME_ROOT: ${RF_RUNTIME_ROOT}"
log "normalized RF_RUNTIME_ROOT: ${RT}"

# --- Mode A: structural checks (always run) ----------------------------------

log "=== required files ==="
REQUIRED_FILES=(
  "bin/wine64.sh"
  "bin/wine32on64.sh"
  "bin/steam-win.sh"
  "x86_64-linux/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
  "x86_64-linux/lib/x86_64-linux-gnu/libc.so.6"
  "i386-linux/lib/i386-linux-gnu/ld-linux.so.2"
  "i386-linux/lib/i386-linux-gnu/libc.so.6"
)

for rel in "${REQUIRED_FILES[@]}"; do
  path="${RT}/${rel}"
  if [[ -f "${path}" ]]; then
    log "ok   ${path}"
  else
    die "MISS ${path}"
  fi
done

log "=== required dirs ==="
REQUIRED_DIRS=(
  "wine64"
  "wine32"
  "dxvk/x64"
  "dxvk/x86"
  "vkd3d/x64"
  "vkd3d/x86"
)

for rel in "${REQUIRED_DIRS[@]}"; do
  path="${RT}/${rel}"
  if [[ -d "${path}" ]]; then
    log "ok   ${path}"
  else
    die "MISS ${path}"
  fi
done

# If Mode A only, we stop here (CI uses this path)
if [[ "${MODE}" == "A" ]]; then
  log "OK: structural runtime smoke (Mode A) passed."
  exit 0
fi

# --- Mode B: light functional check (local-only) -----------------------------

log "Mode B requested (SANDBOT_MODE=${MODE})"

# Heuristic: skip Mode B on GitHub runners
if [[ -n "${CI:-}" ]]; then
  log "CI environment detected (CI=${CI}); skipping Mode B functional checks."
  log "OK: structural runtime smoke (Mode A) passed (Mode B skipped on CI)."
  exit 0
fi

# Also skip Mode B on non-Termux hosts, just to be safe
case "${HOME:-}" in
  /data/data/com.termux/*) : ;; # Termux – OK
  *)
    log "Non-Termux HOME detected (${HOME}); skipping Mode B functional checks."
    log "OK: structural runtime smoke (Mode A) passed (Mode B skipped)."
    exit 0
    ;;
esac

log "=== Mode B: local functional sanity ==="

W64="${RT}/bin/wine64.sh"
W32="${RT}/bin/wine32on64.sh"
STEAM_WIN="${RT}/bin/steam-win.sh"

# 1) Ensure wrappers are executable
for f in "${W64}" "${W32}" "${STEAM_WIN}"; do
  if [[ ! -x "${f}" ]]; then
    die "wrapper not executable: ${f}"
  fi
  log "exec-ok ${f}"
done

soft_run() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    log "${label} OK"
  else
    if [[ "${SANDBOT_STRICT_FUN:-0}" == "1" ]]; then
      die "${label} FAILED (strict functional mode)"
    else
      warn "${label} failed (non-strict functional mode); continuing."
    fi
  fi
}

# 2) Very light version checks; by default they WARN on failure
soft_run "wine64.sh --version" "${W64}" --version
soft_run "wine32on64.sh --version" "${W32}" --version

# Optional for later:
# soft_run "steam-win.sh --help" "${STEAM_WIN}" --help

log "OK: Mode B functional runtime smoke completed (non-strict)."
