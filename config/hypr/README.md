# x — desktop configuration

The desktop configs of x ship **offline** inside the `x-scripts` package as a
vendored snapshot at `/usr/share/x/config`. No external repo is cloned at
setup time on an installed system.

The external repos **remain the source of truth** and their official installer
is [`equisdots/dots`](https://github.com/equisdots/dots):

- `equisdots/hyprland` (branch `main`) — Lua config (`hyprland.lua`,
  `hypridle.conf`, modules), `rofi`, `dunst`, `cava`, `pam.d`, `scripts/`.
- `equisdots/shell` (branch `main`) — Quickshell UI.
- `equisdots/palettes` (branch `main`) — palette JSON set + schema.
- `equisdots/theme-sync`, `equisdots/davincix`, `equisdots/timex` — engines.
- `equisdots/login` (branch `main`) — static SDDM greeter.
- `equisdots/dots` (branch `main`) — meta installer/updater.
- `xscriptor-colors/terminal` (branch `main`) — kitty + starship.
- `xscriptor-colors/nvim` (branch `main`) — nvim config.

They are used **read-only** and are never integrated or modified. NVIDIA is
owned by the X hardware phase: this tree only carries the complete snapshot so
`tools/hyprland-install.sh` can fall back to the upstream equisdots NVIDIA
setup (`--nvidia-only`) when a GPU is present without a driver.

## Vendored snapshot

`packaging/vendor-config.sh` regenerates `packaging/.vendor/x-config`
(git-ignored) from the repos above and prints a summary. The resolved commits
are pinned in `packaging/vendor-config.lock` (tracked), so re-runs reproduce the
same snapshot. `packaging/PKGBUILD` ships that tree at `/usr/share/x/config`
when it exists (no remote `source=()` entries: the snapshot is vendored, not
fetched at build time).

```
/usr/share/x/config
├── equisdots/
│   ├── dots/ hyprland/ shell/ palettes/ theme-sync/ davincix/ timex/ login/
├── kitty/     (kitty.conf + themes/)
├── starship/  (starship.toml + themes/)
└── nvim/      (whole config tree)
```

## Installation

`tools/hyprland-install.sh` is our own non-interactive orchestrator. It:

1. Prefers the **local packaged snapshot** at `/usr/share/x/config/equisdots`
   and deploys the whole stack from it (fully offline). If that tree is absent
   (e.g. a dev checkout) it clones `equisdots/dots` to a temp dir and runs the
   official `dots install` (online fallback).
2. Installs required packages (Hyprland stack, rofi, kitty, starship,
   pipewire, SDDM, ...) plus the AUR extras and the xwww wallpaper daemon.
3. Deploys the payload to `~/.config` (hypr, rofi, dunst, cava, scripts,
   quickshell, palettes), the `~/.local/bin` wrappers, kitty/starship/nvim,
   regenerates the palette artifacts with `theme-sync`, installs the login
   theme, PAM for the lock screen and the font.
4. Enables services (NetworkManager, SDDM, pipewire/wireplumber, ...).

Environment flags:

- `X_HYPR_CONFIG` — packaged config tree (default `/usr/share/x/config`).
- `X_HYPR_SOURCE` — snapshot root override (tests/dev; `$X_HYPR_SOURCE/equisdots`).
- `X_HYPR_REF` — branch/commit of the `equisdots/dots` clone fallback (default `main`).
- `X_HYPR_BASE` — equisdots data dir (default `~/.local/share/equisdots`).
- `X_HYPR_DRYRUN=1` — resolve the source and print the plan only.
- `X_HYPR_OFFLINE=1` — force offline; fail instead of cloning.
- `X_HYPR_KEEP_SRC=1` — keep the temporary clone.

## References

- ADR-0005 in `DECISIONS.md` (workspace root).
