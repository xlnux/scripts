# x — tool de setup de Hyprland

`tools/hyprland-install.sh` es nuestro **setup de escritorio no interactivo**
para x. Aprovisiona el stack de Hyprland y sus configs para el **usuario
target** (se niega a correr como root; las operaciones root van por sudo). Lo
invoca la fase de usuario (`install/user.sh`, controlado por `X_HYPRLAND`,
default activado) y se puede ejecutar a mano.

Objetivos de diseño (ADR-0005):

- Las configs de escritorio viajan **offline** dentro del paquete `x-scripts` y
  se despliegan sin clonar nada en el momento del setup en un sistema
  instalado.
- Los repos externos siguen siendo la fuente de verdad y se usan **de solo
  lectura**, nunca se integran ni modifican.
- **NVIDIA se excluye a propósito aquí**: los drivers los configura la fase de
  hardware del sistema y ningún helper NVIDIA forma parte de la config vendida
  (el `gpu-mode.sh` basado en envycontrol se excluye en el lado upstream).

## Fuentes de verdad (externas, rama `main`)

| Repo | Contenido vendido |
|------|-------------------|
| `xscriptor-colors/hyprland` | `hypr`, `hypridle`, `rofi`, `dunst`, `cava`, `sddm`, `pam.d/quickshell` y `scripts` (scripts helper que caen en `~/.config/hypr/scripts`). |
| `xscriptor-colors/terminal` | solo kitty: `emulators/kitty/config` → `kitty.conf` más `emulators/kitty/themes/`. |
| `xscriptor-colors/nvim` | todo el árbol de config de nvim. |

El snapshot vendido vive en `/usr/share/x/config` en un sistema instalado (lo
produce `packaging/vendor-config.sh`; ver `packaging.md`). `config/hypr/` en
este repo es solo un punto de entrada documental más el wallpaper por defecto;
no es la config de escritorio en sí.

## Cómo funciona el tool

1. **Resuelve la fuente.**
   - Offline (default en un sistema instalado): usa el árbol empaquetado en
     `/usr/share/x/config`; no se clona nada.
   - Override: `X_HYPR_SOURCE=<checkout local de hyprland>` hace primero una
     copia (el árbol del llamante nunca se muta) y le quita `.git`/`.github` a
     la copia. Pensado para tests y desarrollo.
   - Fallback: si no hay ninguna de las anteriores (p.ej. un checkout de dev),
     clona `xscriptor-colors/hyprland` (`--depth 1`, rama `X_HYPR_REF`) a un
     dir temporal, le quita `.git`/`.github` y registra el commit. En este modo
     kitty/nvim solo vienen del árbol empaquetado (no se clonan).
2. **Paquetes.** Quita primero los `quickshell`/`swayosd` oficiales (la config
   apunta a las versiones `-git`), luego instala una lista oficial (stack
   Hyprland, xdg portals, qt5/qt6 wayland, sddm, rofi, kitty, dunst, pipewire,
   red, fuentes, ...) con `pacman -S --needed`, y paquetes AUR
   (`quickshell-git`, `swayosd-git`, `matugen-bin`, ...) vía un `yay`/`paru`
   existente, arrancando `yay` si no hay ninguno. Los fallos se avisan, no son
   fatales.
3. **Despliega configs** a `~/.config`: `hypr` (quitando cualquier `.conf`
   plano legacy), `rofi`, `dunst`, `cava`, `hypridle`, `scripts` (marcados
   ejecutables), más `kitty` y `nvim` cuando el árbol offline los aporta. Crea
   `~/Pictures/Screenshots`, `~/Pictures/Wallpapers` y escribe
   `~/.local/state/xshell-version`.
4. **Fuente.** Instala Hack Nerd Font para el usuario (descargada) y la copia a
   `/usr/share/fonts`.
5. **SDDM + PAM + servicios.** Instala el tema de SDDM `x` (desde la config),
   apunta `/etc/sddm.conf.d/10-x-theme.conf` a él, usa el wallpaper de x cuando
   está presente, genera/instala el `Colors.qml` derivado de la paleta (con un
   fallback para que SDDM nunca caiga al tema por defecto), instala la política
   PAM para `quickshell` y habilita NetworkManager, SDDM,
   power-profiles-daemon y los servicios de usuario de pipewire.
6. Imprime el cierre y pide reiniciar a SDDM → Hyprland.

## Flags / entorno

| Variable | Default | Significado |
|----------|---------|-------------|
| `X_HYPR_CONFIG` | `/usr/share/x/config` | Árbol de config empaquetado (offline). |
| `X_HYPR_SOURCE` | — | Override con checkout local de hyprland; se copia y limpia. |
| `X_HYPR_REF` | `main` | Rama/commit del fallback de clon en runtime. |
| `X_HYPR_DRYRUN` | `0` | `1` = resolver la fuente y solo imprimir el plan (sin instalar). |
| `X_HYPR_KEEP_SRC` | `0` | `1` = conservar la copia temporal en vez de borrarla. |

```bash
# solo plan, desde un checkout local/fake (sin cambios)
X_HYPR_DRYRUN=1 X_HYPR_SOURCE=/path/to/hyprland bash tools/hyprland-install.sh
# solo plan, árbol offline
X_HYPR_DRYRUN=1 X_HYPR_CONFIG=/usr/share/x/config bash tools/hyprland-install.sh
# setup completo para el usuario actual
bash tools/hyprland-install.sh
```

Ejecutar siempre como el usuario target; `X_HYPR_DRYRUN` y las rutas de
override de fuente las ejercita `test/smoke.sh` sin root.
