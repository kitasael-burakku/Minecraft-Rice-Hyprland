#!/usr/bin/env bash

set -u

layout="$HOME/.config/wlogout/layout"
style="$HOME/.config/wlogout/style.css"

command -v wlogout >/dev/null 2>&1 || {
    command -v notify-send >/dev/null 2>&1 && notify-send "Wlogout" "wlogout is not installed or not in PATH"
    exit 127
}

# If a wlogout instance already exists, close it and exit the script
if pgrep -x "wlogout" > /dev/null
then
    pkill -x wlogout
    exit 0
fi

# If it's not open, launch it with your config
wlogout -l "$layout" -C "$style" &