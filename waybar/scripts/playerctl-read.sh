#!/usr/bin/env bash
# ============================================================================
#  playerctl-read.sh — consumidor liviano del cache de playerctl-watch.sh
#  Usado por custom/playerctl y custom/playerlabel en vez de que cada módulo
#  lance su propio playerctl -F.
# ============================================================================

set -u

CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-playerctl.json"

[ -f "$CACHE" ] || printf '%s\n' '{"text":"","tooltip":"","alt":"Stopped","class":"Stopped"}' > "$CACHE"

exec tail -F -n1 "$CACHE"
