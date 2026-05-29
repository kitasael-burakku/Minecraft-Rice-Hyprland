#!/usr/bin/env bash

sleep 2

if ! command -v terminal-bg >/dev/null 2>&1; then
    notify-send "terminal-bg" "No se encontró terminal-bg"
    exit 1
fi

if ! command -v cava >/dev/null 2>&1; then
    notify-send "terminal-bg" "No se encontró cava"
    exit 1
fi

pkill -f "terminal-bg --script cava"

terminal-bg --script cava