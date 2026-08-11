#!/usr/bin/env bash
# ============================================================================
#  playerctl-watch.sh — single playerctl -F process for waybar
#  Writes every metadata event to an atomic cache; custom/playerctl and
#  custom/playerlabel read it with `tail -F` instead of each launching its
#  own playerctl -a metadata -F (two processes listening to the same thing).
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
