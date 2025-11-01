#!/usr/bin/env bash
set -euo pipefail

RROOT="$HOME/android/robotforest-wow64-runtime"
STAGE="$RROOT/staging/rf_runtime"
AMD="$STAGE/x86_64-linux"
I386="$STAGE/i386-linux"
TMP="${TMPDIR:-$HOME/tmp}/rf_sysroots.$$"

DEB_BASE="https://deb.debian.org/debian"
DIST="bookworm"
COMP="main"

# Minimal runtime set for Wine GUI + future Vulkan path
PKGS_COMMON=(zlib1g libgcc-s1 libstdc++6 libglib2.0-0 libfreetype6 libfontconfig1 \
             libx11-6 libxext6 libxrender1 libxrandr2 libxfixes3 libxi6 \
             libxcb1 libxcb-xfixes0 libxcb-render0 libxcb-randr0)
PKG_LIBC=libc6
PKG_GL=libgl1
PKG_VK=libvulkan1

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 1; }; }
need curl; need ar; need tar
# xz is in busybox on many systems, but prefer real one when present
command -v xz >/dev/null 2>&1 || true

# Clean stage slices
mkdir -p "$AMD" "$I386" "$TMP"
rm -rf "$AMD"/* "$I386"/*

echo "[sysroot] preparing Debian $DIST runtime slices (amd64 + i386) via Packages.xz"

# Fetch Packages index once per arch
PKGIDX_AMD="$TMP/Packages-amd64.xz"
PKGIDX_I386="$TMP/Packages-i386.xz"
curl -fsSL "$DEB_BASE/dists/$DIST/$COMP/binary-amd64/Packages.xz" -o "$PKGIDX_AMD"
curl -fsSL "$DEB_BASE/dists/$DIST/$COMP/binary-i386/Packages.xz"  -o "$PKGIDX_I386"

# Grep helper that works on xz without requiring a standalone xz (busybox ok)
xzcat() { command -v xz >/dev/null 2>&1 && xz -dc "$1" || busybox xz -dc "$1"; }

# Resolve a package to its latest Filename path within Packages.xz (stable has one)
# $1: arch tag: amd64|i386
# $2: package name (e.g. libc6)
# -> echo relative path like "pool/main/g/glibc/libc6_2.42-2_amd64.deb"
resolve_deb_path() {
  # $1: arch tag: amd64|i386
  # $2: package name (e.g. libc6)
  # -> echo relative path like "pool/main/g/glibc/libc6_2.xx-yy_amd64.deb"
  local arch="$1" pkg="$2"
  local idx="$PKGIDX_AMD"
  [ "$arch" = "i386" ] && idx="$PKGIDX_I386"

  # Walk stanzas; when the stanza's Package: equals our target, record its Filename:
  xzcat "$idx" | awk -v want_pkg="$pkg" '
    BEGIN{RS=""; FS="\n"; found=0; fn=""}
    {
      found=0; fn="";
      for (i=1; i<=NF; i++) {
        if ($i ~ /^Package:[[:space:]]+/) {
          split($i, a, /:[[:space:]]+/)
          if (a[2] == want_pkg) { found=1 }
        }
        if (found && $i ~ /^Filename:[[:space:]]+/) {
          sub(/^Filename:[[:space:]]+/, "", $i)
          fn=$i  # keep last in stanza (sane in stable)
        }
      }
      if (found && fn != "") print fn
    }
  ' | tail -n1
}

# Fetch a .deb to $3
fetch_deb() {
  local rel="$1" out="$2"
  local url="$DEB_BASE/$rel"
  echo "  [get] $url"
  curl -fL --retry 3 -o "$out" "$url"
}

# Unpack .deb into a temp dir $2, then copy libs into $3 (arch root)
unpack_deb() {
  local deb="$1" tdir="$2" dest="$3"
  rm -rf "$tdir"; mkdir -p "$tdir"
  ( cd "$tdir" && ar x "$deb" )
  local data_tar
  data_tar="$(ls "$tdir"/data.tar.* 2>/dev/null | head -n1 || true)"
  [ -n "$data_tar" ] || { echo "    [warn] no data.tar in $(basename "$deb")"; return 0; }
  mkdir -p "$tdir/data"
  tar -xf "$data_tar" -C "$tdir/data"

  # Copy typical Debian multiarch library locations
  for p in lib usr/lib lib64 lib/x86_64-linux-gnu lib/i386-linux-gnu \
           usr/lib/x86_64-linux-gnu usr/lib/i386-linux-gnu; do
    [ -d "$tdir/data/$p" ] || continue
    mkdir -p "$dest/$p"
    cp -a "$tdir/data/$p/." "$dest/$p/" 2>/dev/null || true
  done
}

install_one() {
  # $1: arch (amd64|i386)  $2: pkg  $3: dest-root  $4: tmpdir
  local arch="$1" pkg="$2" dest="$3" tdir="$4/unpack_$pkg"
  local rel; rel="$(resolve_deb_path "$arch" "$pkg" || true)"
  if [ -z "${rel:-}" ]; then
    echo "  [warn] not found: $pkg ($arch)"; return 0
  fi
  local deb="$4/$(basename "$rel")"
  fetch_deb "$rel" "$deb"
  unpack_deb "$deb" "$tdir" "$dest"
}

install_set() {
  # $1: arch (amd64|i386), $2: dest-root, $3..: pkgs
  local arch="$1" dest="$2"; shift 2
  local tmpa="$TMP/$arch"; mkdir -p "$tmpa"
  for pkg in "$@"; do install_one "$arch" "$pkg" "$dest" "$tmpa"; done
}

# 1) libc first (ensures ld-linux present)
install_set amd64 "$AMD" "$PKG_LIBC"
install_set i386  "$I386" "$PKG_LIBC"

# 2) essentials + GL + Vulkan loader
install_set amd64 "$AMD" "${PKGS_COMMON[@]}" "$PKG_GL" "$PKG_VK"
install_set i386  "$I386" "${PKGS_COMMON[@]}" "$PKG_GL" "$PKG_VK"

# Canonicalize loader locations
link_first_existing() {
  # Usage: link_first_existing <dest_root> <want_rel_path> <candidate_rel>...
  # If a candidate exists, force-create <want_rel_path> (removing any stale/broken symlink first).
  local dest="$1"; local want="$2"; shift 2
  local want_abs="$dest/$want"
  local want_dir
  want_dir="$(dirname "$want_abs")"
  mkdir -p "$want_dir"

  for rel in "$@"; do
    local cand="$dest/$rel"
    if [ -f "$cand" ]; then
      # Nuke whatever is there (file or dangling symlink) and copy the real interpreter.
      rm -f "$want_abs"
      cp -a "$cand" "$want_abs"
      return 0
    fi
  done
  return 1
}

fix_interpreter_links() {
  # Normalize loader links to be self-contained/relative.
  local AMD64="$STAGE/x86_64-linux"
  local I386="$STAGE/i386-linux"

  # amd64: ensure lib64/ld-linux-x86-64.so.2 exists and is relative into lib/x86_64-linux-gnu/
  if [ -f "$AMD64/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" ]; then
    mkdir -p "$AMD64/lib64"
    rm -f "$AMD64/lib64/ld-linux-x86-64.so.2"
    ln -s ../lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 "$AMD64/lib64/ld-linux-x86-64.so.2"
  fi

  # i386: ensure lib/ld-linux.so.2 is a relative link into lib/i386-linux-gnu/
  if [ -f "$I386/lib/i386-linux-gnu/ld-linux.so.2" ]; then
    rm -f "$I386/lib/ld-linux.so.2"
    ln -s i386-linux-gnu/ld-linux.so.2 "$I386/lib/ld-linux.so.2"
  fi
}

# amd64 loader
link_first_existing "$AMD"  "lib64/ld-linux-x86-64.so.2" \
  "lib64/ld-linux-x86-64.so.2" \
  "lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" \
  "lib/ld-linux-x86-64.so.2"

# i386 loader
link_first_existing "$I386" "lib/ld-linux.so.2" \
  "lib/i386-linux-gnu/ld-linux.so.2" \
  "lib/ld-linux.so.2" \
  "lib32/ld-linux.so.2"

fix_interpreter_links

# existing PASS/FAIL summary logic follows...

# Summary
pass=1
[ -f "$AMD/lib64/ld-linux-x86-64.so.2" ] || { echo "[FAIL] missing $AMD/lib64/ld-linux-x86-64.so.2"; pass=0; }
[ -f "$I386/lib/ld-linux.so.2" ]          || { echo "[FAIL] missing $I386/lib/ld-linux.so.2"; pass=0; }

if [ "$pass" = 1 ]; then
  echo "[summary] PASS"
else
  echo "[summary] FAIL"
  exit 1
fi
