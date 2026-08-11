#!/usr/bin/env bash
# ============================================================================
#  generate-keybinds-doc.sh — regenerates ~/Documents/KEYBINDS.txt from
#  hypr/modules/keybinds.lua (+ the private bind from
#  hypr/modules/private.lua, if it exists), instead of maintaining it by
#  hand and waiting for checkkeybinds.fish to flag the drift after the fact.
# ----------------------------------------------------------------------------
#  Convention this script assumes (was already dominant in keybinds.lua
#  before this was written): a bind's description is the "-- " comment(s)
#  immediately above its hl.bind(...) — several consecutive "--" lines get
#  concatenated into a single description, and a SHORT label is derived
#  from that (see shorten_desc(): first natural clause — up to the first
#  " — "/": "/". " — or a hard cap of 60 chars). KEYBINDS.txt is a quick
#  reference, not documentation; the full prose stays in the source
#  comment, it isn't lost, it's just not dumped in full here (it used to
#  be dumped in full, and long comments broke the TUI viewer in
#  fish/functions/keybinds.fish — fixed-width box, see the commits that
#  followed this same change). If several binds share one comment block
#  (e.g. the 4 directions of "Infinite Desktop — Navigation"), they all
#  inherit the SAME description — a known and accepted limitation (same
#  approach checkkeybinds.fish already states about its own false
#  negatives: better to be conservative and correct most of the time than
#  to invent).
#
#  What it does NOT try to parse (and by design doesn't need to): the body
#  of binds with function() ... end (CTRL+ALT+V, SUPER+SHIFT+S) — only the
#  first argument (the key) is read, never the action, so the callback's
#  shape doesn't matter. The dynamic workspace loop (`for i = 1, 10 do`)
#  IS hardcoded as a special case because its key isn't a literal.
#
#  Rare uncovered case: an indented comment INSIDE the body of a
#  function() ... end (e.g. the two "-- it's in..." for SUPER+SHIFT+S) can
#  end up stuck as pending_desc if the next bind has no comment of its own
#  AND there's no section separator in between — doesn't happen today
#  (there's always a banner or its own comment in between), but if some day
#  a bind with no description shows up right after a function with
#  internal comments, check by hand before trusting it blindly.
#
#  Usage: generate-keybinds-doc.sh [--check]
#    --check   writes nothing; exits 1 if the current KEYBINDS.txt differs
#              from what it would generate (for a future dotbackup/CI hook).
# ============================================================================

set -u
set -o pipefail

KEYBINDS_LUA="$HOME/.config/hypr/modules/keybinds.lua"
PRIVATE_LUA="$HOME/.config/hypr/modules/private.lua"
OUT="$HOME/Documents/KEYBINDS.txt"

AWK_PROGRAM=$(cat <<'AWKEOF'
BEGIN {
    section = (section_init == "") ? "" : section_init
    banner_buf = ""
    pending_desc = ""
    last_was_comment = 0
    in_ws_loop = 0
}

function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

# KEYBINDS.txt is a quick reference (and the TUI viewer in
# fish/functions/keybinds.fish has a fixed-width box) — not the place for
# the full explanatory prose that does make sense next to the code. It
# keeps the first natural clause (up to the first " — ", ": " or ". ",
# whichever comes first) as the short label; if none appears nearby (or
# appears beyond the cap), a hard cut at the last space (never mid-word)
# as a safety net. The full prose keeps living in the source comment —
# this doesn't lose it, it's just not dumped in full here.
# MAXLEN=38 isn't arbitrary: keybinds.fish draws the description in a
# fixed-width box (width=74) with a 25-char key column — that leaves
# exactly desc_width=40 real characters for the description (__kb_pair,
# fish/functions/keybinds.fish). If the label generated here were longer,
# the TUI would truncate it too with its own "…" — two overlapping cuts,
# one of which is useless. 38 leaves 2 chars of margin over those 40 so
# the visible cut is always this one, never the TUI's. If those constants
# in keybinds.fish ever change, this number has to move with them — there
# isn't one single source of truth for the two (bash here, fish there), so
# they got out of sync once already (see this file's history) and it can
# happen again.
function shorten_desc(desc,    cut, best, p, maxlen) {
    maxlen = 38
    best = length(desc)

    p = index(desc, " — ")
    if (p > 0 && p - 1 < best) best = p - 1

    p = index(desc, ": ")
    if (p > 0 && p - 1 < best) best = p - 1

    p = index(desc, ". ")
    if (p > 0 && p - 1 < best) best = p - 1

    cut = trim(substr(desc, 1, best))

    if (length(cut) > maxlen) {
        cut = substr(cut, 1, maxlen)
        p = length(cut)
        while (p > 20 && substr(cut, p, 1) != " ") p--
        if (p > 20) cut = substr(cut, 1, p - 1)
        cut = trim(cut) "…"
    }

    return cut
}

function prettify_key(raw,    n, parts, i, out, tok, lower) {
    if (raw == "mouse:272")  return "Left click"
    if (raw == "mouse:273")  return "Right click"
    if (raw == "mouse_down") return "Scroll down"
    if (raw == "mouse_up")   return "Scroll up"
    if (raw == "XF86AudioRaiseVolume") return "Volume +"
    if (raw == "XF86AudioLowerVolume") return "Volume -"
    if (raw == "XF86AudioMute")        return "Mute"
    if (raw == "XF86AudioNext")        return "Next"
    if (raw == "XF86AudioPause")       return "Play/Pause"
    if (raw == "XF86AudioPlay")        return "Play/Pause"
    if (raw == "XF86AudioPrev")        return "Previous"

    n = split(raw, parts, /[ \t]*\+[ \t]*/)
    out = ""
    for (i = 1; i <= n; i++) {
        tok = trim(parts[i])
        if (tok == "") continue
        lower = tolower(tok)
        if (lower == "return")      tok = "Enter"
        else if (lower == "space")  tok = "Space"
        else if (lower == "escape") tok = "Escape"
        else if (lower == "delete") tok = "Delete"
        else if (lower == "left")   tok = "Left"
        else if (lower == "right")  tok = "Right"
        else if (lower == "up")     tok = "Up"
        else if (lower == "down")   tok = "Down"
        else if (length(tok) == 1)  tok = toupper(tok)
        out = (out == "") ? tok : out " + " tok
    }
    return out
}

function emit(key, desc) {
    if (section == "") section = "(NO SECTION)"
    printf "%s\t%s\t%s\n", section, key, shorten_desc(desc)
}

# pure banner separator (possible close of a name block)
/^-+[ \t]*$/ {
    if (banner_buf != "") {
        section = banner_buf
        banner_buf = ""
        pending_desc = ""
    }
    last_was_comment = 0
    next
}

# name line inside a banner
/^----[ \t]+[A-Za-z]/ {
    name = $0
    gsub(/^----[ \t]*/, "", name)
    gsub(/[ \t]*-+[ \t]*$/, "", name)
    name = trim(name)
    banner_buf = (banner_buf == "") ? name : banner_buf " — " name
    last_was_comment = 0
    next
}

# dynamic workspace loop — special case, not parseable line by line
/^for i = 1, 10 do/ { in_ws_loop = 1; last_was_comment = 0; next }
in_ws_loop && /^end[ \t]*$/ {
    in_ws_loop = 0
    emit("SUPER + 1-0", "Switch to workspace 1-10")
    emit("SUPER + SHIFT + 1-0", "Move window to workspace 1-10")
    pending_desc = ""
    last_was_comment = 0
    next
}
in_ws_loop { next }

# descriptive comment — several consecutive "--" lines accumulate into a
# single description; a "--" line that does NOT follow another comment
# starts a new block (overwrites the previous one, doesn't add to it).
# Tolerates indentation (private.lua lives indented inside a Lua table;
# keybinds.lua doesn't, but the same pattern covers both without needing
# two different regexes).
/^[ \t]*--[ \t]/ {
    text = $0
    sub(/^[ \t]*--[ \t]*/, "", text)
    text = trim(text)
    if (last_was_comment) {
        pending_desc = pending_desc " " text
    } else {
        pending_desc = text
    }
    last_was_comment = 1
    next
}

# actual bind
/hl\.bind\(/ {
    line = $0
    if (match(line, /hl\.bind\([ \t]*(mainMod[ \t]*\.\.[ \t]*)?"([^"]*)"/)) {
        matched = substr(line, RSTART, RLENGTH)
        has_mainmod = (matched ~ /mainMod/)
        qstart = index(matched, "\"")
        qrest = substr(matched, qstart + 1)
        qend = index(qrest, "\"")
        raw = trim(substr(qrest, 1, qend - 1))
        sub(/^\+[ \t]*/, "", raw)

        full = has_mainmod ? ("SUPER + " raw) : raw
        key = prettify_key(full)
        desc = (pending_desc != "") ? pending_desc : "(no description)"
        emit(key, desc)
    }
    # pending_desc is NOT cleared here on purpose: several consecutive
    # binds with no comment of their own, under the same explanatory
    # block (see the Navigation/Pan example above), inherit the same
    # description. It does get cleared when crossing into a new section
    # (banner separator rule, above).
    last_was_comment = 0
    next
}

# any other line (code, blanks, function() ... end bodies): doesn't touch
# pending_desc, just breaks the streak of consecutive comments.
{ last_was_comment = 0 }
AWKEOF
)

# ── Pass 1: public keybinds.lua ────────────────────────────────────────
rows="$(awk "$AWK_PROGRAM" "$KEYBINDS_LUA")"

# ── Pass 2: private binds (optional — private.lua isn't versioned) ──
if [ -f "$PRIVATE_LUA" ]; then
    private_rows="$(awk -v section_init="PRIVATE BINDS" "$AWK_PROGRAM" "$PRIVATE_LUA")"
    [ -n "$private_rows" ] && rows="$rows"$'\n'"$private_rows"
fi

# ── Render: group by section in first-appearance order ─────────
render() {
    printf '%s\n' "$rows" | awk -F'\t' '
        NF < 3 { next }
        !( $1 in seen ) { order[++n] = $1; seen[$1] = 1 }
        { keys[$1] = keys[$1] $2 "\x1f" $3 "\x1e" }
        END {
            print "KEYBINDS"
            print "========"
            print ""
            print "Main modifier: SUPER (Windows / Options key)"
            print ""
            print "Automatically generated by hypr/scripts/generate-keybinds-doc.sh"
            print "from hypr/modules/keybinds.lua — do not edit by hand, it gets"
            print "overwritten on the next regeneration. To document a new bind, add a"
            print "\"-- description\" comment above its hl.bind(...) and run this"
            print "script again."
            print ""
            for (i = 1; i <= n; i++) {
                sec = order[i]
                print ""
                print sec
                u = ""
                for (j = 1; j <= length(sec); j++) u = u "-"
                print u
                print ""
                split(keys[sec], entries, "\x1e")
                for (j = 1; j in entries; j++) {
                    if (entries[j] == "") continue
                    split(entries[j], kv, "\x1f")
                    printf "%-26s %s\n", kv[1], kv[2]
                }
            }
        }
    '
}

if [ "${1:-}" = "--check" ]; then
    if diff -q <(render) "$OUT" >/dev/null 2>&1; then
        exit 0
    else
        echo "KEYBINDS.txt is out of date with keybinds.lua — run generate-keybinds-doc.sh" >&2
        exit 1
    fi
fi

render > "$OUT"
echo "$OUT regenerated ($(printf '%s\n' "$rows" | grep -c $'\t') binds documented)."
