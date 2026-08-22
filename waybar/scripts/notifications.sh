#!/usr/bin/env bash
# ============================================================================
#  notifications.sh — SwayNC state for Waybar (custom/notification)
# ----------------------------------------------------------------------------
#  swaync-client -swb already emits Waybar-shaped JSON, but with an empty
#  tooltip and no count in the text, so the widget could only ever say "there
#  is something" through the glyph alone — and "do not disturb" and "nothing
#  pending" are two very different states behind two very similar bells.
#  This wraps it with the same conventions as the other custom modules here:
#  a class ARRAY (dnd and unread stack), a tooltip that spells the state out,
#  and the click hints.
#
#  It's a long-running subscription, not a poll: one line out per notification
#  event, nothing in between.
# ============================================================================
set -o pipefail
set -u

command -v swaync-client >/dev/null 2>&1 || exit 0

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

emit() {  # emit <text> <tooltip> <class...>
    local text="$1" tooltip="$2"; shift 2
    local class_json
    class_json=$(printf '"%s",' "$@")
    class_json="[${class_json%,}]"
    printf '{"text":"%s","tooltip":"%s","class":%s}\n' \
        "$(json_escape "$text")" "$(json_escape "$tooltip")" "$class_json"
}

HINTS="Left: open panel · Middle: clear all · Right: do not disturb"

swaync-client -swb 2>/dev/null | while IFS= read -r line; do
    [[ -n "$line" ]] || continue

    # One jq call per event, and events happen at human speed — this is not a
    # polling loop.
    read -r count alt < <(jq -r '[(.text // "0"), (.alt // "none")] | @tsv' <<<"$line" 2>/dev/null)
    [[ "$count" =~ ^[0-9]+$ ]] || count=0
    [[ -n "${alt:-}" ]] || alt="none"

    dnd=0; unread=0
    [[ "$alt" == *dnd* ]] && dnd=1
    (( count > 0 )) && unread=1

    classes=()
    (( dnd ))    && classes+=("dnd")
    (( unread )) && classes+=("notification")
    (( ${#classes[@]} )) || classes=("none")

    if (( dnd )); then
        icon="󰂛"
        tooltip="Do not disturb"
        (( unread )) && tooltip="$tooltip — $count waiting"
    elif (( unread )); then
        icon="󱅫"
        tooltip="$count unread notification$( (( count != 1 )) && printf s )"
    else
        icon="󰂚"
        tooltip="No notifications"
    fi

    # The count rides along only when there is one, so the resting state stays
    # a single glyph.
    text="$icon"
    (( unread )) && text="$icon $count"

    emit "$text" "$tooltip"$'\n\n'"$HINTS" "${classes[@]}"
done
