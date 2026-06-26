#!/usr/bin/env bash

ROFI_THEME="${HOME}/.config/rofi/power-menu.rasi"

choice=$(printf "⏻  Apagar\n󰜉  Reiniciar\n󰒲  Suspender\n󰌾  Bloquear\n✕  Cancelar" | rofi -dmenu \
    -p "Power" \
    -theme "$ROFI_THEME")

case "$choice" in
    "⏻  Apagar")
        confirm=$(printf "No\nSí" | rofi -dmenu \
            -p "¿Apagar?" \
            -theme "$ROFI_THEME")
        [ "$confirm" = "Sí" ] && systemctl poweroff
        ;;

    "󰜉  Reiniciar")
        confirm=$(printf "No\nSí" | rofi -dmenu \
            -p "¿Reiniciar?" \
            -theme "$ROFI_THEME")
        [ "$confirm" = "Sí" ] && systemctl reboot
        ;;

    "󰒲  Suspender")
        systemctl suspend
        ;;

    "󰌾  Bloquear")
        hyprlock
        ;;

    *)
        exit 0
        ;;
esac