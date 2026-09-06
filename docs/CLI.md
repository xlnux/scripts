# x — CLI

`x` is the system provisioning CLI (see the CLI concept in the conversation;
ADR-0003). It lives in `bin/` of this repo and will be installed as
`/usr/bin/x` when the payload is packaged.

## Commands

| Command | Description |
|---------|-------------|
| `x setup` | Provisions the system (root): config/hardware/login/post-install phases. |
| `x setup --user` | Provisioning of the current user (dotfiles + options). |
| `x theme list` | Lists available themes. |
| `x theme set <name>` | Applies a theme (palette) to the user. |
| `x migrate` | Runs the user's pending migrations. |
| `x update` | `pacman -Syu` + migrations. |
| `x hardware` | Hardware phase (detection + modules). |
| `x info` | System/environment info. |
| `x help` | Help. |

## Adding a command

Create `bin/x-<group>-<verb>.sh` (executable) with metadata in the header:

```bash
#!/usr/bin/env bash
# x:summary=one line
# x:args=[--option]
# x:aliases=alias1 alias2
# x:root=true
set -euo pipefail
```

- `x:summary` (used in `x help`).
- `x:aliases` optional (e.g. `theme` → `x-theme-list.sh`).
- `x:root=true` makes the dispatcher require root.

The dispatcher resolves by file name: `x theme set nord` → looks for
`x-theme-set.sh` (then `x-theme.sh`, then the `x.sh`-alias) and passes the
remaining arguments. There is no central registry: adding a command means
adding a file.

## State

`~/.local/state/x/` stores user state (applied migrations, active theme).
`~/.config/x/` stores generated user config (e.g. `theme.conf`).

## x setup --online

Runs the original `xscriptor-colors/hyprland` installer (the upstream
`./install.sh`) from a temporary clone, then cleans up. Use it when already
logged in and the offline packaged setup is not enough. It asks for the sudo
password when the upstream script needs it.

    x setup --user --online
