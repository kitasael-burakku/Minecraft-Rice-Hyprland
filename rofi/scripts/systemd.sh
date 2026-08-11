#!/usr/bin/env bash
# ============================================================================
#  systemd.sh — gestor rápido de servicios systemd --user, vía rofi
# ----------------------------------------------------------------------------
#  Con la migración de hypr/modules/autostart.lua a systemd (ver
#  ~/.config/systemd/user/) hay bastantes más servicios de usuario que
#  antes. checkerrors.fish y healthcheck.fish ya avisan cuál falló, pero
#  después había que ir a la terminal a reiniciarlo. Esto cierra ese loop:
#  listar (fallidos primero) y start/stop/restart/journal sin salir de rofi.
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/clipboard.rasi"
TERMINAL="${TERMINAL:-kitty}"

command -v systemctl >/dev/null 2>&1 || exit 0

declare -A UNIT_OF
menu_failed=""
menu_rest=""

while IFS= read -r line; do
    [ -n "$line" ] || continue
    unit=$(printf '%s' "$line" | awk '{print $1}')
    active=$(printf '%s' "$line" | awk '{print $3}')
    sub=$(printf '%s' "$line" | awk '{print $4}')
    [[ "$unit" == *.service ]] || continue

    icon="○"
    case "$active" in
        active) icon="●" ;;
        failed) icon="✗" ;;
        *)      icon="○" ;;
    esac

    label="${icon}  ${unit}  [${active}/${sub}]"
    UNIT_OF["$label"]="$unit"
    if [ "$active" = "failed" ]; then
        menu_failed+="$label"$'\n'
    else
        menu_rest+="$label"$'\n'
    fi
done < <(systemctl --user list-units --type=service --all --no-legend --plain 2>/dev/null)

menu="${menu_failed}${menu_rest}"

if [ -z "$menu" ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "systemd" "No user services found"
    exit 0
fi

chosen=$(printf '%s' "$menu" | rofi -dmenu -p "Services" -theme "$THEME")
[ -n "$chosen" ] || exit 0

unit="${UNIT_OF[$chosen]:-}"
[ -n "$unit" ] || exit 0

action=$(printf '󰐊  Start\n󰓛  Stop\n󰑓  Restart\n󰭹  Journal' | rofi -dmenu -p "$unit" -theme "$THEME")
[ -n "$action" ] || exit 0

case "$action" in
    *Start*)   systemctl --user start "$unit" ;;
    *Stop*)    systemctl --user stop "$unit" ;;
    *Restart*) systemctl --user restart "$unit" ;;
    *Journal*)
        "$TERMINAL" --title "journal-${unit%.service}" -e journalctl --user -u "$unit" -f &
        disown
        ;;
esac
