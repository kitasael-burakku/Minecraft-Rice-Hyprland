#!/usr/bin/env bash
set -o pipefail

META_CACHE="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-mpris-meta.cache"

if [ $# -eq 0 ]; then
    echo "Usage: $0 --title | --artist | --source"
    exit 1
fi

# Solo playerctl: los 3 flags de este script lo usan. curl/magick/pkill
# ya no hacen falta desde que se sacó fetch_thumb() (descargaba una carátula
# que ningún widget de layout.conf mostraba nunca).
for cmd in playerctl; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo ""
        exit 0
    }
done

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

# --title/--artist/--source comparten un solo caché de metadata con ventana
# de frescura de 3s: layout.conf dispara los tres cada 3000ms, así que sin
# esto cada tick hacía 3 llamadas separadas a playerctl. Con el caché, solo
# la primera llamada del tick consulta playerctl de verdad; las otras dos
# leen el resultado.
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
--source)
    load_metadata
    get_source_info "$TRACKID"
    ;;
*)
    echo "Invalid option: $1"
    echo "Usage: $0 --title | --artist | --source" ; exit 1
    ;;
esac
