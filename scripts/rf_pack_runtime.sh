#!/usr/bin/env bash
set -euo pipefail

: "${TMP:=${HOME}/tmp}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING="${ROOT}/staging"
DIST="${ROOT}/dist"
mkdir -p "$DIST" "$TMP"

RF_TAG="${RF_TAG:-${GITHUB_REF_NAME:-dev}}"

# Unpack & assemble minimal tree in ${STAGING}/rootfs (idempotent)
ROOTFS="${STAGING}/rootfs"
mkdir -p "${ROOTFS}"

# Proton payload
if [[ -f "${STAGING}/proton.tar.gz" ]]; then
  mkdir -p "${ROOTFS}/proton"
  tar -xzf "${STAGING}/proton.tar.gz" -C "${ROOTFS}/proton" --strip-components=0
fi

# DXVK payload
if [[ -f "${STAGING}/dxvk.tar.gz" ]]; then
  mkdir -p "${ROOTFS}/dxvk"
  tar -xzf "${STAGING}/dxvk.tar.gz" -C "${ROOTFS}/dxvk" --strip-components=0
fi

# vkd3d-proton payload
if [[ -f "${STAGING}/vkd3d.tar.zst" ]]; then
  mkdir -p "${ROOTFS}/vkd3d"
  tar --zstd -xf "${STAGING}/vkd3d.tar.zst" -C "${ROOTFS}/vkd3d" --strip-components=0
fi

# Inject launcher scaffolding (placeholder; extend later)
mkdir -p "${ROOTFS}/bin"
cat > "${ROOTFS}/bin/rf-runtime-env" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Export minimal runtime env; extend for WOW64/steam later
export RF_RUNTIME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "RF_RUNTIME_DIR=${RF_RUNTIME_DIR}"
EOF
chmod +x "${ROOTFS}/bin/rf-runtime-env"

# Zip
OUT="${DIST}/robotforest-wow64-runtime-${RF_TAG}.zip"
( cd "${ROOTFS}/.." && zip -r -9 "${OUT}" "$(basename "${ROOTFS}")" )
sha256sum "${OUT}" | awk '{print $1}' > "${OUT}.sha256"

echo "Packed:"
ls -lh "${OUT}"*
