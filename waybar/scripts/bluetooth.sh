#!/usr/bin/env bash
# ============================================================================
#  bluetooth.sh — estado de bluetooth para Waybar (custom/bluetooth)
# ----------------------------------------------------------------------------
#  El módulo nativo "bluetooth" de Waybar no está reflejando los cambios de
#  power/conexión en la barra (confirmado: el estado real cambia bien vía
#  bluetoothctl, pero el widget no se redibuja) y no expone ningún mecanismo
#  externo para forzarlo a refrescar — a diferencia de un módulo custom/*, que
#  sí acepta "signal" y se puede disparar a demanda. Este script reemplaza al
#  módulo nativo con el mismo patrón que gpu.sh/updates.sh: rofi/scripts/
#  bluetooth.sh manda pkill -RTMIN+9 waybar después de tocar el estado, así
#  que el refresco no depende de que Waybar detecte el cambio por su cuenta.
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
    printf '%s\n' '{"text":"󰂲","tooltip":"Bluetooth apagado","class":"disabled"}'
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
    tooltip=$(printf 'Bluetooth encendido\n\nConectado:\n%s' "$(printf '  • %s\n' "${connected_names[@]}")")
    css_class="connected"
else
    text="󰂯"
    tooltip="Bluetooth encendido"
    css_class="enabled"
fi

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":\"$css_class\"}"
printf '%s\n' "$result"
