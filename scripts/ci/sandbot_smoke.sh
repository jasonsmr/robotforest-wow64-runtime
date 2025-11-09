#!/usr/bin/env bash
set -euo pipefail

# Inputs
RUNTIME_DIR="${1:-dist/robotforest-wow64-runtime}"
WINE_TEST="${2:-notepad.exe}"

if [[ ! -d "$RUNTIME_DIR" ]]; then
  echo "Runtime dir not found: $RUNTIME_DIR" >&2
  exit 2
fi

# Proton layout sanity
test -d "$RUNTIME_DIR/proton" || { echo "missing proton/"; exit 3; }
test -d "$RUNTIME_DIR/dxvk"   || { echo "missing dxvk/";   exit 3; }
test -d "$RUNTIME_DIR/vkd3d"  || { echo "missing vkd3d/";  exit 3; }

# Show versions if present
[[ -f "$RUNTIME_DIR/proton/VERSION" ]] && cat "$RUNTIME_DIR/proton/VERSION" || true
[[ -f "$RUNTIME_DIR/dxvk/VERSION"   ]] && cat "$RUNTIME_DIR/dxvk/VERSION"   || true
[[ -f "$RUNTIME_DIR/vkd3d/VERSION"  ]] && cat "$RUNTIME_DIR/vkd3d/VERSION"  || true

# Minimal headless X + Wine run using Proton’s wine
export WINEDEBUG=-all
export WINEDLLOVERRIDES="dxgi,d3d11,d3d12=n"
export WINEPREFIX="$(pwd)/.sandbot_prefix"
mkdir -p "$WINEPREFIX"

# Prefer xvfb-run if available; otherwise run plainly (CI has it)
if command -v xvfb-run >/dev/null 2>&1; then
  XCMD=(xvfb-run -a -s "-screen 0 800x600x24")
else
  XCMD=()
fi

# Proton’s wine shim path (adjust if your packer places wine elsewhere)
WINE_BIN="$(/usr/bin/env bash -lc "ls -1 $RUNTIME_DIR/proton/*/dist/bin/wine 2>/dev/null | head -n1")"
if [[ -z "${WINE_BIN:-}" || ! -x "$WINE_BIN" ]]; then
  echo "Could not locate proton wine under proton/*/dist/bin/wine" >&2
  exit 4
fi

echo "[sandbot] Running wine --version ..."
"${XCMD[@]}" "$WINE_BIN" --version

echo "[sandbot] Running a trivial Wine app ..."
"${XCMD[@]}" "$WINE_BIN" "$WINE_TEST" || true

echo "[sandbot] OK"
