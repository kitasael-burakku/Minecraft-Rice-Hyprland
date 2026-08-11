#!/usr/bin/env bash

###########
## Restart ##
###########
# Superseded by systemd (waybar.service, playerctl-watch.service,
# swaync.service — see ~/.config/systemd/user/) since the migration away
# from autostart.lua. Nothing in the rice calls this anymore: not session
# startup, not the SUPER+SHIFT+R bind (now "systemctl --user restart
# waybar.service playerctl-watch.service swaync.service"). Left working as
# a manual fallback (bash launch.sh) for debugging outside systemd if
# needed.

set -u

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Single playerctl watcher shared by custom/playerctl and custom/playerlabel
command -v playerctl >/dev/null 2>&1 && {
    pkill -f 'playerctl-watch.sh' 2>/dev/null || true
    "${script_dir}/playerctl-watch.sh" &
    disown
}

# Subshell on purpose: if waybar isn't installed, the "exit" in here
# shouldn't kill the rest of this script (the swaync reload below).
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