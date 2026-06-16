#!/usr/bin/env bash
# ============================================================================
#  generate_thumbnails.sh  —  qs-wallpaper-picker
# ----------------------------------------------------------------------------
#  Genera los thumbnails que el picker LEE para poblar el grid.
#
#  El picker NO lee tus wallpapers originales directamente: lee
#  ~/.cache/wallpaper_picker/thumbs (localFolderModel.folder = thumbDir).
#  Si esa carpeta no existe o está vacía → "No wallpapers found".
#
#  CONVENCIÓN DE NOMBRES (importante para que preview/apply encuentren el original):
#    Imagen   srcDir/sunset.jpg     →  thumb  thumbDir/sunset.jpg        (reducida)
#    Video    srcDir/clip.mp4       →  thumb  thumbDir/000_clip.mp4      (poster JPEG)
#
#    - Los VIDEOS originales van SIN prefijo en srcDir (clip.mp4, no 000_clip.mp4).
#    - El thumb del video lleva '000_' para que el picker lo detecte como video
#      (isVid = nombre.startsWith("000_")).
#    - getCleanName() quita ese '000_' para encontrar el original en srcDir.
#
#  Requisitos:
#    - ImageMagick (magick o convert)   para imágenes
#    - ffmpeg                            para extraer el poster de los videos
#
#  Uso:
#    ./generate_thumbnails.sh                 # usa los paths por defecto
#    WALLPAPER_DIR=~/mis/wallpapers ./generate_thumbnails.sh
#    ./generate_thumbnails.sh --force         # regenera todo aunque ya exista
# ============================================================================

set -u

# ── Configuración (se puede sobrescribir por variable de entorno) ────────────
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Videos/wallpapersvideo}"
THUMB_DIR="${THUMB_DIR:-$HOME/.cache/wallpaper_picker/thumbs}"
THUMB_WIDTH="${THUMB_WIDTH:-640}"     # ancho máximo del thumbnail (px)
FORCE=0

[ "${1:-}" = "--force" ] && FORCE=1

# ── Detección de herramientas ────────────────────────────────────────────────
if command -v magick >/dev/null 2>&1; then
    IM="magick"
elif command -v convert >/dev/null 2>&1; then
    IM="convert"
else
    IM=""
fi

HAS_FFMPEG=0
command -v ffmpeg >/dev/null 2>&1 && HAS_FFMPEG=1

# ── Validaciones iniciales ───────────────────────────────────────────────────
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "ERROR: no existe la carpeta de wallpapers: $WALLPAPER_DIR" >&2
    exit 1
fi

mkdir -p "$THUMB_DIR"

# Extensiones reconocidas (igual que los nameFilters del QML)
IMG_EXTS="jpg jpeg png webp gif"
VID_EXTS="mp4 mkv mov webm"

is_in_list() {  # $1 = ext (lowercase), $2 = lista
    case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

made=0
skipped=0
failed=0

shopt -s nullglob nocaseglob

for src in "$WALLPAPER_DIR"/*; do
    [ -f "$src" ] || continue

    base="$(basename "$src")"
    ext="${base##*.}"
    ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

    # Quitar un posible '000_' que el usuario haya puesto por error en el ORIGINAL
    clean_base="${base#000_}"

    # ── IMAGEN ───────────────────────────────────────────────────────────────
    if is_in_list "$ext_lc" "$IMG_EXTS"; then
        thumb="$THUMB_DIR/$clean_base"

        if [ "$FORCE" -eq 0 ] && [ -f "$thumb" ] && [ "$thumb" -nt "$src" ]; then
            skipped=$((skipped + 1)); continue
        fi
        if [ -z "$IM" ]; then
            echo "WARN: ImageMagick no instalado, salto imagen: $base" >&2
            failed=$((failed + 1)); continue
        fi

        # Reduce manteniendo proporción; '>' = solo si es más grande que THUMB_WIDTH
        if $IM "$src" -auto-orient -strip -resize "${THUMB_WIDTH}>" "$thumb" >/dev/null 2>&1; then
            made=$((made + 1))
        else
            echo "WARN: fallo generando thumb de imagen: $base" >&2
            failed=$((failed + 1))
        fi

    # ── VIDEO ────────────────────────────────────────────────────────────────
    elif is_in_list "$ext_lc" "$VID_EXTS"; then
        # El thumb del video lleva prefijo 000_ y CONSERVA la extensión del video,
        # para que getCleanName() reconstruya el path del original correctamente.
        thumb="$THUMB_DIR/000_${clean_base}"

        if [ "$FORCE" -eq 0 ] && [ -f "$thumb" ] && [ "$thumb" -nt "$src" ]; then
            skipped=$((skipped + 1)); continue
        fi
        if [ "$HAS_FFMPEG" -eq 0 ]; then
            # Sin ffmpeg: creamos un marcador vacío para que el video aparezca
            # en el grid (tile negro + badge de video). El hover preview igual funciona.
            : > "$thumb"
            made=$((made + 1))
            continue
        fi

        # Poster frame ~1s dentro del video (bytes JPEG dentro del archivo .mp4/etc;
        # el grid muestra tile negro + badge, y este poster sirve de lock_bg al aplicar).
        if ffmpeg -y -ss 1 -i "$src" -frames:v 1 -vf "scale=${THUMB_WIDTH}:-1" \
                  -f image2 -c:v mjpeg "$thumb" >/dev/null 2>&1; then
            made=$((made + 1))
        elif ffmpeg -y -i "$src" -frames:v 1 -vf "scale=${THUMB_WIDTH}:-1" \
                  -f image2 -c:v mjpeg "$thumb" >/dev/null 2>&1; then
            # Reintento sin seek (videos muy cortos)
            made=$((made + 1))
        else
            : > "$thumb"   # último recurso: marcador vacío
            made=$((made + 1))
        fi
    fi
done

shopt -u nullglob nocaseglob

# ── Limpieza: borrar thumbs huérfanos (cuyo original ya no existe) ────────────
# Un thumb 'NAME' o '000_NAME' corresponde a un original que puede llamarse
# 'NAME' o '000_NAME' en srcDir. Borramos solo si NINGUNA variante existe.
removed=0
shopt -s nullglob
for thumb in "$THUMB_DIR"/*; do
    [ -f "$thumb" ] || continue
    tbase="$(basename "$thumb")"
    origname="${tbase#000_}"        # nombre sin prefijo
    if [ ! -f "$WALLPAPER_DIR/$origname" ] && [ ! -f "$WALLPAPER_DIR/000_$origname" ]; then
        rm -f "$thumb"
        removed=$((removed + 1))
    fi
done
shopt -u nullglob

echo "thumbs: generados=$made  saltados=$skipped  fallidos=$failed  huérfanos_borrados=$removed"
echo "thumbDir: $THUMB_DIR"
