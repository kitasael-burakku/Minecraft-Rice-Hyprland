#!/usr/bin/env bash
# ============================================================================
#  apply-static-colors.sh — aplica la paleta estática "Kitasan Glass"
# ----------------------------------------------------------------------------
#  Dos usos:
#   1) Bootstrap en un clon nuevo: los 9 archivos de color por app son
#      generados por matugen y NO viven en el repo — solo sus contrapartes
#      *.static.* sí. Correr esto una vez tras clonar deja el sistema con la
#      identidad estática, idéntico a como se ve con el theming dinámico
#      apagado (que es el estado por defecto).
#   2) Restauración al apagar matugen: rofi/scripts/matugen_toggle.sh llama
#      a este mismo script en vez de duplicar la lista de copias.
#
#  Los reloads de daemon (waybar/kitty/swaync) están guardados con
#  "|| true" a propósito: en un clon recién instalado esos procesos todavía
#  no corren, y eso no debe hacer fallar el bootstrap.
# ============================================================================

set -u

cp "$HOME/.config/rofi/colors.static.rasi"         "$HOME/.config/rofi/colors.rasi"          2>/dev/null || true
cp "$HOME/.config/waybar/colors.static.css"        "$HOME/.config/waybar/colors.css"         2>/dev/null || true
cp "$HOME/.config/wlogout/colors.static.css"       "$HOME/.config/wlogout/colors.css"        2>/dev/null || true
cp "$HOME/.config/hyprlock/colors.static.conf"     "$HOME/.config/hyprlock/colors.conf"      2>/dev/null || true
cp "$HOME/.config/kitty/colors/colors.static.conf" "$HOME/.config/kitty/colors/colors.conf"  2>/dev/null || true
cp "$HOME/.config/swaync/colors.static.css"        "$HOME/.config/swaync/colors.css"         2>/dev/null || true
cp "$HOME/.config/starship.static.toml"            "$HOME/.config/starship.toml"             2>/dev/null || true
cp "$HOME/.config/fish/theme-goldship.static.fish" "$HOME/.config/fish/conf.d/theme-goldship.fish" 2>/dev/null || true

STATIC_HYPR="$HOME/.config/hypr/scripts/dynamic-colors.static.sh"
[ -x "$STATIC_HYPR" ] && bash "$STATIC_HYPR"

pkill -SIGUSR2 waybar 2>/dev/null || true
killall -SIGUSR1 kitty 2>/dev/null || true
command -v swaync-client >/dev/null 2>&1 && swaync-client -rs >/dev/null 2>&1 || true
