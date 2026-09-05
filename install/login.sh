#!/usr/bin/env bash
set -euo pipefail

# Fase login (root): servicios base del sistema.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

x_require_root

if ! has_cmd systemctl; then
    log "login: systemd no presente (skip)"
    exit 0
fi

SERVICES=(NetworkManager)

for svc in "${SERVICES[@]}"; do
    if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
        systemctl enable --now "$svc.service"
        log "login: $svc habilitado"
    fi
done
