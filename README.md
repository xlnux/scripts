# x — scripts

Provisioning of the **x** system through scripts (Omarchy style, no graphical
installer). It lives alongside the distro in `xlnux/x` and the tooling in
`xpkg`/`xpm`/`x-repo` (see `AGENTS.md`/`DECISIONS.md` at the workspace root).

## Contents

- `install/` — phase orchestrators (config, hardware, login,
  post-install, user) and idempotent sync helpers.
- `skel/` + `etc/` + `config/` — dotfile seeds: `/etc/skel`, `/etc`
  drop-ins and `~/.config` (includes the Hyprland placeholder).
- `hardware/`, `tools/` — optional modules (NVIDIA, QEMU/libvirt, node).
- `test/` — local tests without root.

Structure and mechanics details in `docs/LAYOUT.md`.

## Usage

```bash
# CLI (from the repo or installed as /usr/bin/x)
bash bin/x help
bash bin/x setup            # system (root)
bash bin/x setup --user     # current user
bash bin/x theme set x-dark
bash bin/x migrate
bash bin/x update

# Direct per phase (equivalent)
sudo bash install/system.sh
X_NODE=1 bash install/user.sh
```

## Status

*reboot* initiative on the `x/reboot` branch. Phases and decisions in the
ROADMAP and DECISIONS at the workspace root `x-lnux`.

- Documentation: https://github.com/xlnux/wiki

`x setup --user --online` runs the original upstream Hyprland installer (clone in temp, run install.sh, cleanup).
WSL lives in its dedicated repos: xlnux/wsl and xlnux/wsl-scripts.
