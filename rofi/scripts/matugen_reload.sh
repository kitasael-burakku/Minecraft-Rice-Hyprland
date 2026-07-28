#!/usr/bin/env bash
# ============================================================================
#  matugen_reload.sh — genera colores dinámicos (Kitasan Glass) desde el
#  wallpaper actual y dispara los reloads correspondientes.
# ----------------------------------------------------------------------------
#  Llamado por wallpaper_grid.sh tras aplicar un wallpaper, con la ruta del
#  archivo como $1. Apagado por defecto — requiere el sentinel
#  ~/.config/matugen/enabled (creado/borrado por matugen_toggle.sh), o la
#  variable de entorno ENABLE_DYNAMIC_COLORS=1 para pruebas manuales.
#
#  matugen solo acepta imágenes estáticas — si el wallpaper es un video
#  (mp4/mkv/mov/webm, el caso por defecto de este rice vía mpvpaper), se
#  extrae un frame con ffmpeg antes de generar colores.
#
#  Los reloads por-app (waybar → SIGUSR2, kitty → SIGUSR1, Hyprland → hyprctl
#  eval) ya NO se manejan acá — cada uno es un post_hook de su template en
#  ~/.config/matugen/config.toml. Este script solo resuelve el frame de
#  entrada y llama a matugen; todo lo demás lo dispara matugen solo.
# ============================================================================

set -u
set -o pipefail

WALL="${1:-}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/matugen-reload.log"
FRAME="${XDG_RUNTIME_DIR:-/tmp}/matugen-frame.png"

MATUGEN_CONFIG="${MATUGEN_CONFIG:-$HOME/.config/matugen/config.toml}"
MATUGEN_SENTINEL="${MATUGEN_SENTINEL:-$HOME/.config/matugen/enabled}"
ENABLE_DYNAMIC_COLORS="${ENABLE_DYNAMIC_COLORS:-0}"

echo "$(date) === matugen_reload START (wall=$WALL) ===" >> "$LOG"

# ── Gate: ¿está encendido el theming dinámico? ───────────────────────────────
if [ "$ENABLE_DYNAMIC_COLORS" != "1" ] && [ ! -f "$MATUGEN_SENTINEL" ]; then
    echo "$(date) dinámico apagado (sin sentinel ni ENABLE_DYNAMIC_COLORS) — nada que hacer" >> "$LOG"
    exit 0
fi

command -v matugen >/dev/null 2>&1 || { echo "$(date) matugen no instalado — abortando" >> "$LOG"; exit 0; }
[ -n "$WALL" ] && [ -f "$WALL" ] || { echo "$(date) wallpaper vacío o inexistente — abortando" >> "$LOG"; exit 0; }

# ── Resolver imagen de entrada: extraer frame si es video ────────────────────
ext="${WALL##*.}"
ext="${ext,,}"

case "$ext" in
    mp4|mkv|mov|webm)
        command -v ffmpeg >/dev/null 2>&1 || { echo "$(date) ffmpeg no instalado, no se puede extraer frame de video — abortando" >> "$LOG"; exit 0; }
        if ! ffmpeg -y -ss 00:00:01 -i "$WALL" -vframes 1 -update 1 "$FRAME" >>"$LOG" 2>&1; then
            echo "$(date) fallo extrayendo frame de $WALL — abortando" >> "$LOG"
            exit 0
        fi
        IN="$FRAME"
        ;;
    *)
        IN="$WALL"
        ;;
esac

# ── Generar colores (los post_hook de cada template disparan sus reloads) ───
if matugen --config "$MATUGEN_CONFIG" image "$IN" -m dark -t scheme-tonal-spot >>"$LOG" 2>&1; then
    echo "$(date) matugen OK (imagen: $IN)" >> "$LOG"
else
    echo "$(date) matugen falló generando templates — los archivos anteriores quedan intactos" >> "$LOG"
fi
echo "$(date) === matugen_reload END ===" >> "$LOG"
