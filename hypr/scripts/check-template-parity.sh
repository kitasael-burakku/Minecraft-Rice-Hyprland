#!/usr/bin/env bash
# ============================================================================
#  check-template-parity.sh — informational check (blocks nothing) that
#  each matugen dynamic template and its *.static.* counterpart declare the
#  same set of identifiers. Same method audits 5 and 6 used by hand to
#  confirm parity — this makes it automatic inside dotbackup.
#
#  An identifier that shows up on one side and not the other usually means
#  a variable was added/removed in one file and the mirror in the other
#  (dynamic template vs. static reference) was forgotten.
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

# Extracts the set of identifiers declared in a file, based on its format.
# Each format uses the same regex for template and static — what matters
# is that both sides get read with the SAME logic, not covering 100% of the
# format's actual syntax (e.g. starship.toml has keys that aren't colors,
# like "Arch" or "Desktop" — it doesn't matter that those get compared too,
# since they exist on both sides either way).
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
            # active_colors=/disabled_colors=/inactive_colors= — anchored to
            # start of line on purpose: without the "^" this also matches
            # substrings of explanatory comments that mention
            # "active_colors" in prose (happened live while writing this).
            grep -oP '^\K[a-zA-Z_]+(?=\s*=)' "$file"
            ;;
    esac
}

mismatches=0

for entry in "${pairs[@]}"; do
    IFS='|' read -r name template static format <<< "$entry"

    if [ ! -f "$template" ] || [ ! -f "$static" ]; then
        echo "  ⚠ template/static parity — $name: couldn't find $template or $static"
        mismatches=$((mismatches + 1))
        continue
    fi

    tmpl_ids="$(extract "$format" "$template" | sort -u)"
    static_ids="$(extract "$format" "$static" | sort -u)"

    only_tmpl="$(comm -23 <(echo "$tmpl_ids") <(echo "$static_ids"))"
    only_static="$(comm -13 <(echo "$tmpl_ids") <(echo "$static_ids"))"

    if [ -n "$only_tmpl" ] || [ -n "$only_static" ]; then
        echo "  ⚠ template/static parity — $name:"
        [ -n "$only_tmpl" ] && echo "$only_tmpl" | sed 's/^/      only in dynamic template: /'
        [ -n "$only_static" ] && echo "$only_static" | sed 's/^/      only in static:          /'
        mismatches=$((mismatches + 1))
    fi
done

exit "$mismatches"
