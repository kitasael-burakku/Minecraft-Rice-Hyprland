#!/usr/bin/env bash
# ============================================================================
#  updates-notify-actionable.sh — notificación con botón "Actualizar ahora"
#  cuando se acumulan muchas actualizaciones pendientes.
# ----------------------------------------------------------------------------
#  Llamado por updates-check.service después de refrescar el cache (ver
#  systemd/user/updates-check.service). Usa el mismo umbral "critical"
#  (total >= 50) que ya define waybar/scripts/updates.sh para su propia
#  clase CSS — por debajo de eso es ruido diario, no algo que amerite un
#  botón.
#
#  `notify-send --action` implica --wait: bloquea hasta que el usuario
#  clickea o descarta la notificación. Por eso quien llama a este script
#  SIEMPRE debe hacerlo en background (ver el ExecStartPost del .service) —
#  nunca debe bloquear a quien lo dispara.
#
#  Marcador de sesión: sin él, cada corrida de updates-check.timer (cada 30
#  min) volvería a notificar mientras el conteo siga por encima del umbral,
#  aunque el usuario ya haya visto y descartado el aviso. Se resetea solo
#  cuando el conteo vuelve a bajar de 50 (o sea, después de actualizar).
# ============================================================================
set -u
set -o pipefail

CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
NOTIFIED_MARKER="${XDG_RUNTIME_DIR:-/tmp}/kitasan-updates-notified"

command -v notify-send >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ -f "$CACHE" ] || exit 0

cls="$(jq -r '.class // ""' "$CACHE" 2>/dev/null)"
tooltip="$(jq -r '.tooltip // ""' "$CACHE" 2>/dev/null)"

if [ "$cls" != "critical" ]; then
    rm -f "$NOTIFIED_MARKER"
    exit 0
fi

[ -f "$NOTIFIED_MARKER" ] && exit 0
touch "$NOTIFIED_MARKER"

action="$(notify-send --app-name="kitasan" --icon=software-update-available \
    --action="update=Actualizar ahora" \
    "Muchas actualizaciones pendientes" "$tooltip" 2>/dev/null)"

if [ "$action" = "update" ]; then
    kitty --title kitasan-update -e fish -c 'kitasan update' &
    disown
fi
