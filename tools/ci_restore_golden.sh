# ~/android/robotforest-wow64-runtime/tools/ci_restore_golden.sh
#!/usr/bin/env bash
set -euo pipefail
branch="ci/baseline-2025-11-07"
echo "[restore] checking out $branch files into working tree (no branch switch)"
git checkout "$branch" -- \
  .github/workflows/ci-guard.yml \
  .github/workflows/manual-release.yml \
  .github/workflows/release-core.yml \
  .github/workflows/smoke-runtime.yml \
  scripts/ci/pins.env \
  scripts/ci/fetch_components.sh \
  scripts/rf_pack_runtime.sh \
  scripts/rf_verify_runtime.sh \
  scripts/sandbot/rf-sandbot.sh
echo "[restore] done; review 'git status' then commit"
