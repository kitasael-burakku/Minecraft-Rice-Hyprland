#!/usr/bin/env bash
# ============================================================================
#  desktop-mode.sh — desktop profiles: normal / focus / gaming / cinema
# ----------------------------------------------------------------------------
#  Combines, per profile:
#   - DND (swaync-client -dn/-df)
#   - blur/animations (hyprctl eval hl.config — same mechanism as
#     hypr/dynamic-colors.sh: an hl.config() applied this way persists
#     until the next login, a plain `hyprctl reload` does NOT reset it,
#     because reload doesn't re-run the Lua modules)
#   - hypridle: "normal" uses hypridle.service (systemd); "focus" stops
#     that service and launches a raw process with hypridle-focus.conf
#     (long timeouts); "gaming"/"cinema" just stop it entirely
#   - power-profile (powerprofilesctl, if installed)
#   - waybar: only "cinema" hides it (systemctl stop waybar.service)
#
#  Known and accepted limitations (documented in the audit, not
#  implemented here): "minimal waybar" in focus and "low brightness" in
#  cinema. Neither has a clean mechanism available — the first would need
#  maintaining a parallel waybar config (debt the rest of this rice
#  deliberately avoids), the second needs brightnessctl, which isn't
#  installed. The rest of each profile does actually work.
#
#  The mode deliberately does NOT survive a relogin — hyprland.start
#  re-runs decoration.lua/animations.lua (blur/animations on) and starts
#  hypridle.service from scratch. Nobody wants to log back in and still
#  be in "gaming" by accident.
#
#  Usage: desktop-mode.sh [normal|focus|gaming|cinema|status]
# ============================================================================
set -u
set -o pipefail

STATE_FILE="$HOME/.cache/kitasan-desktop-mode"
HYPRIDLE_PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/kitasan-hypridle-raw.pid"
FOCUS_HYPRIDLE_CONF="$HOME/.config/hypr/hypridle-focus.conf"

mode="${1:-}"

stop_raw_hypridle() {
    if [ -f "$HYPRIDLE_PID_FILE" ]; then
        pid="$(cat "$HYPRIDLE_PID_FILE" 2>/dev/null)"
        [ -n "$pid" ] && kill "$pid" 2>/dev/null
        rm -f "$HYPRIDLE_PID_FILE"
    fi
    # in case one was left orphaned from a previous run with no pidfile
    pkill -f "hypridle -c $FOCUS_HYPRIDLE_CONF" 2>/dev/null || true
}

set_blur_animations() {
    local enabled="$1"  # true | false
    hyprctl eval "hl.config({ decoration = { blur = { enabled = $enabled } } })" >/dev/null 2>&1
    hyprctl eval "hl.config({ animations = { enabled = $enabled } })" >/dev/null 2>&1
}

set_power_profile() {
    command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set "$1" >/dev/null 2>&1
}

case "$mode" in
    status)
        [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "normal"
        exit 0
        ;;
    normal)
        swaync-client -df >/dev/null 2>&1
        set_blur_animations true
        stop_raw_hypridle
        systemctl --user start hypridle.service 2>/dev/null
        systemctl --user start waybar.service 2>/dev/null
        set_power_profile balanced
        ;;
    focus)
        swaync-client -dn >/dev/null 2>&1
        set_blur_animations true
        systemctl --user stop hypridle.service 2>/dev/null
        stop_raw_hypridle
        if [ -f "$FOCUS_HYPRIDLE_CONF" ] && command -v hypridle >/dev/null 2>&1; then
            nohup hypridle -c "$FOCUS_HYPRIDLE_CONF" >/dev/null 2>&1 &
            echo $! > "$HYPRIDLE_PID_FILE"
            disown
        fi
        set_power_profile balanced
        ;;
    gaming)
        swaync-client -dn >/dev/null 2>&1
        set_blur_animations false
        systemctl --user stop hypridle.service 2>/dev/null
        stop_raw_hypridle
        set_power_profile performance
        ;;
    cinema)
        swaync-client -dn >/dev/null 2>&1
        set_blur_animations true
        systemctl --user stop hypridle.service 2>/dev/null
        stop_raw_hypridle
        systemctl --user stop waybar.service 2>/dev/null
        set_power_profile balanced
        ;;
    *)
        echo "Usage: desktop-mode.sh [normal|focus|gaming|cinema|status]" >&2
        exit 1
        ;;
esac

mkdir -p "$(dirname "$STATE_FILE")"
printf '%s' "$mode" > "$STATE_FILE"
command -v notify-send >/dev/null 2>&1 && notify-send "Desktop mode" "→ $mode"
