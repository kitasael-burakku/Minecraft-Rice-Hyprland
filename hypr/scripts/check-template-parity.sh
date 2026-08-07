#!/usr/bin/env bash
# ============================================================================
#  check-template-parity.sh — chequeo informativo (no bloquea nada) de que
#  cada plantilla dinámica de matugen y su *.static.* declaran el mismo set
#  de identificadores. Mismo método que usaron a mano las auditorías 5 y 6
#  para confirmar la paridad — esto lo deja automático dentro de dotbackup.
#
#  Un identificador que aparece en un lado y no en el otro normalmente
#  significa que se agregó/borró una variable en un archivo y se olvidó el
#  espejo en el otro (plantilla dinámica vs. estático de referencia).
# ============================================================================
set -u

BASE="$HOME/.config"

# name|template|static|formato
pairs=(
    "rofi|$BASE/matugen/templates/rofi-colors.rasi|$BASE/rofi/colors.static.rasi|rasi"
    "waybar|$BASE/matugen/templates/waybar-colors.css|$BASE/waybar/colors.static.css|definecolor"
    "wlogout|$BASE/matugen/templates/wlogout-colors.css|$BASE/wlogout/colors.static.css|definecolor"
    "hyprlock|$BASE/matugen/templates/hyprlock-colors.conf|$BASE/hyprlock/colors.static.conf|dollar"
    "kitty|$BASE/matugen/templates/kitty-colors.conf|$BASE/kitty/colors/colors.static.conf|kitty"
    "swaync|$BASE/matugen/templates/swaync-colors.css|$BASE/swaync/colors.static.css|cssvar"
    "starship|$BASE/matugen/templates/starship.toml|$BASE/starship.static.toml|toml"
    "fish/theme-goldship|$BASE/matugen/templates/theme-goldship.fish|$BASE/fish/theme-goldship.static.fish|fishset"
    "hyprlock/music-colors|$BASE/matugen/templates/music-progress-colors.sh|$BASE/hyprlock/scripts/music-colors.static.sh|shvar"
    "gtk|$BASE/matugen/templates/gtk-colors.css|$BASE/gtk-3.0/gtk-colors.static.css|definecolor"
    "qt|$BASE/matugen/templates/qt-colors.conf|$BASE/qt5ct/colors/kitasan-glass.static.conf|iniassign"
)

# Extrae el set de identificadores declarados de un archivo, según su formato.
# Cada formato usa la misma regex para plantilla y estático — lo que importa
# es que ambos lados se lean con la MISMA lógica, no cubrir el 100% de la
# sintaxis real del formato (ej. starship.toml tiene claves que no son
# colores, como "Arch" o "Desktop" — no molesta que también se comparen,
# porque existen igual en ambos lados).
extract() {
    local format="$1" file="$2"
    case "$format" in
        rasi)
            grep -oP '^\s*\K[\w-]+(?=\s*:)' "$file"
            ;;
        definecolor)
            grep -oP '@define-color\s+\K[\w-]+' "$file"
            ;;
        dollar)
            grep -oP '^\$\K\w+(?=\s*=)' "$file"
            ;;
        kitty)
            grep -vP '^\s*(#|$)' "$file" | grep -oP '^\K\w+'
            ;;
        cssvar)
            grep -oP -- '--\K[\w-]+(?=\s*:)' "$file"
            ;;
        toml)
            grep -vP '^\s*(\[|#|$)' "$file" \
                | grep -oP '^\s*"?\K[^"=]+(?="?\s*=)' \
                | sed -E 's/[[:space:]]+$//'
            ;;
        fishset)
            grep -oP 'set\s+-g\s+\K\S+' "$file"
            ;;
        shvar)
            grep -oP '^\K\w+(?==)' "$file"
            ;;
        iniassign)
            # active_colors=/disabled_colors=/inactive_colors= — anclado a
            # inicio de línea a propósito: sin el "^" esto también matchea
            # substrings de comentarios explicativos que mencionan
            # "active_colors" en prosa (pasó en vivo al escribir esto).
            grep -oP '^\K[a-zA-Z_]+(?=\s*=)' "$file"
            ;;
    esac
}

mismatches=0

for entry in "${pairs[@]}"; do
    IFS='|' read -r name template static format <<< "$entry"

    if [ ! -f "$template" ] || [ ! -f "$static" ]; then
        echo "  ⚠ paridad plantilla/estático — $name: no encontré $template o $static"
        mismatches=$((mismatches + 1))
        continue
    fi

    tmpl_ids="$(extract "$format" "$template" | sort -u)"
    static_ids="$(extract "$format" "$static" | sort -u)"

    only_tmpl="$(comm -23 <(echo "$tmpl_ids") <(echo "$static_ids"))"
    only_static="$(comm -13 <(echo "$tmpl_ids") <(echo "$static_ids"))"

    if [ -n "$only_tmpl" ] || [ -n "$only_static" ]; then
        echo "  ⚠ paridad plantilla/estático — $name:"
        [ -n "$only_tmpl" ] && echo "$only_tmpl" | sed 's/^/      solo en plantilla dinámica: /'
        [ -n "$only_static" ] && echo "$only_static" | sed 's/^/      solo en estático:          /'
        mismatches=$((mismatches + 1))
    fi
done

exit "$mismatches"
