# x — Hyprland config

The Hyprland configuration of x is not versioned in the org: it is installed
**clean** from the external repo `xscriptor-colors/hyprland` (main branch
only, without modifying or integrating it).

## Installation

`install/user.sh` installs it by default (mode `full`) by delegating to
`tools/hyprland-install.sh`, which:

1. Clones the external repo into a temporary copy (default `main`).
2. Removes `.git`/`.github` from the copy to avoid nested repos.
3. Runs its documented `install.sh` (respects the `dotfiles`/`nvidia` modes).

Useful variables: `X_HYPRLAND=0` (do not install), `X_HYPR_MODE=dotfiles|nvidia`,
`X_HYPR_REF=<commit>` (pin a version).

## References

- ADR-0005 in `DECISIONS.md` at the workspace root.
