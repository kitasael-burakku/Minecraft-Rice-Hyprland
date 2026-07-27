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

apply_wallpaper() {
    local target="$1"
    local ext_lc
    ext_lc="$(printf '%s' "${target##*.}" | tr '[:upper:]' '[:lower:]')"

    case "$ext_lc" in
        mp4|mkv|mov|webm)
            pkill -x mpvpaper 2>/dev/null
            sleep 0.1
            if [ -n "$MONITOR" ]; then
                nohup mpvpaper -o "no-audio --loop-file --hwdec=auto" "$MONITOR" "$target" \
                    >"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 &
            else
                nohup mpvpaper -o "no-audio --loop-file --hwdec=auto" '*' "$target" \
                    >"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 &
            fi
            disown
            ;;
        jpg|jpeg|png|webp|gif)
            pkill -x mpvpaper 2>/dev/null
            # Backend nativo awww restaurado y optimizado sin sleeps
            awww img "$target" --transition-type any --transition-fps 60 >/dev/null 2>&1
            ;;
        *)
            echo "$(date) ERROR: extensión no soportada: $target" >> "$LOG"
            return 1
            ;;
    esac
}

if [ "${ROFI_RETV:-0}" = "1" ]; then
    chosen_display="${1:-}"
    echo "$(date) GRID SELECTED: $chosen_display (dir: $SRC_DIR)" >> "$LOG"

    target=""
    shopt -s nullglob
    for f in "$SRC_DIR"/*; do
        [ -f "$f" ] || continue
        if [ "$(display_name "$(basename "$f")")" = "$chosen_display" ]; then
            target="$f"
            break
        fi
    done
    shopt -u nullglob

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

shopt -s nullglob nocaseglob
files=("$SRC_DIR"/*.mp4 "$SRC_DIR"/*.mkv "$SRC_DIR"/*.mov "$SRC_DIR"/*.webm \
       "$SRC_DIR"/*.jpg "$SRC_DIR"/*.jpeg "$SRC_DIR"/*.png "$SRC_DIR"/*.webp "$SRC_DIR"/*.gif)
for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    name="$(display_name "$base")"
    thumb="$THUMB_DIR/${base}.jpg"

    if [ -f "$thumb" ]; then
        echo -en "${name}\0icon\x1f${thumb}\n"
    else
        echo -en "${name}\n"
    fi
done
shopt -u nullglob nocaseglob