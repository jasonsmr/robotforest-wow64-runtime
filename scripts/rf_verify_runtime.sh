# ~/android/robotforest-wow64-runtime/scripts/rf_verify_runtime.sh
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { echo "VERIFY: $*" >&2; exit 1; }

[[ -f "$ROOT/VERSION" ]] || fail "VERSION missing"
[[ -d "$ROOT/runtime/proton" ]] || fail "runtime/proton missing"
[[ -x "$ROOT/sandbot/rf-sandbot.sh" ]] || fail "sandbot/rf-sandbot.sh missing/executable"

DXVK_OK="$(find "$ROOT/runtime" -maxdepth 1 -type d -name "dxvk-* | head -n1")"
[[ -n "$DXVK_OK" ]] || fail "dxvk dir missing"

VKD3D_OK="$(find "$ROOT/runtime" -maxdepth 1 -type d -name "vkd3d-proton-* | head -n1")"
[[ -n "$VKD3D_OK" ]] || fail "vkd3d-proton dir missing"

echo "VERIFY: OK"
