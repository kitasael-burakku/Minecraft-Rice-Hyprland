#!/usr/bin/env bash

ROFI_THEME="/home/kitasa-elburakku/.config/rofi/power-menu.rasi"

choice=$(printf "⏻  Apagar\n󰜉  Reiniciar\n󰌾  Bloquear\n✕  Cancelar" | rofi -dmenu \
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

    "󰌾  Bloquear")
        hyprlock
        ;;

    *)
        exit 0
        ;;
esac