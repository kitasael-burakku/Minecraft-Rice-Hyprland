#!/usr/bin/env bash

set -u

command -v swaync >/dev/null 2>&1 || {
    command -v notify-send >/dev/null 2>&1 && notify-send "SwayNC" "swaync is not installed or not in PATH"
    exit 127
}

if pgrep -x swaync >/dev/null 2>&1; then
    # Ya está corriendo: recargar config/estilo en caliente en vez de matarlo,
    # así un reload de Waybar (SUPER+SHIFT+R) no descarta notificaciones en
    # el instante del kill+relanzamiento.
    if command -v swaync-client >/dev/null 2>&1; then
        swaync-client -R  >/dev/null 2>&1 || true
        swaync-client -rs >/dev/null 2>&1 || true
    fi
else
    swaync &
fi