#!/usr/bin/env bash
# ============================================================================
#  confirm-then.sh — asks for confirmation (rofi Yes/No) before running $1
# ----------------------------------------------------------------------------
#  Reuses rofi/power-menu.rasi for the visual theme. wlogout has no
#  confirmation step of its own; this adds one to the destructive actions
#  (poweroff/reboot/hibernate) without touching lock/logout/suspend.
#
#  Usage: confirm-then.sh '<command to run if confirmed>' ['<question>']
# ============================================================================

set -u
set -o pipefail

CMD="${1:-}"
LABEL="${2:-Confirm?}"
ROFI_THEME="$HOME/.config/rofi/power-menu.rasi"

[ -n "$CMD" ] || exit 1

choice=$(printf "No\nYes" | rofi -dmenu -p "$LABEL" -theme "$ROFI_THEME")

if [ "$choice" = "Yes" ]; then
    # Whitelist instead of "exec bash -c \"$CMD\"": today there are only 3
    # literal callers (wlogout/layout), all fixed systemd commands —
    # re-parsing an arbitrary string is more surface area than that needs.
    case "$CMD" in
        "systemctl poweroff"|"systemctl reboot"|"systemctl hibernate")
            exec $CMD
            ;;
        *)
            echo "confirm-then.sh: command not allowed: $CMD" >&2
            exit 1
            ;;
    esac
fi
