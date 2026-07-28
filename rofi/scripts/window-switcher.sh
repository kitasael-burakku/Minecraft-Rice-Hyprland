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
    # $ROFI_INFO viene del campo "info" de la fila elegida (ver el "\0info\x1f"
    # más abajo, en el listado) — no del texto visible. Antes esto parseaba
    # "addr:..." del label con regex, y se rompía apenas rofi le hacía
    # cualquier cosa al texto (agregar/sacar el markup de los <span>, etc.):
    # el label real termina en "</span>" después del address, no en el hex
    # pelado, así que un regex anclado a fin de línea nunca matcheaba nada.
    address="${ROFI_INFO:-}"

    if [ -z "$address" ]; then
        echo "$(date) ERROR: ROFI_INFO vacío para: $chosen" >> "$LOG"
        exit 1
    fi

    if ! [[ "$address" =~ ^0x[a-f0-9]+$ ]]; then
        echo "$(date) ERROR: address con formato inválido: $address" >> "$LOG"
        exit 1
    fi

    ws="$(hyprctl -j clients | jq -r --arg addr "$address" \
        '.[] | select(.address == $addr) | .workspace.name')"

    echo "$(date) CHOSEN: $chosen | address: $address | ws: $ws" >> "$LOG"

    if [ "$ws" = "$MINIMIZED_WS" ]; then
        # Restaurar: mover al workspace activo y enfocar
        active_ws="$(hyprctl -j activeworkspace | jq -r '.id')"
        hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = \"$active_ws\", window = \"address:$address\" }))" >/dev/null 2>&1
        # OJO: "focus" no existe dentro de hl.dsp.window (confirmado en vivo,
        # ver hl.dsp.focus vs hl.dsp.window.focus) — vive en hl.dsp, un nivel
        # arriba.
        #
        # setsid + delay: este script ES el callback de rofi (rofi lo espera
        # antes de cerrar), y probando con rofi real (vía inyección de
        # teclado sintética con wtype) el dispatch de foco corría y devolvía
        # "ok" pero no siempre pegaba, con o sin delay — no llegué a aislar
        # la causa exacta con las herramientas de este entorno (puede ser
        # algo propio de esa forma de inyectar teclas, no necesariamente de
        # un teclado real). Esto queda como el mejor intento razonable
        # (setsid para no depender del proceso de rofi, delay corto para no
        # sentirse lento) — si en el uso real la ventana restaurada sigue sin
        # foco, hace falta diagnosticarlo con una interacción real, no
        # simulada.
        setsid bash -c '
            sleep 0.15
            hyprctl eval "hl.dispatch(hl.dsp.focus({ window = \"address:$1\" }))" >>"$2" 2>&1
        ' _ "$address" "$LOG" &
        disown
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

    # "info" viaja aparte del texto visible, vía $ROFI_INFO en el callback —
    # no se toca con markup ni con nada que rofi le haga al label para
    # mostrarlo. OJO con la sintaxis: un solo "\0" al principio del bloque de
    # opciones, y CADA par clave/valor separado por "\x1f" — un segundo "\0"
    # antes de "info" (como tenía esto en un intento anterior) hace que rofi
    # descarte silenciosamente todo lo que viene después del primer "\0",
    # dejando $ROFI_INFO vacío. Confirmado en vivo con rofi real.
    echo -en "${label}\0icon\x1f${icon}\x1finfo\x1f${address}\n"

done < <(hyprctl -j clients | jq -r \
    'sort_by(.workspace.name == "special:minimized") |
     .[] | "\(.address)\t\(.class)\t\(.title)\t\(.workspace.name)"')