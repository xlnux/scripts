# x — /etc drop-ins

This tree is dumped onto `/etc` during the system configuration phase
(`install/config.sh`). Each subdirectory mirrors an `/etc` path:

- `sysctl.d/` — kernel parameters.
- `tmpfiles.d/` — temporary files/permissions.
- `sudoers.d/` — sudo rules.
- `pacman.d/hooks/` — own pacman hooks.

Rule: never overwrite package files; always use drop-ins. A file already
modified by the administrator is not overwritten.
