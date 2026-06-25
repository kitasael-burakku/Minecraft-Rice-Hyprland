#!/usr/bin/env bash
# ============================================================================
#  wallpaper_rofi.sh  —  selector de tipo (nivel 0, modi interno)
# ============================================================================

set -u

WALLPAPER_DIR_VIDEO="${WALLPAPER_DIR_VIDEO:-$HOME/Videos/wallpapersvideo}"
WALLPAPER_DIR_IMG="${WALLPAPER_DIR_IMG:-$HOME/Pictures/Wallpapers}"
THUMB_DIR="${THUMB_DIR:-$HOME/.cache/rofi-wallpapers/thumbs}"
GEN_SCRIPT="${GEN_SCRIPT:-$HOME/.config/rofi/scripts/generate-thumbs.sh}"
LOG="/tmp/rofi-wallpaper.log"

mkdir -p "$THUMB_DIR"

if [ "${ROFI_RETV:-0}" = "1" ]; then
    chosen="${1:-}"
    echo "$(date) TIPO ELEGIDO: $chosen" >> "$LOG"

    case "$chosen" in
        *"Video"*)
            src_dir="$WALLPAPER_DIR_VIDEO"
            prompt_label="󰎁  Video"
            ;;
        *"Imagen"*)
            src_dir="$WALLPAPER_DIR_IMG"
            prompt_label="󰉏  Imagen"
            ;;
        *)
            echo "$(date) ERROR: tipo desconocido '$chosen'" >> "$LOG"
            exit 1
            ;;
    esac

    if [ -x "$GEN_SCRIPT" ]; then
        nohup bash "$GEN_SCRIPT" >/tmp/rofi-wallpaper-gen.log 2>&1 &
        disown
    fi

    # Dejar instrucciones para el wrapper y salir — rofi cerrará solo
    printf '%s\t%s' "$src_dir" "$prompt_label" > /tmp/rofi-wallpaper-next

    exit 0
fi

echo -en "\0prompt\x1fWallpaper\n"
echo -en "\0no-custom\x1ftrue\n"
echo -en "󰎁  Video\0icon\x1fvideo-x-generic\n"
echo -en "󰉏  Imagen\0icon\x1fimage-x-generic\n"