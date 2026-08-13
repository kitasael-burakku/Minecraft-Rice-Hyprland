#!/usr/bin/env bash
# ============================================================================
#  apply-wallpaper.sh — applies a wallpaper (video or image) and persists it
# ----------------------------------------------------------------------------
#  Single source of truth for the mpvpaper/awww flags — they used to live
#  duplicated between hypr/modules/autostart.lua and
#  rofi/scripts/wallpaper_grid.sh, synced by hand with cross-referencing
#  comments.
#
#  Besides applying the wallpaper to the desktop:
#    - persists the chosen path to ~/.config/hypr/.current-wallpaper, so the
#      next boot restores the same wallpaper instead of always going back
#      to the default.
#    - generates hyprlock/wallpapers/current.png from that same wallpaper,
#      so the lock screen inherits what's showing on the desktop (this is
#      independent of the matugen toggle — it's the wallpaper, not the
#      colors).
#
#  Usage:
#    apply-wallpaper.sh <path> [monitor]  — applies and persists
#    apply-wallpaper.sh                   — restores the last persisted
#                                            wallpaper, or the default if
#                                            there is none / it no longer
#                                            exists
# ============================================================================

set -u
set -o pipefail

STATE_FILE="$HOME/.config/hypr/.current-wallpaper"
DEFAULT_WALLPAPER="$HOME/Videos/Wallpapers/behind-the-market.mp4"
HYPRLOCK_BG="$HOME/.config/hyprlock/wallpapers/current.png"
LOG="${XDG_RUNTIME_DIR:-/tmp}/apply-wallpaper.log"

target="${1:-}"
MONITOR="${2:-${WALLPAPER_MONITOR:-}}"

if [ -z "$target" ]; then
    if [ -f "$STATE_FILE" ]; then
        target="$(cat "$STATE_FILE" 2>/dev/null)"
    fi
    if [ -z "$target" ] || [ ! -f "$target" ]; then
        target="$DEFAULT_WALLPAPER"
    fi
fi

if [ ! -f "$target" ]; then
    echo "$(date) ERROR: wallpaper doesn't exist: $target" >> "$LOG"
    exit 1
fi

ext_lc="$(printf '%s' "${target##*.}" | tr '[:upper:]' '[:lower:]')"

# pkill solo manda la señal, no espera a que el proceso termine de verdad —
# con hwdec/video pesado, mpvpaper puede tardar más que un sleep fijo en
# soltar el layer-shell, y por esa ventana pueden convivir dos instancias
# consumiendo GPU/decoder al mismo tiempo (más una tercera si volvés a
# cambiar de wallpaper rápido). Este helper espera de verdad — hasta 2s en
# pasos de 100ms — y si a esa altura sigue vivo, un SIGKILL en vez de dejarlo
# potencialmente huérfano (mpvpaper no está supervisado por systemd, así que
# nada más lo va a limpiar).
kill_mpvpaper() {
    pkill -x mpvpaper 2>/dev/null || return 0
    local waited=0
    while pgrep -x mpvpaper >/dev/null 2>&1 && [ "$waited" -lt 20 ]; do
        sleep 0.1
        waited=$((waited + 1))
    done
    pgrep -x mpvpaper >/dev/null 2>&1 && pkill -9 -x mpvpaper 2>/dev/null
    return 0
}

apply_video() {
    kill_mpvpaper
    if [ -n "$MONITOR" ]; then
        nohup mpvpaper -o "--loop-file=inf --no-audio --hwdec=auto" "$MONITOR" "$target" \
            >"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 &
    else
        nohup mpvpaper -o "--loop-file=inf --no-audio --hwdec=auto" '*' "$target" \
            >"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 &
    fi
    disown
}

apply_image() {
    kill_mpvpaper
    awww img "$target" --transition-type any --transition-fps 60 >/dev/null 2>&1
}

case "$ext_lc" in
    mp4|mkv|mov|webm) apply_video ;;
    jpg|jpeg|png|webp|gif) apply_image ;;
    *)
        echo "$(date) ERROR: unsupported extension: $target" >> "$LOG"
        exit 1
        ;;
esac

# ── Persist the choice ─────────────────────────────────────────────────────
mkdir -p "$(dirname "$STATE_FILE")"
printf '%s' "$target" > "$STATE_FILE"

# ── Inheritance into hyprlock ───────────────────────────────────────────────
mkdir -p "$(dirname "$HYPRLOCK_BG")"
case "$ext_lc" in
    mp4|mkv|mov|webm)
        if command -v ffmpeg >/dev/null 2>&1; then
            ffmpeg -y -ss 00:00:01 -i "$target" -vframes 1 -update 1 "$HYPRLOCK_BG" >>"$LOG" 2>&1 \
                || echo "$(date) WARN: couldn't extract frame for hyprlock from $target" >> "$LOG"
        else
            echo "$(date) WARN: ffmpeg not installed, hyprlock won't inherit this wallpaper" >> "$LOG"
        fi
        ;;
    jpg|jpeg|png|webp|gif)
        # Normalized with ImageMagick (same binary generate-thumbs.sh
        # already uses) instead of a raw cp, so current.png's content is
        # a real PNG regardless of the source format.
        if command -v convert >/dev/null 2>&1; then
            convert "$target[0]" "$HYPRLOCK_BG" >>"$LOG" 2>&1 || cp -f "$target" "$HYPRLOCK_BG" 2>>"$LOG"
        else
            cp -f "$target" "$HYPRLOCK_BG" 2>>"$LOG"
        fi
        ;;
esac
