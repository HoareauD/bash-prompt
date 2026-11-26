#!/usr/bin/env bash
set -euo pipefail

if (( $# != 0 )); then
    printf '%s\n' 'Utilisation : bash uninstall.sh' >&2
    exit 1
fi
exec bash "$(dirname -- "${BASH_SOURCE[0]}")/install.sh" --uninstall
