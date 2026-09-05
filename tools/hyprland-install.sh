#!/usr/bin/env bash
set -euo pipefail

# Installs the Hyprland config from the external repo xscriptor-colors/hyprland.
# It does not modify or integrate the upstream repo: it clones (main only),
# strips the git metadata (.git/.github) from the temp copy to avoid nested
# repos and runs the repo's own documented installer.
#
# Variables:
#   X_HYPR_REF        branch/commit (default: main)
#   X_HYPR_MODE       full (default) | dotfiles (--dotfiles-only) | nvidia (--nvidia-only)
#   X_HYPR_SOURCE     alternative local path (for tests/dev; cleaned the same way)
#   X_HYPR_DRYRUN     1 = clone/clean and only print the command (tests)
#   X_HYPR_KEEP_SRC   1 = do not remove the temp copy

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

UPSTREAM_URL="https://github.com/xscriptor-colors/hyprland.git"
X_HYPR_REF="${X_HYPR_REF:-main}"

mode_flags() {
    case "${X_HYPR_MODE:-full}" in
        full) ;;
        dotfiles) printf -- '--dotfiles-only' ;;
        nvidia) printf -- '--nvidia-only' ;;
        *) error "invalid X_HYPR_MODE: ${X_HYPR_MODE} (full|dotfiles|nvidia)" ;;
    esac
}

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/x"
SRC="${X_HYPR_SOURCE:-}"
COMMIT="local"

if [[ -z "$SRC" ]]; then
    SRC="$(mktemp -d "$CACHE/hyprland.XXXXXX")"
    [[ "${X_HYPR_KEEP_SRC:-0}" != "1" ]] && trap 'rm -rf "$SRC"' EXIT
    log "cloning $UPSTREAM_URL (branch $X_HYPR_REF)"
    git clone -q --depth 1 --branch "$X_HYPR_REF" "$UPSTREAM_URL" "$SRC"
    COMMIT="$(git -C "$SRC" rev-parse --short HEAD)"
fi

rm -rf "$SRC/.git" "$SRC/.github"
log "source ready: $SRC (commit $COMMIT)"

if [[ "${X_HYPR_DRYRUN:-0}" == "1" ]]; then
    log "dry-run: install.sh $(mode_flags) at $SRC"
    exit 0
fi

INSTALLER="$SRC/install.sh"
[[ -f "$INSTALLER" ]] || error "install.sh not found in the external repo"
chmod +x "$INSTALLER" 2>/dev/null || true

read -r -a FLAGS < <(mode_flags)
log "running installer (mode=${X_HYPR_MODE:-full})"
if (( ${#FLAGS[@]} )); then
    bash "$INSTALLER" "${FLAGS[@]}"
else
    bash "$INSTALLER"
fi
log "Hyprland config installed"
