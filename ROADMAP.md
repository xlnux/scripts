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

- [ ] CLI `x <grupo> <verbo>` por convención de nombres y metadatos en
      comentarios (sin registro central).
- [ ] Migraciones por usuario idempotentes (markers + timestamps) en `x update`.
- [ ] Temas por paleta (`colors`) + plantillas retintadas.

## WSL

- [ ] Unificar el bootstrap de `wsl/` con las fases del payload.

## Calidad

- [ ] Shellcheck en CI para todo `install/`, `hardware/`, `tools/`.
