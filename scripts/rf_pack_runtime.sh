# ~/android/robotforest-wow64-runtime/scripts/rf_pack_runtime.sh
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/ci/pins.env"

TAG="${RF_TAG:-${DEFAULT_TAG}}"

OUT="$ROOT/dist/robotforest-wow64-runtime-${TAG}"
ZIP="$ROOT/dist/robotforest-wow64-runtime-${TAG}.zip"

rm -rf "$OUT"
mkdir -p "$OUT" "$ROOT/dist" "$OUT/runtime" "$OUT/tools" "$OUT/scripts" "$OUT/sandbot"

echo "[pack] Unpack Proton-GE"
tar -xf "$ROOT/staging/proton.tar.gz" -C "$OUT/runtime"
# Proton unpack name varies; normalize symlink 'proton'
PROTON_DIR="$(find "$OUT/runtime" -maxdepth 1 -type d -name "Proton-*")"
ln -s "$(basename "$PROTON_DIR")" "$OUT/runtime/proton"

echo "[pack] Unpack DXVK"
tar -xf "$ROOT/staging/dxvk.tar.gz" -C "$OUT/runtime"
DXVK_DIR="$(find "$OUT/runtime" -maxdepth 1 -type d -name "dxvk-*")"

echo "[pack] Unpack vkd3d-proton"
unzstd -c "$ROOT/staging/vkd3d.tar.zst" | tar -xf - -C "$OUT/runtime"
VKD3D_DIR="$(find "$OUT/runtime" -maxdepth 1 -type d -name "vkd3d-proton-*")"

echo "[pack] Copy sandbot + helpers"
install -Dm755 "$ROOT/scripts/sandbot/rf-sandbot.sh" "$OUT/sandbot/rf-sandbot.sh"
install -Dm755 "$ROOT/scripts/rf_verify_runtime.sh" "$OUT/scripts/rf_verify_runtime.sh"

echo "[pack] Write VERSION"
echo "$TAG" > "$OUT/VERSION"

echo "[pack] zip"
(cd "$OUT/.." && zip -qr9 "$ZIP" "$(basename "$OUT")")
sha256sum "$ZIP" | tee "${ZIP}.sha256"

echo "[pack] done: $ZIP"
