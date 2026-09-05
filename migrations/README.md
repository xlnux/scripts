# x — migrations

Migrations are **idempotent** bash scripts, one per user configuration change,
named `migrations/<timestamp>-<name>.sh`.

## Contract

- They run per user (`x migrate`) and also at the end of `x update`.
- A migration applied successfully is marked in
  `~/.local/state/x/migrations/<name>` and is not run again.
- They must be safe to repeat (even if the marker already exists, do not
  break) and must not depend on the network or external infrastructure.
- If a migration fails, `x migrate` reports the error and does not mark it.

## How to add one

```bash
# migrations/20260905120000-config-x.sh
mkdir -p "$HOME/.config/x"
# ... idempotent change ...
```

Created under the repo's `x/reboot`; they are packaged with the rest of the
payload.
