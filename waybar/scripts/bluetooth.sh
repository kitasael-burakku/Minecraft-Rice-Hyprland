#!/usr/bin/env bash
# ============================================================================
#  bluetooth.sh — bluetooth status for Waybar (custom/bluetooth)
# ----------------------------------------------------------------------------
#  Waybar's native "bluetooth" module isn't reflecting power/connection
#  changes in the bar (confirmed: the real state changes fine via
#  bluetoothctl, but the widget doesn't redraw) and doesn't expose any
#  external mechanism to force a refresh — unlike a custom/* module, which
#  does accept "signal" and can be triggered on demand. This script
#  replaces the native module with the same pattern as gpu.sh/updates.sh:
#  rofi/scripts/bluetooth.sh sends pkill -RTMIN+9 waybar after touching the
#  state, so the refresh doesn't depend on Waybar detecting the change on
#  its own.
# ============================================================================
set -o pipefail

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

command -v bluetoothctl >/dev/null 2>&1 || {
    printf '%s\n' '{"text":"","tooltip":"bluetoothctl not found","class":"hidden"}'
    exit 0
}

powered=$(bluetoothctl show 2>/dev/null | grep -oP 'Powered:\s*\K\w+')

if [[ "$powered" != "yes" ]]; then
    printf '%s\n' '{"text":"󰂲","tooltip":"Bluetooth off","class":"disabled"}'
    exit 0
fi

connected_names=()
while IFS= read -r line; do
    mac=$(printf '%s' "$line" | awk '{print $2}')
    name=$(printf '%s' "$line" | cut -d' ' -f3-)
    [[ -n "$mac" ]] || continue
    connected_names+=("$name")
done < <(bluetoothctl devices Connected 2>/dev/null)

count=${#connected_names[@]}

if (( count > 0 )); then
    text="󰂱 ${count}"
    tooltip=$(printf 'Bluetooth on\n\nConnected:\n%s' "$(printf '  • %s\n' "${connected_names[@]}")")
    css_class="connected"
else
    text="󰂯"
    tooltip="Bluetooth on"
    css_class="enabled"
fi

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":\"$css_class\"}"
printf '%s\n' "$result"
