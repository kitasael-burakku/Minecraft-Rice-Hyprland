#!/usr/bin/env bash
# ============================================================================
#  link-steam-icons.sh — resolves the "steam_icon_<appid>" icons Steam
#  references in the generated .desktop files but never materializes on disk.
# ----------------------------------------------------------------------------
#  Steam writes Icon=steam_icon_<appid> in
#  ~/.local/share/applications/*.desktop but never creates that file in any
#  icon theme path — it only caches the actual art under
#  ~/.local/share/Steam/appcache/librarycache/<appid>/**/logo.png (the
#  hashed subfolder changes when Steam refreshes that cache). Without an
#  actual steam_icon_<appid> file, Rofi/GTK never resolve the icon
#  regardless of the active theme (ryoku-folders, Adwaita, etc. —
#  none of them ship per-game Steam icons; that's manual curation done by
#  themes like Papirus/Ant-*, and only for popular games).
#
#  Symlinks (not copies) in ~/.local/share/icons/hicolor/256x256/apps/:
#  hicolor is the universal fallback of the freedesktop icon spec,
#  implicitly inherited by any theme — so the fix survives a theme change
#  and doesn't touch ryoku-folders or anything Steam manages.
#
#  Idempotent: running it again only adds symlinks for new .desktop files
#  (recently added games) and doesn't touch the ones already linked.
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
