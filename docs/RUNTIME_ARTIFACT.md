# RobotForest Runtime Artifact (`rf-runtime-dev`)

This repository builds and publishes the **RobotForest runtime** used by the
RobotForest Android launcher.

The canonical output is an artifact named:

- `rf-runtime-dev.tar.zst` (primary, used on-device / in APK)
- `rf-runtime-dev.zip` (alternate format for tooling)

Both variants contain the **same directory tree**.

---

## 1. Layout contract

After extracting `rf-runtime-dev.tar.zst` into a directory (for example
`~/rf_runtime_zip_testN`), the top-level layout MUST look like:

- `bin/`
- `dxvk/`
- `vkd3d/`
- `prefix/`
- `x86_64-linux/`
- `i386-linux/`
- `rf_env.sh`
- `rf_install_runtime.sh`
- `rf_runtime_layout_check.sh`
- `runtime.version`
- `proton/` (OPTIONAL / present in some builds)

Additional subdirectories under these are allowed.

### 1.1 Required directories

These are considered **required** for a valid runtime:

- `bin/`
- `dxvk/`
- `vkd3d/`
- `prefix/`
- `x86_64-linux/`
- `i386-linux/`

At this stage, Wine binaries are still **stubbed/host-only**, so:

- `wine32/` and `wine64/` are required only for **host-side stub / future full builds**.
- The Termux-only / APK-embedded runtime is allowed to **omit** `wine32/` and `wine64/`
  until WoW64 integration is wired up.

### 1.2 Optional `proton/` directory

- `proton/` is **OPTIONAL** in the contract.
- When present, it is expected to hold Proton-GE based trees, e.g.:

  - `proton/Proton-rf-*/proton`
  - `proton/Proton-rf-*/dist/`

The Termux-only runtime currently does **not** require Proton to be present.

---

## 2. Helper scripts inside the runtime

The runtime bundle includes a few helper scripts for consumers:

### 2.1 `rf_env.sh`

- Purpose: wire environment variables for the runtime.
- Behavior:
  - Detects its own directory and sets:
    - `RF_RUNTIME_ROOT`
    - `RF_PREFIX`
    - `WINEPREFIX`
  - Designed to be sourced:

    ```sh
    . /path/to/runtime/rf_env.sh
    ```

### 2.2 `rf_runtime_layout_check.sh`

- Purpose: sanity-check a runtime tree.
- Behavior:
  - Uses `RF_RUNTIME_ROOT` if set, otherwise the script’s directory.
  - Verifies required directories exist.
  - Treats `proton/` as **optional** and reports it as such.
  - Prints a short summary of `bin/` plus basic wine32/wine64 placeholders
    if those directories exist.

Example usage:

```sh
cd /path/to/runtime
./rf_runtime_layout_check.sh

#EXAMPLE MANUAL CONSUMPTION
#example download from github actions and test on device
[<0;56;40M# 1) Download rf-runtime-dev artifact from a green RF Release run
cd ~/android/robotforest-wow64-runtime

RUN_ID=<RF_RELEASE_RUN_ID>  # replace with actual green run ID

rm -rf "$TMP/rf-release-artifact"
mkdir -p "$TMP/rf-release-artifact"

gh run download "$RUN_ID" \
  -n rf-runtime-dev \
  -D "$TMP/rf-release-artifact"

# 2) Extract tar.zst into a test directory
cd "$TMP/rf-release-artifact"

RUNTIME_TEST="$HOME/rf_runtime_zip_manual"
rm -rf "$RUNTIME_TEST"
mkdir -p "$RUNTIME_TEST"

tar --zstd -C "$RUNTIME_TEST" -xf rf-runtime-dev.tar.zst

cd "$RUNTIME_TEST"

# 3) Sanity check
./rf_runtime_layout_check.sh

# 4) Wire env for a shell
. ./rf_env.sh
echo "RF_RUNTIME_ROOT=$RF_RUNTIME_ROOT"
echo "RF_PREFIX=$RF_PREFIX"
echo "WINEPREFIX=$WINEPREFIX"

