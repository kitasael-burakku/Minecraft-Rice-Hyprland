#!/usr/bin/env bash

music_config="$HOME/.config/hyprlock/music.conf"

if command -v playerctl >/dev/null 2>&1 \
    && command -v glava >/dev/null 2>&1 \
    && [ -r "$music_config" ] \
    && [[ "$(playerctl -p spotify status 2>/dev/null)" == "Playing" ]]; then
    pkill -x glava 2>/dev/null || true

    # Start Glava (NOT desktop mode)
    glava &
    sleep 0.6

    # Focus Glava window
    hyprctl dispatch focuswindow class:glava
    sleep 0.1

    # Fullscreen focused window
    hyprctl dispatch fullscreen 

    # Lock screen
    hyprlock --config "$music_config"
else
    hyprlock
fi

pkill -x glava 2>/dev/null || true