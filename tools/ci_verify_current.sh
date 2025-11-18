# ~/android/robotforest-wow64-runtime/tools/ci_verify_current.sh
#!/usr/bin/env bash
set -euo pipefail
echo "[ci-verify] showing workflow status & pins"
sed -n '1,200p' .github/workflows/manual-release.yml
sed -n '1,200p' .github/workflows/release-core.yml
sed -n '1,200p' .github/workflows/smoke-runtime.yml || true
echo
echo "[pins]"
cat scripts/ci/pins.env
