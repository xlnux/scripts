# x — scripts (layout)

Repo de **aprovisionamiento** del sistema x (vía scripts, sin instalador
gráfico; ver ADR-0001/ADR-0003 en `DECISIONS.md` del workspace).

## Arbol

| Ruta | Papel |
|------|-------|
| `install/` | Orquestadores del aprovisionamiento por fases. |
| `install/helpers/` | Librerias bash: `common.sh` (log/privilegios/root) y `sync.sh` (sync de arboles idempotente). |
| `install/system.sh` | Entry root: encadena `config.sh` → `hardware.sh` → `login.sh` → `post-install.sh`. |
| `install/config.sh` | Root: siembra `/etc/skel` desde `skel/` y aplica el overlay de `/etc` desde `etc/`. |
| `install/hardware.sh` | Root: detecta/ejecuta los modulos de `hardware/`. |
| `install/login.sh` | Root: servicios base (NetworkManager, ...). |
| `install/post-install.sh` | Root: branding final (se integrara con `x-release`). |
| `install/user.sh` | Provision de usuario (delega en `user-seed.sh` si corre como root). |
| `install/user-seed.sh` | Siembra el home: `x_seed_home` desde `/etc/skel` y `x_sync_config` de `config/` a `~/.config`. |
| `install/x-base.packages` | Lista de paquetes base legible por el builder (uno por linea). |
| `skel/` | Seed de `/etc/skel` para usuarios nuevos. |
| `etc/` | Drop-ins de `/etc` (sysctl.d, tmpfiles.d, ...). Un dir por ruta. |
| `config/` | Dotfiles de usuario que se sincronizan a `~/.config` (con backup). `hypr/` es un placeholder pendiente del repo de config del mantenedor (ADR-0005). |
| `hardware/` | Modulos autocontenidos: `nvidia.sh`, `qemu.sh`. |
| `tools/` | Toolchains opcionales por usuario (ej. `node.sh` con fnm). |
| `wsl/` | Bootstrap WSL (conservado; se unificara con el payload mas adelante). |
| `test/` | Tests locales sin root. |

## Mecanica (ADR-0003)

- Fases root y de usuario separadas; cada fase es un script invocable.
- Capas del home: seed `/etc/skel` (instalacion) → `x_seed_home` (solo lo que
  falta) → `x_sync_config` con backup `.bak.<ts>`.
- Todos los scripts son idempotentes; los ficheros modificados por el usuario
  no se pisan sin dejar backup.

## Uso

- Como root (durante la instalacion/ISO o en un sistema ya instalado):
  `bash install/system.sh`.
- Como usuario (finalize): `X_NODE=1 bash install/user.sh`.
- Extras opcionales: `X_HW_NVIDIA=1 X_HW_QEMU=1` para forzar modulos de
  hardware.
