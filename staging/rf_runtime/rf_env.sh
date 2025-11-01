# Source this:  . "/data/data/com.termux/files/home/android/robotforest-wow64-runtime/staging/rf_runtime/rf_env.sh"
export WINEPREFIX="/data/data/com.termux/files/home/android/robotforest-wow64-runtime/staging/rf_runtime/prefix"

# Prefer native (DXVK/vkd3d-proton) over builtin d3d* & dxgi
export WINEDLLOVERRIDES="d3d9,dxgi,d3d10core,d3d11,d3d12,d3d12core=n,b"

# Point DXVK to its config (optional)
export DXVK_CONFIG_FILE="/data/data/com.termux/files/home/android/robotforest-wow64-runtime/staging/rf_runtime/prefix/dxvk.conf"

# Keep HUD quiet unless debugging; flip to "1" if needed
export DXVK_HUD="0"

# If you later provide Wine payloads, uncomment and adjust:
# export PATH="/data/data/com.termux/files/home/android/robotforest-wow64-runtime/staging/rf_runtime/wine64/bin:/data/data/com.termux/files/home/android/robotforest-wow64-runtime/staging/rf_runtime/wine32/bin:$PATH"
