#!/usr/bin/env bash
set -euo pipefail

# Local test of the provisioning payload (does not require root).
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

# Syntax of every bash script in the repo (no wsl legacy for now).
echo "== syntax =="
while IFS= read -r f; do
    check "syntax $f" bash -n "$f"
done < <(find "$SRC/install" "$SRC/hardware" "$SRC/tools" "$SRC/bin" -name '*.sh' | sort)
check "syntax dispatcher" bash -n "$SRC/bin/x"

echo "== helpers =="
source "$SRC/install/helpers/sync.sh"

# seed home: never overwrites user files, creates only what is missing.
SKEL="$TMP/skel"
HOME_DIR="$TMP/home"
mkdir -p "$SKEL/.config/x" "$HOME_DIR"
printf 'new\n' > "$SKEL/.bashrc"
printf 'new\n' > "$SKEL/.config/x/a.conf"
printf 'old\n' > "$HOME_DIR/.bashrc"

x_seed_home "$SKEL" "$HOME_DIR"
check "does not overwrite existing .bashrc" test "$(cat "$HOME_DIR/.bashrc")" = "old"
check "creates missing dotfile" test -f "$HOME_DIR/.config/x/a.conf"

# sync config: backs up differences and is idempotent.
CONF="$TMP/conf"
DST="$TMP/home/.config"
mkdir -p "$CONF/hypr" "$DST"
printf 'v1\n' > "$CONF/app.conf"
printf 'v0\n' > "$DST/app.conf"

x_sync_config "$CONF" "$DST"
check "backs up an existing differing file" \
    test -f "$DST/app.conf.bak."*
check "applies the new version" test "$(cat "$DST/app.conf")" = "v1"

BAK_COUNT="$(find "$DST" -name 'app.conf.bak.*' | wc -l)"
x_sync_config "$CONF" "$DST"
check "second pass is idempotent (no extra backup)" \
    test "$(find "$DST" -name 'app.conf.bak.*' | wc -l)" = "$BAK_COUNT"

echo "== tool hyprland-install =="
# Fake local source: verifies .git/.github cleanup and the dry-run plan.
FAKE_HYPR="$TMP/fake-hypr"
mkdir -p "$FAKE_HYPR/.git" "$FAKE_HYPR/.github" "$FAKE_HYPR/config/hypr"
touch "$FAKE_HYPR/config/hypr/placeholder"

X_HYPR_DRYRUN=1 X_HYPR_SOURCE="$FAKE_HYPR" \
    bash "$SRC/tools/hyprland-install.sh" > "$TMP/hypr.out" 2>&1
check "does not destroy the caller source (.git kept)" test -d "$FAKE_HYPR/.git"
check "does not destroy the caller source (.github kept)" test -d "$FAKE_HYPR/.github"
check "prints dry-run plan" grep -q "dry-run: install deps" "$TMP/hypr.out"

echo "== CLI =="
chmod +x "$SRC"/bin/x "$SRC"/bin/*.sh

# Unknown command -> exit code 1.
if bash "$SRC/bin/x" nonexistent-command >/dev/null 2>&1; then
    check "unknown command fails" false
else
    check "unknown command fails" true
fi

HELP_OUT="$(bash "$SRC/bin/x" help)"
THEME_OUT="$(bash "$SRC/bin/x" theme list)"
check "help lists theme list" grep -q "theme list" <<< "$HELP_OUT"
check "theme list shows x-dark" grep -q "x-dark" <<< "$THEME_OUT"

# Dispatch via symlink (equivalent to /usr/bin/x).
ln -s "$SRC/bin/x" "$TMP/xlink"
SYMLINK_OUT="$(bash "$TMP/xlink" help)"
check "dispatch via symlink resolves the binary" grep -q "theme set" <<< "$SYMLINK_OUT"

# theme set with overrides to tmp.
export X_STATE_DIR="$TMP/state"
export X_THEME_CONF="$TMP/home2/.config/x/theme.conf"
bash "$SRC/bin/x" theme set x-dark
check "theme set applies palette" grep -q "^primary=89b4fa" "$X_THEME_CONF"
check "theme set records the active one" test "$(cat "$X_STATE_DIR/theme")" = "x-dark"
if bash "$SRC/bin/x" theme set nonexistent >/dev/null 2>&1; then
    check "theme set nonexistent fails" false
else
    check "theme set nonexistent fails" true
fi

# migrate: a good one (idempotent) and one that fails (not marked).
export X_STATE_DIR="$TMP/state"
MIG_OK="$TMP/mig-ok"
mkdir -p "$MIG_OK"
printf '#!/usr/bin/env bash\nmkdir -p "$HOME/.x-migrated"\n' > "$MIG_OK/20260905120000-good.sh"

export X_MIGRATIONS_DIR="$MIG_OK"
check "migrate applies and marks" bash "$SRC/bin/x" migrate >/dev/null 2>&1
check "migration stays marked" test -f "$X_STATE_DIR/migrations/20260905120000-good"
check "migrate is idempotent (2nd pass)" bash "$SRC/bin/x" migrate >/dev/null 2>&1

MIG_BAD="$TMP/mig-bad"
mkdir -p "$MIG_BAD"
printf '#!/usr/bin/env bash\nexit 3\n' > "$MIG_BAD/20260905130000-bad.sh"
export X_MIGRATIONS_DIR="$MIG_BAD"
if bash "$SRC/bin/x" migrate >/dev/null 2>&1; then
    check "failed migration exits with error" false
else
    check "failed migration exits with error" true
fi
check "failed migration is not marked" test ! -f "$X_STATE_DIR/migrations/20260905130000-bad"

unset X_MIGRATIONS_DIR

if [[ "$FAIL" -eq 0 ]]; then
    echo "smoke: OK"
else
    echo "smoke: failures detected"
    exit 1
fi
