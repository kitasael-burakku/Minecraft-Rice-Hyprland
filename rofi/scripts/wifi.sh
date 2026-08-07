#!/usr/bin/env bash
# ============================================================================
#  wifi.sh — conectar a una red Wi-Fi vía rofi
# ----------------------------------------------------------------------------
#  waybar abre nm-connection-editor (GTK, lento) en el click de la red.
#  nmcli ya alcanza para listar y conectar en una línea — esto sólo le pone
#  una lista rofi encima. Si la red pide contraseña, se detecta por el
#  mensaje de error de nmcli ("Secrets were required") y se pide aparte con
#  `rofi -password` en vez de intentar adivinar de antemano si hace falta.
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/clipboard.rasi"
command -v nmcli >/dev/null 2>&1 || exit 0

if nmcli radio wifi 2>/dev/null | grep -qi disabled; then
    nmcli radio wifi on
    sleep 1
fi

nmcli device wifi rescan >/dev/null 2>&1
sleep 1

declare -A SIGNAL_OF SEC_OF INUSE_OF

# Un SSID puede aparecer varias veces (varios APs de la misma red) — nos
# quedamos con la entrada de mejor señal para cada SSID.
while IFS=: read -r ssid signal sec inuse; do
    [ -n "$ssid" ] || continue
    if [ -n "${SIGNAL_OF[$ssid]:-}" ] && [ "${SIGNAL_OF[$ssid]}" -ge "$signal" ] 2>/dev/null; then
        continue
    fi
    SIGNAL_OF["$ssid"]="$signal"
    SEC_OF["$ssid"]="$sec"
    [ "$inuse" = "*" ] && INUSE_OF["$ssid"]=1
done < <(nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list 2>/dev/null)

if [ "${#SIGNAL_OF[@]}" -eq 0 ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "No se encontraron redes"
    exit 0
fi

declare -A LABEL_TO_SSID
menu=""
for ssid in "${!SIGNAL_OF[@]}"; do
    icon="󰖩"
    [ -n "${SEC_OF[$ssid]}" ] && icon="󰖩 󰌾"
    suffix=""
    [ -n "${INUSE_OF[$ssid]:-}" ] && suffix="  (conectado)"
    label="${icon}  ${ssid}  [${SIGNAL_OF[$ssid]}%]${suffix}"
    LABEL_TO_SSID["$label"]="$ssid"
    menu+="$label"$'\n'
done

# Orden por señal descendente (el número entre corchetes).
chosen=$(printf '%s' "$menu" | sort -t'[' -k2 -rn | rofi -dmenu -p "Wi-Fi" -theme "$THEME")
[ -n "$chosen" ] || exit 0

ssid="${LABEL_TO_SSID[$chosen]}"
[ -n "$ssid" ] || exit 0

err=$(nmcli device wifi connect "$ssid" 2>&1)
status=$?

if [ "$status" -ne 0 ] && printf '%s' "$err" | grep -qiE 'secrets were required|802-1x|key-mgmt'; then
    pass=$(rofi -dmenu -p "Contraseña de $ssid" -password -theme "$THEME")
    [ -n "$pass" ] || exit 0
    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "Conectado a $ssid"
    else
        command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Wi-Fi" "No se pudo conectar a $ssid"
    fi
elif [ "$status" -eq 0 ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "Conectado a $ssid"
else
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Wi-Fi" "No se pudo conectar a $ssid"
fi
