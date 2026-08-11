# ~/.config/fish/conf.d/report-ui.fish
# Drawing helpers shared by the terminal "reports":
# healthcheck, checkerrors, checktrash, cleantrash, quickcache, sysupdate.
#
# Previously each script had its own near-identical copy of these functions
# (with __ce_/__ctr_/__ct_/__hc_/__qc_/__su_ prefixes just to avoid clashing
# with each other). Since fish functions are global, a single set is enough.
#
# Colors: ANSI names, never hex. The terminal resolves them, so the reports
# follow kitty's palette — which matugen already regenerates with the
# wallpaper — instead of staying frozen on their own palette. Same thing
# RPS.exe.fish already did. Convention in use:
#   brblack = borders and dim text      brwhite = titles and values
#   green   = ok      yellow = warning  red = error
#   cyan    = info section              magenta = AUR/yay section

function _rui_top -a w
    set_color brblack
    printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
    set_color normal
end

function _rui_mid -a w
    set_color brblack
    printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
    set_color normal
end

function _rui_bot -a w
    set_color brblack
    printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
    set_color normal
end

function _rui_row -a w color text
    set -l inner (math "$w - 2")
    set -l len (string length --visible "$text")
    set -l left (math "max(0, floor(($inner - $len) / 2))")
    set -l right (math "max(0, $inner - $len - $left)")
    set_color brblack; printf "  │"; printf "%*s" $left ""
    set_color $color; printf "%s" "$text"
    set_color brblack; printf "%*s│\n" $right ""
    set_color normal
end

# Section header with a divider below it (checkerrors/checktrash/healthcheck)
function _rui_section -a color icon text
    echo ""
    set_color $color
    printf "  ── %s %s\n" "$icon" "$text"
    set_color brblack
    printf "  ──────────────────────────────────────────────────\n"
    set_color normal
end

# Section header without a divider (cleantrash/quickcache/sysupdate)
function _rui_section_plain -a color icon text
    echo ""
    set_color $color
    if test -n "$icon"
        printf "  ── %s %s\n" "$icon" "$text"
    else
        printf "  ── %s\n" "$text"
    end
    set_color normal
end

# "label: value" row — optional third argument changes the label width (default 16)
function _rui_val -a label value
    set -l width 16
    if set -q argv[3]
        set width $argv[3]
    end
    set_color brblack; printf "  %-*s" $width "$label"
    set_color brwhite; echo "$value"
    set_color normal
end

# [y/N] confirmation. Returns 0 only for "y"/"Y"; anything else
# (including empty Enter and Ctrl+D) is "no".
#
# Previously cleantrash, quickcache and sysupdate each repeated the whole
# read -p, and in three different ways for the same check: two with
# `!= y -a != Y` and one with `not test = y -o = Y`.
#
# The prompt goes through --prompt-str instead of the old `read -p '<fish code>'`:
# that -p evaluated a code string on every call, here it's enough to pass
# the already-colored text.
function _rui_confirm -a text
    set -l label "  $text [y/N] > "
    set -l prompt (set_color yellow)"$label"(set_color normal)

    read --prompt-str="$prompt" -l reply
    or return 1

    string match -qr '^[yY]$' -- (string trim -- "$reply")
end

function _rui_ok -a text
    set_color green; echo "  ✓ $text"; set_color normal
end

function _rui_warn -a text
    set_color yellow; echo "  ⚠ $text"; set_color normal
end

function _rui_bad -a text
    set_color red; echo "  ✘ $text"; set_color normal
end

function _rui_none -a text
    set_color brblack; echo "  · $text"; set_color normal
end

# _rui_skip was a byte-for-byte copy of _rui_none. The name is kept
# because cleantrash/quickcache use it and "skip" reads better there.
function _rui_skip -a text
    _rui_none $text
end
