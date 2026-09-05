# x — scripts

Aprovisionamiento del sistema **x** por scripts (estilo Omarchy, sin
instalador gráfico). Convivencia con la distro en `xlnux/x` y el tooling en
`xpkg`/`xpm`/`x-repo` (ver `AGENTS.md`/`DECISIONS.md` del workspace).

## Contenido

- `install/` — orquestadores por fases (config, hardware, login,
  post-install, usuario) y helpers de sync idempotentes.
- `skel/` + `etc/` + `config/` — semillas de dotfiles: `/etc/skel`, drop-ins
  de `/etc` y `~/.config` (incluye el placeholder de Hyprland).
- `hardware/`, `tools/` — modulos opcionales (NVIDIA, QEMU/libvirt, node).
- `wsl/` — bootstrap WSL.
- `test/` — tests locales sin root.

Detalles de estructura y mecánica en `docs/LAYOUT.md`.

## Uso

```bash
# Provision del sistema (root)
sudo bash install/system.sh

# Provision del usuario actual (finalize)
X_NODE=1 bash install/user.sh
```

## Estado

Iniciativa *reboot* en rama `x/reboot`. Fases y decisiones en el ROADMAP y
DECISIONS de la raíz del workspace `x-lnux`.
