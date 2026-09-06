#!/usr/bin/env bash
# x:summary=Updates the system and runs migrations
# x:aliases=update upgrade up
# x:root=false
set -euo pipefail

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
X_BIN="${X_BIN:-$X_ROOT/bin}"

run_privileged() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        return 1
    fi
}

if command -v pacman >/dev/null 2>&1; then
    echo "x update: syncing repos and updating"
    run_privileged pacman -Syu --noconfirm
else
    echo "x update: pacman not present (skip)"
fi

if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    runuser -u "$SUDO_USER" -- bash "$X_BIN/x-migrate.sh"
else
    bash "$X_BIN/x-migrate.sh"
fi

echo "x update: done"
