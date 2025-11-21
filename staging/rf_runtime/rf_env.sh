# rf_env.sh - RobotForest runtime environment
#
# Usage:
#   . /path/to/rf_env.sh
#
# This script is self-rooting and host-agnostic:
# - Detects RF_RUNTIME_ROOT from its own location if not already set
# - Sets RF_PREFIX and WINEPREFIX under that root
# - Wires DXVK/vkd3d-proton overrides
# - Adds runtime bin paths (box64, box86, steam-win.sh, wine wrappers)

# If RF_RUNTIME_ROOT is already set, trust it; otherwise derive from this file
if [ -n "${RF_RUNTIME_ROOT:-}" ]; then
  :
else
  # BASH_SOURCE for bash, fallback to $0 for POSIX shells / zsh
  _rf_src="${BASH_SOURCE[0]:-$0}"
  RF_RUNTIME_ROOT="$(cd "$(dirname "$_rf_src")" && pwd)"
fi
export RF_RUNTIME_ROOT

# Prefix (Wine prefix) under the runtime root
RF_PREFIX="${RF_PREFIX:-"$RF_RUNTIME_ROOT/prefix"}"
export RF_PREFIX

# Default Wine prefix is RF_PREFIX
WINEPREFIX="${WINEPREFIX:-"$RF_PREFIX"}"
export WINEPREFIX

# Prefer native DXVK / vkd3d-proton over builtin d3d* & dxgi
export WINEDLLOVERRIDES="d3d9,dxgi,d3d10core,d3d11,d3d12,d3d12core=n,b"

# Point DXVK to its config (optional)
export DXVK_CONFIG_FILE="$RF_PREFIX/dxvk.conf"

# Keep HUD quiet unless debugging; flip to "1" if needed
export DXVK_HUD="${DXVK_HUD:-0}"

# Build PATH segments for runtime binaries
_rf_path_extra=""

# Wine bins (may be empty stubs today; that's OK)
if [ -d "$RF_RUNTIME_ROOT/wine64/bin" ]; then
  _rf_path_extra="$RF_RUNTIME_ROOT/wine64/bin:$_rf_path_extra"
fi

if [ -d "$RF_RUNTIME_ROOT/wine32/bin" ]; then
  _rf_path_extra="$RF_RUNTIME_ROOT/wine32/bin:$_rf_path_extra"
fi

# Core runtime bin helpers (box64, box86, steam-win.sh, wrappers, etc.)
if [ -d "$RF_RUNTIME_ROOT/bin" ]; then
  _rf_path_extra="$RF_RUNTIME_ROOT/bin:$_rf_path_extra"
fi

# Prepend runtime paths if any
if [ -n "$_rf_path_extra" ]; then
  if [ -n "${PATH:-}" ]; then
    export PATH="$_rf_path_extra$PATH"
  else
    export PATH="$_rf_path_extra"
  fi
fi

unset _rf_src _rf_path_extra
