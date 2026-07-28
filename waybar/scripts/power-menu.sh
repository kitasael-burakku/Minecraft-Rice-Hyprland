#!/usr/bin/env bash
set -o pipefail

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
        # wlogout/scripts/suspend.sh bloquea la pantalla antes de suspender
        # (poll acotado a que hyprlock esté listo) — antes este menú suspendía
        # directo, sin bloquear, a diferencia del menú de wlogout.
        ~/.config/wlogout/scripts/suspend.sh
        ;;

    "󰌾  Bloquear")
        hyprlock
        ;;

    *)
        exit 0
        ;;
esac