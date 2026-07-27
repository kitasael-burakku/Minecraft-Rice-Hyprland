#!/usr/bin/env bash
# ============================================================================
#  apply-wallpaper.sh — aplica un wallpaper (video o imagen) y lo persiste
# ----------------------------------------------------------------------------
#  Fuente única de los flags de mpvpaper/awww — antes vivían duplicados entre
#  hypr/modules/autostart.lua y rofi/scripts/wallpaper_grid.sh, sincronizados
#  a mano con comentarios cruzados.
#
#  Además de aplicar el wallpaper al escritorio:
#    - persiste la ruta elegida en ~/.config/hypr/.current-wallpaper, para
#      que el próximo arranque restaure el mismo wallpaper en vez de volver
#      siempre al default.
#    - genera hyprlock/wallpapers/current.png a partir de ese mismo
#      wallpaper, para que la pantalla de bloqueo herede lo que se ve en el
#      escritorio (esto es independiente del toggle de matugen — es el
#      wallpaper, no los colores).
#
#  Uso:
#    apply-wallpaper.sh <ruta> [monitor]  — aplica y persiste
#    apply-wallpaper.sh                   — restaura el último wallpaper
#                                            persistido, o el default si no
#                                            hay ninguno / ya no existe
# ============================================================================

set -u
set -o pipefail

STATE_FILE="$HOME/.config/hypr/.current-wallpaper"
DEFAULT_WALLPAPER="$HOME/Videos/Wallpapers/behind-the-market.mp4"
HYPRLOCK_BG="$HOME/.config/hyprlock/wallpapers/current.png"
LOG="${XDG_RUNTIME_DIR:-/tmp}/apply-wallpaper.log"

target="${1:-}"
MONITOR="${2:-${WALLPAPER_MONITOR:-}}"

if [ -z "$target" ]; then
    if [ -f "$STATE_FILE" ]; then
        target="$(cat "$STATE_FILE" 2>/dev/null)"
    fi
    if [ -z "$target" ] || [ ! -f "$target" ]; then
        target="$DEFAULT_WALLPAPER"
    fi
fi

if [ ! -f "$target" ]; then
    echo "$(date) ERROR: wallpaper no existe: $target" >> "$LOG"
    exit 1
fi

ext_lc="$(printf '%s' "${target##*.}" | tr '[:upper:]' '[:lower:]')"

apply_video() {
    pkill -x mpvpaper 2>/dev/null
    sleep 0.1
    if [ -n "$MONITOR" ]; then
        nohup mpvpaper -o "--loop-file=inf --no-audio --hwdec=auto" "$MONITOR" "$target" \
            >"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 &
    else
        nohup mpvpaper -o "--loop-file=inf --no-audio --hwdec=auto" '*' "$target" \
            >"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 &
    fi
    disown
}

apply_image() {
    pkill -x mpvpaper 2>/dev/null
    awww img "$target" --transition-type any --transition-fps 60 >/dev/null 2>&1
}

case "$ext_lc" in
    mp4|mkv|mov|webm) apply_video ;;
    jpg|jpeg|png|webp|gif) apply_image ;;
    *)
        echo "$(date) ERROR: extensión no soportada: $target" >> "$LOG"
        exit 1
        ;;
esac

# ── Persistir la elección ─────────────────────────────────────────────────────
mkdir -p "$(dirname "$STATE_FILE")"
printf '%s' "$target" > "$STATE_FILE"

# ── Herencia en hyprlock ───────────────────────────────────────────────────────
mkdir -p "$(dirname "$HYPRLOCK_BG")"
case "$ext_lc" in
    mp4|mkv|mov|webm)
        if command -v ffmpeg >/dev/null 2>&1; then
            ffmpeg -y -ss 00:00:01 -i "$target" -vframes 1 -update 1 "$HYPRLOCK_BG" >>"$LOG" 2>&1 \
                || echo "$(date) WARN: no se pudo extraer frame para hyprlock de $target" >> "$LOG"
        else
            echo "$(date) WARN: ffmpeg no instalado, hyprlock no hereda este wallpaper" >> "$LOG"
        fi
        ;;
    jpg|jpeg|png|webp|gif)
        # Normalizado con ImageMagick (mismo binario que ya usa
        # generate-thumbs.sh) en vez de un cp crudo, para que el contenido
        # de current.png sea PNG de verdad sin importar el formato de origen.
        if command -v convert >/dev/null 2>&1; then
            convert "$target[0]" "$HYPRLOCK_BG" >>"$LOG" 2>&1 || cp -f "$target" "$HYPRLOCK_BG" 2>>"$LOG"
        else
            cp -f "$target" "$HYPRLOCK_BG" 2>>"$LOG"
        fi
        ;;
esac
