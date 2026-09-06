#!/usr/bin/env bash
set -euo pipefail

# Login phase (root): base system services.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

x_require_root

if ! has_cmd systemctl; then
    log "login: systemd not present (skip)"
    exit 0
fi

SERVICES=(NetworkManager)

for svc in "${SERVICES[@]}"; do
    if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
        systemctl enable "$svc.service"
        # Only start when systemd is PID 1 (not inside a chroot/live image).
        if [[ "$(ps -p 1 -o comm= 2>/dev/null)" == "systemd" ]]; then
            systemctl start "$svc.service"
        fi
        log "login: $svc enabled"
    fi
done
