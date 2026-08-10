#!/usr/bin/env bash
# ============================================================================
#  power.sh — power menu rápido vía rofi (dmenu)
# ----------------------------------------------------------------------------
#  Alternativa liviana a wlogout/scripts/launch_wlogout.sh (pantalla
#  completa) para cuando sólo hacen falta 2 segundos: "quiero suspender ya".
#  Reusa exactamente los mismos comandos que wlogout/layout — confirm-then.sh
#  para las acciones destructivas (mismo diálogo Sí/No, mismo whitelist de
#  comandos permitidos) y suspend.sh para el poll de hyprlock antes de
#  suspender. Cero lógica nueva de apagado/reinicio, sólo un frontend más
#  rápido para las mismas acciones — wlogout sigue siendo el menú completo
#  (SUPER+ESCAPE).
#
#  power-menu.rasi está pensado para exactamente 5 líneas (ver el comentario
#  en el propio tema) — de ahí que este menú tenga 5 entradas, no 6 como
#  wlogout/layout (se deja Hibernate afuera del atajo rápido; sigue
#  disponible en wlogout).
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/power-menu.rasi"
WLOGOUT_SCRIPTS="$HOME/.config/wlogout/scripts"

LABELS=(
    "󰌾  Lock"
    "󰤄  Suspend"
    "󰗽  Logout"
    "󰜉  Reboot"
    "󰐥  Shutdown"
)
menu=""
for l in "${LABELS[@]}"; do menu+="$l"$'\n'; done

chosen=$(printf '%s' "$menu" | rofi -dmenu -p "Power" -theme "$THEME")
[ -n "$chosen" ] || exit 0

# case en vez de un segundo array (CMDS) + eval: mismo despacho, pero cada
# comando se escribe una sola vez como argumentos reales de bash — sin una
# segunda pasada de parseo sobre un string armado a mano.
case "$chosen" in
    "󰌾  Lock")
        hyprlock &
        ;;
    "󰤄  Suspend")
        "$WLOGOUT_SCRIPTS/suspend.sh" &
        ;;
    "󰗽  Logout")
        hyprctl dispatch 'hl.dsp.exit()' &
        ;;
    "󰜉  Reboot")
        "$WLOGOUT_SCRIPTS/confirm-then.sh" 'systemctl reboot' '¿Reiniciar?' &
        ;;
    "󰐥  Shutdown")
        "$WLOGOUT_SCRIPTS/confirm-then.sh" 'systemctl poweroff' '¿Apagar?' &
        ;;
    *)
        exit 0
        ;;
esac
disown
exit 0
