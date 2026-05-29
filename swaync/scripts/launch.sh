#!/usr/bin/env bash

set -u

command -v swaync >/dev/null 2>&1 || {
    command -v notify-send >/dev/null 2>&1 && notify-send "SwayNC" "swaync is not installed or not in PATH"
    exit 127
}

pkill -x swaync 2>/dev/null || true
swaync &