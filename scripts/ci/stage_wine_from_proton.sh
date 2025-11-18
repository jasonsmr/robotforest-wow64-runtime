#!/usr/bin/env bash
set -euo pipefail

PROTON_TARBALL="${1:-}"
RDIR="${2:-}"

if [[ -z "${PROTON_TARBALL}" || -z "${RDIR}" ]]; then
  echo "usage: stage_wine_from_proton.sh <proton.tar(.gz|.xz|.zst)> <rf_runtime_dir>" >&2
  exit 2
fi

if [[ ! -f "$PROTON_TARBALL" ]]; then
  echo "[stage_wine] proton tarball not found: $PROTON_TARBALL (skipping)" >&2
  exit 0
fi

mkdir -p "$RDIR/wine64" "$RDIR/wine32" "$RDIR/steam"

TMPP="$(mktemp -d)"
cleanup(){ rm -rf "$TMPP"; }
trap cleanup EXIT

# Extract outer Proton archive
case "$PROTON_TARBALL" in
  *.tar.gz|*.tgz) tar -xzf "$PROTON_TARBALL" -C "$TMPP" ;;
  *.tar.xz)       tar -xJf "$PROTON_TARBALL" -C "$TMPP" ;;
  *.tar.zst|*.tzst|*.zst) tar --use-compress-program="zstd -d" -xf "$PROTON_TARBALL" -C "$TMPP" ;;
  *.tar)          tar -xf "$PROTON_TARBALL" -C "$TMPP" ;;
  *) echo "[stage_wine] unknown compression for $PROTON_TARBALL" >&2; exit 0 ;;
esac

# Find inner proton_dist*
PDIST="$(find "$TMPP" -type f -name 'proton_dist*.tar*' | head -n1 || true)"
if [[ -z "$PDIST" ]]; then
  echo "[stage_wine] no proton_dist* tarball inside Proton (skipping)" >&2
  exit 0
fi

mkdir -p "$TMPP/pdist"
# Extract inner dist
case "$PDIST" in
  *.tar.gz|*.tgz) tar -xzf "$PDIST" -C "$TMPP/pdist" ;;
  *.tar.xz)       tar -xJf "$PDIST" -C "$TMPP/pdist" ;;
  *.tar.zst|*.tzst|*.zst) tar --use-compress-program="zstd -d" -xf "$PDIST" -C "$TMPP/pdist" ;;
  *.tar)          tar -xf "$PDIST" -C "$TMPP/pdist" ;;
  *) echo "[stage_wine] unknown compression for $PDIST" >&2; exit 0 ;;
esac

# Copy payloads (Proton GE layout)
# 64-bit wine: files/lib64/wine + files/bin
if [[ -d "$TMPP/pdist/files/lib64/wine" ]]; then
  cp -a "$TMPP/pdist/files/lib64/wine/." "$RDIR/wine64/"
fi
if [[ -d "$TMPP/pdist/files/bin" ]]; then
  cp -a "$TMPP/pdist/files/bin/." "$RDIR/wine64/"
fi

# 32-bit wine (WoW64): files/lib/wine
if [[ -d "$TMPP/pdist/files/lib/wine" ]]; then
  cp -a "$TMPP/pdist/files/lib/wine/." "$RDIR/wine32/"
fi

# Optional steam bits
if [[ -d "$TMPP/pdist/files/steam-runtime" ]]; then
  cp -a "$TMPP/pdist/files/steam-runtime/." "$RDIR/steam/"
fi

# Report
if [[ ! -f "$RDIR/wine64/wine64" ]]; then
  echo "[stage_wine] WARNING: wine64 loader not found after staging." >&2
  ls -la "$RDIR/wine64" || true
  exit 0
fi

echo "[stage_wine] OK: staged Wine into $RDIR"
