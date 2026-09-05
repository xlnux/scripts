# x — themes

Each theme is a directory `themes/<name>/` with a `colors` palette
(format `key=hex`, one per line).

## Commands

- `x theme list` — lists the available themes.
- `x theme set <name>` — installs the palette as `~/.config/x/theme.conf`
  (backing up the previous one) and records the active theme in
  `~/.local/state/x/theme`.

## Consumers

The real Hyprland config (external repo) manages its own palettes
(`dock/palettes`) and is installed separately. This store is the palette of
the x system itself; consumers (shell, terminals, etc.) read from
`~/.config/x/theme.conf`.
