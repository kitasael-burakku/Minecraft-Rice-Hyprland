#!/usr/bin/env bash
# ============================================================================
#  wait-for-hyprland.sh — espera acotada a que Hyprland esté realmente listo
# ----------------------------------------------------------------------------
#  Reemplaza los `sleep 0.5` / `sleep 2` fijos que había en autostart.lua
#  (apuestas de timing sobre cuánto tarda el compositor/daemons en arrancar)
#  por un poll real sobre `hyprctl monitors`, con un timeout máximo para
#  no bloquear el arranque si algo falla — si se agota el tiempo, sigue
#  igual que antes (no cuelga la sesión).
#
#  Uso: wait-for-hyprland.sh [timeout_en_segundos=5]
# ============================================================================

set -u

TIMEOUT="${1:-5}"
INTERVAL=0.1

command -v hyprctl >/dev/null 2>&1 || exit 0

elapsed=0
while ! hyprctl monitors >/dev/null 2>&1; do
    sleep "$INTERVAL"
    elapsed=$(awk -v e="$elapsed" -v i="$INTERVAL" 'BEGIN{printf "%.2f", e+i}')
    if awk -v e="$elapsed" -v t="$TIMEOUT" 'BEGIN{exit !(e>=t)}'; then
        exit 0
    fi
done

exit 0
