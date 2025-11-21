#!/usr/bin/env bash
set -euo pipefail

# rf-wine-build-host.sh
# ----------------------
# Host-side (x86_64 Linux) script to build or stage a RobotForest Wine/Proton runtime.
# Designed for CI (e.g. GitHub Actions ubuntu-latest).
#
# STAGE 0: layout + stub binaries only.
#   - No real Wine build yet.
#   - Produces rf-runtime-dev.tar.zst with correct directory layout.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Source trees (override via env if needed)
WINE_SRC="${WINE_SRC:-"$SCRIPT_DIR/wine-9.0-rf"}"
PROTON_SRC="${PROTON_SRC:-"$SCRIPT_DIR/proton-ge-rf"}"

# Staging root for runtime tree (mirrors ~/.local/share/robotforest/runtime on Android)
OUT_ROOT="${OUT_ROOT:-"$SCRIPT_DIR/rf_runtime_host"}"

echo "[rf/host] Using:"
echo "  WINE_SRC   = $WINE_SRC"
echo "  PROTON_SRC = $PROTON_SRC"
echo "  OUT_ROOT   = $OUT_ROOT"
echo

# Basic validation
if [ ! -d "$WINE_SRC" ]; then
  echo "[rf/host] ERROR: Wine source not found at $WINE_SRC"
  exit 1
fi

if [ ! -d "$PROTON_SRC" ]; then
  echo "[rf/host] ERROR: Proton-GE source not found at $PROTON_SRC"
  exit 1
fi

# Clean staging directory
rm -rf "$OUT_ROOT"
mkdir -p "$OUT_ROOT"
echo "[rf/host] Created staging runtime: $OUT_ROOT"
echo

# Create runtime layout skeleton
for d in bin dxvk vkd3d wine32 wine64 prefix proton x86_64-linux i386-linux; do
  mkdir -p "$OUT_ROOT/$d"
done

# Placeholders: wine32/wine64 READMEs
cat > "$OUT_ROOT/wine32/README.rf-empty" <<'EOF_W32'
RobotForest runtime: wine32 placeholder (host build)
----------------------------------------------------

This directory will contain 32-bit WoW64 Wine binaries and DLLs
built on an x86_64 Linux host and shipped to Android.
EOF_W32

cat > "$OUT_ROOT/wine64/README.rf-empty" <<'EOF_W64'
RobotForest runtime: wine64 placeholder (host build)
----------------------------------------------------

This directory will contain 64-bit Wine binaries and DLLs
built on an x86_64 Linux host and shipped to Android.
EOF_W64

# Proton staging README
cat > "$OUT_ROOT/proton/README.rf" <<'EOF_P'
RobotForest Proton area (host build)
====================================

Expected layout:
  proton/Proton-rf-*/proton
  proton/Proton-rf-*/dist/

In a future stage, this script will:
  - build Proton (or a lean Wine+DXVK+vkd3d stack),
  - populate a Proton-rf-* directory under this folder,
  - and wire it up to rf_env.sh on the Android side.
EOF_P

# STUB binaries so Android wrappers have something executable to hit.
mkdir -p "$OUT_ROOT/wine64/bin" "$OUT_ROOT/wine32/bin"

cat > "$OUT_ROOT/wine64/bin/wine64" <<'EOF_FAKE64'
#!/usr/bin/env bash
echo "[rf/host] STUB wine64: this is not a real Wine build."
echo "[rf/host] Once CI builds Wine, this binary will be replaced."
exit 1
EOF_FAKE64
chmod +x "$OUT_ROOT/wine64/bin/wine64"

cat > "$OUT_ROOT/wine32/bin/wine" <<'EOF_FAKE32'
#!/usr/bin/env bash
echo "[rf/host] STUB wine32: this is not a real Wine build."
echo "[rf/host] Once CI builds WoW64 Wine, this binary will be replaced."
exit 1
EOF_FAKE32
chmod +x "$OUT_ROOT/wine32/bin/wine"

# Copy dxvk / vkd3d trees from Proton if present (placeholder for now)
if [ -d "$PROTON_SRC/dxvk" ]; then
  echo "[rf/host] Copying Proton dxvk tree..."
  rsync -a --delete "$PROTON_SRC/dxvk/" "$OUT_ROOT/dxvk/" || true
fi

if [ -d "$PROTON_SRC/vkd3d-proton" ]; then
  echo "[rf/host] Copying Proton vkd3d-proton tree..."
  rsync -a --delete "$PROTON_SRC/vkd3d-proton/" "$OUT_ROOT/vkd3d/" || true
fi

echo
echo "[rf/host] Staging tree created (dirs up to depth 3):"
find "$OUT_ROOT" -maxdepth 3 -type d | sed "s|^$OUT_ROOT|runtime|"

# Pack into tar.zst — this is what rf-runtime-get on Android expects.
cd "$SCRIPT_DIR"
ARCHIVE="${ARCHIVE:-"rf-runtime-dev.tar.zst"}"
echo
echo "[rf/host] Creating archive $ARCHIVE ..."
tar -C "$OUT_ROOT" -cf - . | zstd -T0 -19 -o "$ARCHIVE"

echo "[rf/host] Done."
echo "[rf/host] Archive at: $SCRIPT_DIR/$ARCHIVE"
