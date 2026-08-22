#!/usr/bin/env bash
# ============================================================================
#  theme.sh — selector de perfil visual (esquema de matugen), vía rofi
# ----------------------------------------------------------------------------
#  matugen_toggle.sh (SUPER+SHIFT+W) es un ON/OFF binario: al encender,
#  siempre usa scheme-tonal-spot (antes hardcodeado en matugen_reload.sh).
#  Esto no reemplaza ese toggle — le agrega una dimensión: CUÁL de los 6
#  esquemas de matugen usar cuando está encendido, más un
#  "Estático (Kitasan Glass)" que apaga el dinámico y restaura la paleta de
#  referencia (mismo camino que matugen_toggle.sh al apagar).
#
#  El esquema elegido se persiste en ~/.config/matugen/scheme —
#  rofi/scripts/matugen_reload.sh ya lo lee de ahí (parametrizado para
#  esto). No hay lógica de generación de color nueva acá: sólo se elige el
#  esquema y se dispara el mismo pipeline de siempre.
# ============================================================================
set -u
set -o pipefail

THEME_RASI="$HOME/.config/rofi/clipboard.rasi"
SCHEME_FILE="$HOME/.config/matugen/scheme"
SENTINEL="$HOME/.config/matugen/enabled"
RELOAD_SCRIPT="$HOME/.config/rofi/scripts/matugen_reload.sh"
APPLY_STATIC="$HOME/.config/hypr/scripts/apply-static-colors.sh"
WALLPAPER_STATE="$HOME/.config/hypr/.current-wallpaper"

LABELS=(
    "󰸌  Tonal Spot (Default)"
    "󰸌  Vibrant"
    "󰸌  Expressive"
    "󰸌  Fidelity"
    "󰸌  Content"
    "󰸌  Neutral"
    "󰸌  Fruit Salad"
    "󰸌  Monochrome"
    "󰸌  Rainbow"
    "󰃟  Static"
)
SCHEMES=(
    "scheme-tonal-spot"
    "scheme-vibrant"
    "scheme-expressive"
    "scheme-fidelity"
    "scheme-content"
    "scheme-neutral"
    "scheme-fruit-salad"
    "scheme-monochrome"
    "scheme-rainbow"
    "static"
)

menu=""
for l in "${LABELS[@]}"; do menu+="$l"$'\n'; done

chosen=$(printf '%s' "$menu" | rofi -dmenu -p "Theme" -theme "$THEME_RASI")
[ -n "$chosen" ] || exit 0

scheme=""
for i in "${!LABELS[@]}"; do
    if [ "${LABELS[$i]}" = "$chosen" ]; then
        scheme="${SCHEMES[$i]}"
        break
    fi
done
[ -n "$scheme" ] || exit 0

if [ "$scheme" = "static" ]; then
    rm -f "$SENTINEL"
    bash "$APPLY_STATIC"
    command -v notify-send >/dev/null 2>&1 && notify-send "Theme" "Static restored"
    exit 0
fi

# Persistir el esquema elegido — matugen_reload.sh lo lee de acá en cada
# regeneración futura (toggle, cambio de wallpaper, etc.), no sólo ahora.
mkdir -p "$(dirname "$SCHEME_FILE")"
printf '%s' "$scheme" > "$SCHEME_FILE"

# Encender el dinámico si estaba apagado — elegir un esquema implica querer
# verlo aplicado ya, no dejarlo guardado para la próxima vez que alguien
# prenda el toggle a mano.
mkdir -p "$(dirname "$SENTINEL")"
touch "$SENTINEL"

# Resolver el wallpaper actual — misma lógica de fallback que ya usa
# matugen_toggle.sh (estado persistido primero, introspección de mpvpaper
# como respaldo).
wall=""
if [ -f "$WALLPAPER_STATE" ]; then
    wall="$(cat "$WALLPAPER_STATE" 2>/dev/null)"
    [ -n "$wall" ] && [ -f "$wall" ] || wall=""
fi
if [ -z "$wall" ]; then
    mpv_cmd="$(pgrep -a mpvpaper 2>/dev/null | head -n1)"
    [ -n "$mpv_cmd" ] && wall="$(echo "$mpv_cmd" | awk '{print $NF}')"
fi

if [ -n "$wall" ]; then
    bash "$RELOAD_SCRIPT" "$wall"
    command -v notify-send >/dev/null 2>&1 && notify-send "Theme" "Visual profile: $scheme"
else
    command -v notify-send >/dev/null 2>&1 && notify-send "Theme" "Saved profile ($scheme) — choose a wallpaper to generate color"
fi
