#!/usr/bin/env bash
# ============================================================================
#  audio.sh — cambiar el sink/source de audio por defecto, vía rofi
# ----------------------------------------------------------------------------
#  pavucontrol es una GUI pesada para "cambiar a los auriculares". wpctl (ya
#  usado por los binds de volumen en hypr/modules/keybinds.lua) alcanza para
#  listar y fijar el default — esto sólo le pone una lista rofi encima.
#
#  Parsea `wpctl status`, que dibuja los sinks/sources como árbol ASCII, ej.:
#    ├─ Sinks:
#    │  *   71. Navi 31 HDMI/DP Audio Digital Stereo (HDMI) [vol: 1.00]
#  El "*" marca el default actual. No hay flag de wpctl para listar en un
#  formato más fácil de parsear (a diferencia de `pactl list short sinks`,
#  que usa OTRO esquema de IDs — mezclarlos apuntaría al dispositivo
#  equivocado), así que esto se queda con wpctl de punta a punta.
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/clipboard.rasi"

command -v wpctl >/dev/null 2>&1 || exit 0

declare -A ID_OF
menu=""

extract_section() {
    local header="$1"
    wpctl status 2>/dev/null | awk -v h="$header" '
        index($0, h) { on=1; next }
        on && /├─ [A-Za-z]/ { exit }
        on && /└─ [A-Za-z]/ { exit }
        on { print }
    '
}

add_section() {
    local header="$1" icon="$2"
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local id name is_default label
        id=$(printf '%s' "$line" | grep -oP '^\s*\S?\s*\*?\s*\K[0-9]+(?=\.)')
        [ -n "$id" ] || continue
        name=$(printf '%s' "$line" | grep -oP '^\s*\S?\s*\*?\s*[0-9]+\.\s+\K.*(?=\s*\[vol:)')
        [ -n "$name" ] || name="(Unnamed)"
        is_default=""
        printf '%s' "$line" | grep -qP '^\s*\S?\s*\*' && is_default=" (Current)"
        label="${icon}  ${name}${is_default}"
        ID_OF["$label"]="$id"
        menu+="$label"$'\n'
    done < <(extract_section "$header")
}

add_section "├─ Sinks:" "󰓃"
add_section "├─ Sources:" "󰍬"

if [ -z "$menu" ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "Audio" "No sinks/sources found"
    exit 0
fi

chosen=$(printf '%s' "$menu" | rofi -dmenu -p "Audio" -theme "$THEME")
[ -n "$chosen" ] || exit 0

id="${ID_OF[$chosen]}"
[ -n "$id" ] || exit 0

wpctl set-default "$id"
