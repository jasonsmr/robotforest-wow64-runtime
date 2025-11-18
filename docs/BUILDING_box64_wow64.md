# Building Box64 (with WOW64) on Android (Termux-free runtime outcome)

This documents how our **prebuilt** `libbox64.so` and optional `box64` binary were produced. We DO NOT depend on Termux packages inside the runtime; Termux was only a *build environment*.

## Toolchain + layout (canonical)
- NDK r27b (clang/lld), host Android/arm64
- Sources live under `~/src`
- Install prefixes:
  - Toolchain: `~/opt/toolchain`
  - MinGW: `~/opt/mingw` (x86_64-w64-mingw32) and optionally `~/opt/mingw32` (i686)
- Environment shims live in `~/.env/` and `~/bin` (see dotfiles/docs)

## Box64 source
- `~/src/box64` (tracked commit known-good; record it via `git -C ~/src/box64 rev-parse --short HEAD`)
- Android build dir: `~/src/box64/build-android`

## Configure + build (Android/arm64 target)
```bash
cd ~/src/box64
mkdir -p build-android && cd build-android
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DBAD_LOG=OFF \
  -DWITH_MUSL=ON \
  -DANDROID=ON \
  -DCMAKE_SYSTEM_NAME=Android \
  -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
  -DCMAKE_ANDROID_NDK="$NDK" \
  -DCMAKE_ANDROID_STL_TYPE=c++_shared \
  -DCMAKE_ANDROID_API=28 \
  -DCMAKE_C_COMPILER="$NDK/toolchains/llvm/prebuilt/linux-aarch64/bin/clang" \
  -DCMAKE_CXX_COMPILER="$NDK/toolchains/llvm/prebuilt/linux-aarch64/bin/clang++"
cmake --build . -j$(nproc)

## 2) `docs/BUILDING_wine_wow64_min.md` (new)

```markdown
# Building minimal Wine-WoW64 userland for Android Box64

We build a **minimal** WoW64 userspace (wine64 + essential dlls) that Box64 will load.

> Heads up: there’s no official Android-native WoW64 package. We produce a minimal tree and place it under `rf_runtime/wine64/` in the runtime.

## High-level steps
1. Prepare MinGW-w64 toolchain (see dotfiles/docs if needed). Target: `x86_64-w64-mingw32`.
2. Build Wine (WoW64) components needed by Proton/DXVK; keep it minimal:
   - Loader (`wine64`), core dlls, and 64-bit prefix scaffolding.
3. Stage results under `wine64/` with the expected Proton layout (our packer script arranges this).

## Outputs we ship
- `rf_runtime/wine64/` with binaries and dlls sufficient to run SteamCMD + Proton bootstrap.
- DXVK/vkd3d-proton will bring D3D <-> Vulkan.

## Testing locally (device)
- Use `rf_runtime/bin/wine64.sh -v` through Box64 (Exec.java maps libbox64.so).
- Ensure `wine64` resolves and prints a version banner.
