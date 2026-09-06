# x — Hyprland setup tool

`tools/hyprland-install.sh` is our own **non-interactive** desktop setup for x.
It provisions the Hyprland stack and its configs for the **target user** (it
refuses to run as root; root operations go through sudo). It is invoked by the
user phase (`install/user.sh`, gated by `X_HYPRLAND`, default on) and can be
run by hand.

Design goals (ADR-0005):

- The desktop configs ship **offline** inside the `x-scripts` package and are
  deployed without cloning anything at setup time on an installed system.
- The external repos remain the source of truth and are used **read-only**,
  never integrated or modified.
- **NVIDIA is intentionally not handled here**: the drivers are configured by
  the system hardware phase and no NVIDIA helper is part of the vendored
  config (the envycontrol-based `gpu-mode.sh` is excluded upstream-side).

## Sources of truth (external, branch `main`)

| Repo | Content vendored |
|------|------------------|
| `xscriptor-colors/hyprland` | `hypr`, `hypridle`, `rofi`, `dunst`, `cava`, `sddm`, `pam.d/quickshell` and `scripts` (helper scripts dropped into `~/.config/hypr/scripts`). |
| `xscriptor-colors/terminal` | kitty only: `emulators/kitty/config` → `kitty.conf` plus `emulators/kitty/themes/`. |
| `xscriptor-colors/nvim` | the whole nvim config tree. |

The vendored snapshot lives at `/usr/share/x/config` on an installed system
(produced by `packaging/vendor-config.sh`; see `packaging.md`). `config/hypr/`
in this repo is only a documentation entry point plus the default wallpaper;
it is not the desktop config itself.

## How the tool works

1. **Resolve the source.**
   - Offline (default on an installed system): uses the packaged tree at
     `/usr/share/x/config`; nothing is cloned.
   - Override: `X_HYPR_SOURCE=<local hyprland checkout>` makes a copy first
     (the caller's tree is never mutated) and strips `.git`/`.github` from the
     copy. Intended for tests and development.
   - Fallback: if neither is present (e.g. a dev checkout) it clones
     `xscriptor-colors/hyprland` (`--depth 1`, branch `X_HYPR_REF`) into a
     temp dir, strips `.git`/`.github` and records the commit. In this mode
     kitty/nvim come only from the packaged tree (they are not cloned).
2. **Packages.** Drops official `quickshell`/`swayosd` first (the config
   targets the `-git` versions), then installs an official list (Hyprland
   stack, xdg portals, qt5/qt6 wayland, sddm, rofi, kitty, dunst, pipewire,
   network, fonts, ...) with `pacman -S --needed`, and AUR packages
   (`quickshell-git`, `swayosd-git`, `matugen-bin`, ...) via an existing
   `yay`/`paru`, bootstrapping `yay` if none is found. Failures are warned, not
   fatal.
3. **Deploy configs** to `~/.config`: `hypr` (removing any legacy flat
   `.conf` files), `rofi`, `dunst`, `cava`, `hypridle`, `scripts`
   (made executable), plus `kitty` and `nvim` when the offline tree provides
   them. Creates `~/Pictures/Screenshots`, `~/Pictures/Wallpapers` and writes
   `~/.local/state/xshell-version`.
4. **Font.** Installs Hack Nerd Font for the user (downloaded) and copies it to
   `/usr/share/fonts`.
5. **SDDM + PAM + services.** Installs the SDDM theme `x` (from the config),
   points `/etc/sddm.conf.d/10-x-theme.conf` at it, uses the x wallpaper when
   present, generates/installs the palette-derived `Colors.qml` (with a
   fallback so SDDM never drops to the default theme), installs the PAM policy
   for `quickshell`, and enables NetworkManager, SDDM,
   power-profiles-daemon and the user pipewire services.
6. Prints completion and asks for a reboot into SDDM → Hyprland.

## Flags / environment

| Variable | Default | Meaning |
|----------|---------|---------|
| `X_HYPR_CONFIG` | `/usr/share/x/config` | Packaged (offline) config tree. |
| `X_HYPR_SOURCE` | — | Local hyprland checkout override; a copy is made and cleaned. |
| `X_HYPR_REF` | `main` | Branch/commit of the runtime-clone fallback. |
| `X_HYPR_DRYRUN` | `0` | `1` = resolve the source and print the plan only (no install). |
| `X_HYPR_KEEP_SRC` | `0` | `1` = keep the temporary copy instead of deleting it. |

```bash
# plan only, from a fake/local checkout (no changes)
X_HYPR_DRYRUN=1 X_HYPR_SOURCE=/path/to/hyprland bash tools/hyprland-install.sh
# plan only, offline tree
X_HYPR_DRYRUN=1 X_HYPR_CONFIG=/usr/share/x/config bash tools/hyprland-install.sh
# full setup for the current user
bash tools/hyprland-install.sh
```

Always run as the target user; `X_HYPR_DRYRUN` and the source-override paths
are exercised by `test/smoke.sh` without root.
