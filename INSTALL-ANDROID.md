# RobotForest WOW64 Runtime – Android / Termux Install

This document describes how to install the **prebuilt runtime** from GitHub
Releases onto an Android device using Termux.

The runtime itself is built and verified in GitHub Actions by the
`RF Release (pack + release)` workflow. Artifacts are then published as
GitHub Releases with assets such as:

- `rf-runtime-dev.tar.zst`
- `rf-runtime-dev.tar.zst.sha256`
- `rf-runtime-dev.zip`
- `rf-runtime-dev.zip.sha256`

## Requirements

On Android (Termux):

- Termux app installed
- Network access
- The following basic tools:
  - `curl`
  - `tar`
  - `zstd` (for `.tar.zst`) or `unzip` (for `.zip`)
  - `sha256sum` (from `coreutils`)

> Note: These tools are standard on Ubuntu/GitHub runners and available via
> normal packages on Termux. They are **only** for host-side management,
> not for compiling Windows binaries.

## Quick install – latest runtime

From a Termux shell:

```bash
# Clone this repo (optional if you just curl the script)
git clone https://github.com/jasonsmr/robotforest-wow64-runtime.git
cd robotforest-wow64-runtime

# Make sure the helper script is executable
chmod +x scripts/get_latest_runtime.sh

# Download and install the latest runtime into ~/rf_runtime
scripts/get_latest_runtime.sh --dest "$HOME/rf_runtime"
