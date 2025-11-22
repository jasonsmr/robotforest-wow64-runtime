#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------
# RobotForest local Path A builder (Proton/WoW64 from CI-friendly bits)
#
# Goal:
#   - Run a reproducible "Path A" build locally on Termux,
#     using the existing rf_runtime staging layout.
#   - Log everything to /sdcard/Download/BUILD/runtime/....
#
# This script is SAFE to run repeatedly; it only touches:
#   - ./staging/rf_runtime
#   - ./scripts/*
#   - /sdcard/Download/BUILD/runtime/*.log  (logs only)
#
# It does *not* try to execute box64/Wine inside Android – SELinux
# will block that from an APK anyway. The APK is used as an installer
# + layout verifier.
# --------------------------------------------------------------------

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_STAGE="$ROOT/staging/rf_runtime"

# Where you want persistent logs visible in Android:
LOG_ROOT="/sdcard/Download/BUILD/runtime"
mkdir -p "$LOG_ROOT"

ts="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_ROOT/rf_pathA_build_${ts}.log"

echo "[rf-local-pathA] ROOT=$ROOT"
echo "[rf-local-pathA] RUNTIME_STAGE=$RUNTIME_STAGE"
echo "[rf-local-pathA] LOG_FILE=$LOG_FILE"
echo

# Tee stdout+stderr to the log file
exec > >(tee "$LOG_FILE") 2>&1

echo "[rf-local-pathA] ===== BEGIN PATH A BUILD ====="

# --------------------------------------------------------------------
# 0) Sanity: show current staging layout
# --------------------------------------------------------------------
if [ -d "$RUNTIME_STAGE" ]; then
  echo "[rf-local-pathA] Existing rf_runtime staging tree:"
  (cd "$RUNTIME_STAGE" && ls -1)
else
  echo "[rf-local-pathA] No rf_runtime staging tree yet; will be created."
fi
echo

# --------------------------------------------------------------------
# 1) Prepare sysroots / base components (if scripts exist)
# --------------------------------------------------------------------
if [ -x "$ROOT/scripts/02_prep_sysroots.sh" ]; then
  echo "[rf-local-pathA] Running 02_prep_sysroots.sh ..."
  "$ROOT/scripts/02_prep_sysroots.sh"
  echo
else
  echo "[rf-local-pathA] SKIP: scripts/02_prep_sysroots.sh not found or not executable."
  echo "                 (OK for now if CI handled sysroots in previous runs.)"
  echo
fi

# --------------------------------------------------------------------
# 2) Fetch Wine/DXVK/VKD3D / Proton bits
#    This is where Path A will eventually:
#      - download Proton-GE or pinned Proton build
#      - fetch DXVK/VKD3D according to scripts/ci/pins.env
# --------------------------------------------------------------------
if [ -x "$ROOT/scripts/03_fetch_wine_dxvk_vkd3d.sh" ]; then
  echo "[rf-local-pathA] Running 03_fetch_wine_dxvk_vkd3d.sh ..."
  "$ROOT/scripts/03_fetch_wine_dxvk_vkd3d.sh"
  echo
else
  echo "[rf-local-pathA] SKIP: scripts/03_fetch_wine_dxvk_vkd3d.sh not found."
  echo "                 (You can wire Proton/DXVK fetch here later.)"
  echo
fi

# Optional: if/when you want to stage from a Proton dist tarball locally,
# you can add a PROTON_TARBALL and call scripts/ci/stage_wine_from_proton.sh:
#
#   PROTON_TARBALL=${PROTON_TARBALL:-/sdcard/Download/BUILD/proton/Proton-GE-custom.tar.gz}
#   if [ -x "$ROOT/scripts/ci/stage_wine_from_proton.sh" ]; then
#       echo "[rf-local-pathA] Staging Wine from Proton tarball: $PROTON_TARBALL"
#       PROTON_TARBALL="$PROTON_TARBALL" \
#         "$ROOT/scripts/ci/stage_wine_from_proton.sh"
#   fi
#
# For now we keep that as a TODO hook.

# --------------------------------------------------------------------
# 3) Wire prefix / WoW64 plumbing helpers if available
# --------------------------------------------------------------------
if [ -x "$ROOT/scripts/04_wire_prefix.sh" ]; then
  echo "[rf-local-pathA] Running 04_wire_prefix.sh ..."
  "$ROOT/scripts/04_wire_prefix.sh"
  echo
else
  echo "[rf-local-pathA] SKIP: scripts/04_wire_prefix.sh not found."
  echo
fi

if [ -x "$ROOT/scripts/06_wow64_prefix_init.sh" ]; then
  echo "[rf-local-pathA] Running 06_wow64_prefix_init.sh ..."
  "$ROOT/scripts/06_wow64_prefix_init.sh"
  echo
else
  echo "[rf-local-pathA] SKIP: scripts/06_wow64_prefix_init.sh not found."
  echo
fi

# --------------------------------------------------------------------
# 4) Assemble runtime tree into staging/rf_runtime
# --------------------------------------------------------------------
if [ -x "$ROOT/scripts/11_assemble_runtime_tree.sh" ]; then
  echo "[rf-local-pathA] Running 11_assemble_runtime_tree.sh ..."
  "$ROOT/scripts/11_assemble_runtime_tree.sh"
  echo
else
  echo "[rf-local-pathA] SKIP: scripts/11_assemble_runtime_tree.sh not found."
  echo "                 (No runtime tree assembly; rf_runtime may be stale.)"
  echo
fi

# --------------------------------------------------------------------
# 5) Quick layout check
# --------------------------------------------------------------------
if [ -x "$RUNTIME_STAGE/rf_runtime_layout_check.sh" ]; then
  echo "[rf-local-pathA] Running rf_runtime_layout_check.sh on staging tree ..."
  "$RUNTIME_STAGE/rf_runtime_layout_check.sh"
  echo
else
  echo "[rf-local-pathA] SKIP: rf_runtime_layout_check.sh not present in staging."
  echo
fi

# --------------------------------------------------------------------
# 6) Pack runtime as rf-runtime-dev.tar.zst for the APK repo
# --------------------------------------------------------------------
OUT_TAR="$ROOT/scripts/runtime/rf-runtime-dev.tar.zst"
mkdir -p "$ROOT/scripts/runtime"

if [ -x "$ROOT/scripts/rf_pack_runtime.sh" ]; then
  echo "[rf-local-pathA] Packing runtime → $OUT_TAR ..."
  RF_RUNTIME_STAGE="$RUNTIME_STAGE" \
  RF_RUNTIME_OUT="$OUT_TAR" \
    "$ROOT/scripts/rf_pack_runtime.sh"
  echo "[rf-local-pathA] Packed: $OUT_TAR"
  echo
else
  echo "[rf-local-pathA] SKIP: scripts/rf_pack_runtime.sh not found."
  echo "                 (You will still have staging/rf_runtime but no tarball.)"
  echo
fi

echo "[rf-local-pathA] ===== DONE PATH A BUILD ====="
echo "[rf-local-pathA] Log file: $LOG_FILE"
