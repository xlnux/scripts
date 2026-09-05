# x — config de Hyprland

La configuracion de Hyprland de x no se versiona en la org: se instala de
forma **limpia** desde el repo externo `xscriptor-colors/hyprland` (solo rama
`main`, sin modificarlo ni integrarlo).

## Instalacion

`install/user.sh` la instala por defecto (modo `full`) delegando en
`tools/hyprland-install.sh`, que:

1. Clona el repo externo en una copia temporal (por defecto `main`).
2. Elimina `.git`/`.github` de la copia para no anidar repos.
3. Ejecuta su `install.sh` documentado (respeta modos `dotfiles`/`nvidia`).

Variables utiles: `X_HYPRLAND=0` (no instalar), `X_HYPR_MODE=dotfiles|nvidia`,
`X_HYPR_REF=<commit>` (fijar version).

## Referencias

- ADR-0005 en `DECISIONS.md` del workspace.

