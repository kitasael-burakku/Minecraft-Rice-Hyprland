#!/usr/bin/env bash
# ============================================================================
#  gpu.sh — uso/temperatura/consumo/VRAM de la GPU (amdgpu) para Waybar
#
#  No hardcodea card1/hwmon2: busca en /sys/class/drm/card*/device la primera
#  tarjeta que exponga gpu_busy_percent (evita romperse si el índice de card
#  cambia entre reinicios, igual que se corrigió para temperature/k10temp).
# ============================================================================
set -o pipefail

# ── Escape JSON seguro (backslash y comillas primero, saltos de línea reales
#    al final para no duplicar el backslash que agrega el paso anterior) ────
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
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

hwmon_dir=$(compgen -G "$gpu_dev/hwmon/hwmon*" | head -n1)

usage=$(cat "$gpu_dev/gpu_busy_percent" 2>/dev/null)
[[ "$usage" =~ ^[0-9]+$ ]] || usage=0

temp_c="?"
watts="?"
if [[ -n "$hwmon_dir" ]]; then
    temp_raw=$(cat "$hwmon_dir/temp1_input" 2>/dev/null)
    [[ "$temp_raw" =~ ^[0-9]+$ ]] && temp_c=$(( temp_raw / 1000 ))

    power_raw=$(cat "$hwmon_dir/power1_average" 2>/dev/null)
    [[ "$power_raw" =~ ^[0-9]+$ ]] && watts=$(awk -v p="$power_raw" 'BEGIN{printf "%.1f", p/1000000}')
fi

vram_used_mb="?"
vram_total_mb="?"
vram_used_raw=$(cat "$gpu_dev/mem_info_vram_used" 2>/dev/null)
vram_total_raw=$(cat "$gpu_dev/mem_info_vram_total" 2>/dev/null)
[[ "$vram_used_raw"  =~ ^[0-9]+$ ]] && vram_used_mb=$(( vram_used_raw / 1024 / 1024 ))
[[ "$vram_total_raw" =~ ^[0-9]+$ ]] && vram_total_mb=$(( vram_total_raw / 1024 / 1024 ))

text="󰢮 ${usage}%"

css_class="normal"
if [[ "$temp_c" =~ ^[0-9]+$ ]] && (( temp_c >= 85 )); then
    css_class="critical"
fi

tooltip=$(printf '   GPU (amdgpu)\n\nUsage:      %s%%\nTemp:     %s°C\nWatts:    %s W\nVRAM:   %s / %s MB' \
    "$usage" "$temp_c" "$watts" "$vram_used_mb" "$vram_total_mb")

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":\"$css_class\"}"

printf '%s\n' "$result"
