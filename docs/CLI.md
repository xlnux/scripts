# x — CLI

`x` es el CLI de aprovisionamiento del sistema (ver concepto de CLI en la
conversacion; ADR-0003). Vive en `bin/` de este repo y se instalara como
`/usr/bin/x` al empaquetar el payload.

## Comandos

| Comando | Descripcion |
|---------|-------------|
| `x setup` | Aprovisiona el sistema (root): fases config/hardware/login/post-install. |
| `x setup --user` | Provision del usuario actual (dotfiles + opciones). |
| `x theme list` | Lista temas disponibles. |
| `x theme set <nombre>` | Aplica un tema (paleta) al usuario. |
| `x migrate` | Ejecuta migraciones pendientes del usuario. |
| `x update` | `pacman -Syu` + migraciones. |
| `x hardware` | Fase de hardware (deteccion + modulos). |
| `x info` | Info del sistema/entorno. |
| `x help` | Ayuda. |

## Anadir un comando

Crear `bin/x-<grupo>-<verbo>.sh` (ejecutable) con metadatos en el encabezado:

```bash
#!/usr/bin/env bash
# x:summary=una linea
# x:args=[--opcion]
# x:aliases=alias1 alias2
# x:root=true
set -euo pipefail
```

- `x:summary` (usado en `x help`).
- `x:aliases` opcional (p. ej. `theme` → `x-theme-list.sh`).
- `x:root=true` hace que el despachador exija root.

El despachador resuelve por el nombre del fichero: `x theme set nord` → busca
`x-theme-set.sh` (despues `x-theme.sh`, luego `x.sh`-alias) y pasa el resto de
argumentos. No hay registro central: anadir un comando = anadir un archivo.

## Estado

`~/.local/state/x/` guarda estado del usuario (migraciones aplicadas, tema
activo). `~/.config/x/` guarda la config de usuario generada (p. ej.
`theme.conf`).
