#!/usr/bin/env bash

updates=0
aur=0

if command -v checkupdates >/dev/null 2>&1; then
    updates=$(checkupdates 2>/dev/null | wc -l)
fi

if command -v yay >/dev/null 2>&1; then
    aur=$(yay -Qua 2>/dev/null | wc -l)
fi

total=$((updates + aur))

if [ "$total" -eq 0 ]; then
    echo '{"text":"󰄬","tooltip":"System fully updated"}'
else
    echo "{\"text\":\"󰚰 $total\",\"tooltip\":\"$updates pacman\\n$aur AUR updates\"}"
fi