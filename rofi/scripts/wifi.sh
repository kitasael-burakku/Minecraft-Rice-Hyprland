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

# Si ya hay un rofi abierto (ej. un click repetido antes de que cierre el
# anterior), lo cerramos en vez de apilar una segunda ventana encima de una
# con datos viejos — mismo patrón que wallpaper_launcher.sh.
if pgrep -x rofi >/dev/null; then
    pkill -x rofi
    exit 0
fi

if nmcli radio wifi 2>/dev/null | grep -qi disabled; then
    nmcli radio wifi on
    sleep 1
fi

# OJO con esto: "nmcli device wifi rescan" NO es confiablemente rápido —
# a veces vuelve casi al instante (si NetworkManager deduplica contra un
# escaneo reciente) y a veces bloquea de verdad varios segundos esperando
# un escaneo real sobre la radio (confirmado en vivo: 14s+ cuando había
# pasado un rato desde el último). Pedirlo ACÁ, antes de mostrar el menú,
# es lo que hacía sentir lento el click. En vez de eso: listar del cache de
# NetworkManager (instantáneo siempre, ~7ms, poblado solo por su escaneo
# periódico de fondo) y disparar el rescan real DESPUÉS, en background — no
# refresca esta apertura, pero deja la próxima más fresca sin que nadie
# tenga que esperarlo.
#
# TRAMPA: "nmcli dev wifi list" sin más también escanea si el caché tiene
# más de ~30s (--rescan auto es el default) — el mismo bloqueo de arriba
# colándose por la puerta de atrás. Por eso el --rescan no explícito abajo:
# confirmado en vivo, sin él tardaba 14.8s en frío y 7ms en caliente.
nohup nmcli device wifi rescan >/dev/null 2>&1 &
disown

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
done < <(nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list --rescan no 2>/dev/null)

if [ "${#SIGNAL_OF[@]}" -eq 0 ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "No nets found"
    exit 0
fi

declare -A LABEL_TO_SSID
menu=""
for ssid in "${!SIGNAL_OF[@]}"; do
    icon="󰖩"
    suffix=""
    if [ -n "${SEC_OF[$ssid]}" ]; then
        icon="󰖩 󰌾"
    else
        suffix="  [OPEN]"
    fi
    [ -n "${INUSE_OF[$ssid]:-}" ] && suffix="${suffix}  (Connected)"
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
    # nmcli no tiene forma no-interactiva de pasar la password sin argv (no
    # soporta stdin para esto); "nmcli --ask" evita el argv pidiéndola de
    # forma interactiva, pero no se usa acá porque no está verificado que
    # funcione bien con un prompt pipeado (no-tty) sin arriesgar dejar al
    # usuario sin poder conectarse. Riesgo aceptado: queda brevemente
    # visible en `ps`/`/proc/<pid>/cmdline` solo para otros procesos DEL
    # MISMO usuario local, nunca en la red ni para otros usuarios.
    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "Connected to $ssid"
    else
        command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Wi-Fi" "Could not connect to $ssid"
    fi
elif [ "$status" -eq 0 ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "Connected to $ssid"
else
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Wi-Fi" "Could not connect to $ssid"
fi
