#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# --- Layout
ROOT="$HOME/android/robotforest-wow64-runtime"
STAGE="$ROOT/staging/rf_runtime"

W64="$STAGE/wine64"
W32="$STAGE/wine32"
DXVK64="$STAGE/dxvk/x64"
DXVK32="$STAGE/dxvk/x86"
VKD364="$STAGE/vkd3d/x64"
VKD332="$STAGE/vkd3d/x86"

mkdir -p "$W64" "$W32" "$DXVK64" "$DXVK32" "$VKD364" "$VKD332" "$HOME/tmp"

# --- Versions
DXVK_VER="${DXVK_VER:-"2.3"}"
VKD3D_VER="${VKD3D_VER:-"2.11"}"

# --- Optional Wine payloads (user may set these)
WINE64_URL="${WINE64_URL:-""}"
WINE32_URL="${WINE32_URL:-""}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1" >&2; exit 1; }; }
for t in curl tar xz file; do need "$t"; done

# zstd optional
have_zstd=0
if command -v zstd >/dev/null 2>&1; then have_zstd=1; fi

extract_tar_zst() {
  # $1 = archive path, $2 = dest dir
  local arch="$1" dest="$2"
  [ -f "$arch" ] || { echo "[error] missing archive: $arch" >&2; exit 1; }
  mkdir -p "$dest"
  # Prefer piping through zstd (works even if tar lacks --zstd)
  if [ "$have_zstd" -eq 1 ]; then
    zstd -dc -- "$arch" | tar -xf - -C "$dest"
  else
    # Try tar integrations that may exist
    tar --use-compress-program=unzstd -xf "$arch" -C "$dest" 2>/dev/null || \
    tar --zstd -xf "$arch" -C "$dest"
  fi
}

echo "[dxvk] fetching ${DXVK_VER}"
DXVK_TGZ="$HOME/tmp/dxvk-${DXVK_VER}.tar.gz"
curl -fL --retry 3 -o "$DXVK_TGZ" \
  "https://github.com/doitsujin/dxvk/releases/download/v${DXVK_VER}/dxvk-${DXVK_VER}.tar.gz"

rm -rf "$HOME/tmp/dxvk-${DXVK_VER}"
tar -xzf "$DXVK_TGZ" -C "$HOME/tmp"

# copy dlls from x64/x32
if [ -d "$HOME/tmp/dxvk-${DXVK_VER}/x64" ]; then
  cp -a "$HOME/tmp/dxvk-${DXVK_VER}/x64/." "$DXVK64/"
fi
if [ -d "$HOME/tmp/dxvk-${DXVK_VER}/x32" ]; then
  cp -a "$HOME/tmp/dxvk-${DXVK_VER}/x32/." "$DXVK32/"
fi

echo "[vkd3d-proton] fetching ${VKD3D_VER}"
VKD3D_TAR_ZST="$HOME/tmp/vkd3d-proton-${VKD3D_VER}.tar.zst"
curl -fL --retry 3 -o "$VKD3D_TAR_ZST" \
  "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v${VKD3D_VER}/vkd3d-proton-${VKD3D_VER}.tar.zst"

# Clean ONLY previously extracted directories, not the tarball
find "$HOME/tmp" -maxdepth 1 -type d -name "vkd3d-proton-${VKD3D_VER}*" -exec rm -rf {} +

echo "[dbg] archive at: $VKD3D_TAR_ZST"
extract_tar_zst "$VKD3D_TAR_ZST" "$HOME/tmp"

# Locate extracted dir (vkd3d-proton-2.11 or vkd3d-proton-2.11-<hash>)
VKD3D_DIR="$(find "$HOME/tmp" -maxdepth 1 -type d -name "vkd3d-proton-${VKD3D_VER}*" | head -n1 || true)"
if [ -n "$VKD3D_DIR" ]; then
  # Preferred split
  if [ -d "$VKD3D_DIR/x64" ]; then
    cp -a "$VKD3D_DIR/x64/." "$VKD364/"
  fi
  if [ -d "$VKD3D_DIR/x86" ]; then
    cp -a "$VKD3D_DIR/x86/." "$VKD332/"
  fi

  # Fallback: classify DLLs from bin/
  if [ -d "$VKD3D_DIR/bin" ]; then
    for f in "$VKD3D_DIR/bin"/*.dll; do
      [ -f "$f" ] || continue
      if file "$f" | grep -q 'PE32+'; then
        cp -f "$f" "$VKD364/"
      else
        cp -f "$f" "$VKD332/"
      fi
    done
  fi
else
  echo "[warn] couldn't locate unpacked vkd3d-proton directory; skipping copy"
fi

# --- Optional Wine payloads (user-provided URLs)
auto_extract_to() {
  # $1 = tarball path, $2 = dest dir
  local t="$1" d="$2"
  mkdir -p "$d"
  case "$t" in
    *.tar.xz)  tar -xJf "$t" -C "$d" --strip-components=1 ;;
    *.tar.zst) extract_tar_zst "$t" "$d" ;;  # note: strip-components not used here
    *.tar.gz)  tar -xzf "$t" -C "$d" --strip-components=1 ;;
    *.tgz)     tar -xzf "$t" -C "$d" --strip-components=1 ;;
    *.zip)     need unzip; unzip -o "$t" -d "$d" >/dev/null ;;
    *)         echo "[warn] unknown archive type: $t" ;;
  esac
}

if [ -n "$WINE64_URL" ]; then
  echo "[wine64] fetching from \$WINE64_URL"
  if curl -fL --retry 3 -o "$HOME/tmp/wine64.tar.xz" "$WINE64_URL"; then
    auto_extract_to "$HOME/tmp/wine64.tar.xz" "$W64"
  elif curl -fL --retry 3 -o "$HOME/tmp/wine64.tar.zst" "$WINE64_URL"; then
    auto_extract_to "$HOME/tmp/wine64.tar.zst" "$W64"
  elif curl -fL --retry 3 -o "$HOME/tmp/wine64.tar.gz" "$WINE64_URL"; then
    auto_extract_to "$HOME/tmp/wine64.tar.gz" "$W64"
  else
    echo "[warn] failed to fetch wine64 from \$WINE64_URL"
  fi
else
  echo "[info] WINE64_URL not set; skipping wine64 payload"
fi

if [ -n "$WINE32_URL" ]; then
  echo "[wine32] fetching from \$WINE32_URL"
  if curl -fL --retry 3 -o "$HOME/tmp/wine32.tar.xz" "$WINE32_URL"; then
    auto_extract_to "$HOME/tmp/wine32.tar.xz" "$W32"
  elif curl -fL --retry 3 -o "$HOME/tmp/wine32.tar.zst" "$WINE32_URL"; then
    auto_extract_to "$HOME/tmp/wine32.tar.zst" "$W32"
  elif curl -fL --retry 3 -o "$HOME/tmp/wine32.tar.gz" "$WINE32_URL"; then
    auto_extract_to "$HOME/tmp/wine32.tar.gz" "$W32"
  else
    echo "[warn] failed to fetch wine32 from \$WINE32_URL"
  fi
else
  echo "[info] WINE32_URL not set; skipping wine32 payload"
fi

echo "[done] DXVK @ $DXVK64 / $DXVK32 ; VKD3D @ $VKD364 / $VKD332 ; Wine @ $W64 / $W32"
