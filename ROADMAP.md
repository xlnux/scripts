# scripts — ROADMAP

Payload de aprovisionamiento + CLI `x`. La planificacion principal vive en el
`ROADMAP.md` de la raiz del workspace (x-lnux).

## Hecho

- Payload por fases (`install/`), CLI (`x setup`, `theme`, `migrate`, `update`,
  `hardware`, `info`) y flag `x setup --user --online`.
- Configs de hyprland/kitty/nvim empaquetadas offline
  (`packaging/vendor-config.sh`); tool de hyprland sin NVIDIA (fase hardware).
- Docs en `docs/en` y `docs/es`; tambien en el repo wiki `xlnux/wiki`.

## Pendiente (auditoria)

- Clobber de `config.sh` (semantica de backup), LICENSE y deps del PKGBUILD,
  alias+subargs del CLI, unificacion de `wsl/`.

## Sincronizacion

No hay sincronizacion roadmap->issues (workflow eliminado).
