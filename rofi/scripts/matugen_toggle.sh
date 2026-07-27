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
set -o pipefail

SENTINEL="$HOME/.config/matugen/enabled"
RELOAD_SCRIPT="$HOME/.config/rofi/scripts/matugen_reload.sh"
APPLY_STATIC="$HOME/.config/hypr/scripts/apply-static-colors.sh"

# La copia de los *.static.* + reloads de daemon vive en apply-static-colors.sh,
# compartido con el bootstrap de un clon nuevo (ver README > Manual Installation).
restore_static() {
    bash "$APPLY_STATIC"
}

current_wallpaper() {
    # Fuente principal: el estado que persiste hypr/scripts/apply-wallpaper.sh
    # cada vez que se aplica un wallpaper — cubre video E imagen por igual.
    local state="$HOME/.config/hypr/.current-wallpaper"
    if [ -f "$state" ]; then
        local wall
        wall="$(cat "$state" 2>/dev/null)"
        if [ -n "$wall" ] && [ -f "$wall" ]; then
            echo "$wall"
            return 0
        fi
    fi

    # Fallback: introspección del proceso de mpvpaper (solo cubre video) —
    # cubre el caso de que el archivo de estado todavía no exista.
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
