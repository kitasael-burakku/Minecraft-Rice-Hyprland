#!/usr/bin/env bash
# ============================================================================
#  confirm-then.sh — pide confirmación (rofi Sí/No) antes de correr $1
# ----------------------------------------------------------------------------
#  Mismo patrón visual que ya usa waybar/scripts/power-menu.sh. wlogout no
#  tiene paso de confirmación propio; esto se lo agrega a las acciones
#  destructivas (apagar/reiniciar/hibernar) sin tocar lock/logout/suspend.
#
#  Uso: confirm-then.sh '<comando a correr si confirma>' ['<pregunta>']
# ============================================================================

set -u
set -o pipefail

CMD="${1:-}"
LABEL="${2:-¿Confirmar?}"
ROFI_THEME="$HOME/.config/rofi/power-menu.rasi"

[ -n "$CMD" ] || exit 1

choice=$(printf "No\nSí" | rofi -dmenu -p "$LABEL" -theme "$ROFI_THEME")

if [ "$choice" = "Sí" ]; then
    # Whitelist en vez de "exec bash -c \"$CMD\"": hoy solo hay 3 llamadores
    # literales (wlogout/layout), todos comandos systemd fijos — un
    # re-parseo de string arbitrario es más superficie de la que hace falta
    # para eso.
    case "$CMD" in
        "systemctl poweroff"|"systemctl reboot"|"systemctl hibernate")
            exec $CMD
            ;;
        *)
            echo "confirm-then.sh: comando no permitido: $CMD" >&2
            exit 1
            ;;
    esac
fi
