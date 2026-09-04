#!/usr/bin/env bash
# ============================================================================
#  dotbackup-remind.sh — avisa (sin tocar nada) si ~/.config divergió de
#  ~/Projects/dotfiles, para recordar correr `dotbackup` a mano.
# ----------------------------------------------------------------------------
#  Sólo lectura: nunca sincroniza, commitea ni pushea — eso sigue siendo
#  ~/.local/bin/dotbackup, que además pide confirmación y escanea secretos
#  antes de comitear. Este script sólo detecta drift y notifica.
#
#  DIRS/FILES son las mismas listas que config_dirs/config_files en
#  ~/.local/bin/dotbackup — no derivadas automáticamente (dotbackup es fish;
#  parsearlo a mano es más frágil que mantener dos listas cortas
#  sincronizadas). Mismo criterio que ya usa fish/conf.d/tools.fish para los
#  alias de `ec` frente a __ec_targets.
#
#  El precio de esa decisión es que hay que sincronizarlas a mano, y ya se
#  desincronizaron una vez (nueve archivos, ver la nota junto a FILES). Para
#  comprobarlo sin leer los dos archivos enteros:
#
#    diff <(awk "/set -l config_files/,/set -l documents_files/" ~/.local/bin/dotbackup \
#             | grep -oE "\"[^\"]+\"" | tr -d "\"" | sort -u) \
#         <(awk "/^FILES=\\(/,/^\\)/" ~/.config/hypr/scripts/dotbackup-remind.sh \
#             | tr " " "\n" | grep -E "^[a-z]" | sort -u)
# ============================================================================

set -u
set -o pipefail

CONFIG="$HOME/.config"
REPO="$HOME/Projects/dotfiles"

DIRS=(cava fastfetch fish hypr hyprlock kitty matugen rofi swaync waybar wlogout)

FILES=(
    starship.toml starship.static.toml
    systemd/user/hyprland-session.service
    systemd/user/waybar.service systemd/user/playerctl-watch.service
    systemd/user/swaync.service systemd/user/hypridle.service
    systemd/user/awww.service systemd/user/wallpaper.service
    systemd/user/cliphist-text.service systemd/user/cliphist-image.service
    systemd/user/udiskie.service systemd/user/infinite-desktop.service
    systemd/user/polkit-agent.service
    systemd/user/updates-check.service systemd/user/updates-check.timer
    systemd/user/thumbs-refresh.service systemd/user/thumbs-refresh.timer
    systemd/user/healthcheck-notify.service systemd/user/healthcheck-notify.timer
    systemd/user/dotbackup-remind.service systemd/user/dotbackup-remind.timer
    systemd/user/kb-layout-notify.service
    gtk-3.0/gtk.css gtk-3.0/gtk-colors.static.css
    gtk-4.0/gtk.css gtk-4.0/gtk-colors.static.css
    qt5ct/qt5ct.conf qt5ct/colors/kitasan-glass.static.conf
    qt6ct/qt6ct.conf qt6ct/colors/kitasan-glass.static.conf
)
# Las nueve entradas de arriba (kb-layout-notify + los ocho archivos gtk/qt) se
# agregaron el 2026-09-04: estaban en config_files de dotbackup pero se habían
# quedado fuera de ESTA lista, así que un cambio en el tema GTK o en la config
# de Qt nunca disparaba el recordatorio — el timer comparaba, no veía nada y
# decía que todo estaba al día.

[ -d "$REPO/.git" ] || exit 0

# waybar/config.jsonc es el único archivo que dotbackup edita al copiar (le
# borra la línea de rewrite "^.*maly.*$": — ver redact_pattern en
# dotbackup). Un diff crudo contra eso daría drift falso SIEMPRE, incluso
# recién después de correr dotbackup. Se compara ignorando esa línea en
# ambos lados, igual que hace el propio dotbackup al redactar.
waybar_config_diverged() {
    local a="$CONFIG/waybar/config.jsonc" b="$REPO/waybar/config.jsonc"
    local pattern='"\^\.\*[Mm][Aa][Ll][Yy]\.\*\$":'
    [ -f "$a" ] && [ -f "$b" ] || return 0
    ! diff -q <(grep -Ev "$pattern" "$a") <(grep -Ev "$pattern" "$b") >/dev/null 2>&1
}

diverged=0

for d in "${DIRS[@]}"; do
    [ -d "$CONFIG/$d" ] || continue
    if [ "$d" = "waybar" ]; then
        if ! diff -rq --exclude=config.jsonc "$CONFIG/waybar" "$REPO/waybar" >/dev/null 2>&1 \
           || waybar_config_diverged; then
            diverged=1
            break
        fi
    else
        if ! diff -rq "$CONFIG/$d" "$REPO/$d" >/dev/null 2>&1; then
            diverged=1
            break
        fi
    fi
done

if [ "$diverged" -eq 0 ]; then
    for f in "${FILES[@]}"; do
        [ -f "$CONFIG/$f" ] || continue
        if ! diff -q "$CONFIG/$f" "$REPO/$f" >/dev/null 2>&1; then
            diverged=1
            break
        fi
    done
fi

if [ "$diverged" -eq 1 ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send -u low -i document-save \
        "dotbackup" "~/.config divergió de ~/Projects/dotfiles — corré 'dotbackup' cuando quieras."
fi
