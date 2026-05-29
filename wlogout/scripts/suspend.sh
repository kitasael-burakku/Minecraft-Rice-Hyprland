#!/usr/bin/env bash

set -u

if command -v hyprlock >/dev/null 2>&1; then
    hyprlock &
    sleep 0.8
fi

systemctl suspend