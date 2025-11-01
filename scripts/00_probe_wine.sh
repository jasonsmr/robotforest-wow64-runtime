#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/android/robotforest-wow64-runtime}"
STAGE="${STAGE:-$ROOT/staging/rf_runtime}"
ENV_FILE="${ENV_FILE:-$STAGE/rf_env.sh}"

mkdir -p "$STAGE"

# Probe order: explicit env overrides > PATH > a few common locations
probe_one() {
  local name="$1" given="${2:-}" out=""
  if [[ -n "$given" && -x "$given" ]]; then
    out="$given"
  else
    out="$(command -v "$name" 2>/dev/null || true)"
    # Common fallbacks (custom installs)
    if [[ -z "$out" ]]; then
      for p in \
        "$HOME/opt/wine/bin/$name" \
        "$HOME/.local/bin/$name" \
        "$HOME/bin/$name"
      do
        [[ -x "$p" ]] && out="$p" && break
      done
    fi
  fi
  echo "$out"
}

W64_GIVEN="${W64_BIN:-${WINE64_BIN:-}}"
W32_GIVEN="${W32_BIN:-${WINE32_BIN:-}}"

W64="$(probe_one wine64 "$W64_GIVEN")"
W32="$(probe_one wine   "$W32_GIVEN")"

if [[ -z "$W64" || -z "$W32" ]]; then
  echo "[error] Could not find wine64/wine."
  echo "        Tips:"
  echo "          - Put Wine in PATH, or"
  echo "          - Re-run as: W64_BIN=/path/to/wine64 W32_BIN=/path/to/wine $0"
  exit 2
fi

echo "[ok] wine64 -> $W64"
echo "[ok] wine   -> $W32"

# Ensure env file exists
[[ -f "$ENV_FILE" ]] || { echo "[info] creating $ENV_FILE"; printf '# rf_env\n' > "$ENV_FILE"; }

# Replace or append exports
upsert_export() {
  local key="$1" val="$2"
  if grep -qE "^export[[:space:]]+$key=" "$ENV_FILE"; then
    sed -i "s|^export[[:space:]]\+$key=.*$|export $key=\"$val\"|" "$ENV_FILE"
  else
    printf 'export %s="%s"\n' "$key" "$val" >> "$ENV_FILE"
  fi
}

upsert_export WINE64_BIN "$W64"
upsert_export WINE32_BIN "$W32"

echo "[summary] Updated $ENV_FILE with:"
grep -E '^export (WINE64_BIN|WINE32_BIN)=' "$ENV_FILE" || true
