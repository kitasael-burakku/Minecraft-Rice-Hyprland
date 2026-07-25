#!/usr/bin/env bash
# ============================================================================
#  matugen_patch_starship.sh — parche quirúrgico de starship.toml
# ----------------------------------------------------------------------------
#  starship.toml NO se regenera entero (a diferencia de kitty/colors.conf) —
#  TOML no tiene forma de importar otro archivo, así que "poseer" el archivo
#  completo sería arriesgado (un edit a mano futuro se perdería en el próximo
#  cambio de wallpaper). En cambio, solo se tocan las líneas marcadas con
#  "# matugen:accent" / "# matugen:gold" — todo lo demás del archivo queda
#  exactamente como esté, sin importar lo que haga este script.
#
#  Uso: matugen_patch_starship.sh [archivo-de-hex]
#       (default: ~/.config/matugen/dynamic-hex.sh; para restaurar el
#        estático, se le pasa ~/.config/matugen/dynamic-hex.static.sh)
# ============================================================================

set -u

HEXFILE="${1:-$HOME/.config/matugen/dynamic-hex.sh}"
STARSHIP="$HOME/.config/starship.toml"

[ -f "$HEXFILE" ]  || exit 0
[ -f "$STARSHIP" ] || exit 0

# shellcheck disable=SC1090
. "$HEXFILE"

if [ -n "${MATUGEN_ACCENT:-}" ]; then
    sed -i -E "s/(fg:#)[0-9a-fA-F]{6}(.*# matugen:accent)/\1${MATUGEN_ACCENT}\2/" "$STARSHIP"
fi

if [ -n "${MATUGEN_GOLD:-}" ]; then
    sed -i -E "s/(fg:#)[0-9a-fA-F]{6}(.*# matugen:gold)/\1${MATUGEN_GOLD}\2/" "$STARSHIP"
fi
