#!/usr/bin/env bash
set -euo pipefail

# Fase config (root): siembra /etc/skel y aplica el overlay de /etc.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/helpers/sync.sh"

x_require_root

x_copy_tree "$X_ROOT/skel" /etc/skel
log "skel: /etc/skel sembrado"

if [[ -d "$X_ROOT/etc" ]] && [[ "$(find "$X_ROOT/etc" -mindepth 1 -type d | wc -l)" -gt 0 ]]; then
    for d in "$X_ROOT"/etc/*/; do
        [[ -d "$d" ]] || continue
        name="$(basename "$d")"
        x_copy_tree "$d" "/etc/$name"
    done
    log "etc: overlay aplicado"
else
    log "etc: sin drop-ins todavia"
fi
