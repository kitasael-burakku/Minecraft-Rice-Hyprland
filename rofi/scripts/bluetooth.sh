#!/usr/bin/env bash
# ============================================================================
#  bluetooth.sh — conectar/desconectar dispositivos ya emparejados, vía rofi
# ----------------------------------------------------------------------------
#  waybar abre blueman-manager en el click de bluetooth. bluetoothctl cubre
#  el 95% del uso real (conectar/desconectar algo que ya está emparejado) —
#  esto no reemplaza a blueman-manager para emparejar dispositivos nuevos,
#  sólo evita abrirlo para el caso común.
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/clipboard.rasi"
command -v bluetoothctl >/dev/null 2>&1 || exit 0

powered="$(bluetoothctl show 2>/dev/null | grep -oP 'Powered:\s*\K\w+')"

declare -A ACTION_OF
menu=""

if [ "$powered" = "yes" ]; then
    label="󰂲  Apagar Bluetooth"
    ACTION_OF["$label"]="power_off"
else
    label="󰂯  Encender Bluetooth"
    ACTION_OF["$label"]="power_on"
fi
menu+="$label"$'\n'

if [ "$powered" = "yes" ]; then
    while IFS= read -r line; do
        mac="$(printf '%s' "$line" | awk '{print $2}')"
        name="$(printf '%s' "$line" | cut -d' ' -f3-)"
        [ -n "$mac" ] || continue
        connected="$(bluetoothctl info "$mac" 2>/dev/null | grep -oP 'Connected:\s*\K\w+')"
        icon="󰂲"
        [ "$connected" = "yes" ] && icon="󰂱"
        label="${icon}  ${name}"
        ACTION_OF["$label"]="toggle:${mac}:${connected}"
        menu+="$label"$'\n'
    done < <(bluetoothctl devices Paired 2>/dev/null)
fi

chosen="$(printf '%s' "$menu" | rofi -dmenu -p "Bluetooth" -theme "$THEME")"
[ -n "$chosen" ] || exit 0

action="${ACTION_OF[$chosen]:-}"
[ -n "$action" ] || exit 0

case "$action" in
    power_on)  bluetoothctl power on ;;
    power_off) bluetoothctl power off ;;
    toggle:*)
        rest="${action#toggle:}"
        mac="${rest%%:*}"
        connected="${rest#*:}"
        if [ "$connected" = "yes" ]; then
            bluetoothctl disconnect "$mac"
        else
            bluetoothctl connect "$mac"
        fi
        ;;
esac
