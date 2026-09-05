#!/usr/bin/env bash
# x:summary=Aplica un tema (paleta) al usuario
# x:args=<nombre>
# x:root=false
set -euo pipefail

# Los temas viven en themes/<nombre>/colors (clave=hex). Aplicar un tema
# instala esa paleta como ~/.config/x/theme.conf (con backup) y registra el
# tema activo en ~/.local/state/x/theme. Los consumidores reales (Hyprland,
# shell, ...) leen de ahi.

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEMES_DIR="${X_THEMES_DIR:-$X_ROOT/themes}"
STATE_DIR="${X_STATE_DIR:-$HOME/.local/state/x}"
CONF_OUT="${X_THEME_CONF:-$HOME/.config/x/theme.conf}"

if [[ $# -ne 1 ]]; then
    echo "uso: x theme set <nombre>" >&2
    exit 1
fi

NAME="$1"
PALETTE="$THEMES_DIR/$NAME/colors"

if [[ ! -f "$PALETTE" ]]; then
    echo "x theme: tema no encontrado: $NAME" >&2
    exit 1
fi

mkdir -p "$(dirname "$CONF_OUT")" "$STATE_DIR"

if [[ -e "$CONF_OUT" ]] && ! cmp -s "$PALETTE" "$CONF_OUT"; then
    cp -p "$CONF_OUT" "$CONF_OUT.bak.$(date +%Y%m%d%H%M%S)"
fi
cp -p "$PALETTE" "$CONF_OUT"

printf '%s\n' "$NAME" > "$STATE_DIR/theme"
echo "x theme: tema activo: $NAME"
