#!/usr/bin/env bash
# ============================================================================
#  updates.sh — update counter for Waybar (pacman + AUR)
# ============================================================================
set -o pipefail

CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
NOTIFIED_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.notified"
FAILED_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.failed"
CACHE_TTL=300  # 5 minutes

# ── Allow a forced refresh: updates.sh --force ────────────────────────────────
if [[ "${1:-}" != "--force" && -f "$CACHE_FILE" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if (( age < CACHE_TTL )); then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# ── Safe JSON escaping for tooltips ─────────────────────────────────────────
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"   # backslash
    s="${s//\"/\\\"}"   # quotes
    printf '%s' "$s"
}

updates=0
aur=0
error_msg=""

# pacman (pacman-contrib's checkupdates doesn't touch the real database)
# checkupdates documents its exit codes: 0 = updates available, 2 = no
# updates (normal case, not a failure), anything else (e.g. 1: couldn't
# sync the temp DB — no network, lock, etc.) is a real failure.
if command -v checkupdates >/dev/null 2>&1; then
    cu_out="$(mktemp)"; cu_err="$(mktemp)"
    checkupdates >"$cu_out" 2>"$cu_err"
    cu_rc=$?
    updates=$(wc -l < "$cu_out")
    if (( cu_rc != 0 && cu_rc != 2 )); then
        error_msg="checkupdates: $(tr '\n' ' ' < "$cu_err" | sed 's/  */ /g; s/^ *//; s/ *$//')"
    fi
    rm -f "$cu_out" "$cu_err"
fi

# AUR — supports yay or paru automatically
aur_helper=""
if command -v yay >/dev/null 2>&1; then
    aur_helper="yay"
elif command -v paru >/dev/null 2>&1; then
    aur_helper="paru"
fi

if [[ -n "$aur_helper" ]]; then
    # Unlike checkupdates, yay/paru -Qua exits with code 1 both in the
    # normal "no AUR updates" case and on a real failure, and there's no
    # way to tell them apart from the exit code alone. A real failure (no
    # network, RPC down, etc.) does print something to stderr; "no
    # updates" prints nothing. timeout killing the process (124) also
    # counts as a failure.
    au_out="$(mktemp)"; au_err="$(mktemp)"
    timeout 20 "$aur_helper" -Qua >"$au_out" 2>"$au_err"
    au_rc=$?
    aur=$(wc -l < "$au_out")
    if (( au_rc == 124 )); then
        error_msg="${error_msg:+$error_msg; }$aur_helper: timeout (20s)"
    elif (( au_rc != 0 )) && [[ -s "$au_err" ]]; then
        error_msg="${error_msg:+$error_msg; }$aur_helper: $(tr '\n' ' ' < "$au_err" | sed 's/  */ /g; s/^ *//; s/ *$//')"
    fi
    rm -f "$au_out" "$au_err"
fi

# Sanitize (in case wc returns empty or timeout kills the process)
[[ "$updates" =~ ^[0-9]+$ ]] || updates=0
[[ "$aur"     =~ ^[0-9]+$ ]] || aur=0

total=$((updates + aur))

# ── Build output ─────────────────────────────────────────────────────────
if (( total == 0 )); then
    text="󰄬"
    tooltip="System up to date"
    css_class="updated"
else
    text="󰚰 $total"
    tooltip="󰣇 $updates pacman"
    if [[ -n "$aur_helper" ]]; then
        tooltip="$tooltip\n󰮯 $aur AUR ($aur_helper)"
    fi
    # visual marker when there are lots of pending updates
    if (( total >= 50 )); then
        css_class="critical"
    else
        css_class="pending"
    fi
fi

# Extra classes to return besides the one above (e.g. "error"). Waybar
# accepts "class" as a string or as an array of strings in custom modules.
classes=("$css_class")

if [[ -n "$error_msg" ]]; then
    text="$text 󰀦"
    tooltip="$tooltip\n⚠ $error_msg"
    classes+=("error")
fi

# ── Desktop notification ────────────────────────────────────────────────────
# Only alerts when the total rises above the last alert (not on every
# cache refresh), and resets to 0 as soon as the system is up to date so
# the next batch of updates triggers a notification again.
last_notified=0
[[ -f "$NOTIFIED_FILE" ]] && last_notified=$(<"$NOTIFIED_FILE")
[[ "$last_notified" =~ ^[0-9]+$ ]] || last_notified=0

if (( total > 0 && total > last_notified )) && command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Waybar" -i software-update-available \
        "󰚰 Updates available" \
        "$updates pacman$( [[ -n "$aur_helper" ]] && printf ' · %s AUR (%s)' "$aur" "$aur_helper" )"
fi
printf '%s\n' "$total" > "$NOTIFIED_FILE"

# Same as above but for failures: only alerts when entering a failed state
# (not on every refresh while it keeps failing) and resets as soon as it
# works again.
was_failed=0
[[ -f "$FAILED_FILE" ]] && was_failed=$(<"$FAILED_FILE")
[[ "$was_failed" =~ ^(0|1)$ ]] || was_failed=0

if [[ -n "$error_msg" ]]; then
    if (( was_failed == 0 )) && command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical -a "Waybar" -i dialog-warning \
            "󰀦 Failed to check for updates" \
            "$error_msg"
    fi
    printf '1\n' > "$FAILED_FILE"
else
    printf '0\n' > "$FAILED_FILE"
fi

class_json=$(printf '"%s",' "${classes[@]}")
class_json="[${class_json%,}]"

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":${class_json}}"

# Write the cache atomically (avoids Waybar reading a half-written file)
tmp="$(mktemp "${CACHE_FILE}.XXXXXX")"
printf '%s\n' "$result" > "$tmp"
mv -f "$tmp" "$CACHE_FILE"

printf '%s\n' "$result"