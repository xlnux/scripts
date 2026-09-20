#!/usr/bin/env bash
set -euo pipefail

# Run the ORIGINAL equisdots installer (online, interactive).
# Use when already logged in and the offline packaged setup is not enough.
# Clones equisdots/dots to a temp dir, runs its ./dots setup (it will ask for
# the sudo password when needed) and cleans up afterwards.
#   X_HYPR_REF   branch/commit (default: main)

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

if [[ "$(id -u)" -eq 0 ]]; then
    error "hyprland online setup must run as the target user, not root"
fi

X_HYPR_REF="${X_HYPR_REF:-main}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/x"
mkdir -p "$CACHE"

SRC="$(mktemp -d "$CACHE/dots-online.XXXXXX")"
trap 'rm -rf "$SRC"' EXIT

log "cloning https://github.com/equisdots/dots.git (branch $X_HYPR_REF)"
git clone -q --depth 1 --branch "$X_HYPR_REF" \
    "https://github.com/equisdots/dots.git" "$SRC/dots"

log "running the upstream installer (dots setup)"
cd "$SRC/dots"
bash ./dots setup

log "upstream installer finished; temporary copy removed"
