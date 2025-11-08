#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING="$ROOT/staging"
DIST="$ROOT/dist"
TAG="${RF_TAG:-${GITHUB_REF_NAME:-dev}}"

mkdir -p "$DIST" "$ROOT/runtime"

# Extract staged components
work="$ROOT/.work"
rm -rf "$work"; mkdir -p "$work"

echo "[extract] Proton"
tar -C "$work" -xf "$STAGING/proton.tar.gz"
PROTON_DIR="$(find "$work" -maxdepth 1 -type d -name 'Proton-*' | head -n1)"

echo "[extract] DXVK"
tar -C "$work" -xf "$STAGING/dxvk.tar.gz"

echo "[extract] VKD3D"
tar -C "$work" --use-compress-program=unzstd -xf "$STAGING/vkd3d.tar.zst"

# Runtime layout
RUNTIME="$ROOT/runtime/robotforest-wow64-runtime"
rm -rf "$RUNTIME"; mkdir -p "$RUNTIME"

# Copy Proton (as core)
cp -a "$PROTON_DIR" "$RUNTIME/proton"

# Minimal DXVK + VKD3D drop-ins (keep it simple; full mapping can be added later)
mkdir -p "$RUNTIME/overrides/dxvk" "$RUNTIME/overrides/vkd3d"
cp -a "$work"/dxvk-*/* "$RUNTIME/overrides/dxvk/"
cp -a "$work"/vkd3d-proton-*/* "$RUNTIME/overrides/vkd3d/"

# Sandbot launcher (portable)
install -Dm755 "$ROOT/scripts/sandbot/rf-sandbot.sh" "$RUNTIME/bin/rf-sandbot"

# Version manifest
cat > "$RUNTIME/VERSION.txt" <<EOF
RobotForest WOW64 Runtime
Tag: ${TAG}
Proton: $(basename "$PROTON_DIR")
DXVK: $(basename "$(<"$STAGING/dxvk.tar.gz" tar -tzf - 2>/dev/null | head -n1)" 2>/dev/null || echo "$(<"$STAGING/dxvk.tar.gz" tar -tzf - 2>/dev/null | head -n1)")
VKD3D: $(basename "$(<"$STAGING/vkd3d.tar.zst" tar -tI zstd -f - 2>/dev/null | head -n1)" 2>/dev/null || true)
Built: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

# Zip it
OUT_ZIP="$DIST/robotforest-wow64-runtime-${TAG}.zip"
rm -f "$OUT_ZIP" "$OUT_ZIP.sha256"
( cd "$ROOT/runtime" && zip -r9 "$OUT_ZIP" "robotforest-wow64-runtime" )
sha256sum "$OUT_ZIP" | tee "$OUT_ZIP.sha256"

echo "[packed] $OUT_ZIP"
