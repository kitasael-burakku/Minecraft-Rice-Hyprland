#!/usr/bin/env bash

THUMB="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-mpris-thumb"
META_CACHE="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-mpris-meta.cache"

if [ $# -eq 0 ]; then
    echo "Usage: $0 --title | --artist | --position | --length | --album | --status | --source"
    exit 1
fi

for cmd in playerctl curl magick pkill; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo ""
        exit 0
    }
done

# Function to get metadata using playerctl (usado solo por los flags que no
# pasan por el caché compartido: --position, --length, --album)
get_metadata() {
    key=$1
    playerctl metadata --format "{{ $key }}" 2>/dev/null
}

# Escapa markup Pango: title/artist se interpolan crudos en un <span> de
# hyprlock/layouts/layout.conf, y un título con "&" o "<" (común en pestañas
# de navegador, ej. "Tom & Jerry") rompe el render sin esto.
escape_pango() {
    local s="$1"
    # "\&" a propósito: en "${var//pat/repl}" bash trata un "&" suelto en
    # repl como "lo que matcheó" (igual que sed) — sin escaparlo, "&lt;"
    # se reescribe mal como "<lt;" cuando el patrón es "<".
    s="${s//&/\&amp;}"
    s="${s//</\&lt;}"
    s="${s//>/\&gt;}"
    echo "$s"
}

# Function to determine the source and return an icon and text
get_source_info() {
    local trackid="$1"
    if [[ "$trackid" == *"firefox"* ]]; then
        echo -e "Firefox 󰈹"
    elif [[ "$trackid" == *"spotify"* ]]; then
        echo -e "Spotify "
    elif [[ "$trackid" == *"chromium"* ]]; then
        echo -e "Chrome "
    elif [[ "$trackid" == *"YoutubeMusic"* ]]; then
        echo -e "YouTubeMusic "
    else
        echo ""
    fi
}

# Function to get position using playerctl
get_position() {
    playerctl position 2>/dev/null
}

# Function to convert microseconds to minutes and seconds
convert_length() {
    local length=$1
    local seconds=$((length / 1000000))
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%d:%02d m" $minutes $remaining_seconds
}

# Function to convert seconds to minutes and seconds
convert_position() {
    local position=$1
    local seconds=${position%.*} # Remove fractional part if exists
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%d:%02d" $minutes $remaining_seconds
}

# Function to fetch album art (se dispara solo cuando el caché de metadata
# se refresca de verdad, no en cada invocación del script)
fetch_thumb() {
    artUrl=$(playerctl -p spotify metadata --format '{{mpris:artUrl}}' 2>/dev/null)
    [[ -z "$artUrl" ]] && return 0
    [[ -f "${THUMB}.inf" && "${artUrl}" = "$(cat "${THUMB}.inf")" ]] && return 0

    printf "%s\n" "$artUrl" > "${THUMB}.inf"

    curl -so "${THUMB}.png" "$artUrl"
    magick "${THUMB}.png" -quality 50 "${THUMB}.png"
    # Avisa a hyprlock para que relea el thumbnail actualizado
    pkill -USR2 hyprlock 2>/dev/null || true
}

# --title/--artist/--source comparten un solo caché de metadata con ventana
# de frescura de 3s: layout.conf dispara los tres cada 3000ms, así que sin
# esto cada tick hacía 3 llamadas separadas a playerctl (más 3 fetch_thumb
# redundantes en background). Con el caché, solo la primera llamada del
# tick consulta playerctl de verdad; las otras dos leen el resultado.
load_metadata() {
    local mtime age
    if [ -f "$META_CACHE" ]; then
        mtime=$(stat -c %Y "$META_CACHE" 2>/dev/null || echo 0)
        age=$(( $(date +%s) - mtime ))
    else
        age=999
    fi

    if [ "$age" -ge 3 ]; then
        local title artist trackid
        title=$(playerctl metadata --format "{{ xesam:title }}" 2>/dev/null)
        artist=$(playerctl metadata --format "{{ xesam:artist }}" 2>/dev/null)
        trackid=$(playerctl metadata --format "{{ mpris:trackid }}" 2>/dev/null)
        {
            printf 'TITLE=%q\n' "$title"
            printf 'ARTIST=%q\n' "$artist"
            printf 'TRACKID=%q\n' "$trackid"
        } > "$META_CACHE"
        fetch_thumb &
    fi

    # shellcheck disable=SC1090
    source "$META_CACHE" 2>/dev/null
}

# Parse the argument
case "$1" in
--title)
    load_metadata
    if [ -z "$TITLE" ]; then
        echo ""
    else
        escape_pango "${TITLE:0:50}" # Limit the output to 50 characters
    fi
    ;;
--artist)
    load_metadata
    if [ -z "$ARTIST" ]; then
        echo ""
    else
        escape_pango "${ARTIST:0:50}" # Limit the output to 50 characters
    fi
    ;;
--position)
    position=$(get_position)
    length=$(get_metadata "mpris:length")
    if [ -z "$position" ] || [ -z "$length" ]; then
        echo ""
    else
        position_formatted=$(convert_position "$position")
        length_formatted=$(convert_length "$length")
        echo "$position_formatted/$length_formatted"
    fi
    ;;
--length)
    length=$(get_metadata "mpris:length")
    if [ -z "$length" ]; then
        echo ""
    else
        convert_length "$length"
    fi
    ;;
--status)
    status=$(playerctl status 2>/dev/null)
    if [[ $status == "Playing" ]]; then
        echo "󰎆"
    elif [[ $status == "Paused" ]]; then
        echo "󱑽"
    else
        echo ""
    fi
    ;;
--album)
    album=$(playerctl metadata --format "{{ xesam:album }}" 2>/dev/null)
    if [[ -n $album ]]; then
        echo "$album"
    else
        status=$(playerctl status 2>/dev/null)
        if [[ -n $status ]]; then
            echo "Not album"
        else
            echo ""
        fi
    fi
    ;;
--source)
    load_metadata
    get_source_info "$TRACKID"
    ;;
*)
    echo "Invalid option: $1"
    echo "Usage: $0 --title | --artist | --position | --length | --album | --status | --source" ; exit 1
    ;;
esac
