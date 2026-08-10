#!/usr/bin/env bash
# ============================================================================
#  link-steam-icons.sh — resuelve los iconos "steam_icon_<appid>" que Steam
#  referencia en los .desktop generados pero nunca materializa en disco.
# ----------------------------------------------------------------------------
#  Steam escribe Icon=steam_icon_<appid> en ~/.local/share/applications/*.desktop
#  pero jamás crea ese archivo en ninguna ruta de tema de iconos — sólo cachea
#  el arte real bajo ~/.local/share/Steam/appcache/librarycache/<appid>/**/logo.png
#  (la subcarpeta con hash cambia cuando Steam refresca esa caché). Sin un
#  archivo steam_icon_<appid> real, Rofi/GTK nunca resuelven el icono sin
#  importar el tema activo (Slot-Gray-Dark-Icons, Adwaita, etc. — ninguno trae
#  iconos por-juego de Steam; eso es curación manual que hacen temas como
#  Papirus/Ant-*, y sólo para juegos populares).
#
#  Symlinks (no copias) en ~/.local/share/icons/hicolor/256x256/apps/: hicolor
#  es el fallback universal de la spec de iconos freedesktop, heredado
#  implícitamente por cualquier tema — así el fix sobrevive a un cambio de
#  tema y no toca ni Slot-Gray-Dark-Icons ni nada gestionado por Steam.
#
#  Idempotente: correr de nuevo sólo agrega symlinks para .desktop nuevos
#  (juegos recién agregados) y no toca los que ya están linkeados.
# ============================================================================
set -euo pipefail

APPS_DIR="$HOME/.local/share/applications"
LIBRARYCACHE="$HOME/.local/share/Steam/appcache/librarycache"
DEST="$HOME/.local/share/icons/hicolor/256x256/apps"

[ -d "$APPS_DIR" ] || exit 0
[ -d "$LIBRARYCACHE" ] || exit 0

mkdir -p "$DEST"

while IFS= read -r -d '' desktop_file; do
    icon_line=$(grep -m1 '^Icon=steam_icon_' "$desktop_file" || true)
    [ -z "$icon_line" ] && continue

    appid="${icon_line#Icon=steam_icon_}"
    link_path="$DEST/steam_icon_${appid}.png"

    [ -L "$link_path" ] && [ -e "$link_path" ] && continue

    logo=$(find "$LIBRARYCACHE/$appid" -iname "logo.png" 2>/dev/null | head -n1)
    [ -z "$logo" ] && continue

    ln -sf "$logo" "$link_path"
done < <(find "$APPS_DIR" -maxdepth 1 -name "*.desktop" -print0)
