#!/usr/bin/env bash
# x:summary=Lists the available themes
# x:aliases=theme themes
# x:root=false
set -euo pipefail

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEMES_DIR="${X_THEMES_DIR:-$X_ROOT/themes}"

if [[ ! -d "$THEMES_DIR" ]] || [[ -z "$(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)" ]]; then
    echo "x theme: no themes"
    exit 0
fi

for d in "$THEMES_DIR"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    if [[ -f "$d/colors" ]]; then
        echo "$name"
    else
        echo "$name (no colors palette)"
    fi
done
