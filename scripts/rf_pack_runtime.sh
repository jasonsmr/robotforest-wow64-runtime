cd ~/android/robotforest-wow64-runtime

cat > scripts/rf_pack_runtime.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# rf_pack_runtime.sh
# Pack the committed rf_runtime tree (built on Termux) into reproducible tar.zst + zip
# Outputs:
#   dist/rf-runtime-dev.tar.zst(.sha256)
#   dist/rf-runtime-dev.zip(.sha256)

set -euo pipefail

REPO="$(CDPATH= cd -- "$(dirname -- "$0")"/.. && pwd)"
STAGE="${REPO}/staging"
ROOT="${STAGE}/rf_runtime"
DIST="${REPO}/dist"

mkdir -p "${DIST}"

if [[ ! -d "${ROOT}" ]]; then
  echo "[pack] ERROR: rf_runtime tree missing at: ${ROOT}" >&2
  exit 1
fi

echo "[pack] rf_runtime root: ${ROOT}"

# Rebuild MANIFEST.SHA256 deterministically
MANIFEST="${STAGE}/MANIFEST.SHA256"
echo "[pack] Writing MANIFEST.SHA256"
(
  cd "${ROOT}"
  LC_ALL=C find . -type f -print0 | sort -z | xargs -0 sha256sum
) > "${MANIFEST}"

# Fixed, boring output names (branch-independent)
BASE="rf-runtime-dev"
TAR="${DIST}/${BASE}.tar.zst"
ZIP="${DIST}/${BASE}.zip"

echo "[pack] Creating ${TAR}"
(
  cd "${STAGE}"
  tar --sort=name \
      --mtime='UTC 2020-01-01' \
      --owner=0 --group=0 --numeric-owner \
      -I 'zstd -19 --long=31' \
      -cf "${TAR}" \
      MANIFEST.SHA256 \
      rf_runtime
)

echo "[pack] Creating ${TAR}.sha256"
(
  cd "${DIST}"
  sha256sum "$(basename "${TAR}")" > "${TAR}.sha256"
)

echo "[pack] Creating ${ZIP}"
(
  cd "${STAGE}"
  # zip doesn't have the same nice determinism knobs, but that's OK for now
  zip -rq "${ZIP}" MANIFEST.SHA256 rf_runtime
)

echo "[pack] Creating ${ZIP}.sha256"
(
  cd "${DIST}"
  sha256sum "$(basename "${ZIP}")" > "${ZIP}.sha256"
)

echo "[pack] [ok] built:"
ls -lh "${TAR}" "${TAR}.sha256" "${ZIP}" "${ZIP}.sha256"
EOF

chmod +x scripts/rf_pack_runtime.sh
