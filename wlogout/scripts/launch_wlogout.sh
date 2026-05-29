#!/usr/bin/env bash

set -u

layout="$HOME/.config/wlogout/layout"
style="$HOME/.config/wlogout/style.css"

command -v wlogout >/dev/null 2>&1 || {
    command -v notify-send >/dev/null 2>&1 && notify-send "Wlogout" "wlogout is not installed or not in PATH"
    exit 127
}

# Si ya existe una instancia de wlogout, la cierra y sale del script
if pgrep -x "wlogout" > /dev/null
then
    pkill -x wlogout
    exit 0
fi

# Si no está abierto, lo lanza con tu configuración
wlogout -l "$layout" -C "$style" &