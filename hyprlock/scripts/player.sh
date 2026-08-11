#!/usr/bin/env bash
# ============================================================================
#  player.sh — metadata + progress bar for the active player, for
#  hyprlock/layouts/layout.conf
# ----------------------------------------------------------------------------
#  Replaces music-progress.sh + playerlayout4.sh (merged): the two picked
#  the player with different policies (one preferred a hardcoded "spotify"
#  and otherwise the first alphabetically from `playerctl -l`; the other
#  took playerctl's default), so with more than one player open the title
#  could show one while the bar followed another. There's a single, cached
#  player decision here that feeds all three rows.
#
#  BUG this replaces (confirmed live against an actual video in progress,
#  8:23 of 12:48): `playerctl position` returns SECONDS but
#  `mpris:length` returns MICROSECONDS — music-progress.sh mixed the two,
#  so the bar was always at 0% and the time at 0:00 regardless of the
#  player. Here both fields are requested inside a single --format, where
#  `{{ position }}` does return microseconds — same unit as mpris:length,
#  no manual conversion or "synthetic progress" cache.
#
#  Usage: player.sh --source | --title | --bar
# ============================================================================
set -o pipefail

CACHE="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-player.cache"
BAR_LENGTH=16
SEP=$'\x1f' # field separator: a literal "|" can show up in a title

command -v playerctl >/dev/null 2>&1 || { echo ""; exit 0; }

# Pango/HTML bar colors — default values (static "Kitasan Glass" palette),
# overwritten by music-colors.sh if matugen has already generated one
# (dynamic, follows the wallpaper). See
# matugen/templates/music-progress-colors.sh. The rest of the card's text
# (source, title, times) gets its color from the `color =` of the `label`
# itself in layout.conf, not from here.
COLOR_PLAYED="#7ab8b8"
COLOR_REMAINING="#e8e8e840"
MUSIC_COLORS="$HOME/.config/hyprlock/scripts/music-colors.sh"
# shellcheck disable=SC1090
[ -f "$MUSIC_COLORS" ] && source "$MUSIC_COLORS"

# Escapes Pango markup: source/title/artist get interpolated raw into a
# <span> in layout.conf, and a title with "&" or "<" (common in browser
# tabs, e.g. "Tom & Jerry") breaks rendering without this.
escape_pango() {
    local s="$1"
    # "\&" on purpose: in "${var//pat/repl}" bash treats a bare "&" in
    # repl as "whatever matched" (same as sed) — without escaping it,
    # "&lt;" gets rewritten wrong as "<lt;" when the pattern is "<".
    s="${s//&/\&amp;}"
    s="${s//</\&lt;}"
    s="${s//>/\&gt;}"
    printf '%s' "$s"
}

# The 3 card rows share a ~1s cache: layout.conf fires --source/--title/--bar
# every 1000ms each, so without this every tick would make 3 separate calls
# to playerctl. With the cache, only the first call of the tick actually
# queries; the other two read the already-written result (same pattern as
# META_CACHE in the old playerlayout4.sh).
load_state() {
    local mtime age
    if [ -f "$CACHE" ]; then
        mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)
        age=$(( $(date +%s) - mtime ))
    else
        age=999
    fi

    if [ "$age" -ge 1 ]; then
        # A single call brings back ALL players at once — avoids each card
        # row picking its own separately (the root bug of the previous
        # version).
        local raw chosen
        raw="$(playerctl -a metadata --format \
            "{{playerName}}${SEP}{{status}}${SEP}{{position}}${SEP}{{mpris:length}}${SEP}{{xesam:title}}${SEP}{{xesam:artist}}" \
            2>/dev/null)"

        # Priority: the first one that's Playing; if none, the first
        # Paused; if none, empty. (Before: hardcoded "spotify" or the
        # first alphabetically — neither reflects what's actually
        # playing.)
        chosen="$(printf '%s\n' "$raw" | awk -F"$SEP" '$2=="Playing"{print; exit}')"
        if [ -z "$chosen" ]; then
            chosen="$(printf '%s\n' "$raw" | awk -F"$SEP" '$2=="Paused"{print; exit}')"
        fi

        {
            if [ -n "$chosen" ]; then
                local p_name p_status p_pos p_len p_title p_artist
                IFS="$SEP" read -r p_name p_status p_pos p_len p_title p_artist <<< "$chosen"
                printf 'P_NAME=%q\n' "$p_name"
                printf 'P_STATUS=%q\n' "$p_status"
                printf 'P_POS=%q\n' "$p_pos"
                printf 'P_LEN=%q\n' "$p_len"
                printf 'P_TITLE=%q\n' "$p_title"
                printf 'P_ARTIST=%q\n' "$p_artist"
            else
                printf 'P_NAME=\n'
            fi
        } > "$CACHE"
    fi

    # shellcheck disable=SC1090
    source "$CACHE" 2>/dev/null
}

# Icon + readable name per source. The 4 branded cases are kept; any other
# player uses the name playerctl reports instead of blanking the row
# (before: empty string for anything that wasn't Firefox/Spotify/Chromium/
# YoutubeMusic).
source_label() {
    case "$P_NAME" in
        *firefox*|*zen*)         echo "Firefox" ;;
        *[Ss]potify*)            echo "Spotify" ;;
        *chromium*|*chrome*)     echo "Chrome" ;;
        *)                       echo "$(escape_pango "${P_NAME^}") " ;;
    esac
}

format_time() {
    local total=$1
    printf '%d:%02d' $(( total / 60 )) $(( total % 60 ))
}

# Builds the bar in eighths of a character (BAR_LENGTH * 8 steps instead of
# BAR_LENGTH) so it advances smoothly instead of jumping block by block.
# Returns "filled_part<SEP>empty_part" — each one gets colored separately.
render_bar() {
    local pos=$1 len=$2 status=$3
    local steps_total=$(( BAR_LENGTH * 8 ))
    local steps=$(( pos * steps_total / len ))
    (( steps < 0 )) && steps=0
    (( steps > steps_total )) && steps=$steps_total
    # Same as before: if it just started and is playing, show at least a
    # fraction instead of a bar that looks frozen/empty.
    if [ "$status" = "Playing" ] && [ "$steps" -eq 0 ]; then
        steps=1
    fi

    local partials=("▏" "▎" "▍" "▌" "▋" "▊" "▉")
    local full=$(( steps / 8 ))
    local rem=$(( steps % 8 ))
    local played="" empty="" i

    for (( i = 0; i < full; i++ )); do played+="█"; done
    if [ "$rem" -gt 0 ] && [ "$full" -lt "$BAR_LENGTH" ]; then
        played+="${partials[$((rem - 1))]}"
        full=$(( full + 1 ))
    fi
    for (( i = full; i < BAR_LENGTH; i++ )); do empty+="░"; done

    printf '%s%s%s' "$played" "$SEP" "$empty"
}

case "${1:-}" in
    --source)
        load_state
        [ -z "$P_NAME" ] && { echo ""; exit 0; }
        icon="󰐊"
        [ "$P_STATUS" = "Paused" ] && icon="󰏤"
        echo "$icon  $(source_label)"
        ;;
    --title)
        load_state
        [ -z "$P_NAME" ] && { echo ""; exit 0; }
        if [ -n "$P_TITLE" ] && [ -n "$P_ARTIST" ]; then
            escape_pango "${P_TITLE:0:42} — ${P_ARTIST:0:30}"
        elif [ -n "$P_TITLE" ]; then
            escape_pango "${P_TITLE:0:50}"
        elif [ -n "$P_ARTIST" ]; then
            escape_pango "${P_ARTIST:0:50}"
        else
            echo ""
        fi
        ;;
    --bar)
        load_state
        [ -z "$P_NAME" ] && { echo ""; exit 0; }
        if ! [[ "${P_LEN:-}" =~ ^[0-9]+$ ]] || [ "$P_LEN" -le 0 ] || ! [[ "${P_POS:-}" =~ ^[0-9]+$ ]]; then
            # No valid duration/position (live stream, incomplete metadata)
            # — the title already covered this row, here we avoid printing
            # a meaningless "0:00 / 0:00".
            echo ""
            exit 0
        fi
        played_empty="$(render_bar "$P_POS" "$P_LEN" "$P_STATUS")"
        IFS="$SEP" read -r played empty <<< "$played_empty"
        pos_sec=$(( P_POS / 1000000 ))
        len_sec=$(( P_LEN / 1000000 ))
        printf '<span foreground="%s">%s</span><span foreground="%s">%s</span>  %s / %s\n' \
            "$COLOR_PLAYED" "$played" "$COLOR_REMAINING" "$empty" \
            "$(format_time "$pos_sec")" "$(format_time "$len_sec")"
        ;;
    *)
        echo "Usage: $0 --source | --title | --bar" >&2
        exit 1
        ;;
esac
