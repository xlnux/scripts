#!/usr/bin/env bash
set -euo pipefail

# Siembra de dotfiles para el usuario actual (se invoca desde install/user.sh).
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/helpers/sync.sh"

SKEL_DIR="${X_SKEL_DIR:-/etc/skel}"
CONFIG_SEED="${X_CONFIG_SEED:-$X_ROOT/config}"
HOME_DIR="$HOME"

if [[ -d "$SKEL_DIR" ]]; then
    x_seed_home "$SKEL_DIR" "$HOME_DIR"
    log "home sembrado desde $SKEL_DIR"
fi

if [[ -d "$CONFIG_SEED" ]] && [[ "$(find "$CONFIG_SEED" -mindepth 1 | wc -l)" -gt 0 ]]; then
    x_sync_config "$CONFIG_SEED" "$HOME_DIR/.config"
    log "config sincronizada desde $CONFIG_SEED"
fi
