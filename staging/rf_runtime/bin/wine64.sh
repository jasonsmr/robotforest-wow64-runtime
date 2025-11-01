#!/system/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/.."; pwd)"
BIN="$ROOT/bin"

export BOX64_LOG=${BOX64_LOG:-0}
export BOX64_PATH="$ROOT/wine64:$ROOT/steam:$ROOT/x86_64-linux/bin:$ROOT/x86_64-linux/usr/bin"
export BOX64_LD_LIBRARY_PATH="$ROOT/x86_64-linux/lib:$ROOT/x86_64-linux/lib64:$ROOT/x86_64-linux/usr/lib:$ROOT/x86_64-linux/usr/lib64:$ROOT/wine64"

export WINEPREFIX="${WINEPREFIX:-$ROOT/prefixes/default}"
export WINEDEBUG="${WINEDEBUG:-fixme-all,err+all}"
export WINEDLLPATH="$ROOT/wine64:$ROOT/wine32"
export DXVK_LOG_PATH="$WINEPREFIX/dxvk-logs"

exec "$BIN/box64" "$ROOT/wine64/wine64" "$@"
