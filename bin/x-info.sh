#!/usr/bin/env bash
# x:summary=Shows system and x environment info
# x:aliases=info status doctor
# x:root=false
set -euo pipefail

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
X_BIN="${X_BIN:-$X_ROOT/bin}"

version="dev"
if git -C "$X_ROOT" rev-parse --short HEAD >/dev/null 2>&1; then
    version="$(git -C "$X_ROOT" describe --tags --always 2>/dev/null || git -C "$X_ROOT" rev-parse --short HEAD)"
fi

echo "x $(basename "$X_ROOT") $version"
echo "repo: $X_ROOT"
echo "user: $(id -un) ($(id -u))"

if command -v pacman >/dev/null 2>&1; then
    echo "dist: arch (packages: $(pacman -Q 2>/dev/null | wc -l))"
else
    echo "dist: no-pacman"
fi

theme_file="${X_STATE_DIR:-$HOME/.local/state/x}/theme"
if [[ -f "$theme_file" ]]; then
    echo "theme: $(cat "$theme_file")"
fi
