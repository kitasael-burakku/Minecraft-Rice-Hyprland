#!/usr/bin/env bash

##############
## Reinicio ##
##############

set -u

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"${script_dir}/launch_waybar.sh"

if [ -x "$HOME/.config/swaync/scripts/launch.sh" ]; then
    "$HOME/.config/swaync/scripts/launch.sh"
else
    command -v swaync >/dev/null 2>&1 && {
        pkill -x swaync 2>/dev/null || true
        swaync &
    }
fi