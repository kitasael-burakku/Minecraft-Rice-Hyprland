#!/usr/bin/env bash
# ============================================================================
#  web_launcher.sh — entry point for the Rofi web hub (two-level picker)
# ----------------------------------------------------------------------------
#  Bound to SUPER + SHIFT + / (see hypr/modules/keybinds.lua). This is the
#  only script the keybind calls — it drives the category picker then the
#  page picker as two blocking, sequential rofi calls, mirroring
#  wallpaper_launcher.sh: no nested rofi processes, no lingering state.
#
#  Unlike the wallpaper picker (which needs rofi script mode for
#  thumbnails), both levels here are plain text lists, so web_category.sh
#  and web_picker.sh just print their pick on stdout and this script reads
#  it straight from the command substitution — no XDG_RUNTIME_DIR handoff
#  file needed. ESC at either level means empty output, which this script
#  treats as "stop here, open nothing".
# ============================================================================
set -u
set -o pipefail

ROFI_DIR="${ROFI_DIR:-$HOME/.config/rofi}"
SCRIPTS_DIR="${SCRIPTS_DIR:-$ROFI_DIR/scripts}"
PROGRAMS_LUA="${PROGRAMS_LUA:-$HOME/.config/hypr/modules/programs.lua}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/rofi-web-hub.log"

# shellcheck source=web_common.sh
source "$SCRIPTS_DIR/web_common.sh"

notify_err() {
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Web Hub" "$1"
}

# Toggle: if a menu from this flow (or any other rofi picker) is already
# open, closing it is more useful than stacking a second window with fresh
# state on top of it — same pattern as wallpaper_launcher.sh.
if pgrep -x rofi >/dev/null; then
    pkill -x rofi
    exit 0
fi

if ! command -v rofi >/dev/null 2>&1; then
    echo "web_launcher.sh: rofi is not installed" >&2
    notify_err "rofi is not installed"
    exit 1
fi

if [ ! -f "$WEBSITES_CONF" ]; then
    echo "web_launcher.sh: data file not found: $WEBSITES_CONF" >&2
    notify_err "websites.conf not found"
    exit 1
fi

# resolve_browser — echoes the command to launch, or nothing if none found.
#   1) $BROWSER, exported from hypr/modules/programs.lua via
#      hl.env("BROWSER", Programs.browser) — the normal path once Hyprland
#      has (re)loaded.
#   2) Parse `browser = "..."` straight out of programs.lua — covers
#      running this script before a reload, or outside Hyprland entirely,
#      without a second hardcoded copy of the browser name.
#   3) xdg-open — respects the desktop's default browser (xdg-settings) as
#      a last resort if neither of the above resolved to something usable.
resolve_browser() {
    if [ -n "${BROWSER:-}" ] && command -v "${BROWSER%% *}" >/dev/null 2>&1; then
        printf '%s' "$BROWSER"
        return 0
    fi

    if [ -f "$PROGRAMS_LUA" ]; then
        local from_lua
        from_lua="$(sed -nE 's/^[[:space:]]*browser[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$PROGRAMS_LUA" | head -n1)"
        if [ -n "$from_lua" ] && command -v "$from_lua" >/dev/null 2>&1; then
            printf '%s' "$from_lua"
            return 0
        fi
    fi

    if command -v xdg-open >/dev/null 2>&1; then
        printf '%s' "xdg-open"
        return 0
    fi

    return 1
}

browser="$(resolve_browser)"
if [ -z "$browser" ]; then
    echo "web_launcher.sh: no usable browser found (\$BROWSER, programs.lua, xdg-open all failed)" >&2
    notify_err "No browser found — check Programs.browser in programs.lua"
    exit 1
fi

category=$("$SCRIPTS_DIR/web_category.sh")
[ -n "$category" ] || exit 0

url=$("$SCRIPTS_DIR/web_picker.sh" "$category")
[ -n "$url" ] || exit 0

echo "$(date) OPEN: [$category] $url via $browser" >> "$LOG"

read -r -a browser_cmd <<< "$browser"
nohup "${browser_cmd[@]}" "$url" >/dev/null 2>&1 &
disown
