#!/usr/bin/env bash
# ============================================================================
#  generate-thumbs.sh  —  rofi wallpaper picker
# ----------------------------------------------------------------------------
#  Genera thumbnails para DOS directorios:
#    WALLPAPER_DIR_VIDEO  →  ~/Videos/wallpapersvideo   (videos + imágenes)
#    WALLPAPER_DIR_IMG    →  ~/Pictures/Wallpapers       (solo imágenes)
#
#  CONVENCIÓN:
#    srcDir/eyes.mp4   →  thumbDir/eyes.mp4.jpg
#    srcDir/bg.png     →  thumbDir/bg.png.jpg
#
#  Requisitos: ffmpeg (video), ImageMagick (imagen)
# ============================================================================

set -u

WALLPAPER_DIR_VIDEO="${WALLPAPER_DIR_VIDEO:-$HOME/Videos/wallpapersvideo}"
WALLPAPER_DIR_IMG="${WALLPAPER_DIR_IMG:-$HOME/Pictures/Wallpapers}"
THUMB_DIR="${THUMB_DIR:-$HOME/.cache/rofi-wallpapers/thumbs}"
THUMB_WIDTH="${THUMB_WIDTH:-480}"
FORCE=0

[ "${1:-}" = "--force" ] && FORCE=1

if command -v magick >/dev/null 2>&1; then IM="magick"
elif command -v convert >/dev/null 2>&1; then IM="convert"
else IM=""
fi

HAS_FFMPEG=0
command -v ffmpeg >/dev/null 2>&1 && HAS_FFMPEG=1

mkdir -p "$THUMB_DIR"

IMG_EXTS="jpg jpeg png webp gif"
VID_EXTS="mp4 mkv mov webm"

is_in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac }

made=0; skipped=0; failed=0

# ── Procesa todos los archivos de un directorio ───────────────────────────────
process_dir() {
    local src_dir="$1"

    [ -d "$src_dir" ] || {
        echo "WARN: directorio no existe, saltando: $src_dir" >&2
        return
    }

    shopt -s nullglob nocaseglob

    for src in "$src_dir"/*; do
        [ -f "$src" ] || continue

        local base ext ext_lc thumb
        base="$(basename "$src")"
        ext="${base##*.}"
        ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"
        thumb="$THUMB_DIR/${base}.jpg"

        if [ "$FORCE" -eq 0 ] && [ -f "$thumb" ] && [ "$thumb" -nt "$src" ]; then
            skipped=$((skipped + 1)); continue
        fi

        if is_in_list "$ext_lc" "$IMG_EXTS"; then
            if [ -z "$IM" ]; then
                echo "WARN: falta ImageMagick, salto: $base" >&2
                failed=$((failed + 1)); continue
            fi
            if $IM "$src" -auto-orient -strip -resize "${THUMB_WIDTH}>" "jpg:$thumb" >/dev/null 2>&1; then
                made=$((made + 1))
            else
                echo "WARN: fallo generando thumb de imagen: $base" >&2
                failed=$((failed + 1))
            fi

        elif is_in_list "$ext_lc" "$VID_EXTS"; then
            if [ "$HAS_FFMPEG" -eq 0 ]; then
                echo "WARN: falta ffmpeg, salto: $base" >&2
                failed=$((failed + 1)); continue
            fi

            local ok=0

            ffmpeg -y -ss 1 -i "$src" -frames:v 1 -vf "scale=${THUMB_WIDTH}:-1" \
                  -f image2 -c:v mjpeg "$thumb" >/dev/null 2>&1
            [ -s "$thumb" ] && ok=1

            if [ "$ok" -eq 0 ]; then
                ffmpeg -y -i "$src" -frames:v 1 -vf "scale=${THUMB_WIDTH}:-1" \
                      -f image2 -c:v mjpeg "$thumb" >/dev/null 2>&1
                [ -s "$thumb" ] && ok=1
            fi

            if [ "$ok" -eq 1 ]; then
                made=$((made + 1))
            else
                rm -f "$thumb"
                echo "WARN: fallo generando poster de video: $base" >&2
                failed=$((failed + 1))
            fi
        fi
    done

    shopt -u nullglob nocaseglob
}

process_dir "$WALLPAPER_DIR_VIDEO"
process_dir "$WALLPAPER_DIR_IMG"

# ── Limpiar huérfanos (thumb sin original en ninguno de los dos dirs) ─────────
removed=0
shopt -s nullglob
for thumb in "$THUMB_DIR"/*.jpg; do
    [ -f "$thumb" ] || continue
    origname="$(basename "${thumb%.jpg}")"
    if [ ! -f "$WALLPAPER_DIR_VIDEO/$origname" ] && [ ! -f "$WALLPAPER_DIR_IMG/$origname" ]; then
        rm -f "$thumb"
        removed=$((removed + 1))
    fi
done
shopt -u nullglob

echo "thumbs: generados=$made saltados=$skipped fallidos=$failed huérfanos_borrados=$removed"
echo "videosDir: $WALLPAPER_DIR_VIDEO"
echo "imgsDir:   $WALLPAPER_DIR_IMG"
echo "thumbDir:  $THUMB_DIR"