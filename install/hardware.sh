#!/usr/bin/env bash
set -euo pipefail

# Hardware phase (root): driver/virtualization modules under hardware/.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

x_require_root

X_HW_DIR="$X_ROOT/hardware"
X_HW_AUTO="${X_HW_AUTO:-1}"

auto_nvidia() {
    [[ "$X_HW_AUTO" == "1" ]] && has_cmd lspci && lspci 2>/dev/null | grep -qiE 'vga.*nvidia|3d.*nvidia'
}

if [[ "${X_HW_NVIDIA:-0}" == "1" ]] || auto_nvidia; then
    log "nvidia: applying module"
    bash "$X_HW_DIR/nvidia.sh"
else
    log "nvidia: not detected (X_HW_NVIDIA=1 to force, X_HW_AUTO=0 to disable auto-detection)"
fi

if [[ "${X_HW_QEMU:-0}" == "1" ]]; then
    log "qemu/libvirt: applying module"
    bash "$X_HW_DIR/qemu.sh"
else
    log "qemu: skip (set X_HW_QEMU=1 to enable)"
fi
