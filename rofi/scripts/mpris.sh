#!/usr/bin/env bash
# ============================================================================
#  mpris.sh — selector de reproductor MPRIS + acciones rápidas, vía rofi
# ----------------------------------------------------------------------------
#  Los binds XF86Audio* (hypr/modules/keybinds.lua) llaman a `playerctl` sin
#  -p, así que con más de un reproductor abierto (Spotify + navegador + maly)
#  actúan sobre el que playerctl elija por su cuenta — no hay forma de decir
#  "éste". Esto no toca esos binds; es un control explícito y puntual:
#  elegís el reproductor, elegís la acción, se aplica con
#  `playerctl -p <player> <acción>`.
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/clipboard.rasi"

command -v playerctl >/dev/null 2>&1 || exit 0

mapfile -t players < <(playerctl -l 2>/dev/null)
if [ "${#players[@]}" -eq 0 ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "MPRIS" "No active players"
    exit 0
fi

declare -A LABEL_TO_PLAYER
menu=""
for p in "${players[@]}"; do
    status=$(playerctl -p "$p" status 2>/dev/null || echo "?")
    meta=$(playerctl -p "$p" metadata --format '{{artist}} - {{title}}' 2>/dev/null)
    icon="󰐊"
    [ "$status" = "Paused" ] && icon="󰏤"
    [ "$status" = "Stopped" ] && icon="󰓛"
    label="${icon}  ${p}  [${status}]  ${meta}"
    LABEL_TO_PLAYER["$label"]="$p"
    menu+="$label"$'\n'
done

chosen_player_label=$(printf '%s' "$menu" | rofi -dmenu -p "Player" -theme "$THEME")
[ -n "$chosen_player_label" ] || exit 0
player="${LABEL_TO_PLAYER[$chosen_player_label]}"
[ -n "$player" ] || exit 0

action=$(printf '󰐊  Play/Pause\n󰒭  Next\n󰒮  Previous\n󰓛  Stop' | rofi -dmenu -p "$player" -theme "$THEME")
[ -n "$action" ] || exit 0

case "$action" in
    *Play/Pause*) playerctl -p "$player" play-pause ;;
    *Next*)       playerctl -p "$player" next ;;
    *Previous*)   playerctl -p "$player" previous ;;
    *Stop*)       playerctl -p "$player" stop ;;
esac
