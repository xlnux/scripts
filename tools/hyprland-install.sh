#!/usr/bin/env bash
set -euo pipefail

# Instala la config de Hyprland desde el repo externo xscriptor-colors/hyprland.
# No modifica ni integra el repo origen: clona (solo main), limpia los
# metadatos git (.git/.github) de la copia temporal para no anidar repos y
# ejecuta el instalador documentado del propio repo.
#
# Variables:
#   X_HYPR_REF        rama/commit (default: main)
#   X_HYPR_MODE       full (default) | dotfiles (--dotfiles-only) | nvidia (--nvidia-only)
#   X_HYPR_SOURCE     ruta local alternativa (para pruebas/dev; se limpia igual)
#   X_HYPR_DRYRUN     1 = clonar/limpiar y solo mostrar el comando (tests)
#   X_HYPR_KEEP_SRC   1 = no borrar la copia temporal

source "$(dirname "${BASH_SOURCE[0]}")/../install/helpers/common.sh"

UPSTREAM_URL="https://github.com/xscriptor-colors/hyprland.git"
X_HYPR_REF="${X_HYPR_REF:-main}"

mode_flags() {
    case "${X_HYPR_MODE:-full}" in
        full) ;;
        dotfiles) printf -- '--dotfiles-only' ;;
        nvidia) printf -- '--nvidia-only' ;;
        *) error "X_HYPR_MODE invalido: ${X_HYPR_MODE} (full|dotfiles|nvidia)" ;;
    esac
}

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/x"
SRC="${X_HYPR_SOURCE:-}"
COMMIT="local"

if [[ -z "$SRC" ]]; then
    SRC="$(mktemp -d "$CACHE/hyprland.XXXXXX")"
    [[ "${X_HYPR_KEEP_SRC:-0}" != "1" ]] && trap 'rm -rf "$SRC"' EXIT
    log "clonando $UPSTREAM_URL (rama $X_HYPR_REF)"
    git clone -q --depth 1 --branch "$X_HYPR_REF" "$UPSTREAM_URL" "$SRC"
    COMMIT="$(git -C "$SRC" rev-parse --short HEAD)"
fi

rm -rf "$SRC/.git" "$SRC/.github"
log "origen listo: $SRC (commit $COMMIT)"

if [[ "${X_HYPR_DRYRUN:-0}" == "1" ]]; then
    log "dry-run: install.sh $(mode_flags) en $SRC"
    exit 0
fi

INSTALLER="$SRC/install.sh"
[[ -f "$INSTALLER" ]] || error "no se encontro install.sh en el repo externo"
chmod +x "$INSTALLER" 2>/dev/null || true

read -r -a FLAGS < <(mode_flags)
log "ejecutando instalador (mode=${X_HYPR_MODE:-full})"
if (( ${#FLAGS[@]} )); then
    bash "$INSTALLER" "${FLAGS[@]}"
else
    bash "$INSTALLER"
fi
log "config de Hyprland instalada"
