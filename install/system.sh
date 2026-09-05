#!/usr/bin/env bash
set -euo pipefail

# Entry de aprovisionamiento del sistema (root). Orquesta las fases
# config -> hardware -> login -> post-install.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

x_require_root

X_INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$X_INSTALL_DIR/config.sh"
bash "$X_INSTALL_DIR/hardware.sh"
bash "$X_INSTALL_DIR/login.sh"
bash "$X_INSTALL_DIR/post-install.sh"

log "sistema aprovisionado"
