#!/usr/bin/env bash
# x:summary=Runs the user's pending migrations
# x:aliases=migrate migrations
# x:root=false
set -euo pipefail

# Migrations live in migrations/<timestamp>-<name>.sh and are idempotent.
# A migration that ran successfully is marked in
# ~/.local/state/x/migrations/<name> and is not run again.

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATIONS_DIR="${X_MIGRATIONS_DIR:-$X_ROOT/migrations}"
STATE_DIR="${X_STATE_DIR:-$HOME/.local/state/x}"

if [[ ! -d "$MIGRATIONS_DIR" ]] || [[ -z "$(find "$MIGRATIONS_DIR" -name '*.sh' | head -1)" ]]; then
    echo "x migrate: no migrations"
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
    echo "x migrate: applying $name"
    if bash "$m"; then
        : > "$marker"
    else
        echo "x migrate: failed on $name" >&2
        failed=1
    fi
done

[[ "$failed" -eq 0 ]] || exit 1
echo "x migrate: no pending migrations"
