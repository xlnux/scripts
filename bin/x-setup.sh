#!/usr/bin/env bash
# x:summary=Provision the system (root) or the user (--user); --online runs the upstream Hyprland installer
# x:args=[--user] [--online]
# x:root=false
set -euo pipefail

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

USER_MODE=0
ONLINE=0

for arg in "$@"; do
    case "$arg" in
        --user)   USER_MODE=1 ;;
        --online) ONLINE=1 ;;
        -h|--help)
            echo "usage: x setup [--user] [--online]"
            echo "  --user    provision the current user"
            echo "  --online  also run the upstream xscriptor-colors/hyprland install.sh (interactive, asks for sudo)"
            exit 0
            ;;
        *)
            echo "x setup: unknown argument '$arg' (see 'x setup --help')" >&2
            exit 1
            ;;
    esac
done

if [[ "$ONLINE" == "1" ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then
        echo "x setup --online must run as your user (open a terminal after login)" >&2
        exit 1
    fi
    bash "$X_ROOT/tools/hyprland-online.sh"
    exit 0
fi

if [[ "$USER_MODE" == "1" ]]; then
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
