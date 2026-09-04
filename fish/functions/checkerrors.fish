# checkerrors — read-only troubleshooting pass over the journal and systemd.
#
# Every section here answers a question that has three possible outcomes, not
# two: healthy, something found, or "the query itself could not run". The old
# version collapsed the last two into the first by writing
#
#     journalctl ... | rg -i "error|fail" || _rui_none "No errors found."
#
# where the `||` only ever saw rg's exit status. If journalctl failed — an
# unreadable journal, a unit that does not exist — rg got an empty stream,
# exited 1, and the report printed a confident "No errors found." for a query
# that never ran. Each section now captures the command and its stderr first
# so the three outcomes stay distinct.

function checkerrors --description "Read-only journal/systemd error report"
    # These reports take no arguments. They used to accept and silently ignore
    # anything, so `checkerrors --help` ran the full report — while the other
    # functions in this set had started returning 2 for a bad argument. Same
    # contract everywhere now. Checked before `clear` so the message survives.
    if test (count $argv) -gt 0
        if contains -- $argv[1] -h --help
            echo "checkerrors — Read-only journal/systemd error report."
            echo "Usage: checkerrors   (takes no arguments)"
            return 0
        end
        _rui_bad "checkerrors: unexpected argument '$argv[1]'"
        _rui_none "usage: checkerrors   (takes no arguments)"
        return 2
    end

    _rui_have rg "pacman -S ripgrep"
    or return $status

    clear

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰅚  System Error Check"
    _rui_mid $W
    _rui_row $W brblack "journalctl · systemd · portals · coredumps"
    _rui_bot $W
    echo ""

    # findings = sections that reported something actionable.
    # broken   = sections whose query could not run at all.
    set -l findings 0
    set -l broken 0

    # ── Failed system services ────────────────────────────────────────────────
    _rui_section yellow "󰋊" "Failed system services"
    __ce_query "No failed system services." systemctl --failed --no-legend --no-pager
    switch $status
        case 1
            set findings (math $findings + 1)
        case 2
            set broken (math $broken + 1)
    end

    # ── Failed user services ──────────────────────────────────────────────────
    _rui_section yellow "󰋊" "Failed user services"
    __ce_query "No failed user services." systemctl --user --failed --no-legend --no-pager
    switch $status
        case 1
            set findings (math $findings + 1)
        case 2
            set broken (math $broken + 1)
    end

    # ── Critical errors ───────────────────────────────────────────────────────
    _rui_section red "󰍛" "Critical errors — current boot"
    __ce_query "No critical errors this boot." journalctl -b -p 3 --no-pager
    switch $status
        case 1
            set findings (math $findings + 1)
        case 2
            set broken (math $broken + 1)
    end

    # ── Important warnings ────────────────────────────────────────────────────
    _rui_section yellow "󰍛" "Important warnings — current boot"
    __ce_filter "error|fail|warn|amdgpu|sddm|pipewire|wireplumber|tpm|boot|random-seed|bluetooth|networkmanager" \
        "No important warnings matched." \
        journalctl -b -p 4 --no-pager
    switch $status
        case 1
            set findings (math $findings + 1)
        case 2
            set broken (math $broken + 1)
    end

    # ── Hyprland / Portal errors ──────────────────────────────────────────────
    _rui_section cyan "󰣇" "Hyprland / Portal errors"
    __ce_filter "error|fail|failed|critical|denied" \
        "No Hyprland/portal errors found." \
        journalctl --user -b -p 3 --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service
    switch $status
        case 1
            set findings (math $findings + 1)
        case 2
            set broken (math $broken + 1)
    end

    # ── Portal startup info ───────────────────────────────────────────────────
    # Informational: matches here are the healthy case, so this section never
    # contributes to the verdict.
    _rui_section cyan "󰣇" "Portal startup info"
    __ce_filter "Started Portal service|pipewire.*connected|screencopy.*successful|XDG_CURRENT_DESKTOP set to Hyprland" \
        "No portal startup info found." \
        journalctl --user -b --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service

    # ── Coredumps ─────────────────────────────────────────────────────────────
    _rui_section red "󰚌" "Recent user coredumps"
    __ce_filter "dumped core|coredump|segfault" \
        "No coredumps found." \
        journalctl --user -b -p 3 --no-pager
    switch $status
        case 1
            set findings (math $findings + 1)
        case 2
            set broken (math $broken + 1)
    end

    # ── Auth errors ───────────────────────────────────────────────────────────
    _rui_section yellow "󰓅" "Recent sudo / auth errors"
    __ce_filter "authentication failure|incorrect password|conversation failed" \
        "No sudo/auth errors found." \
        journalctl -b --no-pager
    switch $status
        case 1
            set findings (math $findings + 1)
        case 2
            set broken (math $broken + 1)
    end

    # ── Verdict ───────────────────────────────────────────────────────────────
    if test $broken -gt 0
        _rui_verdict bad "$broken check(s) could not run — this report is incomplete."
        _rui_pause
        return 20
    end

    if test $findings -gt 0
        _rui_verdict warn "$findings section(s) reported errors — see above."
        _rui_pause
        return 10
    end

    _rui_verdict ok "No errors found."
    _rui_pause
    return 0
end

# Runs a query and prints its output verbatim.
#   0 = ran, nothing to report      (prints $empty_msg)
#   1 = ran, produced output
#   2 = the query itself failed
#
# The distinction between 0 and 2 is the whole point: a query that could not
# run has not proven anything, and must not be rendered as a clean result.
function __ce_query -a empty_msg
    set -l errfile (mktemp -t checkerrors.XXXXXX)
    or return 2

    set -l out ($argv[2..] 2>$errfile)
    set -l rc $status
    set -l err (cat $errfile)
    rm -f $errfile

    # Judged on the exit status alone. Every command routed through here —
    # systemctl, journalctl — exits 0 when there is simply nothing to report,
    # so a non-zero status is always a real failure. Requiring stderr as well
    # let a command that failed silently (exit 3, no output) be rendered as a
    # clean result, which is precisely what this helper exists to prevent.
    # The pacman query verbs, which DO exit 1 for "no results", are handled by
    # _rui_capture's callers instead and never reach this path.
    if test $rc -ne 0
        if test (count $err) -gt 0
            _rui_bad "Query failed: $err[1]"
        else
            _rui_bad "Query failed with exit $rc and no diagnostic."
        end
        return 2
    end

    if test (count $out) -eq 0
        _rui_none $empty_msg
        return 0
    end

    printf "  %s\n" $out
    return 1
end

# Same contract as __ce_query, with an rg filter applied to the output.
# The filter runs on already-captured text rather than inside a pipeline, so
# rg's "matched nothing" can never be mistaken for the command's failure.
function __ce_filter -a pattern empty_msg
    set -l errfile (mktemp -t checkerrors.XXXXXX)
    or return 2

    set -l out ($argv[3..] 2>$errfile)
    set -l rc $status
    set -l err (cat $errfile)
    rm -f $errfile

    # Judged on the exit status alone. Every command routed through here —
    # systemctl, journalctl — exits 0 when there is simply nothing to report,
    # so a non-zero status is always a real failure. Requiring stderr as well
    # let a command that failed silently (exit 3, no output) be rendered as a
    # clean result, which is precisely what this helper exists to prevent.
    # The pacman query verbs, which DO exit 1 for "no results", are handled by
    # _rui_capture's callers instead and never reach this path.
    if test $rc -ne 0
        if test (count $err) -gt 0
            _rui_bad "Query failed: $err[1]"
        else
            _rui_bad "Query failed with exit $rc and no diagnostic."
        end
        return 2
    end

    if test (count $out) -eq 0
        _rui_none $empty_msg
        return 0
    end

    set -l hits (printf '%s\n' $out | rg -i -- $pattern)
    if test (count $hits) -eq 0
        _rui_none $empty_msg
        return 0
    end

    printf "  %s\n" $hits
    return 1
end
