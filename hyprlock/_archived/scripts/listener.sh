#!/usr/bin/env bash

log_file="/tmp/dunst_log"

[ -r "$log_file" ] || exit 0
command -v hyprctl >/dev/null 2>&1 || exit 0

tail -f "$log_file" | while read -r line; do
    echo "New Notification: $line"
    hyprctl hyprlock:text notify1 "$line"
done