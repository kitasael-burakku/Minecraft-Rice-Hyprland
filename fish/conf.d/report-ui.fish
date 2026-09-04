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

# ─────────────────────────────────────────────────────────────────────────────
# Exit-status policy
# ─────────────────────────────────────────────────────────────────────────────
# Before this, every report ended with `read ... __discard`, so they all
# returned 0 no matter what they had just printed on screen — a health check
# that found four failed services and one that found none were
# indistinguishable to anything calling them. The reports now share one ladder:
#
#     0    success / healthy
#     1    expected failure, or the user cancelled
#     2    usage error (bad arguments)
#    10    finished, warnings found
#    20    finished, problems found
#   127    a required command is missing
#
# sysupdate extends the same ladder upward with 30 (failed) and 40 (cancelled
# mid-operation); the meanings of 0/1/10/20/127 are identical there.

# Blocking "Press Enter" footer. Was copy-pasted verbatim into six files, each
# passing a snippet of fish code to `read -p` that got re-evaluated on every
# call; --prompt-str takes the already-rendered string instead.
function _rui_pause
    set -l prompt (set_color brblack)"  Press Enter to exit..."(set_color normal)
    read --prompt-str="$prompt" -l __discard
    return 0
end

# Dependency guard with one consistent message and exit status.
#   _rui_have rg "pacman -S ripgrep"; or return $status
# Returns 127 when missing, so callers can propagate it verbatim.
function _rui_have -a cmd hint
    if command -q -- $cmd
        return 0
    end
    if test -n "$hint"
        _rui_bad "Missing '$cmd' — $hint"
    else
        _rui_bad "Missing '$cmd'"
    end
    return 127
end

# Final verdict line, drawn the same way everywhere.
# The level is passed explicitly rather than derived from the exit code: the
# caller knows whether "20" means "problems found" (yellow) or "it failed"
# (red), and guessing that from the number is how a report ends up claiming a
# state it can't back up.
#   _rui_verdict ok|warn|bad "message"
function _rui_verdict -a level text
    echo ""
    set_color brblack
    printf "  ────────────────────────────────────────────────────\n"
    set_color normal
    switch $level
        case ok
            set_color green
            echo "  ✓ $text"
        case warn
            set_color yellow
            echo "  ⚠ $text"
        case bad
            set_color red
            echo "  ✘ $text"
        case '*'
            echo "  $text"
    end
    set_color normal
    echo ""
    return 0
end

# Runs a command, keeping stdout, stderr and exit status apart.
# Results land in __rui_out / __rui_err / __rui_rc; fish cannot return arrays.
#
# Returns 0 if the command ran at all, 1 if the capture could not even be set
# up. That second case matters more than it looks: when mktemp fails the
# substitution yields an EMPTY ARRAY, so a later `cat $errfile` collapses to a
# bare `cat` and blocks forever on stdin. Callers must therefore check this
# return value, not just the captured fields.
#
# Why stderr and not the exit status alone: pacman's query verbs (-Qu, -Qtdq,
# -Qua) exit 1 for BOTH "no results" and "real failure", so for those the only
# discriminator is whether anything was written to stderr. Commands that do
# NOT overload their exit code that way — systemctl, journalctl — should be
# judged on __rui_rc directly.
function _rui_capture
    set -g __rui_out
    set -g __rui_err
    set -g __rui_rc 0

    set -l errfile (mktemp -t rui-capture.XXXXXX)
    or return 1

    set __rui_out ($argv 2>"$errfile")
    set __rui_rc $status
    set __rui_err (cat "$errfile")
    rm -f "$errfile"
    return 0
end

# .pacnew/.pacsave scan, shared by healthcheck and sysupdate.
#
# Both used to run `find /etc ... 2>/dev/null` as the user. That had two
# separate blind spots, and the silent 2>/dev/null hid them both:
#
#   1. As a normal user, find cannot descend into /etc/sudoers.d,
#      /etc/ssl/private, /etc/polkit-1/rules.d and nine more root-only
#      directories — and the report then said "no pacnew files".
#   2. /etc is not the only place pacman writes them. On this machine the
#      package database tracks backup files under /var/named, /var/lib/nfs,
#      /usr/share/sddm/scripts and /usr/lib/avahi as well, none of which were
#      ever looked at, with or without root.
#
# Both are fixed by asking the database where backup files actually live —
# pacman only ever writes a .pacnew for a file in some package's backup array
# — and scanning exactly those directories plus /etc and /boot.
#
# That also keeps the "incomplete" warning meaningful: an unprivileged scan
# always trips over those twelve root-only directories, but almost none of
# them hold a tracked backup file, so they cannot produce a .pacnew and are
# not worth warning about. Only a backup-holding directory that cannot be
# read makes the result genuinely uncertain.
#
# Results land in __rui_pacfiles (the matches) and __rui_pacfiles_blind (the
# directories that could not be read); fish cannot return arrays.
# __rui_pacfiles_partial is always exactly `count $__rui_pacfiles_blind` — it is
# kept for readability, but callers should branch on the array itself so that a
# `string join` over it is provably non-empty.
#
# Known limit: a .pacsave left by a package that has since been removed is no
# longer in any backup array, so an unprivileged scan cannot rule one out
# inside a root-only directory. A warm sudo timestamp — which sysupdate always
# has by this point — takes the privileged path and avoids the question.
function _rui_pacfiles
    set -g __rui_pacfiles
    set -g __rui_pacfiles_partial 0
    set -g __rui_pacfiles_blind

    # Directories pacman tracks a backup file in. Read straight from the local
    # database: `pacman -Qii` gives the same answer but takes seconds.
    #
    # -F'\t': entries are "path<TAB>md5", and awk's default splitting would cut
    # a path containing a space at the space instead of at the tab, yielding a
    # truncated (wrong) directory. No installed package has such a path today,
    # so this changes nothing here — it just stops the parser from being one
    # package away from being wrong.
    set -l tracked (awk -F'\t' '/^%BACKUP%$/ { f = 1; next }
                                 /^%/         { f = 0 }
                                 f && NF      { p = "/" $1; sub(/\/[^\/]*$/, "", p); print p }' \
        /var/lib/pacman/local/*/files 2>/dev/null | sort -u)

    # Checked before the privileged branch, not after it: without the database
    # we do not know where backup files live, so no amount of privilege makes
    # the scan complete. This used to sit below and was unreachable when sudo
    # was available, letting a root scan of /etc alone claim full coverage.
    if test (count $tracked) -eq 0
        set -a __rui_pacfiles_blind "(package database unreadable)"
    end

    # /etc and /boot are scanned whole; anything the database points at
    # outside them is added as its own root.
    set -l roots /etc /boot
    for d in $tracked
        test -d "$d"; or continue
        string match -q '/etc' "$d"; and continue
        string match -q '/etc/*' "$d"; and continue
        string match -q '/boot' "$d"; and continue
        string match -q '/boot/*' "$d"; and continue
        set -a roots "$d"
    end

    set -l cmd find $roots -xdev -type f "(" -name '*.pacnew' -o -name '*.pacsave' ")"
    set -l privileged 0
    if sudo -n true 2>/dev/null
        set cmd sudo -n $cmd
        set privileged 1
    end

    # The privileged branch used to discard find's stderr and return "complete
    # coverage" unconditionally. A warm sudo timestamp that has since expired,
    # or any other find failure, then rendered as "no .pacnew files" — the
    # exact false clean this helper exists to prevent. Both branches now go
    # through the same capture and both report what they could not read.
    if not _rui_capture $cmd
        set -a __rui_pacfiles_blind "(could not create a temporary file)"
        set __rui_pacfiles_partial (count $__rui_pacfiles_blind)
        return 1
    end

    set __rui_pacfiles $__rui_out

    if test $privileged -eq 1
        # Running as root, every complaint from find is a genuine gap.
        if test (count $__rui_err) -gt 0
            set -a __rui_pacfiles_blind "(scan error: $__rui_err[1])"
        end
    else
        # Unprivileged, find always trips over root-only directories. Only the
        # ones that actually hold a tracked backup file could hide a .pacnew,
        # so only those are worth reporting as uncertainty.
        for d in $tracked
            test -d "$d"; or continue
            if not test -r "$d" -a -x "$d"
                set -a __rui_pacfiles_blind "$d"
            end
        end
    end

    set __rui_pacfiles_partial (count $__rui_pacfiles_blind)
    return 0
end
