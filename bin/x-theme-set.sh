#!/usr/bin/env bash
# x:summary=Applies a theme (palette) to the user
# x:args=<name>
# x:root=false
set -euo pipefail

# Themes live in themes/<name>/colors (key=hex). Applying a theme
# installs that palette as ~/.config/x/theme.conf (with a backup) and records the
# active theme in ~/.local/state/x/theme. The real consumers (Hyprland,
# shell, ...) read from there.

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEMES_DIR="${X_THEMES_DIR:-$X_ROOT/themes}"
STATE_DIR="${X_STATE_DIR:-$HOME/.local/state/x}"
CONF_OUT="${X_THEME_CONF:-$HOME/.config/x/theme.conf}"

if [[ $# -ne 1 ]]; then
    echo "usage: x theme set <name>" >&2
    exit 1
fi

NAME="$1"
PALETTE="$THEMES_DIR/$NAME/colors"

if [[ ! -f "$PALETTE" ]]; then
    echo "x theme: theme not found: $NAME" >&2
    exit 1
fi

mkdir -p "$(dirname "$CONF_OUT")" "$STATE_DIR"

if [[ -e "$CONF_OUT" ]] && ! cmp -s "$PALETTE" "$CONF_OUT"; then
    cp -p "$CONF_OUT" "$CONF_OUT.bak.$(date +%Y%m%d%H%M%S)"
fi
cp -p "$PALETTE" "$CONF_OUT"

printf '%s\n' "$NAME" > "$STATE_DIR/theme"
echo "x theme: active theme: $NAME"
