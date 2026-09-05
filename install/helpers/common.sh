#!/usr/bin/env bash

# Helpers comunes del aprovisionamiento x.

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export X_ROOT

log() {
    printf '\033[1;32m[x]\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33m[x!]\033[0m %s\n' "$*"
}

error() {
    printf '\033[1;31m[x!!]\033[0m %s\n' "$*"
    exit 1
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

x_require_root() {
    [[ "$(id -u)" -eq 0 ]] || error "se requiere root (ejecuta con sudo o como root)."
}

x_target_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        printf '%s\n' "$SUDO_USER"
    else
        printf '%s\n' "${USER:-$(id -un)}"
    fi
}

x_target_home() {
    local user
    user="$(x_target_user)"
    if [[ "$user" == "root" ]]; then
        printf '%s\n' "/root"
    else
        getent passwd "$user" | cut -d: -f6
    fi
}

run_privileged() {
    if [[ "${X_DRY_RUN:-0}" == "1" ]]; then
        log "(dry-run) $*"
        return 0
    fi
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif has_cmd x; then
        x "$@"
    else
        sudo "$@"
    fi
}

run_as_user() {
    if [[ "${X_DRY_RUN:-0}" == "1" ]]; then
        log "(dry-run, como usuario) $*"
        return 0
    fi
    if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
        runuser -u "$SUDO_USER" -- "$@"
    else
        "$@"
    fi
}
