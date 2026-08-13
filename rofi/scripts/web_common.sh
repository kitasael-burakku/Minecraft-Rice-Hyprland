#!/usr/bin/env bash
# ============================================================================
#  web_common.sh — shared helpers for the Rofi web hub
# ----------------------------------------------------------------------------
#  Sourced by web_launcher.sh, web_category.sh and web_picker.sh so
#  websites.conf's format (a `[Category]` header per section, then
#  `Name | URL` lines) is parsed in exactly one place. Deliberately left
#  non-executable: rofi auto-detects every executable script in this
#  directory as a mode (see `rofi -h`), and this file isn't meant to run on
#  its own.
# ============================================================================

WEBSITES_CONF="${WEBSITES_CONF:-$HOME/.config/rofi/websites.conf}"

# list_categories <file>
# Prints every [Category] header, in file order, one per line.
list_categories() {
    local file="$1"
    grep -E '^\[.+\]$' "$file" | sed -E 's/^\[(.+)\]$/\1/'
}

# list_pages <file> <category>
# Prints "Name<TAB>URL" for every entry inside [category], in file order.
# Matches the category name literally (no regex, no globbing), so a
# category containing characters like "." or "+" still works. A stray "|"
# inside the URL itself is tolerated by rejoining every field past the
# first back into the URL.
list_pages() {
    local file="$1" category="$2"
    awk -F'|' -v want="$category" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        /^\[.+\]$/ {
            section = $0
            gsub(/^\[|\]$/, "", section)
            in_section = (section == want)
            next
        }
        in_section && NF >= 2 {
            name = $1
            url = $2
            for (i = 3; i <= NF; i++) url = url "|" $i
            gsub(/^[ \t]+|[ \t]+$/, "", name)
            gsub(/^[ \t]+|[ \t]+$/, "", url)
            if (name != "" && url != "") print name "\t" url
        }
    ' "$file"
}
