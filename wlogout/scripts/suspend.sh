#!/usr/bin/env bash

set -u

# Poll acotado sobre el proceso de hyprlock en vez de una apuesta de timing
# fija (`sleep 0.8`) — mismo criterio que hypr/scripts/wait-for-hyprland.sh:
# si hyprlock tarda menos, no se espera de más; si tarda más (o falla), hay
# un techo para no colgar la suspensión indefinidamente.
if command -v hyprlock >/dev/null 2>&1; then
    hyprlock &
    timeout=3
    interval=0.1
    elapsed=0
    while ! pgrep -x hyprlock >/dev/null 2>&1; do
        sleep "$interval"
        elapsed=$(awk -v e="$elapsed" -v i="$interval" 'BEGIN{printf "%.2f", e+i}')
        if awk -v e="$elapsed" -v t="$timeout" 'BEGIN{exit !(e>=t)}'; then
            break
        fi
    done
fi

systemctl suspend