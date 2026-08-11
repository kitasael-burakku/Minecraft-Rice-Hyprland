#!/usr/bin/env bash

set -u

# Bounded poll on the hyprlock process instead of a fixed timing bet
# (`sleep 0.8`) — same approach as hypr/scripts/wait-for-hyprland.sh: if
# hyprlock takes less time, there's no extra wait; if it takes longer (or
# fails), there's a ceiling so it doesn't hang suspend indefinitely.
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