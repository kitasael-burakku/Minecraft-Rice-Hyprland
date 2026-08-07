#!/usr/bin/env bash

##############
## Reinicio ##
##############
# Superseded por systemd (waybar.service, playerctl-watch.service,
# swaync.service — ver ~/.config/systemd/user/) desde la migración de
# autostart.lua. Ya no lo llama nada del rice: ni el arranque de sesión ni
# el bind SUPER+SHIFT+R (ahora "systemctl --user restart waybar.service
# playerctl-watch.service swaync.service"). Se deja andando como fallback
# manual (bash launch.sh) para debug fuera de systemd si hiciera falta.

set -u

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Único watcher de playerctl compartido por custom/playerctl y custom/playerlabel
command -v playerctl >/dev/null 2>&1 && {
    pkill -f 'playerctl-watch.sh' 2>/dev/null || true
    "${script_dir}/playerctl-watch.sh" &
    disown
}

# Subshell a propósito: si waybar no está instalado, el "exit" de acá adentro
# no debe matar el resto de este script (el reload de swaync más abajo).
(
    command -v waybar >/dev/null 2>&1 || {
        command -v notify-send >/dev/null 2>&1 && notify-send "Waybar" "waybar is not installed or not in PATH"
        exit 127
    }

    pkill -x waybar 2>/dev/null || true
    waybar &
)

if [ -x "$HOME/.config/swaync/scripts/launch.sh" ]; then
    "$HOME/.config/swaync/scripts/launch.sh"
else
    command -v swaync >/dev/null 2>&1 && {
        pkill -x swaync 2>/dev/null || true
        swaync &
    }
fi