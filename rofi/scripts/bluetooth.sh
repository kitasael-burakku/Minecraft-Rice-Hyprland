#!/usr/bin/env bash
# ============================================================================
#  bluetooth.sh — conectar/desconectar/emparejar dispositivos, vía rofi
# ----------------------------------------------------------------------------
#  waybar abre blueman-manager en el click de bluetooth. bluetoothctl cubre
#  el uso real: conectar/desconectar algo ya emparejado, y también emparejar
#  algo nuevo (ítem "Buscar dispositivos nuevos") sin recurrir a
#  blueman-manager. `devices Paired` sólo lista lo YA emparejado — un mando o
#  auricular nuevo en modo pairing no aparece ahí ni con nada de esto si no
#  se pide un scan activo, por eso el ítem de búsqueda es explícito.
# ============================================================================
set -u
set -o pipefail

THEME="$HOME/.config/rofi/clipboard.rasi"
command -v bluetoothctl >/dev/null 2>&1 || exit 0

# Si ya hay un rofi abierto (ej. un click repetido antes de que cierre el
# anterior), lo cerramos en vez de apilar una segunda ventana encima de una
# con datos viejos — mismo patrón que wallpaper_launcher.sh.
if pgrep -x rofi >/dev/null; then
    pkill -x rofi
    exit 0
fi

powered="$(bluetoothctl show 2>/dev/null | grep -oP 'Powered:\s*\K\w+')"

declare -A ACTION_OF MAC_OF CONNECTED_OF
menu=""

# El ícono acá representa el ESTADO actual (no la acción del click) — antes
# era al revés (ícono de "apagado" en la fila que dice "Apagar", visible
# cuando está prendido), lo que hacía parecer que nada cambiaba entre
# abrir/cerrar bluetooth aunque el toggle sí funcionara. Ahora el ícono
# coincide con lo que ves, y el texto deja explícita la acción aparte.
if [ "$powered" = "yes" ]; then
    label="󰂯  Bluetooth on — click to turn off"
    ACTION_OF["$label"]="power_off"
else
    label="󰂲  Bluetooth off — click to turn on"
    ACTION_OF["$label"]="power_on"
fi
menu+="$label"$'\n'

if [ "$powered" = "yes" ]; then
    scan_label="󰂰  Buscar dispositivos nuevos…"
    ACTION_OF["$scan_label"]="scan"
    menu+="$scan_label"$'\n'

    while IFS= read -r line; do
        mac="$(printf '%s' "$line" | awk '{print $2}')"
        name="$(printf '%s' "$line" | cut -d' ' -f3-)"
        [ -n "$mac" ] || continue
        connected="$(bluetoothctl info "$mac" 2>/dev/null | grep -oP 'Connected:\s*\K\w+')"
        icon="󰂲"
        [ "$connected" = "yes" ] && icon="󰂱"
        label="${icon}  ${name}"
        # No metemos mac y connected juntos en un solo string tipo
        # "toggle:$mac:$connected" — un MAC ya tiene dos puntos adentro
        # (14:3A:9A:CD:BD:14), así que cortar por ":" con ${rest%%:*} se
        # quedaba con "14" como si fuera el mac completo, y el estado
        # "connected" terminaba pegoteado con el resto del mac. Con eso
        # nunca daba "yes" y el click SIEMPRE terminaba llamando a
        # `connect` (nunca a `disconnect`) contra un mac inválido — el
        # motivo real de que "no pasara nada" al clickear un dispositivo
        # conectado. Arreglado con dos mapas paralelos en vez de encodear
        # todo en un string.
        ACTION_OF["$label"]="toggle"
        MAC_OF["$label"]="$mac"
        CONNECTED_OF["$label"]="$connected"
        menu+="$label"$'\n'
    done < <(bluetoothctl devices Paired 2>/dev/null)
fi

chosen="$(printf '%s' "$menu" | rofi -dmenu -p "Bluetooth" -theme "$THEME")"
[ -n "$chosen" ] || exit 0

action="${ACTION_OF[$chosen]:-}"
[ -n "$action" ] || exit 0

case "$action" in
    power_on)  bluetoothctl power on ;;
    power_off) bluetoothctl power off ;;
    scan)
        # OJO: `bluetoothctl scan on` como comando de una sola invocación
        # (args de la shell) NO escanea nada de verdad en bluez 5.87 — hace
        # SetDiscoveryFilter y el proceso termina ahí mismo, nunca llega a
        # "Discovery started" (confirmado en vivo, con y sin pty, timeout
        # incluido: sale al instante sin encontrar nada). El modo que sí
        # funciona es alimentar "scan on" por stdin a una sesión interactiva
        # y mantenerla viva con un sleep — así el proceso no se cierra antes
        # de que lleguen los eventos [NEW] Device. No hace falta pty (probado
        # con y sin `script`, da igual).
        command -v notify-send >/dev/null 2>&1 && notify-send "Bluetooth" "Buscando dispositivos…"
        found="$( (printf 'scan on\n'; sleep 6; printf 'exit\n') | timeout 10 bluetoothctl 2>/dev/null | grep -oP '(?<=Device )[0-9A-F:]{17}' | sort -u)"

        declare -A DEV_ACTION
        dev_menu=""
        while IFS= read -r mac; do
            [ -n "$mac" ] || continue
            info="$(bluetoothctl info "$mac" 2>/dev/null)"
            # Salteamos lo que ya está emparejado — eso vive en el menú
            # principal con toggle de conectar/desconectar, no acá.
            paired="$(printf '%s' "$info" | grep -oP 'Paired:\s*\K\w+')"
            [ "$paired" = "yes" ] && continue
            name="$(printf '%s' "$info" | grep -oP 'Name:\s*\K.+')"
            [ -n "$name" ] || name="$mac"
            label="󰂲  ${name}"
            DEV_ACTION["$label"]="pair:${mac}"
            dev_menu+="$label"$'\n'
        done <<< "$found"

        if [ -z "$dev_menu" ]; then
            command -v notify-send >/dev/null 2>&1 && notify-send "Bluetooth" "No se encontraron dispositivos nuevos"
            exit 0
        fi

        dev_chosen="$(printf '%s' "$dev_menu" | rofi -dmenu -p "Emparejar" -theme "$THEME")"
        [ -n "$dev_chosen" ] || exit 0
        dev_action="${DEV_ACTION[$dev_chosen]:-}"
        mac="${dev_action#pair:}"
        [ -n "$mac" ] || exit 0

        if bluetoothctl pair "$mac" && bluetoothctl trust "$mac" && bluetoothctl connect "$mac"; then
            command -v notify-send >/dev/null 2>&1 && notify-send "Bluetooth" "Emparejado y conectado"
        else
            command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Bluetooth" "No se pudo emparejar — ¿está en modo pairing?"
        fi
        ;;
    toggle)
        mac="${MAC_OF[$chosen]}"
        connected="${CONNECTED_OF[$chosen]}"
        if [ "$connected" = "yes" ]; then
            bluetoothctl disconnect "$mac"
        else
            bluetoothctl connect "$mac"
        fi
        ;;
esac

# custom/bluetooth (waybar) sondea cada 5s, pero no hay que esperar ese
# margen para ver el cambio reflejado — mismo patrón que custom/updates.
pkill -RTMIN+9 waybar 2>/dev/null
