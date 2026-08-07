#!/usr/bin/env bash
# ============================================================================
#  desktop-mode.sh — perfiles de escritorio: normal / focus / gaming / cinema
# ----------------------------------------------------------------------------
#  Combina, por perfil:
#   - DND (swaync-client -dn/-df)
#   - blur/animaciones (hyprctl eval hl.config — igual mecanismo que
#     hypr/dynamic-colors.sh: un hl.config() aplicado así persiste hasta el
#     próximo login, un simple `hyprctl reload` NO lo resetea, porque reload
#     no vuelve a ejecutar los módulos Lua)
#   - hypridle: "normal" usa hypridle.service (systemd); "focus" para ese
#     servicio y lanza un proceso crudo con hypridle-focus.conf (timeouts
#     largos); "gaming"/"cinema" simplemente lo paran del todo
#   - power-profile (powerprofilesctl, si está instalado)
#   - waybar: sólo "cinema" la oculta (systemctl stop waybar.service)
#
#  Limitaciones conocidas y aceptadas (documentadas en la auditoría, no
#  implementadas acá): "waybar minimal" en focus y "brillo bajo" en cinema.
#  Ninguna de las dos tiene un mecanismo limpio disponible — la primera
#  necesitaría mantener una config de waybar paralela (deuda que el resto
#  de este rice evita a propósito), la segunda necesita brightnessctl, que
#  no está instalado. El resto de cada perfil sí funciona de verdad.
#
#  El modo NO sobrevive un relogin a propósito — hyprland.start vuelve a
#  correr decoration.lua/animations.lua (blur/animaciones on) y arranca
#  hypridle.service de cero. Nadie quiere volver a loguearse y seguir en
#  "gaming" por accidente.
#
#  Uso: desktop-mode.sh [normal|focus|gaming|cinema|status]
# ============================================================================
set -u
set -o pipefail

STATE_FILE="$HOME/.cache/kitasan-desktop-mode"
HYPRIDLE_PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/kitasan-hypridle-raw.pid"
FOCUS_HYPRIDLE_CONF="$HOME/.config/hypr/hypridle-focus.conf"

mode="${1:-}"

stop_raw_hypridle() {
    if [ -f "$HYPRIDLE_PID_FILE" ]; then
        pid="$(cat "$HYPRIDLE_PID_FILE" 2>/dev/null)"
        [ -n "$pid" ] && kill "$pid" 2>/dev/null
        rm -f "$HYPRIDLE_PID_FILE"
    fi
    # por si quedó uno huérfano de una corrida anterior sin pidfile
    pkill -f "hypridle -c $FOCUS_HYPRIDLE_CONF" 2>/dev/null || true
}

set_blur_animations() {
    local enabled="$1"  # true | false
    hyprctl eval "hl.config({ decoration = { blur = { enabled = $enabled } } })" >/dev/null 2>&1
    hyprctl eval "hl.config({ animations = { enabled = $enabled } })" >/dev/null 2>&1
}

set_power_profile() {
    command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set "$1" >/dev/null 2>&1
}

case "$mode" in
    status)
        [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "normal"
        exit 0
        ;;
    normal)
        swaync-client -df >/dev/null 2>&1
        set_blur_animations true
        stop_raw_hypridle
        systemctl --user start hypridle.service 2>/dev/null
        systemctl --user start waybar.service 2>/dev/null
        set_power_profile balanced
        ;;
    focus)
        swaync-client -dn >/dev/null 2>&1
        set_blur_animations true
        systemctl --user stop hypridle.service 2>/dev/null
        stop_raw_hypridle
        if [ -f "$FOCUS_HYPRIDLE_CONF" ] && command -v hypridle >/dev/null 2>&1; then
            nohup hypridle -c "$FOCUS_HYPRIDLE_CONF" >/dev/null 2>&1 &
            echo $! > "$HYPRIDLE_PID_FILE"
            disown
        fi
        set_power_profile balanced
        ;;
    gaming)
        swaync-client -dn >/dev/null 2>&1
        set_blur_animations false
        systemctl --user stop hypridle.service 2>/dev/null
        stop_raw_hypridle
        set_power_profile performance
        ;;
    cinema)
        swaync-client -dn >/dev/null 2>&1
        set_blur_animations true
        systemctl --user stop hypridle.service 2>/dev/null
        stop_raw_hypridle
        systemctl --user stop waybar.service 2>/dev/null
        set_power_profile balanced
        ;;
    *)
        echo "Uso: desktop-mode.sh [normal|focus|gaming|cinema|status]" >&2
        exit 1
        ;;
esac

mkdir -p "$(dirname "$STATE_FILE")"
printf '%s' "$mode" > "$STATE_FILE"
command -v notify-send >/dev/null 2>&1 && notify-send "Modo de escritorio" "→ $mode"
