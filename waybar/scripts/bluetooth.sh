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
#
#  Modes:
#    (no args)   JSON for Waybar
#    --toggle    power the adapter on/off and refresh the bar (right click)
# ============================================================================
set -o pipefail

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

pango_escape() {
    local s="$1"
    # The backslashes are load-bearing: since bash 5.2 an unescaped & in the
    # replacement of ${var//pat/repl} expands to the matched text, so "&lt;"
    # silently produced "<lt;" instead of an entity.
    s="${s//&/\&amp;}"
    s="${s//</\&lt;}"
    s="${s//>/\&gt;}"
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

command -v bluetoothctl >/dev/null 2>&1 || {
    emit "" "bluetoothctl not found" "hidden"
    exit 0
}

# One call, parsed in the shell: `show` answers both "is there an adapter at
# all" and "is it powered", and telling those two apart matters — without an
# adapter the old version reported "Bluetooth off", which sent you looking for
# a switch that doesn't exist.
adapter=""
alias_name=""
powered=""
while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"   # ltrim
    case "$line" in
        Controller\ *) adapter="${line#Controller }"; adapter="${adapter%% *}" ;;
        Alias:\ *)     alias_name="${line#Alias: }" ;;
        Powered:\ *)   powered="${line#Powered: }" ;;
    esac
done < <(timeout 5 bluetoothctl show 2>/dev/null)

if [[ -z "$adapter" ]]; then
    emit "󰂲" "No Bluetooth adapter found" "unavailable"
    exit 0
fi

# ── --toggle: the right click ───────────────────────────────────────────────
if [[ "${1:-}" == "--toggle" ]]; then
    if [[ "$powered" == "yes" ]]; then
        timeout 5 bluetoothctl power off >/dev/null 2>&1
        new_state="off"
    else
        timeout 5 bluetoothctl power on >/dev/null 2>&1
        new_state="on"
    fi
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -a "Waybar" -i bluetooth "Bluetooth turned $new_state"
    pkill -RTMIN+9 waybar 2>/dev/null
    exit 0
fi

if [[ "$powered" != "yes" ]]; then
    emit "󰂲" "Bluetooth off${alias_name:+
Adapter: $(pango_escape "$alias_name")}
Right click to turn it on" "disabled"
    exit 0
fi

# ── Connected devices, with battery where the device reports it ─────────────
names=()
batteries=()
low=0
while IFS= read -r line; do
    # "Device AA:BB:CC:DD:EE:FF  Some Name"
    [[ "$line" == Device\ * ]] || continue
    rest="${line#Device }"
    mac="${rest%% *}"
    name="${rest#* }"
    [[ -n "$mac" ]] || continue

    # Only connected devices are queried, so this is 0-2 extra calls in
    # practice, once every 20s. Devices that don't implement the battery
    # profile simply don't print the line.
    batt=""
    while IFS= read -r info; do
        if [[ "$info" == *"Battery Percentage:"* ]]; then
            batt="${info##*\(}"; batt="${batt%\)}"
            break
        fi
    done < <(timeout 5 bluetoothctl info "$mac" 2>/dev/null)

    [[ "$batt" =~ ^[0-9]+$ ]] || batt=""
    if [[ -n "$batt" ]] && (( batt <= 20 )); then low=1; fi

    names+=("$name")
    batteries+=("$batt")
done < <(timeout 5 bluetoothctl devices Connected 2>/dev/null)

count=${#names[@]}

if (( count > 0 )); then
    text="󰂱 ${count}"
    tooltip="Bluetooth on"
    [[ -n "$alias_name" ]] && tooltip="$tooltip"$'\n'"Adapter: $(pango_escape "$alias_name")"
    tooltip="$tooltip"$'\n\n'"Connected:"
    for i in "${!names[@]}"; do
        line="  • $(pango_escape "${names[$i]}")"
        [[ -n "${batteries[$i]}" ]] && line="$line  ${batteries[$i]}%"
        tooltip="$tooltip"$'\n'"$line"
    done
    classes=("connected")
    (( low )) && classes+=("low-battery")
    if (( low )); then
        tooltip="$tooltip"$'\n\n'"⚠ Low battery on a connected device"
    fi
    tooltip="$tooltip"$'\n\n'"Left click: devices · Right click: turn off"
    emit "$text" "$tooltip" "${classes[@]}"
else
    tooltip="Bluetooth on — nothing connected"
    [[ -n "$alias_name" ]] && tooltip="$tooltip"$'\n'"Adapter: $(pango_escape "$alias_name")"
    tooltip="$tooltip"$'\n\n'"Left click: devices · Right click: turn off"
    emit "󰂯" "$tooltip" "enabled"
fi
