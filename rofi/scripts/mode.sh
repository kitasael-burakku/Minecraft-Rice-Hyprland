#!/usr/bin/env bash
# ============================================================================
#  mode.sh — selector de perfil de escritorio, vía rofi
#  (normal/focus/gaming/cinema — ver hypr/scripts/desktop-mode.sh)
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/clipboard.rasi"
SCRIPT="$HOME/.config/hypr/scripts/desktop-mode.sh"

current="$(bash "$SCRIPT" status 2>/dev/null)"

LABELS=(
    "󰋜  Normal"
    "󰒱  Focus"
    "󰊗  Gaming"
    "󰎁  Cinema"
)
MODES=(normal focus gaming cinema)

menu=""
for i in "${!LABELS[@]}"; do
    label="${LABELS[$i]}"
    [ "${MODES[$i]}" = "$current" ] && label="$label  (actual)"
    menu+="$label"$'\n'
done

chosen=$(printf '%s' "$menu" | rofi -dmenu -p "Modo" -theme "$THEME")
[ -n "$chosen" ] || exit 0

for i in "${!LABELS[@]}"; do
    if [[ "$chosen" == "${LABELS[$i]}"* ]]; then
        bash "$SCRIPT" "${MODES[$i]}"
        exit 0
    fi
done
