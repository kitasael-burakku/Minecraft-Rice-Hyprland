#!/usr/bin/env bash
# ============================================================================
#  generate_thumbs.sh  —  rofi wallpaper picker
# ----------------------------------------------------------------------------
#  Genera los posters/thumbnails que rofi usa como icono en el grid.
#
#  A diferencia del intento anterior (qs-wallpaper-picker), aquí los thumbs
#  de video llevan SIEMPRE extensión .jpg real, sin prefijos especiales ni
#  ambigüedad de tipo de archivo. Esto evita el bug que tuvimos con
#  ImageMagick/ffmpeg colgándose al confundir un JPEG con extensión .mp4.
#
#  CONVENCIÓN DE NOMBRES:
#    Original                          Thumb
#    srcDir/eyes.mp4              →    thumbDir/eyes.mp4.jpg
#    srcDir/sunset.jpg            →    thumbDir/sunset.jpg.jpg   (sí, doble
#                                       extensión: simple y sin colisiones,
#                                       y deja clarísimo que SIEMPRE es jpg)
#
#  Para volver del thumb al original: quitar el último ".jpg" del nombre.
#
#  Requisitos: ffmpeg (video), ImageMagick (imagen, opcional si no usas imgs)
# ============================================================================

set -u

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Videos/wallpapersvideo}"
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

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "ERROR: no existe la carpeta de wallpapers: $WALLPAPER_DIR" >&2
    exit 1
fi

mkdir -p "$THUMB_DIR"

IMG_EXTS="jpg jpeg png webp gif"
VID_EXTS="mp4 mkv mov webm"

is_in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac }

made=0; skipped=0; failed=0

shopt -s nullglob nocaseglob

for src in "$WALLPAPER_DIR"/*; do
    [ -f "$src" ] || continue

    base="$(basename "$src")"
    ext="${base##*.}"
    ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

    thumb="$THUMB_DIR/${base}.jpg"   # siempre .jpg real, conserva el nombre completo

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

        ok=0

        ffmpeg -y -ss 1 -i "$src" -frames:v 1 -vf "scale=${THUMB_WIDTH}:-1" \
              -f image2 -c:v mjpeg "$thumb" >/dev/null 2>&1
        # ffmpeg puede salir con 0 aunque no haya escrito ningún frame
        # (p.ej. -ss cae después del final del clip) -> hay que verificar
        # que el archivo de verdad se creó y no quedó vacío.
        [ -s "$thumb" ] && ok=1

        if [ "$ok" -eq 0 ]; then
            ffmpeg -y -i "$src" -frames:v 1 -vf "scale=${THUMB_WIDTH}:-1" \
                  -f image2 -c:v mjpeg "$thumb" >/dev/null 2>&1
            [ -s "$thumb" ] && ok=1
        fi

        if [ "$ok" -eq 1 ]; then
            made=$((made + 1))
        else
            rm -f "$thumb"   # por si quedó un archivo de 0 bytes
            echo "WARN: fallo generando poster de video: $base" >&2
            failed=$((failed + 1))
        fi
    fi
done

shopt -u nullglob nocaseglob

# Limpieza de huérfanos: thumb cuyo original ya no existe
removed=0
shopt -s nullglob
for thumb in "$THUMB_DIR"/*.jpg; do
    [ -f "$thumb" ] || continue
    origname="$(basename "${thumb%.jpg}")"
    if [ ! -f "$WALLPAPER_DIR/$origname" ]; then
        rm -f "$thumb"
        removed=$((removed + 1))
    fi
done
shopt -u nullglob

echo "thumbs: generados=$made saltados=$skipped fallidos=$failed huérfanos_borrados=$removed"
echo "thumbDir: $THUMB_DIR"