#!/usr/bin/env bash
# ============================================================================
#  playerctl-read.sh — lightweight consumer of playerctl-watch.sh's cache
#  Used by custom/playerctl and custom/playerlabel instead of each module
#  launching its own playerctl -F.
# ============================================================================

set -u

CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-playerctl.json"

[ -f "$CACHE" ] || printf '%s\n' '{"text":"","tooltip":"","alt":"Stopped","class":"Stopped"}' > "$CACHE"

exec tail -F -n1 "$CACHE"
