# x — scripts (layout)

**Provisioning** repo of the x system (via scripts, no graphical installer;
see ADR-0001/ADR-0003 in `DECISIONS.md` at the workspace root).

## Tree

| Path | Role |
|------|------|
| `bin/` | `x` CLI (dispatcher + `x-*.sh` subcommands by convention). See `docs/CLI.md`. |
| `install/` | Provisioning orchestrators per phase. |
| `install/helpers/` | Bash libraries: `common.sh` (log/privileges/root) and `sync.sh` (idempotent tree sync). |
| `install/system.sh` | Root entry: chains `config.sh` → `hardware.sh` → `login.sh` → `post-install.sh`. |
| `install/config.sh` | Root: seeds `/etc/skel` from `skel/` and applies the `/etc` overlay from `etc/`. |
| `install/hardware.sh` | Root: detects/runs the modules under `hardware/`. |
| `install/login.sh` | Root: base services (NetworkManager, ...). |
| `install/post-install.sh` | Root: final branding (will integrate with `x-release`). |
| `install/user.sh` | User provisioning (delegates to `user-seed.sh` when run as root). |
| `install/user-seed.sh` | Seeds the home: `x_seed_home` from `/etc/skel` and `x_sync_config` from `config/` to `~/.config`. |
| `install/x-base.packages` | Base package list readable by the builder (one per line). |
| `skel/` | `/etc/skel` seed for new users. |
| `etc/` | `/etc` drop-ins (sysctl.d, tmpfiles.d, ...). One dir per path. |
| `config/` | User dotfiles synced to `~/.config` (with backup). `hypr/` points to the external repo `xscriptor-colors/hyprland` (ADR-0005), installed via `tools/hyprland-install.sh`. |
| `migrations/` | Per-user idempotent migrations (`<timestamp>-<name>.sh`), applied by `x migrate`. |
| `themes/` | Theme store: `themes/<name>/colors` (key=hex), applied by `x theme set`. |
| `hardware/` | Self-contained modules: `nvidia.sh`, `qemu.sh`. |
| `tools/` | Optional per-user toolchains/installers: `node.sh` (fnm), `hyprland-install.sh` (Hyprland config from external repo). |
| `wsl/` | WSL bootstrap (kept; will be unified with the payload later). |
| `test/` | Local tests without root. |

## Mechanics (ADR-0003)

- Root and user phases are separate; each phase is an invocable script.
- Home layers: seed `/etc/skel` (install) → `x_seed_home` (only what is
  missing) → `x_sync_config` with `.bak.<ts>` backup.
- All scripts are idempotent; files modified by the user are not overwritten
  without leaving a backup.

## Usage

- As root (during the install/ISO or on an already installed system):
  `bash install/system.sh`.
- As user (finalize): `X_NODE=1 bash install/user.sh`.
- Optional extras: `X_HW_NVIDIA=1 X_HW_QEMU=1` to force hardware modules.
