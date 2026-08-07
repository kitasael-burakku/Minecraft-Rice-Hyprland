#!/usr/bin/env bash
# ============================================================================
#  apply-static-colors.sh — aplica la paleta estática "Kitasan Glass"
# ----------------------------------------------------------------------------
#  Dos usos:
#   1) Bootstrap en un clon nuevo: los archivos de color por app son
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
cp "$HOME/.config/hyprlock/scripts/music-colors.static.sh" "$HOME/.config/hyprlock/scripts/music-colors.sh" 2>/dev/null || true
cp "$HOME/.config/gtk-3.0/gtk-colors.static.css"    "$HOME/.config/gtk-3.0/gtk-colors.css"    2>/dev/null || true
cp "$HOME/.config/gtk-4.0/gtk-colors.static.css"    "$HOME/.config/gtk-4.0/gtk-colors.css"    2>/dev/null || true
cp "$HOME/.config/qt5ct/colors/kitasan-glass.static.conf" "$HOME/.config/qt5ct/colors/kitasan-glass.conf" 2>/dev/null || true
cp "$HOME/.config/qt6ct/colors/kitasan-glass.static.conf" "$HOME/.config/qt6ct/colors/kitasan-glass.conf" 2>/dev/null || true

STATIC_HYPR="$HOME/.config/hypr/scripts/dynamic-colors.static.sh"
[ -x "$STATIC_HYPR" ] && bash "$STATIC_HYPR"

# gtk-4.0/theme-base.css: symlink al tema real (Colorful-Dark-GTK), NO
# versionado a propósito — es un archivo de ~140 KB de un tema de terceros
# instalado en ~/.local/share/themes/, no algo que este repo deba publicar,
# y un symlink absoluto con el username hardcodeado tampoco sobrevive a un
# clon en otra máquina. Se recrea acá (idempotente) para que el bootstrap
# de un clon nuevo deje gtk-4.0/gtk.css funcionando sin depender de que
# theme-base.css haya sobrevivido el clonado.
THEME_GTK4="$HOME/.local/share/themes/Colorful-Dark-GTK/gtk-4.0/gtk.css"
[ -f "$THEME_GTK4" ] && ln -sf "$THEME_GTK4" "$HOME/.config/gtk-4.0/theme-base.css" 2>/dev/null || true

# Fondo de hyprlock: bootstrap desde el estático 2.png solo si todavía no hay
# un current.png — no pisa la elección real del usuario si ya existe (elegir
# un wallpaper actualiza current.png independientemente del toggle de
# matugen, así que apagar el toggle nunca debe revertirlo).
[ -f "$HOME/.config/hyprlock/wallpapers/current.png" ] || \
    cp "$HOME/.config/hyprlock/wallpapers/2.png" "$HOME/.config/hyprlock/wallpapers/current.png" 2>/dev/null || true

pkill -SIGUSR2 waybar 2>/dev/null || true
killall -SIGUSR1 kitty 2>/dev/null || true
command -v swaync-client >/dev/null 2>&1 && swaync-client -rs >/dev/null 2>&1 || true
