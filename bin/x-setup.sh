#!/usr/bin/env bash
# x:summary=Provisions the system (root) or the user (--user)
# x:args=[--user]
# x:root=false
set -euo pipefail

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "--user" ]]; then
    bash "$X_ROOT/install/user.sh"
    exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        sudo bash "$X_ROOT/install/system.sh"
    else
        echo "x setup: requires root" >&2
        exit 1
    fi
else
    bash "$X_ROOT/install/system.sh"
fi
