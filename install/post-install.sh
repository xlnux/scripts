#!/usr/bin/env bash
set -euo pipefail

# Fase post-install (root): identidad y branding final del sistema.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

x_require_root

log "post-install: pendiente de integrar con el paquete x-release (branding, hooks)"
