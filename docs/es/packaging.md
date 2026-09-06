# x — packaging

El payload de aprovisionamiento se empaqueta como **`x-scripts`** con un
**PKGBUILD + makepkg** plano en `packaging/`. (El tooling Rust `xpkg`/`xpm`
está fuera de alcance para el empaquetado por ahora; ver el ROADMAP del
workspace, Fase 4.)

## Construir `x-scripts`

`packaging/PKGBUILD` produce el paquete de Arch (`any`, depende de `bash`):

- Publica `bin`, `install`, `skel`, `etc`, `config`, `hardware`, `tools`,
  `migrations` y `themes` en **`/usr/share/x`**.
- Hace ejecutables todos los `*.sh` (y el dispatcher `x`) bajo
  `/usr/share/x/{bin,install,hardware,tools}`.
- Instala `/usr/bin/x` como symlink a `/usr/share/x/bin/x`.
- Si existe `packaging/.vendor/x-config`, sus contenidos se fusionan en
  `/usr/share/x/config` (el árbol de config offline que usa
  `tools/hyprland-install.sh`). **No hay entradas remotas en `source=()`**: el
  snapshot se vende en-repo y nunca se descarga en tiempo de build.

Metadatos de versión: `pkgver=0.1.0`, `pkgrel` sube por iteración (ahora 11 en
el PKGBUILD). En el directorio queda un artefacto de build sobrante
(`packaging/x-scripts-0.1.0-5-any.pkg.tar.zst`) obsoleto y git-ignored
(`*.pkg.tar.zst`); reconstruir produce el pkgrel actual.

Para construir (sin red respecto a las fuentes de config; el árbol vendido debe
estar presente primero, ver abajo):

```bash
cd packaging
makepkg   # requiere packaging/.vendor/x-config presente
```

`packaging/.gitignore` ignora `src/`, `pkg/`, `.vendor/` y los artefactos
construidos.

## `vendor-config.sh` — el snapshot offline

`packaging/vendor-config.sh` regenera el snapshot de config vendido en
**`packaging/.vendor/x-config`** desde los repos externos de origen (rama
`main`), que se usan de solo lectura y siguen siendo la fuente de verdad:

- `xscriptor-colors/hyprland` → `hypr`, `hypridle`, `rofi`, `dunst`, `cava`,
  `sddm`, `pam.d`, más `scripts` → `scripts`.
- `xscriptor-colors/terminal` → solo kitty (`kitty.conf` + `themes/`).
- `xscriptor-colors/nvim` → todo el árbol de `nvim`.

Comportamiento:

- Se niega a correr como root; exige `git` y acceso a red (clones shallow).
- Quita `.git`/`.github` de cada clon y del árbol final.
- **Excluye NVIDIA**: `scripts/gpu-mode.sh` (un wrapper envycontrol/Optimus) se
  elimina y el script verifica que ya no esté; nada relacionado con NVIDIA se
  vende ni configura.
- Nunca modifica los repos externos.
- Al terminar imprime los commits fijados de las tres fuentes y un conteo de
  archivos por directorio.

```bash
packaging/vendor-config.sh        # desde la raíz del repo
packaging/vendor-config.sh /path/to/repo
```

La salida `.vendor` está **git-ignored**, así que un mantenedor debe
(re)generarla antes de construir; no forma parte del historial de git.
`config/hypr/README.md` documenta el mismo flujo.

## Layout vendido

```
packaging/.vendor/x-config
├── hypr/ hypridle/ rofi/ dunst/ cava/ sddm/ pam.d/   ← repo hyprland
├── scripts/                                          ← repo hyprland (→ ~/.config/hypr/scripts)
├── kitty/                                            ← repo terminal (kitty.conf + themes/)
└── nvim/                                             ← repo nvim
```

Publicado por el PKGBUILD como `/usr/share/x/config`, replica el layout de
hyprland un nivel más arriba (`config/hypr` → `hypr`, `config/<rel>` →
`<rel>`, `scripts` → `scripts`), que es exactamente como lo consume
`tools/hyprland-install.sh`.

## Uso offline en la ISO

El sentido de vender es que un **escritorio Hyprland se pueda aprovisionar
offline** justo después de la instalación:

1. Un mantenedor ejecuta `vendor-config.sh` y construye `x-scripts` (snapshot
   embebido en el paquete).
2. La distro (`xlnux/x`) instala `x-scripts` en el target y ejecuta las fases
   root durante la instalación.
3. En el primer arranque la fase de usuario ejecuta
   `tools/hyprland-install.sh`, que encuentra `/usr/share/x/config` y despliega
   las configs **sin ningún clon externo**. La instalación de paquetes
   (oficial + AUR) es la única parte que necesita repo/red, porque las configs
   en sí viajan dentro del paquete.

Notas / estado actual (del ROADMAP del workspace):

- `x-base.packages` (la lista base legible por el builder) se publica pero
  todavía no tiene consumidor cableado en el builder de la distro.
- El mirror offline empaquetado del lado distro (instalación totalmente sin
  red) sigue siendo una mejora pendiente en `xlnux/x`.
