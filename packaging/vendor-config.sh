#!/usr/bin/env bash
set -euo pipefail

# Vendors a snapshot of the user configs that ship inside the x-scripts
# package, so a Hyprland desktop can be provisioned OFFLINE after install
# (no cloning of external repos at setup time).
#
# The external config repos (branch main) are used READ-ONLY and remain the
# source of truth. This script only produces a copy at
# packaging/.vendor/x-config which packaging/PKGBUILD ships to
# /usr/share/x/config and tools/hyprland-install.sh deploys from when present.
#
# Vendored layout (packaging/.vendor/x-config):
#   hypr hypridle rofi dunst cava sddm pam.d scripts  <- xscriptor-colors/hyprland
#   kitty                                             <- xscriptor-colors/terminal (emulators/kitty only)
#   nvim                                              <- xscriptor-colors/nvim
#
# NVIDIA: nothing NVIDIA is vendored or configured. hyprland/scripts/gpu-mode.sh
# (an envycontrol/Optimus wrapper) is intentionally skipped; the remaining files
# are copied verbatim and never modified.
#
# Usage: packaging/vendor-config.sh [REPO_ROOT]
#   REPO_ROOT defaults to the repo root (parent of packaging/).
#   Refuses to run as root. Requires network access.

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [[ "$(id -u)" -eq 0 ]]; then
    error "vendor-config must not run as root"
fi

PACKAGING="$REPO_ROOT/packaging"
STAGE="$PACKAGING/.vendor/stage"
XCFG="$PACKAGING/.vendor/x-config"
BRANCH="main"

has_cmd git || error "git is required"

clone_src() { # name url -> prints commit
    local name="$1" url="$2" rev=""
    if [[ -d "$STAGE/$name" ]]; then
        rm -rf "$STAGE/$name"
    fi
    git clone -q --depth 1 --branch "$BRANCH" "$url" "$STAGE/$name"
    rev="$(git -C "$STAGE/$name" rev-parse --short HEAD)"
    rm -rf "$STAGE/$name/.git" "$STAGE/$name/.github"
    printf '%s' "$rev"
}

mkdir -p "$STAGE"
rm -rf "$XCFG"

log "cloning read-only config sources (branch $BRANCH) into $STAGE"
HYPR_REV="$(clone_src hyprland "https://github.com/xscriptor-colors/hyprland.git")"
TERM_REV="$(clone_src terminal "https://github.com/xscriptor-colors/terminal.git")"
NVIM_REV="$(clone_src nvim "https://github.com/xscriptor-colors/nvim.git")"

echo "== normalizing into $XCFG"

install_dir() { # src dst : copy the contents of src into dst (if src is a dir)
    if [[ -d "$1" ]]; then
        mkdir -p "$2"
        cp -a "$1/." "$2/"
    fi
}

# xscriptor-colors/hyprland: config/* maps to the matching name.
install_dir "$STAGE/hyprland/config/hypr"    "$XCFG/hypr"
install_dir "$STAGE/hyprland/config/hypridle" "$XCFG/hypridle"
install_dir "$STAGE/hyprland/config/rofi"    "$XCFG/rofi"
install_dir "$STAGE/hyprland/config/dunst"   "$XCFG/dunst"
install_dir "$STAGE/hyprland/config/cava"    "$XCFG/cava"
install_dir "$STAGE/hyprland/config/sddm"    "$XCFG/sddm"
install_dir "$STAGE/hyprland/config/pam.d"   "$XCFG/pam.d"

# hyprland/scripts are helper scripts upstream drops into ~/.config/hypr/scripts.
install_dir "$STAGE/hyprland/scripts" "$XCFG/scripts"
rm -f "$XCFG/scripts/gpu-mode.sh" # NVIDIA/envycontrol wrapper: excluded

# xscriptor-colors/terminal: only the kitty emulator config is vendored.
# emulators/kitty/config becomes kitty.conf; themes/*.conf land under themes/.
mkdir -p "$XCFG/kitty/themes"
if [[ -f "$STAGE/terminal/emulators/kitty/config" ]]; then
    cp -a "$STAGE/terminal/emulators/kitty/config" "$XCFG/kitty/kitty.conf"
fi
install_dir "$STAGE/terminal/emulators/kitty/themes" "$XCFG/kitty/themes"

# xscriptor-colors/nvim: whole config tree (what upstream clones to ~/.config/nvim).
install_dir "$STAGE/nvim" "$XCFG/nvim"

rm -rf "$STAGE"

echo "== verify: no .git/.github or nvidia driver remnants"
if [[ -n "$(find "$XCFG" \( -name .git -o -name .github \) -print -quit)" ]]; then
    error "vendored tree still contains .git/.github"
fi
if [[ -e "$XCFG/scripts/gpu-mode.sh" ]]; then
    error "NVIDIA helper gpu-mode.sh is still present"
fi

echo
echo "vendored config snapshot ready: $XCFG"
printf 'sources: hyprland@%s terminal@%s nvim@%s (branch %s)\n' \
    "$HYPR_REV" "$TERM_REV" "$NVIM_REV" "$BRANCH"
for d in hypr rofi dunst cava hypridle sddm pam.d scripts kitty nvim; do
    printf '  %-10s %4s file(s)\n' "$d" "$(find "$XCFG/$d" -type f 2>/dev/null | wc -l | tr -d ' ')"
done
echo "regenerate the package snapshot with: packaging/vendor-config.sh"
