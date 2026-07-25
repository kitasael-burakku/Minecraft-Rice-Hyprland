#!/usr/bin/env bash

# ============================================================================
#  wallpaper_launcher.sh  —  wrapper externo del picker de dos niveles
# ----------------------------------------------------------------------------
#  Este es el script que llama Hyprland (reemplaza el comando del keybind).
#
#  Flujo:
#    1) Limpia estado anterior
#    2) Abre rofi nivel 0 (selector Video/Imagen) y ESPERA a que cierre
#    3) Lee $XDG_RUNTIME_DIR/rofi-wallpaper-next para saber qué abrir
#    4) Abre rofi nivel 1 (grid de thumbs) y ESPERA a que cierre
# ============================================================================

set -u

ROFI_DIR="${ROFI_DIR:-$HOME/.config/rofi}"
SCRIPTS_DIR="$ROFI_DIR/scripts"
NEXT_FILE="${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next"

# Matar rofi si ya hay uno abierto (toggle)
if pgrep -x rofi >/dev/null; then
    pkill -x rofi
    exit 0
fi

rm -f "$NEXT_FILE"

# ── Nivel 0: selector de tipo — bloqueante, espera a que cierre ──────────────
rofi \
    -show wallpapers \
    -modi "wallpapers:$SCRIPTS_DIR/wallpaper_rofi.sh" \
    -theme "$ROFI_DIR/wallpaper-type-select.rasi"

# rofi cerró — leer qué eligió el usuario
[ -f "$NEXT_FILE" ] || exit 0

src_dir="$(cut -f1 "$NEXT_FILE")"
prompt_label="$(cut -f2 "$NEXT_FILE")"
rm -f "$NEXT_FILE"

[ -z "$src_dir" ] && exit 0

# ── Nivel 1: grid picker — bloqueante, espera a que cierre ───────────────────
export WALLPAPER_SRC_DIR="$src_dir"
export WALLPAPER_PROMPT="$prompt_label"

rofi \
    -show grid \
    -modi "grid:$SCRIPTS_DIR/wallpaper_grid.sh" \
    -theme "$ROFI_DIR/wallpaper-picker.rasi"
