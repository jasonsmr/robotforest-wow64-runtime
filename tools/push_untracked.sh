#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"

# Show deltas
git status -uno
git ls-files --others --exclude-standard

# Add tracked areas you’ve approved in CODEOWNERS
git add .github/workflows/*.yml scripts/** tools/** staging/** dist/** || true

# Add any truly new files interactively (safer)
echo
echo "Add untracked? (y/N)"
read -r ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  git add -N .
  git add $(git ls-files --others --exclude-standard) || true
fi

git commit -m "sync: bring local changes into repo (tools/push_untracked.sh)" || echo "Nothing to commit."
git push
