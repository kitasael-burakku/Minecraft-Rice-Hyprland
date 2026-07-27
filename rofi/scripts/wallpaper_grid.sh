#!/usr/bin/env bash
# ============================================================================
#  wallpaper_grid.sh  —  grid picker (nivel 1, modi interno)
# ============================================================================

set -u
set -o pipefail

SRC_DIR="${WALLPAPER_SRC_DIR:-$HOME/Videos/Wallpapers}"
PROMPT_LABEL="${WALLPAPER_PROMPT:-󰎁  Video}"

THUMB_DIR="${THUMB_DIR:-$HOME/.cache/rofi-wallpapers/thumbs}"
RELOAD_SCRIPT="${RELOAD_SCRIPT:-$HOME/.config/rofi/scripts/matugen_reload.sh}"
MONITOR="${WALLPAPER_MONITOR:-}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper.log"

display_name() {
    local f="$1"
    f="${f%.*}"
    f="${f//_/ }"
    f="${f//-/ }"
    printf '%s' "$f"
}

# Lista filtrada de wallpapers (mismas extensiones que se ofrecen en el grid).
# Compartida entre el listado y la resolución de la selección, para que
# ambos vean exactamente el mismo conjunto de archivos.
collect_files() {
    files=()
    shopt -s nullglob nocaseglob
    files=("$SRC_DIR"/*.mp4 "$SRC_DIR"/*.mkv "$SRC_DIR"/*.mov "$SRC_DIR"/*.webm \
           "$SRC_DIR"/*.jpg "$SRC_DIR"/*.jpeg "$SRC_DIR"/*.png "$SRC_DIR"/*.webp "$SRC_DIR"/*.gif)
    shopt -u nullglob nocaseglob
}

# display_name() normaliza "_" Y "-" a espacio, así que p.ej. "night_city.mp4"
# y "night-city.mp4" colapsan al mismo texto — sin desambiguar, la resolución
# inversa (que matchea por ese texto) se queda con el primero que encuentra y
# el segundo archivo queda inalcanzable. name_count se llena antes de listar
# o resolver, contando cuántos archivos comparten cada display_name; si un
# archivo choca, se le agrega la extensión para volverlo único. El caso
# normal (sin colisión, hoy el 100% de los archivos) no cambia.
declare -A name_count

count_names() {
    local f base name
    for f in "${files[@]}"; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        name="$(display_name "$base")"
        name_count["$name"]=$(( ${name_count["$name"]:-0} + 1 ))
    done
}

display_name_unique() {
    local f="$1" base name
    base="$(basename "$f")"
    name="$(display_name "$base")"
    if [ "${name_count[$name]:-0}" -gt 1 ]; then
        # El nombre crudo del archivo siempre es único dentro del directorio
        # (a diferencia de solo la extensión: "night_city.mp4" vs
        # "night-city.mp4" chocan en extensión también).
        name="$name ($base)"
    fi
    printf '%s' "$name"
}

# La aplicación real (mpvpaper/awww), la persistencia para el próximo
# arranque, y la herencia del wallpaper en hyprlock viven todas en
# hypr/scripts/apply-wallpaper.sh — fuente única compartida con
# hypr/modules/autostart.lua, no hay una segunda copia de los flags.
APPLY_WALLPAPER_SCRIPT="$HOME/.config/hypr/scripts/apply-wallpaper.sh"

apply_wallpaper() {
    local target="$1"
    if [ ! -x "$APPLY_WALLPAPER_SCRIPT" ]; then
        echo "$(date) ERROR: no se encontró apply-wallpaper.sh" >> "$LOG"
        return 1
    fi
    "$APPLY_WALLPAPER_SCRIPT" "$target" "$MONITOR"
}

if [ "${ROFI_RETV:-0}" = "1" ]; then
    chosen_display="${1:-}"
    echo "$(date) GRID SELECTED: $chosen_display (dir: $SRC_DIR)" >> "$LOG"

    target=""
    collect_files
    count_names
    for f in "${files[@]}"; do
        [ -f "$f" ] || continue
        if [ "$(display_name_unique "$f")" = "$chosen_display" ]; then
            target="$f"
            break
        fi
    done

    if [ -z "$target" ]; then
        echo "$(date) ERROR: no se encontró '$chosen_display' en $SRC_DIR" >> "$LOG"
        exit 1
    fi

    echo "$(date) APPLYING: $target" >> "$LOG"
    apply_wallpaper "$target" || exit 1

    if [ -x "$RELOAD_SCRIPT" ]; then
        nohup bash "$RELOAD_SCRIPT" "$target" >"${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-reload.log" 2>&1 &
        disown
    fi

    exit 0
fi

echo -en "\0prompt\x1f${PROMPT_LABEL}\n"
echo -en "\0no-custom\x1ftrue\n"

[ -d "$SRC_DIR" ] || exit 0

collect_files
count_names
for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    name="$(display_name_unique "$f")"
    thumb="$THUMB_DIR/${base}.jpg"

    if [ -f "$thumb" ]; then
        echo -en "${name}\0icon\x1f${thumb}\n"
    else
        echo -en "${name}\n"
    fi
done