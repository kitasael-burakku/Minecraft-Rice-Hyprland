#!/usr/bin/env bash
# ============================================================================
#  wallpaper_rofi.sh  —  selector de tipo (nivel 0, modi interno)
# ============================================================================

set -u
set -o pipefail

WALLPAPER_DIR_VIDEO="${WALLPAPER_DIR_VIDEO:-$HOME/Videos/Wallpapers}"
WALLPAPER_DIR_IMG="${WALLPAPER_DIR_IMG:-$HOME/Pictures/Wallpapers}"
THUMB_DIR="${THUMB_DIR:-$HOME/.cache/rofi-wallpapers/thumbs}"
GEN_SCRIPT="${GEN_SCRIPT:-$HOME/.config/rofi/scripts/generate-thumbs.sh}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper.log"
NEXT_FILE="${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next"

mkdir -p "$THUMB_DIR"

video_active() {
    pgrep -x mpvpaper >/dev/null 2>&1
}

if [ "${ROFI_RETV:-0}" = "1" ]; then
    chosen="${1:-}"
    echo "$(date) TIPO ELEGIDO: $chosen" >> "$LOG"

    case "$chosen" in
        *"Kill video wallpaper"*)
            pkill -x mpvpaper 2>/dev/null
            echo "$(date) VIDEO WALLPAPER KILLED (imagen actual de awww queda intacta)" >> "$LOG"
            # Por si quedó un hand-off de una selección anterior, lo limpiamos
            # para que el wrapper no reaccione a datos viejos.
            rm -f "$NEXT_FILE"
            exit 0
            ;;
        *"Video"*)
            src_dir="$WALLPAPER_DIR_VIDEO"
            prompt_label="Video"
            ;;
        *"Imagen"*)
            src_dir="$WALLPAPER_DIR_IMG"
            prompt_label="Imagen"
            ;;
        *)
            echo "$(date) ERROR: Unknown type '$chosen'" >> "$LOG"
            exit 1
            ;;
    esac

    # Solo relanzar el generador de thumbnails si hay wallpapers más nuevos
    # que el último escaneo completo — evita ~137 fork+exec de "basename" en
    # cada apertura del picker cuando no cambió nada (caso común).
    MARKER="$THUMB_DIR/.last-scan"
    if [ -x "$GEN_SCRIPT" ] && { [ ! -f "$MARKER" ] || find "$WALLPAPER_DIR_VIDEO" "$WALLPAPER_DIR_IMG" -newer "$MARKER" -print -quit 2>/dev/null | grep -q .; }; then
        nohup bash "$GEN_SCRIPT" >"${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-gen.log" 2>&1 &
        disown
    fi

    # Dejar instrucciones para el wrapper y salir — rofi cerrará solo
    printf '%s\t%s' "$src_dir" "$prompt_label" > "$NEXT_FILE"

    exit 0
fi

echo -en "\0prompt\x1fWallpaper\n"
echo -en "\0no-custom\x1ftrue\n"

if video_active; then
    echo -en "Kill video wallpaper\0icon\x1fmedia-playback-stop\n"
fi

echo -en "Video\0icon\x1fvideo-x-generic\n"
echo -en "Imagen\0icon\x1fimage-x-generic\n" 