# x — scripts ROADMAP

Development is driven by the **workspace ROADMAP** (`x-lnux/ROADMAP.md`).
This file reflects the deliverables that belong to this repo.

## Phase 2 — Provisioning payload (reboot)

- [x] Phased structure under `install/` (system.sh, config.sh, hardware.sh,
      login.sh, post-install.sh, user.sh) with idempotent sync helpers.
- [x] `skel/`, `etc/` and `config/` seeds (with Hyprland placeholder,
      ADR-0005).
- [x] Legacy modules migrated to `hardware/` (nvidia, qemu) and `tools/`
      (node); monolithic `x.sh` removed.
- [x] `x-base.packages` list readable by the builder.
- [x] Local test without root (`test/smoke.sh`): syntax + sync helpers.
- [ ] Wrap the payload in an `x-scripts` package with `xpkg` (Phase 4) and
      consume it from the distro (Phase 5).

## Phase 3 — x CLI, migrations and themes (reboot)

- [x] `x` CLI in `bin/` with dispatch by naming convention and header-comment
      metadata (no central registry). Commands: setup, theme (list/set),
      migrate, update, hardware, info. Docs in `docs/CLI.md`.
- [x] Per-user idempotent migrations (markers + timestamps) wired into
      `x migrate` and `x update`.
- [x] Palette-based themes (`themes/<name>/colors`) applied by `x theme set`
      to `~/.config/x/theme.conf`.
- [x] Local CLI tests (dispatch, migrations, themes) in `test/smoke.sh`.
- [ ] Connect the system palette with the real consumers (the external
      Hyprland config manages its own palettes).

## WSL

- [ ] Unify the `wsl/` bootstrap with the payload phases.

## Quality

- [ ] Shellcheck in CI for all of `install/`, `hardware/`, `tools/`.
