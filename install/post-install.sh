#!/usr/bin/env bash
set -euo pipefail

# Post-install phase (root): final system identity and branding.
source "$(dirname "${BASH_SOURCE[0]}")/helpers/common.sh"

x_require_root

log "post-install: pending integration with the x-release package (branding, hooks)"
