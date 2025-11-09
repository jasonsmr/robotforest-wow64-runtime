#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"
mapfile -t FILES <<'LIST'
.editorconfig
.github/CODEOWNERS
.github/workflows/ci-guard.yml
.github/workflows/manual-release.yml
.github/workflows/release-core.yml
.github/workflows/rf-release-full.yml
.github/workflows/smoke-runtime.yml
scripts/ci/fetch_components.sh
scripts/ci/pins.env
scripts/ci/sandbot_smoke.sh
scripts/rf_pack_runtime.sh
scripts/rf_verify_runtime.sh
scripts/sandbot/rf-sandbot.sh
tools/await_release.sh
tools/cut_release.sh
tools/dispatch_tag_build.sh
tools/whoami.sh
LIST
mkdir -p .golden
> .golden/files.sha256
for f in "${FILES[@]}"; do
  test -f "$f" || continue
  sha256sum "$f" >> .golden/files.sha256
done
