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
#
#  Esquema de color: antes hardcodeado a "scheme-tonal-spot". Ahora se lee de
#  ~/.config/matugen/scheme (una línea, sin saltos) si existe — así
#  rofi/scripts/theme.sh puede cambiarlo sin tocar este script. Sin ese
#  archivo, cae al mismo default de siempre (tonal-spot), cero cambio de
#  comportamiento para quien no use el selector de perfiles.
# ============================================================================

set -u
set -o pipefail

WALL="${1:-}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/matugen-reload.log"
FRAME="${XDG_RUNTIME_DIR:-/tmp}/matugen-frame.png"

MATUGEN_CONFIG="${MATUGEN_CONFIG:-$HOME/.config/matugen/config.toml}"
MATUGEN_SENTINEL="${MATUGEN_SENTINEL:-$HOME/.config/matugen/enabled}"
MATUGEN_SCHEME_FILE="${MATUGEN_SCHEME_FILE:-$HOME/.config/matugen/scheme}"
ENABLE_DYNAMIC_COLORS="${ENABLE_DYNAMIC_COLORS:-0}"

# Whitelist — misma lista que reporta `matugen --help`. Si el archivo trae
# basura (edición a mano, corrupción), cae al default en vez de pasarle un
# -t inválido a matugen.
VALID_SCHEMES="scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot scheme-vibrant"
MATUGEN_SCHEME="scheme-tonal-spot"
if [ -f "$MATUGEN_SCHEME_FILE" ]; then
    candidate="$(tr -d '[:space:]' < "$MATUGEN_SCHEME_FILE" 2>/dev/null)"
    for s in $VALID_SCHEMES; do
        if [ "$s" = "$candidate" ]; then
            MATUGEN_SCHEME="$candidate"
            break
        fi
    done
fi

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
if matugen --config "$MATUGEN_CONFIG" image "$IN" -m dark -t "$MATUGEN_SCHEME" >>"$LOG" 2>&1; then
    echo "$(date) matugen OK (imagen: $IN, scheme: $MATUGEN_SCHEME)" >> "$LOG"
else
    echo "$(date) matugen falló generando templates — los archivos anteriores quedan intactos" >> "$LOG"
fi
echo "$(date) === matugen_reload END ===" >> "$LOG"
