#!/usr/bin/env bash
# ============================================================================
#  confirm-then.sh — pide confirmación (rofi Sí/No) antes de correr $1
# ----------------------------------------------------------------------------
#  Mismo patrón visual que ya usa waybar/scripts/power-menu.sh. wlogout no
#  tiene paso de confirmación propio; esto se lo agrega solo a las acciones
#  destructivas (apagar/reiniciar) sin tocar lock/logout/suspend/hibernate.
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

[ "$choice" = "Sí" ] && exec bash -c "$CMD"
