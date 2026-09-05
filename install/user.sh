#!/usr/bin/env bash
set -euo pipefail

# Entry de provision de usuario (se ejecuta como el usuario objetivo, o con
# root: en ese caso se delega a install/user-seed.sh vía runuser).
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

TARGET_USER="$(x_target_user)"
TARGET_HOME="$(x_target_home)"
[[ -n "$TARGET_HOME" ]] || error "no se pudo resolver el home de $TARGET_USER"

log "usuario: $TARGET_USER ($TARGET_HOME)"

if [[ "$(id -u)" -eq 0 ]]; then
    env X_SKEL_DIR="${X_SKEL_DIR:-/etc/skel}" X_CONFIG_SEED="$X_ROOT/config" \
        runuser -u "$TARGET_USER" -- bash "$X_ROOT/install/user-seed.sh"
else
    X_SKEL_DIR="${X_SKEL_DIR:-/etc/skel}" X_CONFIG_SEED="$X_ROOT/config" \
        bash "$X_ROOT/install/user-seed.sh"
fi

if [[ "${X_NODE:-0}" == "1" ]]; then
    log "usuario: instalando toolchain node (fnm)"
    run_as_user bash "$X_ROOT/tools/node.sh"
fi

log "usuario aprovisionado"
