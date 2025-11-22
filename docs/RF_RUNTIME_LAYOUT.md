# RobotForest Runtime Layout (contract)

This describes what each top-level directory in `rf_runtime/` is for.
CI and the Android launcher both assume this layout.

Top-level:
- bin/                → launcher entry points (box64, box86, steam-win.sh, wine32on64.sh, wine64.sh)
- dxvk/               → DXVK runtime DLLs (x64/x86)
- vkd3d/              → DX12/VKD3D DLLs (x64/x86)
- x86_64-linux/       → 64-bit host ELF runtime (glibc, X11, Vulkan, etc.)
- i386-linux/         → 32-bit host ELF runtime
- prefix/             → default WINEPREFIX used by RobotForest (drive_c/windows/... + DXVK/VKD3D glue)
- wine64/             → 64-bit Wine tree (DLLs, EXEs, libs) – future: Proton-derived
- wine32/             → 32-bit Wine tree for WoW64 – future: Proton-derived
- proton/             → Proton "distribution" metadata / versioned trees (optional)
- rf_env.sh           → canonical env wiring for RobotForest (sets RF_RUNTIME_ROOT, RF_PREFIX, WINEPREFIX)
- rf_install_runtime.sh
                      → installer used by Android APK to unpack a runtime bundle into app-private storage
- rf_runtime_layout_check.sh
                      → sanity checker for this layout (used in CI + local dev)
- runtime.version     → version stamp written by CI (e.g. "dev", "2025-11-22-geX")

Contract for future Wine/Proton:

- wine64/bin/         → must contain wine64 entry points (e.g. wine64, wineserver, etc.)
- wine32/bin/         → must contain wine32 entry points (for WoW64)
- steam-win.sh        → orchestration script that:
                        - wires RF env via rf_env.sh
                        - selects Proton/Wine tree from wine32/wine64/proton/
                        - launches Steam or a Windows game with box64+Wine
- wine32on64.sh       → helper for 32-on-64 WoW64 staging (wraps box64 + wine32 tree)
- wine64.sh           → helper for 64-bit-only Wine runs using wine64 tree

The Android app / launcher assume:
- RF_RUNTIME_ROOT is the extracted rf_runtime root.
- RF_PREFIX is a usable default WINEPREFIX.
- Running `RF_RUNTIME_ROOT/bin/box64` will be **attempted** (but may be blocked by SELinux on some devices).
