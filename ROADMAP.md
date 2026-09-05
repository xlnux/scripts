# x — scripts ROADMAP

El desarrollo se guía por el **ROADMAP del workspace** (`x-lnux/ROADMAP.md`).
Este fichero refleja los entregables que tocan a este repo.

## Fase 2 — Payload de aprovisionamiento (reboot)

- [x] Estructura por fases en `install/` (system.sh, config.sh, hardware.sh,
      login.sh, post-install.sh, user.sh) con helpers de sync idempotentes.
- [x] Semillas `skel/`, `etc/` y `config/` (con placeholder de Hyprland,
      ADR-0005).
- [x] Migrados los modulos legacy a `hardware/` (nvidia, qemu) y `tools/`
      (node); eliminado `x.sh` monolítico.
- [x] Lista `x-base.packages` legible por el builder.
- [x] Test local sin root (`test/smoke.sh`): sintaxis + helpers de sync.
- [ ] Envolver el payload en un paquete `x-scripts` con `xpkg` (Fase 4) y
      consumirlo desde la distro (Fase 5).

## Fase 3 — CLI x, migraciones y temas (reboot)

- [x] CLI `x` en `bin/` con despacho por convención de nombres y metadatos en
      comentarios (sin registro central). Comandos: setup, theme (list/set),
      migrate, update, hardware, info. Docs en `docs/CLI.md`.
- [x] Migraciones por usuario idempotentes (markers + timestamps) integradas
      en `x migrate` y `x update`.
- [x] Temas por paleta (`themes/<nombre>/colors`) aplicados por `x theme set`
      a `~/.config/x/theme.conf`.
- [x] Tests locales del CLI (despacho, migraciones, temas) en `test/smoke.sh`.
- [ ] Conectar la paleta del sistema con los consumidores reales (la config de
      Hyprland externa gestiona sus propias paletas).

## WSL

- [ ] Unificar el bootstrap de `wsl/` con las fases del payload.

## Calidad

- [ ] Shellcheck en CI para todo `install/`, `hardware/`, `tools/`.
