#!/usr/bin/env bash
set -euo pipefail

# Non-interactive Hyprland setup for X Linux.
#
# The Hyprland/kitty/nvim configs ship OFFLINE inside the x-scripts package as
# a vendored snapshot at /usr/share/x/config (regenerated with
# packaging/vendor-config.sh). When that local tree exists it is used directly
# and NO external repo is cloned at setup time.
#
# The external repos (xscriptor-colors/hyprland, xscriptor-colors/terminal,
# xscriptor-colors/nvim, branch main) remain the source of truth and are used
# READ-ONLY. A runtime clone is kept only as a fallback when the local tree is
# absent (e.g. a dev checkout). NVIDIA is intentionally NOT configured here: it
# is handled by the system hardware phase to avoid driver conflicts, and no
# NVIDIA script is part of the vendored config.
#
# Runs as the TARGET USER (never as root): root operations go through sudo.
#
# Env:
#   X_HYPR_CONFIG     packaged config tree (default: /usr/share/x/config)
#   X_HYPR_SOURCE     local copy override (for tests/dev; a copy is made)
#   X_HYPR_REF        branch/commit of the runtime-clone fallback (default: main)
#   X_HYPR_DRYRUN     1 = resolve the source and print the plan only
#   X_HYPR_KEEP_SRC   1 = keep the temp copy

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

if [[ "$(id -u)" -eq 0 ]]; then
    error "hyprland setup must run as the target user, not root"
fi

X_HYPR_REF="${X_HYPR_REF:-main}"
X_HYPR_CONFIG="${X_HYPR_CONFIG:-/usr/share/x/config}"
UPSTREAM_URL="https://github.com/xscriptor-colors/hyprland.git"

root() { sudo "$@"; }

# --- resolve the config source (offline packaged tree first) ---------------
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/x"
mkdir -p "$CACHE"
SRC="${X_HYPR_SOURCE:-}"
COMMIT="local"
MODE=""
CFG=""

if [[ -n "$SRC" ]]; then
    # Never mutate the caller's source: work on a copy.
    COPY="$(mktemp -d "$CACHE/hyprland-copy.XXXXXX")"
    cp -a "$SRC/." "$COPY/"
    SRC="$COPY"
    rm -rf "$SRC/.git" "$SRC/.github"
    MODE="repo"
    log "source (override copy): $SRC"
elif [[ -d "$X_HYPR_CONFIG" ]]; then
    CFG="$X_HYPR_CONFIG"
    MODE="offline"
    log "offline configs found in packaged tree: $X_HYPR_CONFIG"
else
    SRC="$(mktemp -d "$CACHE/hyprland.XXXXXX")"
    [[ "${X_HYPR_KEEP_SRC:-0}" != "1" ]] && trap 'rm -rf "$SRC"' EXIT
    log "cloning $UPSTREAM_URL (branch $X_HYPR_REF)"
    git clone -q --depth 1 --branch "$X_HYPR_REF" "$UPSTREAM_URL" "$SRC"
    COMMIT="$(git -C "$SRC" rev-parse --short HEAD)"
    rm -rf "$SRC/.git" "$SRC/.github"
    MODE="repo"
    log "source ready: $SRC (commit $COMMIT)"
fi

# Per-mode source paths. The vendored tree mirrors the hyprland layout one
# level up: config/hypr -> hypr, config/<rel> -> <rel>, scripts -> scripts.
if [[ "$MODE" == "offline" ]]; then
    HYPR_SRC="$CFG/hypr"
    REL_SRC="$CFG"
    SCRIPTS_SRC="$CFG/scripts"
    SDDM_SRC="$CFG/sddm"
    PAM_SRC="$CFG/pam.d/quickshell"
    KITTY_SRC="$CFG/kitty"
    NVIM_SRC="$CFG/nvim"
else
    HYPR_SRC="$SRC/config/hypr"
    REL_SRC="$SRC/config"
    SCRIPTS_SRC="$SRC/scripts"
    SDDM_SRC="$SRC/config/sddm"
    PAM_SRC="$SRC/config/pam.d/quickshell"
    KITTY_SRC=""
    NVIM_SRC=""
fi

if [[ "${X_HYPR_DRYRUN:-0}" == "1" ]]; then
    if [[ "$MODE" == "offline" ]]; then
        log "dry-run: install deps + deploy configs from packaged tree $X_HYPR_CONFIG (offline) + sddm + services"
    else
        log "dry-run: install deps + deploy configs + sddm + services"
    fi
    exit 0
fi

# --- package split: official (repos) vs AUR -----------------------------------
OFFICIAL=(
    hyprland     hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr qt5-wayland qt6-wayland qt5ct qt6ct
    polkit-kde-agent hyprpolkitagent swayosd quickshell xorg-xwayland sddm
    rofi jq imagemagick librsvg
    kitty dunst grim slurp wl-clipboard cliphist brightnessctl pamixer
    playerctl hyprpicker libnotify iproute2 pciutils pavucontrol networkmanager
    pipewire pipewire-alsa pipewire-pulse wireplumber network-manager-applet
    blueman bluez bluez-utils xdg-utils xdg-user-dirs wget curl gnome-keyring
    seahorse libsecret noto-fonts noto-fonts-emoji papirus-icon-theme nautilus
    gvfs gvfs-mtp cava zbar fd ripgrep socat inotify-tools acpi iw lm_sensors
    bc python python-websockets qt6-websockets ffmpeg fastfetch wmctrl
    power-profiles-daemon lsp-plugins qt5-quickcontrols qt5-quickcontrols2
    qt5-graphicaleffects unzip
)

AUR=(
    bibata-cursor-theme mpvpaper networkmanager-dmenu-git
)

echo "== official packages"
root pacman -S --needed --noconfirm "${OFFICIAL[@]}" || warn "some official packages failed"

if (( ${#AUR[@]} )); then
    HELPER=""
    has_cmd yay && HELPER="yay"
    has_cmd paru && HELPER="paru"

    if [[ -z "$HELPER" ]]; then
        echo "== installing yay (as user)"
        root pacman -S --needed --noconfirm base-devel >/dev/null 2>&1 || true
        YAY_TMP="$(mktemp -d "$CACHE/yay.XXXXXX")"
        git clone -q https://aur.archlinux.org/yay.git "$YAY_TMP/yay"
        (cd "$YAY_TMP/yay" && makepkg -si --noconfirm) || warn "yay build failed"
        rm -rf "$YAY_TMP"
        has_cmd yay && HELPER="yay"
    fi

    if [[ -n "$HELPER" ]]; then
        for p in "${AUR[@]}"; do
            echo "== aur: $p ($HELPER)"
            "$HELPER" -S --needed --noconfirm "$p" || warn "aur package $p failed"
        done
    else
        warn "no AUR helper available; AUR packages skipped"
    fi
fi

# --- deploy configs (user-owned) ------------------------------------------
echo "== deploying configs to $HOME"
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR" "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers"

deploy_dir() { # src dst : copy the contents of src into dst
    local src="$1" dst="$2"
    [[ -d "$src" ]] || return 0
    mkdir -p "$dst"
    cp -r "$src/." "$dst/"
}

if [[ -d "$HYPR_SRC" ]]; then
    deploy_dir "$HYPR_SRC" "$CONFIG_DIR/hypr"
    rm -f "$CONFIG_DIR"/hypr/hyprland.conf "$CONFIG_DIR"/hypr/colors.conf \
        "$CONFIG_DIR"/hypr/animations.conf "$CONFIG_DIR"/hypr/autostart.conf \
        "$CONFIG_DIR"/hypr/env.conf "$CONFIG_DIR"/hypr/keybinds.conf \
        "$CONFIG_DIR"/hypr/theme.conf "$CONFIG_DIR"/hypr/windowrules.conf \
        "$CONFIG_DIR"/hypr/workspaces.conf
fi
for rel in rofi dunst cava hypridle; do
    deploy_dir "$REL_SRC/$rel" "$CONFIG_DIR/$rel"
done
if [[ -d "$SCRIPTS_SRC" ]]; then
    deploy_dir "$SCRIPTS_SRC" "$CONFIG_DIR/hypr/scripts"
    find "$CONFIG_DIR/hypr/scripts" -type f -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
fi
if [[ -n "$KITTY_SRC" && -d "$KITTY_SRC" ]]; then
    echo "== kitty config (offline)"
    deploy_dir "$KITTY_SRC" "$CONFIG_DIR/kitty"
fi
if [[ -n "$NVIM_SRC" && -d "$NVIM_SRC" ]]; then
    echo "== nvim config (offline)"
    deploy_dir "$NVIM_SRC" "$CONFIG_DIR/nvim"
fi
mkdir -p "$HOME/.local/state"
printf 'LOCAL_VERSION="x-1"\n' > "$HOME/.local/state/xshell-version"

# --- fonts -----------------------------------------------------------------
FONT="$HOME/.local/share/fonts/HackNerdFont-Regular.ttf"
if [[ ! -f "$FONT" ]]; then
    echo "== font"
    mkdir -p "$HOME/.local/share/fonts"
    wget -q -O "$FONT" \
        "https://raw.githubusercontent.com/xscriptor-colors/terminal/main/assets/fonts/HackNerdFont/HackNerdFont-Regular.ttf" \
        || warn "font download failed"
    fc-cache -f >/dev/null 2>&1 || true
fi
root bash -c "cp '$FONT' /usr/share/fonts/ 2>/dev/null; fc-cache -f >/dev/null 2>&1 || true" || true

# --- SDDM + PAM + services ------------------------------------------------
echo "== sddm theme"
if [[ -d "$SRC/config/sddm/themes/x" ]]; then
    root mkdir -p /usr/share/sddm/themes/x
    root cp -r "$SRC/config/sddm/themes/x/." /usr/share/sddm/themes/x/
    root mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=x\n' | root tee /etc/sddm.conf.d/10-x-theme.conf >/dev/null

    # Use the X system wallpaper as the login background.
    if [[ -f /usr/share/backgrounds/x/x-wallpaper.jpg ]]; then
        root cp /usr/share/backgrounds/x/x-wallpaper.jpg /usr/share/sddm/themes/x/wallpaper.jpg
    fi

    # The theme's QML needs Colors.qml (derived from the active palette).
    # Generate it when possible, otherwise install a fallback so SDDM does not
    # drop to the default theme.
    if [[ -x "$HOME/.config/hypr/scripts/sddm-colors.sh" ]]; then
        bash "$HOME/.config/hypr/scripts/sddm-colors.sh" >/dev/null 2>&1 || true
    fi
    if [[ -f "$HOME/.config/hypr/sddm-colors.qml" ]]; then
        root cp "$HOME/.config/hypr/sddm-colors.qml" /usr/share/sddm/themes/x/Colors.qml
    fi
    if [[ ! -f /usr/share/sddm/themes/x/Colors.qml ]]; then
        cat > /tmp/x-Colors.qml <<'EOF'
pragma Singleton
import QtQuick
QtObject {
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color mauve: "#f5c2e7"
    readonly property color blue: "#89b4fa"
    readonly property color red: "#f38ba8"
}
EOF
        root cp /tmp/x-Colors.qml /usr/share/sddm/themes/x/Colors.qml
    fi
fi
if [[ -f "$PAM_SRC" ]]; then
    root tee /etc/pam.d/quickshell < "$PAM_SRC" >/dev/null || true
fi
echo "== services"
root systemctl enable NetworkManager.service 2>/dev/null || true
root systemctl enable sddm.service 2>/dev/null || true
root systemctl enable power-profiles-daemon.service 2>/dev/null || true
root systemctl --global enable pipewire pipewire-pulse wireplumber 2>/dev/null || true

echo "hyprland setup complete. Reboot and select Hyprland in SDDM."
