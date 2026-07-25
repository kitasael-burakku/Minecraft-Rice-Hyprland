#!/usr/bin/env bash
# ============================================================================
#  matugen_toggle.sh — enciende/apaga el theming dinámico por wallpaper
# ----------------------------------------------------------------------------
#  Apagado por defecto. Al encender, intenta generar colores ya mismo a
#  partir del wallpaper actual (detectado vía el proceso de mpvpaper si es
#  video). Al apagar, restaura los *.static exactos — cero diferencia
#  visual contra el estado previo a instalar todo esto.
# ============================================================================

set -u

SENTINEL="$HOME/.config/matugen/enabled"
RELOAD_SCRIPT="$HOME/.config/rofi/scripts/matugen_reload.sh"
STATIC_HYPR="$HOME/.config/hypr/scripts/dynamic-colors.static.sh"
PATCH_STARSHIP="$HOME/.config/rofi/scripts/matugen_patch_starship.sh"

restore_static() {
    cp "$HOME/.config/rofi/colors.static.rasi"      "$HOME/.config/rofi/colors.rasi"        2>/dev/null || true
    cp "$HOME/.config/waybar/colors.static.css"      "$HOME/.config/waybar/colors.css"        2>/dev/null || true
    cp "$HOME/.config/wlogout/colors.static.css"     "$HOME/.config/wlogout/colors.css"       2>/dev/null || true
    cp "$HOME/.config/hyprlock/colors.static.conf"   "$HOME/.config/hyprlock/colors.conf"     2>/dev/null || true
    cp "$HOME/.config/kitty/colors/colors.static.conf" "$HOME/.config/kitty/colors/colors.conf" 2>/dev/null || true
    cp "$HOME/.config/swaync/colors.static.css"      "$HOME/.config/swaync/colors.css"        2>/dev/null || true
    [ -x "$STATIC_HYPR" ] && bash "$STATIC_HYPR"
    [ -x "$PATCH_STARSHIP" ] && bash "$PATCH_STARSHIP" "$HOME/.config/matugen/dynamic-hex.static.sh"
    pkill -SIGUSR2 waybar 2>/dev/null || true
    killall -SIGUSR1 kitty 2>/dev/null || true
    command -v swaync-client >/dev/null 2>&1 && swaync-client -rs >/dev/null 2>&1 || true
}

current_wallpaper() {
    # Caso video (mpvpaper, el default de este rice) — el path es el último
    # argumento del proceso. Si no hay mpvpaper corriendo (wallpaper de
    # imagen vía awww), no hay forma simple de introspectar el path actual;
    # se deja para la próxima vez que se elija un wallpaper con el picker.
    local mpv_cmd
    mpv_cmd="$(pgrep -a mpvpaper 2>/dev/null | head -n1)"
    if [ -n "$mpv_cmd" ]; then
        echo "$mpv_cmd" | awk '{print $NF}'
        return 0
    fi
    return 1
}

if [ -f "$SENTINEL" ]; then
    # ── Apagar ────────────────────────────────────────────────────────────
    rm -f "$SENTINEL"
    restore_static
    command -v notify-send >/dev/null 2>&1 && notify-send "Matugen" "Theming dinámico apagado — colores estáticos restaurados"
    echo "apagado"
else
    # ── Encender ──────────────────────────────────────────────────────────
    mkdir -p "$(dirname "$SENTINEL")"
    touch "$SENTINEL"
    if wall="$(current_wallpaper)" && [ -n "$wall" ]; then
        bash "$RELOAD_SCRIPT" "$wall"
        command -v notify-send >/dev/null 2>&1 && notify-send "Matugen" "Theming dinámico activado"
    else
        command -v notify-send >/dev/null 2>&1 && notify-send "Matugen" "Theming dinámico activado — elegí un wallpaper para generar colores"
    fi
    echo "encendido"
fi
