#!/usr/bin/env bash
# x:summary=Ejecuta las migraciones pendientes del usuario
# x:aliases=migrate migrations
# x:root=false
set -euo pipefail

# Las migraciones viven en migrations/<timestamp>-<nombre>.sh y son
# idempotentes. Una migracion ejecutada con exito se marca en
# ~/.local/state/x/migrations/<nombre> y no se vuelve a correr.

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATIONS_DIR="${X_MIGRATIONS_DIR:-$X_ROOT/migrations}"
STATE_DIR="${X_STATE_DIR:-$HOME/.local/state/x}"

if [[ ! -d "$MIGRATIONS_DIR" ]] || [[ -z "$(find "$MIGRATIONS_DIR" -name '*.sh' | head -1)" ]]; then
    echo "x migrate: no hay migraciones"
    exit 0
fi

mkdir -p "$STATE_DIR/migrations"

failed=0
for m in "$MIGRATIONS_DIR"/*.sh; do
    [[ -e "$m" ]] || continue
    name="$(basename "$m" .sh)"
    marker="$STATE_DIR/migrations/$name"
    if [[ -f "$marker" ]]; then
        continue
    fi
    echo "x migrate: aplicando $name"
    if bash "$m"; then
        : > "$marker"
    else
        echo "x migrate: fallo en $name" >&2
        failed=1
    fi
done

[[ "$failed" -eq 0 ]] || exit 1
echo "x migrate: sin migraciones pendientes"
