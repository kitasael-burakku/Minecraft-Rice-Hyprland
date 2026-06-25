#!/usr/bin/env bash

set -u

command -v waybar >/dev/null 2>&1 || {
    command -v notify-send >/dev/null 2>&1 && notify-send "Waybar" "waybar is not installed or not in PATH"
    exit 127
}

pkill -x waybar 2>/dev/null || true

waybar &