#!/usr/bin/env bash
set -euo pipefail

# Non-interactive Hyprland setup for X Linux.
#
# Uses the external repo xscriptor-colors/hyprland (branch main) as a READ-ONLY
# source for configs: it clones it to a temp dir, strips .git/.github and
# deploys what is needed, installing required packages. The external repo is
# never modified nor committed.
#
# Env:
#   X_HYPR_USER       target user when running as root (default: $USER)
#   X_HYPR_NVIDIA     auto-configure NVIDIA when detected (default: 1)
#   X_HYPR_WALLPAPERS download the 1.37GB wallpaper pack (default: 0)
#   X_HYPR_SOURCE     local copy override (for tests/dev)
#   X_HYPR_DRYRUN     1 = fetch/cleanup and print plan only
#   X_HYPR_KEEP_SRC   1 = keep the temp copy

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

UPSTREAM_URL="https://github.com/xscriptor-colors/hyprland.git"
X_HYPR_REF="${X_HYPR_REF:-main}"

if [[ "$(id -u)" -eq 0 ]]; then
    TARGET_USER="${X_HYPR_USER:-$(x_target_user)}"
else
    TARGET_USER="$(id -un)"
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$TARGET_HOME" ]] || error "cannot resolve home for $TARGET_USER"

log "hyprland setup for user $TARGET_USER ($TARGET_HOME)"

# --- fetch source -----------------------------------------------------------
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/x"
mkdir -p "$CACHE"
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
    log "dry-run: install deps + deploy configs + sddm + services"
    exit 0
fi

# --- official packages ------------------------------------------------------
PAC_OFFICIAL=(
    hyprland hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr qt5-wayland qt6-wayland qt5ct qt6ct
    polkit-kde-agent xorg-xwayland sddm
    rofi-wayland jq imagemagick librsvg kitty dunst grim slurp wl-clipboard
    cliphist brightnessctl pamixer playerctl hyprpicker libnotify iproute2
    pciutils pavucontrol networkmanager pipewire pipewire-alsa pipewire-pulse
    wireplumber network-manager-applet blueman bluez bluez-utils xdg-utils
    xdg-user-dirs wget curl gnome-keyring seahorse libsecret noto-fonts
    noto-fonts-emoji adw-gtk3 papirus-icon-theme bibata-cursor-theme nautilus
    gvfs gvfs-mtp cava zbar fd ripgrep socat inotify-tools acpi iw lm_sensors
    bc python python-websockets qt6-websockets ffmpeg fastfetch yq mpvpaper
    wmctrl power-profiles-daemon lsp-plugins gpu-screen-recorder qt5-quickcontrols
    qt5-quickcontrols2 qt5-graphicaleffects unzip
)

# AUR packages (installed via yay, non-fatal individually).
PAC_AUR=(quickshell-git swayosd-git hyprpolkitagent networkmanager-dmenu-git)

echo "== packages (official)"
run_privileged pacman -S --needed --noconfirm "${PAC_OFFICIAL[@]}" || warn "some official packages failed"

if (( ${#PAC_AUR[@]} )); then
    echo "== ensuring yay"
    if ! has_cmd yay && ! has_cmd paru; then
        run_privileged pacman -S --needed --noconfirm git base-devel >/dev/null 2>&1 || true
        YAY_TMP="$(mktemp -d)"
        git clone -q https://aur.archlinux.org/yay.git "$YAY_TMP/yay"
        (cd "$YAY_TMP/yay" && makepkg -si --noconfirm) || warn "yay build failed"
        rm -rf "$YAY_TMP"
    fi
    HELPER="paru"
    has_cmd yay && HELPER="yay"
    for p in "${PAC_AUR[@]}"; do
        echo "== aur: $p"
        run_privileged "$HELPER" -S --needed --noconfirm "$p" || warn "aur package $p failed"
    done
fi

# --- NVIDIA -----------------------------------------------------------------
if [[ "${X_HYPR_NVIDIA:-1}" == "1" ]] && has_cmd lspci && lspci | grep -qi nvidia; then
    echo "== nvidia detected"
    KERNEL="$(uname -r | sed 's/-.*//')"
    if [[ "$(uname -r)" == *lts* ]]; then
        HEADERS="linux-lts-headers"
    elif [[ "$(uname -r)" == *zen* ]]; then
        HEADERS="linux-zen-headers"
    else
        HEADERS="linux-headers"
    fi
    run_privileged pacman -S --needed --noconfirm "$HEADERS" nvidia-dkms nvidia-utils \
        nvidia-settings libva-nvidia-driver egl-wayland envycontrol || warn "nvidia packages failed"
    # mkinitcpio modules
    if has_cmd mkinitcpio && [[ -f /etc/mkinitcpio.conf ]]; then
        if ! grep -q "nvidia nvidia_modeset" /etc/mkinitcpio.conf; then
            run_privileged sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        fi
    fi
    # blacklist nouveau + drm modeset
    run_privileged bash -c 'echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf;
      echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf;
      echo "options nvidia-drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf'
    # bootloader params (systemd-boot entries first)
    if [[ -d /boot/loader/entries ]]; then
        run_privileged bash -c 'grep -rl "" /boot/loader/entries/ | while read -r e; do
          sed -i "/^options/ s/$/ nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1/" "$e"; done'
    fi
    if command -v grub-mkconfig >/dev/null 2>&1 && [[ -f /etc/default/grub ]]; then
        run_privileged sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1 /' /etc/default/grub
        run_privileged grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
    fi
    run_privileged bash -c 'systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null || true'
fi

# --- deploy configs ----------------------------------------------------------
echo "== deploying configs to $TARGET_HOME"
CONFIG_DIR="$TARGET_HOME/.config"
run_home() { # run as target user
    if [[ "$(id -u)" -eq 0 && "$TARGET_USER" != "root" ]]; then
        runuser -u "$TARGET_USER" -- "$@"
    else
        "$@"
    fi
}
run_home mkdir -p "$CONFIG_DIR"

deploy_tree() {
    local src="$1" rel="$2"
    [[ -d "$src" ]] || return 0
    run_home cp -r "$src/." "$CONFIG_DIR/$rel/"
}

# hypr config + modules
if [[ -d "$SRC/config/hypr" ]]; then
    run_home mkdir -p "$CONFIG_DIR/hypr"
    run_home cp -r "$SRC/config/hypr/." "$CONFIG_DIR/hypr/"
    # drop legacy hyprlang leftovers
    run_home bash -c 'rm -f "$HOME"/.config/hypr/hyprland.conf "$HOME"/.config/hypr/colors.conf \
      "$HOME"/.config/hypr/animations.conf "$HOME"/.config/hypr/autostart.conf \
      "$HOME"/.config/hypr/env.conf "$HOME"/.config/hypr/keybinds.conf \
      "$HOME"/.config/hypr/theme.conf "$HOME"/.config/hypr/windowrules.conf \
      "$HOME"/.config/hypr/workspaces.conf'
fi
deploy_tree "$SRC/config/rofi" rofi
deploy_tree "$SRC/config/dunst" dunst
deploy_tree "$SRC/config/cava" cava
deploy_tree "$SRC/config/hypridle" hypridle

if [[ -d "$SRC/scripts" ]]; then
    run_home mkdir -p "$CONFIG_DIR/hypr/scripts"
    run_home cp -r "$SRC/scripts/." "$CONFIG_DIR/hypr/scripts/"
    run_home bash -c 'find "$HOME/.config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true'
fi

# screenshots dirs
run_home mkdir -p "$TARGET_HOME/Pictures/Screenshots" "$TARGET_HOME/Pictures/Wallpapers"

# version marker
run_home bash -c 'mkdir -p "$HOME/.local/state"; printf "LOCAL_VERSION=\"x-1\"\n" > "$HOME/.local/state/xshell-version"'

# --- fonts ------------------------------------------------------------------
echo "== font"
if [[ ! -f "$TARGET_HOME/.local/share/fonts/HackNerdFont-Regular.ttf" ]]; then
    run_home mkdir -p "$TARGET_HOME/.local/share/fonts"
    run_home wget -q -O "$TARGET_HOME/.local/share/fonts/HackNerdFont-Regular.ttf" \
        "https://raw.githubusercontent.com/xscriptor-colors/terminal/main/assets/fonts/HackNerdFont/HackNerdFont-Regular.ttf" || warn "font download failed"
    run_home fc-cache -f >/dev/null 2>&1 || true
fi
run_privileged bash -c 'cp "$1" /usr/share/fonts/ 2>/dev/null; fc-cache -f >/dev/null 2>&1 || true' _ "$TARGET_HOME/.local/share/fonts/HackNerdFont-Regular.ttf" || true

# --- SDDM -------------------------------------------------------------------
echo "== sddm theme"
if [[ -d "$SRC/config/sddm/themes/x" ]]; then
    run_privileged mkdir -p /usr/share/sddm/themes/x
    run_privileged cp -r "$SRC/config/sddm/themes/x/." /usr/share/sddm/themes/x/
    run_privileged mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=x\n' | run_privileged tee /etc/sddm.conf.d/10-x-theme.conf >/dev/null
fi

# --- PAM (quickshell lock) ---------------------------------------------------
if [[ -f "$SRC/config/pam.d/quickshell" ]]; then
    run_privileged tee /etc/pam.d/quickshell < "$SRC/config/pam.d/quickshell" >/dev/null || true
fi

# --- services ----------------------------------------------------------------
echo "== services"
run_privileged systemctl enable NetworkManager.service 2>/dev/null || true
run_privileged systemctl enable sddm.service 2>/dev/null || true
run_privileged systemctl enable power-profiles-daemon.service 2>/dev/null || true
run_privileged systemctl --global enable pipewire pipewire-pulse wireplumber 2>/dev/null || true

echo "hyprland setup complete (user $TARGET_USER). Reboot and select Hyprland in SDDM."
