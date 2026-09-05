#!/usr/bin/env bash
# x:summary=Runs the hardware phase (detection + modules)
# x:aliases=hardware hw
# x:root=true
set -euo pipefail

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$X_ROOT/install/hardware.sh"
