#!/usr/bin/env bash
# ============================================================================
#  wallpaper_rofi.sh  —  rofi script-mode wallpaper picker
# ----------------------------------------------------------------------------
#  Uso:
#    rofi -show wallpapers -modi "wallpapers:~/.config/rofi/scripts/wallpaper_rofi.sh"
#
#  Flujo:
#    1) ROFI_RETV=0 (primera llamada) -> listamos cada wallpaper con su thumb
#       como icono, formato: nombre\0icon\x1f/ruta/al/thumb.jpg
#    2) ROFI_RETV=1 (usuario seleccionó una fila) -> $1 es el nombre elegido,
#       lo mapeamos al archivo original y lo aplicamos con mpvpaper.
#
#  Reutiliza matugen_reload.sh para el theming dinámico tras aplicar.
# ============================================================================

set -u

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Videos/wallpapersvideo}"
THUMB_DIR="${THUMB_DIR:-$HOME/.cache/rofi-wallpapers/thumbs}"
GEN_SCRIPT="${GEN_SCRIPT:-$HOME/.config/rofi/scripts/generate-thumbs.sh}"
RELOAD_SCRIPT="${RELOAD_SCRIPT:-$HOME/.config/rofi/scripts/matugen_reload.sh}"
MONITOR="${WALLPAPER_MONITOR:-}"   # vacío = mpvpaper elige el monitor activo/todos según su config
LOG="/tmp/rofi-wallpaper.log"

mkdir -p "$THUMB_DIR"

# ── Helper: nombre "bonito" para mostrar (sin extensión, guiones -> espacios) ─
display_name() {
    local f="$1"
    f="${f%.*}"
    f="${f//_/ }"
    f="${f//-/ }"
    printf '%s' "$f"
}

# ── ROFI_RETV=1: el usuario eligió algo ───────────────────────────────────────
if [ "${ROFI_RETV:-0}" = "1" ]; then
    chosen_display="${1:-}"
    echo "$(date) SELECTED: $chosen_display" >> "$LOG"

    # Reconstruir el nombre real del archivo a partir del display_name
    # (recorremos WALLPAPER_DIR y comparamos por display_name, evita
    # tener que escapar caracteres raros en ROFI_INFO).
    target=""
    shopt -s nullglob
    for f in "$WALLPAPER_DIR"/*; do
        [ -f "$f" ] || continue
        if [ "$(display_name "$(basename "$f")")" = "$chosen_display" ]; then
            target="$f"
            break
        fi
    done
    shopt -u nullglob

    if [ -z "$target" ]; then
        echo "$(date) ERROR: no se encontró archivo para '$chosen_display'" >> "$LOG"
        exit 1
    fi

    ext_lc="$(printf '%s' "${target##*.}" | tr '[:upper:]' '[:lower:]')"

    case "$ext_lc" in
        mp4|mkv|mov|webm)
            pkill -x mpvpaper 2>/dev/null
            sleep 0.2
            if [ -n "$MONITOR" ]; then
                nohup mpvpaper -o "no-audio --loop-file --hwdec=auto" "$MONITOR" "$target" >/tmp/mpvpaper.log 2>&1 &
            else
                nohup mpvpaper -o "no-audio --loop-file --hwdec=auto" '*' "$target" >/tmp/mpvpaper.log 2>&1 &
            fi
            disown
            ;;
        jpg|jpeg|png|webp|gif)
            pkill -x mpvpaper 2>/dev/null
            if command -v swww >/dev/null 2>&1; then
                swww img "$target" --transition-type any >/dev/null 2>&1
            elif command -v awww >/dev/null 2>&1; then
                awww img "$target" >/dev/null 2>&1
            fi
            ;;
        *)
            echo "$(date) ERROR: extensión no soportada: $target" >> "$LOG"
            exit 1
            ;;
    esac

    # Theming dinámico (matugen/hypr/waybar/etc.), igual que en qs-wallpaper-picker
    if [ -x "$RELOAD_SCRIPT" ]; then
        nohup bash "$RELOAD_SCRIPT" "$target" >/tmp/rofi-wallpaper-reload.log 2>&1 &
        disown
    fi

    exit 0
fi

# ── ROFI_RETV=0: primera llamada, listar entradas ─────────────────────────────

# Regenera thumbs en segundo plano (no bloquea la apertura del menú;
# si faltan thumbs nuevos no se verán hasta la siguiente apertura, pero
# nunca cuelga el picker esperando a ffmpeg).
if [ -x "$GEN_SCRIPT" ]; then
    nohup bash "$GEN_SCRIPT" >/tmp/rofi-wallpaper-gen.log 2>&1 &
    disown
fi

echo -en "\0prompt\x1fWallpaper\n"
echo -en "\0no-custom\x1ftrue\n"

shopt -s nullglob nocaseglob
for f in "$WALLPAPER_DIR"/*.{mp4,mkv,mov,webm,jpg,jpeg,png,webp,gif}; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    name="$(display_name "$base")"
    thumb="$THUMB_DIR/${base}.jpg"

    if [ -f "$thumb" ]; then
        echo -en "${name}\0icon\x1f${thumb}\n"
    else
        # sin thumb todavía (recién agregado): aparece sin icono, sigue siendo seleccionable
        echo -en "${name}\n"
    fi
done
shopt -u nullglob nocaseglob