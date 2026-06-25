#!/usr/bin/env bash

CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
CACHE_TTL=300  # 5 minutos

# Usar caché si existe y es reciente
if [[ -f "$CACHE_FILE" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if [[ $age -lt $CACHE_TTL ]]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

updates=0
aur=0

if command -v checkupdates >/dev/null 2>&1; then
    updates=$(checkupdates 2>/dev/null | wc -l)
fi

if command -v yay >/dev/null 2>&1; then
    aur=$(timeout 15 yay -Qua 2>/dev/null | wc -l)
fi

total=$((updates + aur))

if [[ "$total" -eq 0 ]]; then
    result='{"text":"󰄬","tooltip":"Sistema actualizado"}'
else
    result="{\"text\":\"󰚰 $total\",\"tooltip\":\"󰣇 $updates pacman\n $aur AUR\"}"
fi

echo "$result" | tee "$CACHE_FILE"