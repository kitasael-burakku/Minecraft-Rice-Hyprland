#!/usr/bin/env bash

set -u

command -v swaync >/dev/null 2>&1 || {
    command -v notify-send >/dev/null 2>&1 && notify-send "SwayNC" "swaync is not installed or not in PATH"
    exit 127
}

if pgrep -x swaync >/dev/null 2>&1; then
    # Already running: hot-reload config/style instead of killing it, so a
    # Waybar reload (SUPER+SHIFT+R) doesn't drop notifications at the moment
    # of the kill+relaunch.
    if command -v swaync-client >/dev/null 2>&1; then
        swaync-client -R  >/dev/null 2>&1 || true
        swaync-client -rs >/dev/null 2>&1 || true
    fi
else
    swaync &
fi