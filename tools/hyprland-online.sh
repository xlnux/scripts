#!/usr/bin/env bash
set -euo pipefail

# Run the ORIGINAL xscriptor-colors/hyprland installer (online, interactive).
# Use when already logged in and the offline packaged setup is not enough.
# Clones the repo to a temp dir, runs its ./install.sh (it will ask for the
# sudo password when needed) and cleans up afterwards.
#   X_HYPR_REF   branch/commit (default: main)

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

if [[ "$(id -u)" -eq 0 ]]; then
    error "hyprland online setup must run as the target user, not root"
fi

X_HYPR_REF="${X_HYPR_REF:-main}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/x"
mkdir -p "$CACHE"

SRC="$(mktemp -d "$CACHE/hyprland-online.XXXXXX")"
trap 'rm -rf "$SRC"' EXIT

log "cloning https://github.com/xscriptor-colors/hyprland.git (branch $X_HYPR_REF)"
git clone -q --depth 1 --branch "$X_HYPR_REF" \
    "https://github.com/xscriptor-colors/hyprland.git" "$SRC"

log "running the upstream installer"
cd "$SRC"
bash ./install.sh

log "upstream installer finished; temporary copy removed"
