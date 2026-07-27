#!/usr/bin/env bash
# ============================================================================
#  playerctl-watch.sh — único proceso playerctl -F para waybar
#  Escribe cada evento de metadata en un cache atómico; custom/playerctl y
#  custom/playerlabel lo leen con `tail -F` en vez de lanzar cada uno su
#  propio playerctl -a metadata -F (dos procesos escuchando lo mismo).
# ============================================================================
set -o pipefail

set -u

CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-playerctl.json"
TMP="${CACHE}.tmp"

command -v playerctl >/dev/null 2>&1 || exit 0

printf '%s\n' '{"text":"","tooltip":"","alt":"Stopped","class":"Stopped"}' > "$CACHE"

playerctl -a metadata --format \
    '{"text": "{{artist}} - {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' \
    -F | while IFS= read -r line; do
        printf '%s\n' "$line" > "$TMP" && mv -f "$TMP" "$CACHE"
    done
