#!/usr/bin/env bash
# ============================================================================
#  window-switcher.sh — ALT+TAB style con minimize/restore via rofi
#  Click en ventana activa   → minimizar
#  Click en ventana minimizada → restaurar y enfocar
# ============================================================================
set -o pipefail

MINIMIZED_WS="special:minimized"
LOG="${XDG_RUNTIME_DIR:-/tmp}/rofi-winswitcher.log"
ICON_CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/rofi-winswitcher-icons"

# Escapa markup Pango: rofi interpreta $label como markup (markup-rows=true
# más abajo), y un título de ventana con "&" o "<" (común en pestañas de
# navegador) rompe la fila sin esto.
escape_pango() {
    local s="$1"
    # "\&" a propósito: en "${var//pat/repl}" bash trata un "&" suelto en
    # repl como "lo que matcheó" (igual que sed) — sin escaparlo, "&lt;"
    # se reescribe mal como "<lt;" cuando el patrón es "<".
    s="${s//&/\&amp;}"
    s="${s//</\&lt;}"
    s="${s//>/\&gt;}"
    echo "$s"
}

get_icon() {
    local class="$1"
    # Cache por clase en $XDG_RUNTIME_DIR: sin esto, el find sobre los dos
    # árboles de .desktop corre una vez POR VENTANA en cada apertura de
    # ALT+TAB. Se limpia solo entre logins (una clase rara vez cambia de
    # icono entre reinicios).
    mkdir -p "$ICON_CACHE_DIR"
    local cache_file="$ICON_CACHE_DIR/$class"
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
        return 0
    fi

    # Busca el .desktop file y extrae el Icon=
    local desktop_file icon
    desktop_file="$(find /usr/share/applications ~/.local/share/applications 2>/dev/null \
        -iname "${class}.desktop" -o -iname "${class,,}.desktop" 2>/dev/null \
        | head -n1)"

    if [ -n "$desktop_file" ]; then
        icon="$(grep -m1 '^Icon=' "$desktop_file" | cut -d= -f2)"
    else
        icon="$class"
    fi

    printf '%s' "$icon" > "$cache_file"
    printf '%s' "$icon"
}

# ── Callback: el usuario eligió una entrada ───────────────────────────────────
if [ "${ROFI_RETV:-0}" = "1" ]; then
    chosen="$1"
    address="$(echo "$chosen" | grep -oP '(?<=addr:)[a-fx0-9]+')"

    if [ -z "$address" ]; then
        echo "$(date) ERROR: no se pudo extraer address de: $chosen" >> "$LOG"
        exit 1
    fi

    ws="$(hyprctl -j clients | jq -r --arg addr "$address" \
        '.[] | select(.address == $addr) | .workspace.name')"

    echo "$(date) CHOSEN: $chosen | address: $address | ws: $ws" >> "$LOG"

    if [ "$ws" = "$MINIMIZED_WS" ]; then
        # Restaurar: mover al workspace activo y enfocar
        active_ws="$(hyprctl -j activeworkspace | jq -r '.id')"
        hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = \"$active_ws\", window = \"address:$address\" }))" >/dev/null 2>&1
        sleep 0.05
        hyprctl eval "hl.dispatch(hl.dsp.window.focus({ window = \"address:$address\" }))" >/dev/null 2>&1
    else
        # Minimizar
        hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = \"$MINIMIZED_WS\", follow = false, window = \"address:$address\" }))" >/dev/null 2>&1
    fi

    exit 0
fi

# ── Listado inicial ───────────────────────────────────────────────────────────
echo -en "\0prompt\x1f󰖯  Windows\n"
echo -en "\0no-custom\x1ftrue\n"
echo -en "\0markup-rows\x1ftrue\n"

# Primero las activas, luego las minimizadas
while IFS=$'\t' read -r address class title ws; do
    [ -z "$address" ] && continue
    [ "$class" = "" ] && continue

    icon="$(get_icon "$class")"
    title="$(escape_pango "$title")"

    if [ "$ws" = "$MINIMIZED_WS" ]; then
        # Minimizada — label con indicador
        label="<span alpha='60%'>󰘲  $title</span>  <span size='small' alpha='40%'>addr:$address</span>"
    else
        # Activa
        label="  $title  <span size='small' alpha='40%'>addr:$address</span>"
    fi

    echo -en "${label}\0icon\x1f${icon}\n"

done < <(hyprctl -j clients | jq -r \
    'sort_by(.workspace.name == "special:minimized") |
     .[] | "\(.address)\t\(.class)\t\(.title)\t\(.workspace.name)"')