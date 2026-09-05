#!/usr/bin/env bash
set -euo pipefail

# Test local del payload de aprovisionamiento (no requiere root).
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAIL=0

check() {
    local desc="$1"
    shift
    if "$@"; then
        printf 'ok - %s\n' "$desc"
    else
        printf 'FAIL - %s\n' "$desc"
        FAIL=1
    fi
}

# Sintaxis de todos los scripts bash del repo (sin wsl legacy por ahora).
echo "== sintaxis =="
while IFS= read -r f; do
    check "sintaxis $f" bash -n "$f"
done < <(find "$SRC/install" "$SRC/hardware" "$SRC/tools" -name '*.sh' | sort)

echo "== helpers =="
source "$SRC/install/helpers/sync.sh"

# seed home: no pisa ficheros del usuario, crea solo lo que falta.
SKEL="$TMP/skel"
HOME_DIR="$TMP/home"
mkdir -p "$SKEL/.config/x" "$HOME_DIR"
printf 'nuevo\n' > "$SKEL/.bashrc"
printf 'nuevo\n' > "$SKEL/.config/x/a.conf"
printf 'viejo\n' > "$HOME_DIR/.bashrc"

x_seed_home "$SKEL" "$HOME_DIR"
check "no sobrescribe .bashrc existente" test "$(cat "$HOME_DIR/.bashrc")" = "viejo"
check "crea dotfile faltante" test -f "$HOME_DIR/.config/x/a.conf"

# sync config: respalda diferencias y es idempotente.
CONF="$TMP/conf"
DST="$TMP/home/.config"
mkdir -p "$CONF/hypr" "$DST"
printf 'v1\n' > "$CONF/app.conf"
printf 'v0\n' > "$DST/app.conf"

x_sync_config "$CONF" "$DST"
check "respalda fichero existente que difiere" \
    test -f "$DST/app.conf.bak."*
check "aplica la nueva version" test "$(cat "$DST/app.conf")" = "v1"

BAK_COUNT="$(find "$DST" -name 'app.conf.bak.*' | wc -l)"
x_sync_config "$CONF" "$DST"
check "segunda pasada es idempotente (sin backup extra)" \
    test "$(find "$DST" -name 'app.conf.bak.*' | wc -l)" = "$BAK_COUNT"

echo "== tool hyprland-install =="
# Fuente local falsa: verifica que se limpia .git/.github y el mapeo de modos.
FAKE_HYPR="$TMP/fake-hypr"
mkdir -p "$FAKE_HYPR/.git" "$FAKE_HYPR/.github" 
touch "$FAKE_HYPR/install.sh"

X_HYPR_DRYRUN=1 X_HYPR_SOURCE="$FAKE_HYPR" X_HYPR_MODE=dotfiles \
    bash "$SRC/tools/hyprland-install.sh" > "$TMP/hypr.out" 2>&1
check "limpia .git de la copia" test ! -e "$FAKE_HYPR/.git"
check "limpia .github de la copia" test ! -e "$FAKE_HYPR/.github"
check "mapea modo dotfiles" grep -q -- '--dotfiles-only' "$TMP/hypr.out"

X_HYPR_DRYRUN=1 X_HYPR_SOURCE="$FAKE_HYPR" X_HYPR_MODE=full \
    bash "$SRC/tools/hyprland-install.sh" > "$TMP/hypr2.out" 2>&1
check "modo full sin flags" grep -q 'install.sh  en' "$TMP/hypr2.out"

if [[ "$FAIL" -eq 0 ]]; then
    echo "smoke: OK"
else
    echo "smoke: fallos detectados"
    exit 1
fi