#!/usr/bin/env bash
# ============================================================================
#  web_picker.sh — page picker (level 1) for the Rofi web hub
# ----------------------------------------------------------------------------
#  Takes a category name as $1 (the exact text web_category.sh printed),
#  lists that section's pages from websites.conf as a rofi -dmenu list, and
#  writes the chosen page's URL to stdout. Called by web_launcher.sh only.
#
#  `--list <category>` prints "Name<TAB>URL" for that section without
#  opening rofi.
# ============================================================================
set -u
set -o pipefail

ROFI_DIR="${ROFI_DIR:-$HOME/.config/rofi}"
SCRIPTS_DIR="${SCRIPTS_DIR:-$ROFI_DIR/scripts}"
THEME="${WEB_HUB_THEME:-$ROFI_DIR/web-hub.rasi}"

# shellcheck source=web_common.sh
source "$SCRIPTS_DIR/web_common.sh"

list_mode=0
if [ "${1:-}" = "--list" ]; then
    list_mode=1
    shift
fi

category="${1:-}"
if [ -z "$category" ]; then
    echo "web_picker.sh: usage: web_picker.sh [--list] <category>" >&2
    exit 1
fi

if [ ! -f "$WEBSITES_CONF" ]; then
    echo "web_picker.sh: data file not found: $WEBSITES_CONF" >&2
    exit 1
fi

pages="$(list_pages "$WEBSITES_CONF" "$category")"
if [ -z "$pages" ]; then
    echo "web_picker.sh: unknown or empty category: $category" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Web Hub" "No pages found for \"$category\""
    exit 1
fi

if [ "$list_mode" -eq 1 ]; then
    printf '%s\n' "$pages"
    exit 0
fi

declare -A URL_OF
menu=""
while IFS=$'\t' read -r name url; do
    [ -n "$name" ] || continue
    URL_OF["$name"]="$url"
    menu+="$name"$'\n'
done <<< "$pages"

chosen=$(printf '%s' "$menu" | rofi -dmenu -p "$category" -theme "$THEME")
[ -n "$chosen" ] || exit 0

url="${URL_OF[$chosen]:-}"
[ -n "$url" ] || exit 0

printf '%s' "$url"
