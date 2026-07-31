#!/usr/bin/env bash
# ============================================================================
#  player.sh — metadata + barra de progreso del reproductor activo, para
#  hyprlock/layouts/layout.conf
# ----------------------------------------------------------------------------
#  Reemplaza a music-progress.sh + playerlayout4.sh (fusionados): los dos
#  elegían el reproductor con políticas distintas (uno prefería "spotify" a
#  mano y si no el primero alfabético de `playerctl -l`; el otro tomaba el
#  default de playerctl), así que con más de un reproductor abierto el
#  título podía mostrar uno mientras la barra seguía a otro. Acá hay una
#  sola decisión de reproductor, cacheada, que alimenta las tres filas.
#
#  BUG que esto reemplaza (confirmado en vivo contra un video real en curso,
#  8:23 de 12:48): `playerctl position` devuelve SEGUNDOS pero
#  `mpris:length` devuelve MICROSEGUNDOS — music-progress.sh mezclaba los
#  dos, así que la barra estaba siempre en 0% y el tiempo en 0:00 sin
#  importar el reproductor. Acá se piden ambos campos dentro de un solo
#  --format, donde `{{ position }}` sí devuelve microsegundos — misma unidad
#  que mpris:length, sin conversión manual ni caché de "avance sintético".
#
#  Uso: player.sh --source | --title | --bar
# ============================================================================
set -o pipefail

CACHE="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-player.cache"
BAR_LENGTH=16
SEP=$'\x1f' # separador de campos: un "|" real puede aparecer en un título

command -v playerctl >/dev/null 2>&1 || { echo ""; exit 0; }

# Colores Pango/HTML de la barra — valores por defecto (paleta estática
# "Kitasan Glass"), sobreescritos por music-colors.sh si matugen ya generó
# uno (dinámico, sigue al wallpaper). Ver
# matugen/templates/music-progress-colors.sh. El resto del texto de la
# tarjeta (fuente, título, tiempos) toma su color del `color =` del propio
# `label` en layout.conf, no de acá.
COLOR_PLAYED="#7ab8b8"
COLOR_REMAINING="#e8e8e840"
MUSIC_COLORS="$HOME/.config/hyprlock/scripts/music-colors.sh"
# shellcheck disable=SC1090
[ -f "$MUSIC_COLORS" ] && source "$MUSIC_COLORS"

# Escapa markup Pango: fuente/título/artista se interpolan crudos en un
# <span> de layout.conf, y un título con "&" o "<" (común en pestañas de
# navegador, ej. "Tom & Jerry") rompe el render sin esto.
escape_pango() {
    local s="$1"
    # "\&" a propósito: en "${var//pat/repl}" bash trata un "&" suelto en
    # repl como "lo que matcheó" (igual que sed) — sin escaparlo, "&lt;" se
    # reescribe mal como "<lt;" cuando el patrón es "<".
    s="${s//&/\&amp;}"
    s="${s//</\&lt;}"
    s="${s//>/\&gt;}"
    printf '%s' "$s"
}

# Las 3 filas de la tarjeta comparten un caché de ~1s: layout.conf dispara
# --source/--title/--bar cada 1000ms cada una, así que sin esto cada tick
# haría 3 llamadas separadas a playerctl. Con el caché, solo la primera
# llamada del tick consulta de verdad; las otras dos leen el resultado ya
# escrito (mismo patrón que META_CACHE en la vieja playerlayout4.sh).
load_state() {
    local mtime age
    if [ -f "$CACHE" ]; then
        mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)
        age=$(( $(date +%s) - mtime ))
    else
        age=999
    fi

    if [ "$age" -ge 1 ]; then
        # Una sola llamada trae TODOS los reproductores de una — evita que
        # cada fila de la tarjeta elija el suyo por separado (el bug de raíz
        # de la versión anterior).
        local raw chosen
        raw="$(playerctl -a metadata --format \
            "{{playerName}}${SEP}{{status}}${SEP}{{position}}${SEP}{{mpris:length}}${SEP}{{xesam:title}}${SEP}{{xesam:artist}}" \
            2>/dev/null)"

        # Prioridad: el primero que esté Playing; si ninguno, el primero
        # Paused; si no hay ninguno, vacío. (Antes: "spotify" fijo o el
        # primero alfabético — ninguno de los dos refleja cuál está
        # realmente sonando.)
        chosen="$(printf '%s\n' "$raw" | awk -F"$SEP" '$2=="Playing"{print; exit}')"
        if [ -z "$chosen" ]; then
            chosen="$(printf '%s\n' "$raw" | awk -F"$SEP" '$2=="Paused"{print; exit}')"
        fi

        {
            if [ -n "$chosen" ]; then
                local p_name p_status p_pos p_len p_title p_artist
                IFS="$SEP" read -r p_name p_status p_pos p_len p_title p_artist <<< "$chosen"
                printf 'P_NAME=%q\n' "$p_name"
                printf 'P_STATUS=%q\n' "$p_status"
                printf 'P_POS=%q\n' "$p_pos"
                printf 'P_LEN=%q\n' "$p_len"
                printf 'P_TITLE=%q\n' "$p_title"
                printf 'P_ARTIST=%q\n' "$p_artist"
            else
                printf 'P_NAME=\n'
            fi
        } > "$CACHE"
    fi

    # shellcheck disable=SC1090
    source "$CACHE" 2>/dev/null
}

# Ícono + nombre legible por fuente. Los 4 casos con marca propia se
# mantienen; cualquier otro reproductor usa el nombre que reporta playerctl
# en vez de desaparecer la fila (antes: cadena vacía para todo lo que no
# fuera Firefox/Spotify/Chromium/YoutubeMusic).
source_label() {
    case "$P_NAME" in
        *firefox*|*zen*)         echo "Firefox" ;;
        *[Ss]potify*)            echo "Spotify" ;;
        *chromium*|*chrome*)     echo "Chrome" ;;
        *)                       echo "$(escape_pango "${P_NAME^}") " ;;
    esac
}

format_time() {
    local total=$1
    printf '%d:%02d' $(( total / 60 )) $(( total % 60 ))
}

# Construye la barra en octavos de carácter (BAR_LENGTH * 8 pasos en vez de
# BAR_LENGTH) para que avance suave en vez de saltar de bloque en bloque.
# Devuelve "parte_llena<SEP>parte_vacía" — cada una se colorea aparte.
render_bar() {
    local pos=$1 len=$2 status=$3
    local steps_total=$(( BAR_LENGTH * 8 ))
    local steps=$(( pos * steps_total / len ))
    (( steps < 0 )) && steps=0
    (( steps > steps_total )) && steps=$steps_total
    # Igual que antes: si recién arrancó y está sonando, mostrar al menos
    # una fracción en vez de una barra que parece congelada/vacía.
    if [ "$status" = "Playing" ] && [ "$steps" -eq 0 ]; then
        steps=1
    fi

    local partials=("▏" "▎" "▍" "▌" "▋" "▊" "▉")
    local full=$(( steps / 8 ))
    local rem=$(( steps % 8 ))
    local played="" empty="" i

    for (( i = 0; i < full; i++ )); do played+="█"; done
    if [ "$rem" -gt 0 ] && [ "$full" -lt "$BAR_LENGTH" ]; then
        played+="${partials[$((rem - 1))]}"
        full=$(( full + 1 ))
    fi
    for (( i = full; i < BAR_LENGTH; i++ )); do empty+="░"; done

    printf '%s%s%s' "$played" "$SEP" "$empty"
}

case "${1:-}" in
    --source)
        load_state
        [ -z "$P_NAME" ] && { echo ""; exit 0; }
        icon="󰐊"
        [ "$P_STATUS" = "Paused" ] && icon="󰏤"
        echo "$icon  $(source_label)"
        ;;
    --title)
        load_state
        [ -z "$P_NAME" ] && { echo ""; exit 0; }
        if [ -n "$P_TITLE" ] && [ -n "$P_ARTIST" ]; then
            escape_pango "${P_TITLE:0:42} — ${P_ARTIST:0:30}"
        elif [ -n "$P_TITLE" ]; then
            escape_pango "${P_TITLE:0:50}"
        elif [ -n "$P_ARTIST" ]; then
            escape_pango "${P_ARTIST:0:50}"
        else
            echo ""
        fi
        ;;
    --bar)
        load_state
        [ -z "$P_NAME" ] && { echo ""; exit 0; }
        if ! [[ "${P_LEN:-}" =~ ^[0-9]+$ ]] || [ "$P_LEN" -le 0 ] || ! [[ "${P_POS:-}" =~ ^[0-9]+$ ]]; then
            # Sin duración/posición válida (stream en vivo, metadata
            # incompleta) — el título ya cubrió esta fila, acá evitamos
            # imprimir "0:00 / 0:00" sin sentido.
            echo ""
            exit 0
        fi
        played_empty="$(render_bar "$P_POS" "$P_LEN" "$P_STATUS")"
        IFS="$SEP" read -r played empty <<< "$played_empty"
        pos_sec=$(( P_POS / 1000000 ))
        len_sec=$(( P_LEN / 1000000 ))
        printf '<span foreground="%s">%s</span><span foreground="%s">%s</span>  %s / %s\n' \
            "$COLOR_PLAYED" "$played" "$COLOR_REMAINING" "$empty" \
            "$(format_time "$pos_sec")" "$(format_time "$len_sec")"
        ;;
    *)
        echo "Usage: $0 --source | --title | --bar" >&2
        exit 1
        ;;
esac
