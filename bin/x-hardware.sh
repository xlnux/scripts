#!/usr/bin/env bash
# x:summary=Ejecuta la fase de hardware (deteccion + modulos)
# x:aliases=hardware hw
# x:root=true
set -euo pipefail

X_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$X_ROOT/install/hardware.sh"
