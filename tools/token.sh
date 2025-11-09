#!/usr/bin/env bash
set -euo pipefail
CONF="$HOME/.config/rf/github_token"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  printf '%s' "$GITHUB_TOKEN"
  exit 0
fi
if [ -f "$CONF" ]; then
  # print exactly, no trailing newline
  tr -d '\r\n' < "$CONF"
  exit 0
fi
exit 1
