#!/usr/bin/env bash
# ============================================================================
#  wait-for-hyprland.sh — bounded wait for Hyprland to actually be ready
# ----------------------------------------------------------------------------
#  Replaces the fixed `sleep 0.5` / `sleep 2` calls that used to be in
#  autostart.lua (timing bets on how long the compositor/daemons take to
#  start) with a real poll on `hyprctl monitors`, with a max timeout so it
#  doesn't block startup if something fails — if the time runs out, it
#  continues just like before (doesn't hang the session).
#
#  Usage: wait-for-hyprland.sh [timeout_in_seconds=5]
# ============================================================================

set -u

TIMEOUT="${1:-5}"
INTERVAL=0.1

command -v hyprctl >/dev/null 2>&1 || exit 0

elapsed=0
while ! hyprctl monitors >/dev/null 2>&1; do
    sleep "$INTERVAL"
    elapsed=$(awk -v e="$elapsed" -v i="$INTERVAL" 'BEGIN{printf "%.2f", e+i}')
    if awk -v e="$elapsed" -v t="$TIMEOUT" 'BEGIN{exit !(e>=t)}'; then
        exit 0
    fi
done

exit 0
