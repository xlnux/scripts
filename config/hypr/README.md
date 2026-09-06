# x — Hyprland configuration

The Hyprland/kitty/nvim configs of x ship **offline** inside the `x-scripts`
package as a vendored snapshot at `/usr/share/x/config`. No external repo is
cloned at setup time on an installed system.

The external repos **remain the source of truth**:

- `xscriptor-colors/hyprland` (branch `main`) — hypr, hypridle, rofi, dunst,
  cava, sddm, pam.d, `scripts/`.
- `xscriptor-colors/terminal` (branch `main`) — kitty config (`emulators/kitty`).
- `xscriptor-colors/nvim` (branch `main`) — nvim config.

They are used **read-only** and are never integrated or modified. NVIDIA is
explicitly excluded: nothing NVIDIA-related is vendored (e.g. the
envycontrol-based `gpu-mode.sh` helper is skipped) and this tool never
configures NVIDIA — that is the job of the system hardware phase.

## Vendored snapshot

`packaging/vendor-config.sh` regenerates `packaging/.vendor/x-config`
(git-ignored) from the repos above and prints a summary. `packaging/PKGBUILD`
ships that tree at `/usr/share/x/config` when it exists (no remote `source=()`
entries: the snapshot is vendored, not fetched at build time).

```
/usr/share/x/config
├── hypr/ hypridle/ rofi/ dunst/ cava/ sddm/ pam.d/   ← hyprland repo
├── scripts/                                          ← hyprland repo (→ ~/.config/hypr/scripts)
├── kitty/                                            ← terminal repo (kitty.conf + themes/)
└── nvim/                                             ← nvim repo
```

## Installation

`tools/hyprland-install.sh` is our own non-interactive orchestrator. It:

1. Prefers the **local packaged tree** at `/usr/share/x/config` and deploys
   from it (fully offline). If that tree is absent (e.g. a dev checkout) it
   falls back to cloning `xscriptor-colors/hyprland` to a temp dir and
   stripping `.git`/`.github`.
2. Installs required packages (Hyprland stack, rofi, kitty, pipewire, SDDM, ...).
3. Deploys the configs to `~/.config` (hypr, rofi, dunst, cava, hypridle,
   scripts), kitty and nvim, the SDDM theme, PAM for the lock screen and the
   font.
4. Enables services (NetworkManager, SDDM, pipewire/wireplumber).

Environment flags:

- `X_HYPR_CONFIG` — packaged config tree (default `/usr/share/x/config`).
- `X_HYPR_SOURCE` — local hyprland checkout override (tests/dev; a copy is made).
- `X_HYPR_REF` — branch/commit of the runtime-clone fallback (default `main`).
- `X_HYPR_DRYRUN=1` — resolve the source and print the plan only.
- `X_HYPR_KEEP_SRC=1` — keep the temp copy.

## References

- ADR-0005 in `DECISIONS.md` (workspace root).
