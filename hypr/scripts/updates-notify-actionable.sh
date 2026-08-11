#!/usr/bin/env bash
# ============================================================================
#  updates-notify-actionable.sh — notification with an "Update now" button
#  when too many updates pile up.
# ----------------------------------------------------------------------------
#  Called by updates-check.service after refreshing the cache (see
#  systemd/user/updates-check.service). Uses the same "critical" threshold
#  (total >= 50) that waybar/scripts/updates.sh already defines for its own
#  CSS class — below that it's daily noise, not something worth a button.
#
#  `notify-send --action` implies --wait: it blocks until the user clicks
#  or dismisses the notification. That's why whoever calls this script
#  MUST ALWAYS do so in the background (see the .service's ExecStartPost) —
#  it should never block whoever triggers it.
#
#  Session marker: without it, every run of updates-check.timer (every 30
#  min) would notify again while the count stays above the threshold, even
#  if the user already saw and dismissed the alert. It only resets when
#  the count drops back below 50 (i.e. after updating).
# ============================================================================
set -u
set -o pipefail

CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
NOTIFIED_MARKER="${XDG_RUNTIME_DIR:-/tmp}/kitasan-updates-notified"

command -v notify-send >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ -f "$CACHE" ] || exit 0

cls="$(jq -r '.class // ""' "$CACHE" 2>/dev/null)"
tooltip="$(jq -r '.tooltip // ""' "$CACHE" 2>/dev/null)"

if [ "$cls" != "critical" ]; then
    rm -f "$NOTIFIED_MARKER"
    exit 0
fi

[ -f "$NOTIFIED_MARKER" ] && exit 0
touch "$NOTIFIED_MARKER"

action="$(notify-send --app-name="kitasan" --icon=software-update-available \
    --action="update=Update now" \
    "Lots of pending updates" "$tooltip" 2>/dev/null)"

if [ "$action" = "update" ]; then
    kitty --title kitasan-update -e fish -c 'kitasan update' &
    disown
fi
