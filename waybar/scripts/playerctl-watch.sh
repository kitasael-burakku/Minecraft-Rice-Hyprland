#!/usr/bin/env bash
# ============================================================================
#  playerctl-watch.sh — single playerctl -F process for waybar
#  Writes every metadata event to an atomic cache; custom/playerctl and
#  custom/playerlabel read it with `tail -F` instead of each launching its
#  own playerctl -a metadata -F (two processes listening to the same thing).
# ----------------------------------------------------------------------------
#  The JSON is assembled here instead of inside playerctl's --format for two
#  reasons:
#
#   1. Escaping. The old template escaped the title but not the artist, so
#      anything like "Simon & Garfunkel" produced invalid Pango markup and
#      Waybar rendered the label empty — verified with Pango.parse_markup.
#      Both fields go through the same escape now.
#   2. Empty fields. A stream with no artist used to render as " - Title"
#      with a dangling separator, and a player shutting down left the last
#      track frozen in the bar because nothing mapped "no status" back to
#      Stopped.
# ============================================================================
set -o pipefail
set -u

CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-playerctl.json"
TMP="${CACHE}.tmp"

command -v playerctl >/dev/null 2>&1 || exit 0

# 0x1F (unit separator): a control byte no track title is going to contain,
# unlike any printable delimiter.
SEP=$'\x1f'

IDLE='{"text":"","tooltip":"","alt":"Stopped","class":"Stopped"}'

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

# A bar label has to stay on one line; a tooltip must not. Only the label
# gets flattened, which is why this isn't folded into json_escape.
one_line() {
    local s="$1"
    s="${s//$'\n'/ }"
    s="${s//$'\r'/ }"
    printf '%s' "$s"
}

pango_escape() {
    local s="$1"
    # The backslashes are load-bearing: since bash 5.2 an unescaped & in the
    # replacement of ${var//pat/repl} expands to the matched text, so "&lt;"
    # silently produced "<lt;" instead of an entity.
    s="${s//&/\&amp;}"
    s="${s//</\&lt;}"
    s="${s//>/\&gt;}"
    printf '%s' "$s"
}

write_cache() {
    printf '%s\n' "$1" > "$TMP" && mv -f "$TMP" "$CACHE"
}

write_cache "$IDLE"

playerctl -a metadata --format \
    "{{status}}${SEP}{{artist}}${SEP}{{title}}${SEP}{{album}}${SEP}{{playerName}}" \
    -F | while IFS="$SEP" read -r status artist title album player; do

        # No status, or a player that stopped: back to the idle line so the
        # bar doesn't keep showing a track that isn't playing anymore.
        if [[ -z "${status:-}" || "$status" == "Stopped" || ( -z "${title:-}" && -z "${artist:-}" ) ]]; then
            write_cache "$IDLE"
            continue
        fi

        if [[ -n "${artist:-}" && -n "${title:-}" ]]; then
            label="$artist - $title"
        else
            label="${title:-$artist}"
        fi

        tooltip="${player:-Player}"
        [[ -n "${title:-}"  ]] && tooltip+=$'\n'"$title"
        [[ -n "${artist:-}" ]] && tooltip+=$'\n'"$artist"
        [[ -n "${album:-}"  ]] && tooltip+=$'\n'"$album"
        tooltip+=$'\n\n'"Left: previous · Middle: play/pause · Right: next"

        write_cache "{\"text\":\"$(json_escape "$(pango_escape "$(one_line "$label")")")\",\"tooltip\":\"$(json_escape "$(pango_escape "$tooltip")")\",\"alt\":\"$(json_escape "$status")\",\"class\":\"$(json_escape "$status")\"}"
    done
