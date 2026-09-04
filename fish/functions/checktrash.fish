# checktrash — read-only inventory of what could be reclaimed.
#
# Nothing here removes anything; cleantrash is the counterpart that does.
# The point of keeping them apart is that this one can be run without
# thinking about it, so it must not need root and must not claim a clean
# result it did not actually verify.

function checktrash --description "Read-only report of orphans, caches, journal and trash"
    # These reports take no arguments. They used to accept and silently ignore
    # anything, so `checktrash --help` ran the full report — while the other
    # functions in this set had started returning 2 for a bad argument. Same
    # contract everywhere now. Checked before `clear` so the message survives.
    if test (count $argv) -gt 0
        if contains -- $argv[1] -h --help
            echo "checktrash — Read-only report of orphans, caches, journal and trash."
            echo "Usage: checktrash   (takes no arguments)"
            return 0
        end
        _rui_bad "checktrash: unexpected argument '$argv[1]'"
        _rui_none "usage: checktrash   (takes no arguments)"
        return 2
    end

    clear

    set -l W 52

    # Counts what is actually reclaimable, so the exit status reflects the
    # report instead of always being 0.
    set -l findings 0
    set -l unknown 0

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰮯  Package & Trash Report"
    _rui_mid $W
    _rui_row $W brblack "Orphans · Cache · Journal · Trash"
    _rui_bot $W
    echo ""

    # ── Orphan packages ───────────────────────────────────────────────────────
    _rui_section yellow "󰮯" "Orphan packages"
    if not command -q pacman
        _rui_none "pacman not found."
        set unknown (math $unknown + 1)
    else
        # -Qtdq exits 1 both for "no orphans" and for a database error, so
        # stderr is what tells them apart.
        if not _rui_capture pacman -Qtdq
            _rui_warn "Could not run the orphan query (no temporary file)."
            set unknown (math $unknown + 1)
        else if test (count $__rui_err) -gt 0
            _rui_warn "Could not query orphans: $__rui_err[1]"
            set unknown (math $unknown + 1)
        else if test (count $__rui_out) -gt 0
            printf "  %s\n" $__rui_out
            set findings (math $findings + 1)
        else
            _rui_none "No orphan packages."
        end
    end

    # ── Pacman cache ──────────────────────────────────────────────────────────
    _rui_section cyan "󰪺" "Pacman cache"
    # /var/cache/pacman/pkg is mode 755, so `du` reads it fine as a normal
    # user. The sudo that used to be here made a read-only report stop and ask
    # for a password — and, worse, silently produced an empty size when the
    # prompt was declined, because the failure went to 2>/dev/null.
    set -l cache_size (du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
    test -n "$cache_size"; or set cache_size "unreadable"
    _rui_val "Size:" "$cache_size" 24

    set -l downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)
    if test (count $downloads) -gt 0
        echo ""
        set_color yellow; echo "  Temporary downloads:"; set_color normal
        printf "  %s\n" $downloads
        echo ""
        _rui_val "Temp size:" (du -ch $downloads 2>/dev/null | tail -n 1 | cut -f1) 24
        set findings (math $findings + 1)
    else
        _rui_none "No temporary downloads."
    end

    # ── Yay cache ─────────────────────────────────────────────────────────────
    _rui_section magenta "󰏗" "Yay cache"
    if test -d ~/.cache/yay
        _rui_val "Size:" (du -sh ~/.cache/yay 2>/dev/null | cut -f1) 24
    else
        _rui_none "No yay cache found."
    end

    # ── Journal ───────────────────────────────────────────────────────────────
    _rui_section green "󰍛" "Journal"
    _rui_val "Disk usage:" (journalctl --disk-usage 2>/dev/null | string replace -r '.*: ' '') 24

    # ── User trash ────────────────────────────────────────────────────────────
    _rui_section yellow "󰩺" "User trash"
    if test -d ~/.local/share/Trash
        _rui_val "Size:" (du -sh ~/.local/share/Trash 2>/dev/null | cut -f1) 24
        # -maxdepth 1 so this counts trashed ITEMS, not every file inside every
        # trashed directory: a single deleted project used to report hundreds.
        set -l trash_count (count (find ~/.local/share/Trash/files -mindepth 1 -maxdepth 1 2>/dev/null))
        if test "$trash_count" -gt 0
            _rui_val "Items:" "$trash_count" 24
            set findings (math $findings + 1)
        else
            _rui_none "Trash is empty."
        end
    else
        _rui_none "Trash folder not found."
    end

    # ── Verdict ───────────────────────────────────────────────────────────────
    if test $unknown -gt 0
        _rui_verdict warn "$findings item(s) reclaimable; $unknown check(s) could not answer."
        _rui_pause
        return 10
    end

    if test $findings -gt 0
        _rui_verdict warn "$findings category(ies) can be reclaimed — run cleantrash."
        _rui_pause
        return 10
    end

    _rui_verdict ok "Nothing to reclaim."
    _rui_pause
    return 0
end
