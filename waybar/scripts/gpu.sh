#!/usr/bin/env bash
# ============================================================================
#  gpu.sh — GPU (amdgpu) usage/temperature/power/VRAM for Waybar
#
#  Doesn't hardcode card1/hwmon2: searches /sys/class/drm/card*/device for
#  the first card exposing gpu_busy_percent (avoids breaking if the card
#  index changes between reboots, same fix already applied for
#  temperature/k10temp).
#
#  Everything here is a sysfs read, so the whole thing runs without spawning
#  a single subprocess: `read < file` instead of $(cat file). At interval 5
#  that's ~10 forks/run saved, ~120/min, for exactly the same numbers.
# ============================================================================
set -o pipefail

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

# Reads a sysfs file into the named variable, empty if missing/unreadable.
# Keeps the "does this attribute exist on this card" checks to one place —
# amdgpu exposes a different subset depending on model and driver version.
sysread() {
    local __var="$1" __file="$2" __val=""
    [[ -r "$__file" ]] && read -r __val < "$__file" 2>/dev/null
    printf -v "$__var" '%s' "$__val"
}

gpu_dev=""
for d in /sys/class/drm/card*/device; do
    [[ -f "$d/gpu_busy_percent" ]] || continue
    gpu_dev="$d"
    break
done

if [[ -z "$gpu_dev" ]]; then
    printf '%s\n' '{"text":"","tooltip":"GPU not detected","class":"hidden"}'
    exit 0
fi

hwmon_dir=""
for h in "$gpu_dev"/hwmon/hwmon*; do
    [[ -d "$h" ]] && { hwmon_dir="$h"; break; }
done

sysread usage "$gpu_dev/gpu_busy_percent"
[[ "$usage" =~ ^[0-9]+$ ]] || usage=0

sysread vram_busy "$gpu_dev/mem_busy_percent"
sysread vram_used_raw "$gpu_dev/mem_info_vram_used"
sysread vram_total_raw "$gpu_dev/mem_info_vram_total"

# ── Temperatures: edge / junction / mem, whatever this card labels ──────────
temp_c=""          # edge, the one the class threshold uses
temp_lines=""
if [[ -n "$hwmon_dir" ]]; then
    for i in 1 2 3; do
        sysread traw "$hwmon_dir/temp${i}_input"
        [[ "$traw" =~ ^[0-9]+$ ]] || continue
        sysread tlabel "$hwmon_dir/temp${i}_label"
        [[ -n "$tlabel" ]] || tlabel="temp${i}"
        tc=$(( traw / 1000 ))
        (( i == 1 )) && temp_c="$tc"
        temp_lines+=$(printf '\n%-16s %s°C' "Temp ($tlabel):" "$tc")
    done
fi

# ── Power: average draw against the card's own cap ──────────────────────────
watts="?"
if [[ -n "$hwmon_dir" ]]; then
    sysread praw "$hwmon_dir/power1_average"
    # Some cards only expose the instantaneous reading
    [[ "$praw" =~ ^[0-9]+$ ]] || sysread praw "$hwmon_dir/power1_input"
    if [[ "$praw" =~ ^[0-9]+$ ]]; then
        watts=$(( praw / 1000000 ))
        sysread pcap "$hwmon_dir/power1_cap"
        [[ "$pcap" =~ ^[0-9]+$ ]] && watts="$watts / $(( pcap / 1000000 ))"
    fi
fi

# ── Fan and core clock: only reported when they say something ───────────────
fan_line=""
clock_line=""
if [[ -n "$hwmon_dir" ]]; then
    sysread fan "$hwmon_dir/fan1_input"
    if [[ "$fan" =~ ^[0-9]+$ ]]; then
        if (( fan > 0 )); then
            fan_line=$(printf '\n%-16s %s RPM' "Fan:" "$fan")
        else
            fan_line=$(printf '\n%-16s stopped (idle)' "Fan:")
        fi
    fi
    sysread fhz "$hwmon_dir/freq1_input"
    [[ "$fhz" =~ ^[0-9]+$ ]] && (( fhz > 0 )) && \
        clock_line=$(printf '\n%-16s %s MHz' "Core clock:" "$(( fhz / 1000000 ))")
fi

# ── VRAM ────────────────────────────────────────────────────────────────────
vram_line=""
if [[ "$vram_used_raw" =~ ^[0-9]+$ && "$vram_total_raw" =~ ^[0-9]+$ && "$vram_total_raw" -gt 0 ]]; then
    vram_pct=$(( vram_used_raw * 100 / vram_total_raw ))
    vram_line=$(printf '\n%-16s %s / %s GiB (%s%%)' "VRAM:" \
        "$(awk -v v="$vram_used_raw"  'BEGIN{printf "%.1f", v/1073741824}')" \
        "$(awk -v v="$vram_total_raw" 'BEGIN{printf "%.1f", v/1073741824}')" \
        "$vram_pct")
fi

text="󰢮 ${usage}%"

# Critical on junction temp if the card reports one — that's the sensor that
# actually throttles; edge always reads lower and would under-report.
crit_temp="$temp_c"
if [[ -n "$hwmon_dir" ]]; then
    sysread jraw "$hwmon_dir/temp2_input"
    [[ "$jraw" =~ ^[0-9]+$ ]] && crit_temp=$(( jraw / 1000 ))
fi
css_class="normal"
[[ "$crit_temp" =~ ^[0-9]+$ ]] && (( crit_temp >= 95 )) && css_class="critical"

# The data block goes inside <tt>: the tooltip font is Iosevka *Propo*, which
# is proportional, so space-padded columns would never line up without it.
body="$(printf '%-16s %s%%' "Usage:" "$usage")"
[[ "$vram_busy" =~ ^[0-9]+$ ]] && body+=$(printf '\n%-16s %s%%' "Memory bus:" "$vram_busy")
body+="$temp_lines$clock_line$fan_line"
body+=$(printf '\n%-16s %s W' "Power:" "$watts")
body+="$vram_line"

tooltip="   GPU (amdgpu)"$'\n\n'"<tt>$body</tt>"

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":\"$css_class\"}"

printf '%s\n' "$result"
