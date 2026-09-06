#!/usr/bin/env bash
set -euo pipefail

# Non-interactive Hyprland setup for X Linux.
#
# The external repo xscriptor-colors/hyprland (branch main) is used READ-ONLY
# as a source for configs: cloned to a temp dir, .git/.github stripped, and
# everything needed is installed/deployed. The external repo is never modified
# or committed.
#
# Runs as the TARGET USER (never as root): root operations go through sudo.
#
# Env:
#   X_HYPR_NVIDIA     auto-configure NVIDIA when detected (default: 1)
#   X_HYPR_WALLPAPERS download the 1.37GB wallpaper pack (default: 0)
#   X_HYPR_SOURCE     local copy override (for tests/dev)
#   X_HYPR_REF        branch/commit (default: main)
#   X_HYPR_DRYRUN     1 = fetch/cleanup and print the plan only
#   X_HYPR_KEEP_SRC   1 = keep the temp copy

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

if [[ "$(id -u)" -eq 0 ]]; then
    error "hyprland setup must run as the target user, not root"
fi

X_HYPR_REF="${X_HYPR_REF:-main}"
UPSTREAM_URL="https://github.com/xscriptor-colors/hyprland.git"

root() { sudo "$@"; }

# --- fetch source (in the user's own cache) ----------------------------------
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

# --- package split: official (repos) vs AUR -----------------------------------
OFFICIAL=(
    hyprland hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr qt5-wayland qt6-wayland qt5ct qt6ct
    polkit-kde-agent xorg-xwayland sddm rofi-wayland jq imagemagick librsvg
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
    adw-gtk3 bibata-cursor-theme mpvpaper quickshell-git swayosd-git
    hyprpolkitagent networkmanager-dmenu-git
)

echo "== official packages"
root pacman -S --needed --noconfirm "${OFFICIAL[@]}" || warn "some official packages failed"

if (( ${#AUR[@]} )); then
    HELPER=""
    has_cmd yay && HELPER="yay"
    has_cmd paru && HELPER="paru"

    if [[ -z "$HELPER" ]]; then
        echo "== installing yay (as user)"
        YAY_TMP="$(mktemp -d)"
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

# --- NVIDIA --------------------------------------------------------------
if [[ "${X_HYPR_NVIDIA:-1}" == "1" ]] && has_cmd lspci && lspci | grep -qi nvidia; then
    echo "== nvidia detected"
    case "$(uname -r)" in
        *lts*) HEADERS="linux-lts-headers" ;;
        *zen*) HEADERS="linux-zen-headers" ;;
        *)     HEADERS="linux-headers" ;;
    esac
    root pacman -S --needed --noconfirm "$HEADERS" nvidia-dkms nvidia-utils \
        nvidia-settings libva-nvidia-driver egl-wayland envycontrol || warn "nvidia packages failed"
    if has_cmd mkinitcpio && [[ -f /etc/mkinitcpio.conf ]] \
        && ! grep -q "nvidia nvidia_modeset" /etc/mkinitcpio.conf; then
        root sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        root mkinitcpio -P || true
    fi
    root bash -c 'echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf;
      echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf;
      echo "options nvidia-drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf'
    if [[ -d /boot/loader/entries ]]; then
        root bash -c 'for e in /boot/loader/entries/*.conf; do
          sed -i "/^options/ s/$/ nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1/" "$e"; done'
    fi
    if command -v grub-mkconfig >/dev/null 2>&1 && [[ -f /etc/default/grub ]]; then
        root sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1 /' /etc/default/grub
        root grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
    fi
    root bash -c 'systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null || true'
fi

# --- deploy configs (user-owned) ------------------------------------------
echo "== deploying configs to $HOME"
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR" "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers"

if [[ -d "$SRC/config/hypr" ]]; then
    mkdir -p "$CONFIG_DIR/hypr"
    cp -r "$SRC/config/hypr/." "$CONFIG_DIR/hypr/"
    rm -f "$CONFIG_DIR"/hypr/hyprland.conf "$CONFIG_DIR"/hypr/colors.conf \
        "$CONFIG_DIR"/hypr/animations.conf "$CONFIG_DIR"/hypr/autostart.conf \
        "$CONFIG_DIR"/hypr/env.conf "$CONFIG_DIR"/hypr/keybinds.conf \
        "$CONFIG_DIR"/hypr/theme.conf "$CONFIG_DIR"/hypr/windowrules.conf \
        "$CONFIG_DIR"/hypr/workspaces.conf
fi
for rel in rofi dunst cava hypridle; do
    [[ -d "$SRC/config/$rel" ]] && { mkdir -p "$CONFIG_DIR/$rel"; cp -r "$SRC/config/$rel/." "$CONFIG_DIR/$rel/"; }
done
if [[ -d "$SRC/scripts" ]]; then
    mkdir -p "$CONFIG_DIR/hypr/scripts"
    cp -r "$SRC/scripts/." "$CONFIG_DIR/hypr/scripts/"
    find "$CONFIG_DIR/hypr/scripts" -type f -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
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
fi
if [[ -f "$SRC/config/pam.d/quickshell" ]]; then
    root tee /etc/pam.d/quickshell < "$SRC/config/pam.d/quickshell" >/dev/null || true
fi
echo "== services"
root systemctl enable NetworkManager.service 2>/dev/null || true
root systemctl enable sddm.service 2>/dev/null || true
root systemctl enable power-profiles-daemon.service 2>/dev/null || true
root systemctl --global enable pipewire pipewire-pulse wireplumber 2>/dev/null || true

echo "hyprland setup complete. Reboot and select Hyprland in SDDM."
