#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
AMD64="$STAGE/x86_64-linux"
I386="$STAGE/i386-linux"

pass=1

say() { printf '%s\n' "$*"; }
need_file() { if [[ ! -f "$1" ]]; then say "[FAIL] missing: $1"; pass=0; fi; }

# --- 1) ELF interpreters present & linked correctly ---
need_file "$AMD64/lib64/ld-linux-x86-64.so.2"
need_file "$AMD64/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
need_file "$I386/lib/ld-linux.so.2"
need_file "$I386/lib/i386-linux-gnu/ld-linux.so.2"

# symlink sanity
if [[ -L "$AMD64/lib64/ld-linux-x86-64.so.2" ]]; then
  tgt="$(readlink "$AMD64/lib64/ld-linux-x86-64.so.2")"
  if [[ "$tgt" != "../lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" ]]; then
    say "[FAIL] bad amd64 interpreter link -> $tgt"; pass=0
  fi
fi
if [[ -L "$I386/lib/ld-linux.so.2" ]]; then
  tgt="$(readlink "$I386/lib/ld-linux.so.2")"
  if [[ "$tgt" != "i386-linux-gnu/ld-linux.so.2" ]]; then
    say "[FAIL] bad i386 interpreter link -> $tgt"; pass=0
  fi
fi

# --- 2) DXVK/VKD3D payload checks ---
DX64="$STAGE/dxvk/x64"; DX86="$STAGE/dxvk/x86"
VK64="$STAGE/vkd3d/x64"; VK86="$STAGE/vkd3d/x86"

for f in d3d11.dll dxgi.dll d3d9.dll d3d10core.dll; do
  need_file "$DX64/$f"
  need_file "$DX86/$f"
done
for f in d3d12.dll d3d12core.dll; do
  need_file "$VK64/$f"
  need_file "$VK86/$f"
done

# --- 3) PE type sanity using `file` ---
chk_pe() {
  local path="$1" want="$2"
  if out="$(file "$path" 2>/dev/null)"; then
    case "$want" in
      PE32+) [[ "$out" == *"PE32+ executable for MS Windows"* ]] || { say "[FAIL] $path expected PE32+ (x64), got: $out"; pass=0; }
      ;;
      PE32)  [[ "$out" == *"PE32 executable for MS Windows"*  ]] || { say "[FAIL] $path expected PE32 (x86), got: $out"; pass=0; }
      ;;
    esac
  else
    say "[FAIL] file(1) failed for $path"; pass=0
  fi
}

# x64
for f in "$DX64/d3d11.dll" "$DX64/dxgi.dll" "$VK64/d3d12.dll" "$VK64/d3d12core.dll"; do
  [[ -f "$f" ]] && chk_pe "$f" PE32+
done
# x86
for f in "$DX86/d3d11.dll" "$DX86/dxgi.dll" "$VK86/d3d12.dll" "$VK86/d3d12core.dll"; do
  [[ -f "$f" ]] && chk_pe "$f" PE32
done

# --- Summary ---
if [[ $pass -eq 1 ]]; then
  say "[summary] PASS"
  exit 0
else
  say "[summary] FAIL"
  exit 1
fi
