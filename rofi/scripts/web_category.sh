#!/usr/bin/env bash
# ============================================================================
#  web_category.sh — category picker (level 0) for the Rofi web hub
# ----------------------------------------------------------------------------
#  Prints every [Category] header from websites.conf, in file order, as a
#  rofi -dmenu list, and writes the chosen category to stdout. Called by
#  web_launcher.sh only — never bound directly to a key (same rule as
#  wallpaper_rofi.sh in the wallpaper picker chain).
#
#  `--list` prints the categories without opening rofi, so the parser in
#  web_common.sh can be exercised headless.
# ============================================================================
set -u
set -o pipefail

ROFI_DIR="${ROFI_DIR:-$HOME/.config/rofi}"
SCRIPTS_DIR="${SCRIPTS_DIR:-$ROFI_DIR/scripts}"
THEME="${WEB_HUB_THEME:-$ROFI_DIR/web-hub.rasi}"

# shellcheck source=web_common.sh
source "$SCRIPTS_DIR/web_common.sh"

if [ ! -f "$WEBSITES_CONF" ]; then
    echo "web_category.sh: data file not found: $WEBSITES_CONF" >&2
    exit 1
fi

categories="$(list_categories "$WEBSITES_CONF")"
if [ -z "$categories" ]; then
    echo "web_category.sh: no categories found in $WEBSITES_CONF" >&2
    exit 1
fi

if [ "${1:-}" = "--list" ]; then
    printf '%s\n' "$categories"
    exit 0
fi

chosen=$(printf '%s\n' "$categories" | rofi -dmenu -p "Web Hub" -theme "$THEME")
printf '%s' "$chosen"
