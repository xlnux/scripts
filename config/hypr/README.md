# x — Hyprland configuration

The Hyprland configuration of x is NOT versioned in the org: it is installed
cleanly from the external repo `xscriptor-colors/hyprland` (branch `main`),
without modifying or integrating that repo.

## Installation

`tools/hyprland-install.sh` is our own non-interactive orchestrator. It:

1. Clones the external repo to a temp dir (default `main`) and strips
   `.git`/`.github`.
2. Installs required packages (Hyprland stack, rofi, kitty, pipewire, SDDM, ...).
3. Deploys the configs to `~/.config` (hypr, rofi, dunst, cava, hypridle,
   scripts), the SDDM theme, PAM for the lock screen and the font.
4. Optionally configures NVIDIA when detected.
5. Enables services (NetworkManager, SDDM, pipewire/wireplumber).

Environment flags:

- `X_HYPR_USER` — target user when running as root.
- `X_HYPR_NVIDIA=0` — skip NVIDIA setup.
- `X_HYPR_WALLPAPERS=1` — download the large wallpaper pack.
- `X_HYPR_REF` — branch/commit (default `main`).
- `X_HYPR_DRYRUN=1` — fetch/clean and print the plan only.

## References

- ADR-0005 in `DECISIONS.md` (workspace root).
