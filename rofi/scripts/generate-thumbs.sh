#!/usr/bin/env bash
# ============================================================================
#  generate-thumbs.sh — genera thumbnails para el wallpaper picker
#  Imágenes : convert (ImageMagick)
#  Videos   : ffmpegthumbnailer
# ============================================================================

set -u
set -o pipefail

WALLPAPER_DIR_VIDEO="${WALLPAPER_DIR_VIDEO:-$HOME/Videos/Wallpapers}"
WALLPAPER_DIR_IMG="${WALLPAPER_DIR_IMG:-$HOME/Pictures/Wallpapers}"
THUMB_DIR="${THUMB_DIR:-$HOME/.cache/rofi-wallpapers/thumbs}"
THUMB_SIZE="${THUMB_SIZE:-320}"   # ancho del thumbnail en píxeles
LOG="${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-gen.log"

mkdir -p "$THUMB_DIR"

generated=0
skipped=0
errors=0

process_image() {
    local src="$1"
    local thumb="$THUMB_DIR/$(basename "$src").jpg"

    [ -f "$thumb" ] && { skipped=$((skipped + 1)); return 0; }

    convert "$src[0]" \
        -thumbnail "${THUMB_SIZE}x" \
        -quality 85 \
        "$thumb" >>"$LOG" 2>&1 \
    && generated=$((generated + 1)) \
    || { echo "$(date) ERROR imagen: $src" >> "$LOG"; errors=$((errors + 1)); }
}

process_video() {
    local src="$1"
    local thumb="$THUMB_DIR/$(basename "$src").jpg"

    [ -f "$thumb" ] && { skipped=$((skipped + 1)); return 0; }

    ffmpegthumbnailer \
        -i "$src" \
        -o "$thumb" \
        -s "$THUMB_SIZE" \
        -q 8 \
        -t 10% \
        >>"$LOG" 2>&1 \
    && generated=$((generated + 1)) \
    || { echo "$(date) ERROR video: $src" >> "$LOG"; errors=$((errors + 1)); }
}

echo "$(date) === generate-thumbs START ===" >> "$LOG"

# ── Imágenes ──────────────────────────────────────────────────────────────────
if [ -d "$WALLPAPER_DIR_IMG" ]; then
    shopt -s nullglob nocaseglob
    for f in "$WALLPAPER_DIR_IMG"/*.{jpg,jpeg,png,webp,gif}; do
        [ -f "$f" ] && process_image "$f"
    done
    shopt -u nullglob nocaseglob
fi

# ── Videos ────────────────────────────────────────────────────────────────────
if [ -d "$WALLPAPER_DIR_VIDEO" ]; then
    shopt -s nullglob nocaseglob
    for f in "$WALLPAPER_DIR_VIDEO"/*.{mp4,mkv,mov,webm}; do
        [ -f "$f" ] && process_video "$f"
    done
    shopt -u nullglob nocaseglob
fi

echo "$(date) === generate-thumbs END | generados=$generated saltados=$skipped errores=$errors ===" >> "$LOG"

# Marca de "último escaneo completo" — wallpaper_rofi.sh la usa para saltarse
# el escaneo por completo cuando no hay wallpapers nuevos desde la última vez.
touch "$THUMB_DIR/.last-scan"