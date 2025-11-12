#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
# Usage:
#   rf_verify_runtime.sh [runtime_dir|archive] [optional_sha256_file]

INPUT="${1:-$PWD/staging/rf_runtime}"
SHA_FILE="${2:-}"

workdir=""
cleanup() { [[ -n "${workdir:-}" && -d "$workdir" ]] && rm -rf "$workdir"; }
trap cleanup EXIT

is_zip=0; is_zst=0
if [[ -f "$INPUT" ]]; then
  case "$INPUT" in
    *.zip) is_zip=1 ;;
    *.tar.zst|*.tzst) is_zst=1 ;;
  esac
fi

if [[ -n "${SHA_FILE:-}" && -f "$SHA_FILE" ]]; then
  echo "[verify] checking sha256: $SHA_FILE"
  file_base="$(basename "$INPUT")"
  if grep -q "$file_base" "$SHA_FILE"; then
    sha256sum -c "$SHA_FILE"
  else
    echo "$(cat "$SHA_FILE")  $INPUT" | sha256sum -c -
  fi
fi

if (( is_zip || is_zst )); then
  workdir="$(mktemp -d)"
  echo "[verify] extracting archive into: $workdir"
  if (( is_zip )); then
    unzip -q "$INPUT" -d "$workdir"
  else
    tar --use-compress-program="zstd -d" -C "$workdir" -xf "$INPUT"
  fi
  if   [[ -d "$workdir/runtime"    ]]; then R="$workdir/runtime"
  elif [[ -d "$workdir/rf_runtime" ]]; then R="$workdir/rf_runtime"
  else R="$(find "$workdir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  fi
  [[ -d "$R" ]] || { echo "FATAL: no runtime directory inside archive"; exit 2; }
else
  R="$INPUT"
fi

echo "[verify] runtime root: $R"

req_bins=( "$R/bin/wine64.sh" "$R/bin/wine32on64.sh" "$R/bin/steam-win.sh" )
x64_need=( "ld-linux-x86-64.so.2" "libc.so.6" )
x86_need=( "ld-linux.so.2" "libc.so.6" )

echo "==[ wrappers ]=="
for f in "${req_bins[@]}"; do [[ -x "$f" ]] && echo "ok  $f" || echo "MISS $f"; done

have_x64=0
echo "==[ x86_64 sysroot ]=="
for name in "${x64_need[@]}"; do
  hit="$( (find "$R/x86_64-linux" -maxdepth 3 -type f -name "$name" 2>/dev/null || true) | head -n1 )"
  if [[ -n "$hit" ]]; then echo "ok  $hit"; ((have_x64++))||true; else echo "MISS $R/x86_64-linux/**/$name"; fi
done

have_x86=0
echo "==[ i386 sysroot ]=="
for name in "${x86_need[@]}"; do
  hit="$( (find "$R/i386-linux" -maxdepth 3 -type f -name "$name" 2>/dev/null || true) | head -n1 )"
  if [[ -n "$hit" ]]; then echo "ok  $hit"; ((have_x86++))||true; else echo "MISS $R/i386-linux/**/$name"; fi
done

echo "==[ wine trees ]=="
for d in "$R/wine64" "$R/wine32"; do
  if [[ -d "$d" ]]; then echo "ok  $d"; find "$d" -maxdepth 1 -type f | sed 's/^/  - /' | head
  else echo "MISS $d"; fi
done

echo "==[ dxvk/vkd3d ]=="
for d in "$R/dxvk/x64" "$R/dxvk/x86" "$R/vkd3d/x64" "$R/vkd3d/x86"; do
  [[ -d "$d" ]] && echo "ok  $d" || echo "MISS $d"
done

ex=0
[[ $have_x64 -lt 2 ]] && ex=1
[[ $have_x86 -lt 2 ]] && ex=1
exit $ex
