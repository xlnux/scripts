#!/usr/bin/env bash
set -euo pipefail

# Fase hardware (root): modulos de drivers/virtualizacion bajo hardware/.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

x_require_root

X_HW_DIR="$X_ROOT/hardware"

if [[ "${X_HW_NVIDIA:-0}" == "1" ]] || (has_cmd lspci && lspci | grep -qiE 'vga.*nvidia|3d.*nvidia'); then
    log "nvidia: aplicando modulo"
    bash "$X_HW_DIR/nvidia.sh"
else
    log "nvidia: no detectado (skip, usa X_HW_NVIDIA=1 para forzar)"
fi

if [[ "${X_HW_QEMU:-0}" == "1" ]]; then
    log "qemu/libvirt: aplicando modulo"
    bash "$X_HW_DIR/qemu.sh"
else
    log "qemu: skip (usa X_HW_QEMU=1 para activar)"
fi
