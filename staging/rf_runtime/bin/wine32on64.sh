#!/system/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/.."; pwd)"
BIN="$ROOT/bin"
export BOX86_LOG=${BOX86_LOG:-0}
export BOX86_LD_LIBRARY_PATH="$ROOT/i386-linux/lib:$ROOT/i386-linux/usr/lib:$ROOT/wine32"
exec "$BIN/box86" "$ROOT/wine32/wine" "$@"
