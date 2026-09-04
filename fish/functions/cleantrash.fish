# cleantrash — orphans, package caches and the user trash, in one pass.
#
# Every step here is destructive, so the rule this file follows is: never run
# a removal against a path that hasn't been proven to be the intended one, and
# never report success for a step whose exit status was not checked. The old
# version printed "✓ System cleanup complete." unconditionally at the end,
# even if pacman had refused to run, and returned 0 even when cancelled.

function cleantrash --description "Remove orphans, package caches and user trash"
    # Takes no arguments; rejecting them rather than ignoring them keeps the
    # contract identical across every function in this directory.
    if test (count $argv) -gt 0
        if contains -- $argv[1] -h --help
            echo "cleantrash — Remove orphans, package caches and user trash."
            echo "Usage: cleantrash   (takes no arguments)"
            return 0
        end
        _rui_bad "cleantrash: unexpected argument '$argv[1]'"
        _rui_none "usage: cleantrash   (takes no arguments)"
        return 2
    end

    clear

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰮯  System Cleanup"
    _rui_mid $W
    _rui_row $W brblack "Orphans · Package cache · Yay cache · Trash"
    _rui_bot $W
    echo ""

    # $HOME is used to build the paths this function deletes from. If it were
    # unset, "$HOME/.local/share/Trash/files" would become an absolute
    # "/.local/..." path — bail out instead of computing a target from nothing.
    if test -z "$HOME"; or not test -d "$HOME"
        _rui_bad "\$HOME is unset or not a directory — refusing to touch anything."
        return 2
    end

    if not _rui_confirm "Continue?"
        echo ""
        set_color red
        echo "  Cancelled."
        set_color normal
        return 1
    end

    # Three separate tallies, because they mean three different things and
    # collapsing them is how a verdict starts lying:
    #   failures  something went wrong
    #   declined  the user said no at a sub-prompt — a choice, not a problem
    #   skipped   a tool is missing, so that area was never actually checked
    set -l failures 0
    set -l declined 0
    set -l skipped 0
    set -l did_work 0

    # ── Orphan packages ───────────────────────────────────────────────────────
    _rui_section_plain yellow "󰮯" "Orphan packages"

    if not command -q pacman
        _rui_skip "pacman not found — orphans not checked."
        set skipped (math $skipped + 1)
    else if not _rui_capture pacman -Qtdq
        _rui_bad "Could not run the orphan query (no temporary file)."
        set failures (math $failures + 1)
    else if test (count $__rui_err) -gt 0
        # -Qtdq exits 1 for "no orphans" and for a database error alike, so
        # stderr is what separates the two; treating an unreadable database as
        # "nothing to do" would quietly hide a broken system.
        _rui_bad "Could not query orphans: $__rui_err[1]"
        set failures (math $failures + 1)
    else if test (count $__rui_out) -eq 0
        _rui_skip "No orphan packages."
    else
        set -l orphans $__rui_out
        printf "  %s\n" $orphans
        echo ""
        # pacman runs its own [Y/n] confirmation and does its own dependency
        # checking; -Rns is the standard orphan removal and is never given a
        # package list this function built by hand.
        sudo pacman -Rns -- $orphans
        set -l rm_rc $status

        if test $rm_rc -eq 0
            _rui_ok (count $orphans)" orphan(s) removed."
            set did_work 1
        else
            # pacman exits 1 both for "the user answered n" and for a real
            # failure. Re-querying settles it: if every orphan is still there,
            # nothing was attempted and the user simply declined — which is a
            # choice, not a problem to report.
            if _rui_capture pacman -Qtdq; and test (count $__rui_err) -eq 0; and test (count $__rui_out) -eq (count $orphans)
                _rui_skip "Orphan removal declined — packages left in place."
                set declined (math $declined + 1)
            else
                _rui_warn "Orphan removal did not complete — nothing was forced."
                set failures (math $failures + 1)
            end
        end
    end

    # ── Pacman temp downloads ─────────────────────────────────────────────────
    _rui_section_plain cyan "󰪺" "Pacman temporary downloads"

    set -l cache_dir /var/cache/pacman/pkg
    set -l downloads (find $cache_dir -maxdepth 1 -name 'download-*' 2>/dev/null)

    if test (count $downloads) -eq 0
        _rui_skip "No temporary downloads found."
    else
        # find already restricted this to one directory level under the cache,
        # but the list is about to be handed to `sudo rm -rf`. Re-checking each
        # entry against the directory it is supposed to live in costs nothing
        # and means a surprising path can never reach the removal.
        set -l safe
        for d in $downloads
            if string match -q -- "$cache_dir/download-*" "$d"
                set -a safe "$d"
            else
                _rui_bad "Refusing unexpected path: $d"
                set failures (math $failures + 1)
            end
        end

        if test (count $safe) -gt 0
            printf "  %s\n" $safe
            sudo rm -rf -- $safe
            if test $status -eq 0
                _rui_ok (count $safe)" temporary download(s) removed."
                set did_work 1
            else
                _rui_warn "Could not remove some temporary downloads."
                set failures (math $failures + 1)
            end
        end
    end

    # ── Pacman cache ──────────────────────────────────────────────────────────
    _rui_section_plain cyan "󰪺" "Pacman cache"

    if not command -q paccache
        _rui_skip "paccache not found (pacman-contrib) — cache left untouched."
        set skipped (math $skipped + 1)
    else
        # Default policy: keep the last 3 versions of each package. Deliberately
        # not -rk1 or -ruk0: the cache is what a downgrade needs when an update
        # goes wrong, and this function runs right after sysupdate.
        sudo paccache -r
        if test $status -eq 0
            _rui_ok "Old cached packages pruned (last 3 kept)."
            set did_work 1
        else
            _rui_warn "paccache did not complete."
            set failures (math $failures + 1)
        end
    end

    # ── Yay cache ─────────────────────────────────────────────────────────────
    _rui_section_plain magenta "󰏗" "Yay cache"

    if not command -q yay
        _rui_skip "yay not found."
        set skipped (math $skipped + 1)
    else
        yay -Sc
        # yay -Sc prompts, and returns 1 both when the user declines and when
        # it fails, with no way to tell them apart from here. Declining is by
        # far the common case and is not a problem, so it is recorded as a
        # skipped step rather than escalated to "problems found".
        if test $status -eq 0
            _rui_ok "Yay cache cleaned."
            set did_work 1
        else
            _rui_skip "Yay cache not cleaned (declined or unavailable)."
            set declined (math $declined + 1)
        end
    end

    # ── Trash ─────────────────────────────────────────────────────────────────
    _rui_section_plain yellow "󰩺" "User trash"

    set -l trash_root "$HOME/.local/share/Trash"

    if not test -d "$trash_root"
        _rui_skip "No trash directory at "(string replace "$HOME" "~" "$trash_root")"."
        set skipped (math $skipped + 1)
    else if __cleantrash_empty_trash "$trash_root"
        _rui_ok "Trash emptied."
        set did_work 1
    else
        _rui_warn "Trash could not be fully emptied."
        set failures (math $failures + 1)
    end

    # ── Verdict ───────────────────────────────────────────────────────────────
    if test $failures -gt 0
        _rui_verdict warn "Cleanup finished with $failures problem(s) — see above."
        _rui_pause
        return 20
    end

    # "Nothing to clean" is only honest when every area was actually looked at.
    # With a tool missing, the areas it covers were never inspected, so the
    # claim would be about work that did not happen.
    if test $skipped -gt 0; and test $did_work -eq 0
        _rui_verdict warn "Nothing was cleaned — $skipped area(s) could not be checked."
        _rui_pause
        return 10
    end

    if test $declined -gt 0
        _rui_verdict ok "Cleanup finished — $declined step(s) skipped by choice."
        _rui_pause
        return 0
    end

    if test $skipped -gt 0
        _rui_verdict warn "Cleanup finished, but $skipped area(s) could not be checked."
        _rui_pause
        return 10
    end

    if test $did_work -eq 0
        _rui_verdict ok "Nothing to clean — system was already tidy."
        _rui_pause
        return 0
    end

    _rui_verdict ok "System cleanup complete."
    _rui_pause
    return 0
end

# Empties the trash, preferring gio (which also updates the desktop's own
# bookkeeping) and falling back to removing the spec directories by hand.
#
# The fallback is the dangerous half, so it re-derives its targets from the
# resolved trash root and refuses anything that does not sit underneath it —
# a symlinked ~/.local/share/Trash/files pointing somewhere else must not turn
# this into a recursive delete of that target.
function __cleantrash_empty_trash -a trash_root
    if command -q gio
        if gio trash --empty 2>/dev/null
            return 0
        end
        _rui_none "gio could not empty the trash — falling back to manual removal."
    end

    set -l root_real (realpath -- "$trash_root" 2>/dev/null)
    if test -z "$root_real"
        _rui_bad "Cannot resolve $trash_root — refusing manual removal."
        return 1
    end
    if not string match -q -- "$HOME/*" "$root_real"
        _rui_bad "Trash resolves outside \$HOME ($root_real) — refusing manual removal."
        return 1
    end

    set -l rc 0
    for sub in files info expunged
        set -l dir "$root_real/$sub"
        test -d "$dir"; or continue

        # -mindepth 1 keeps the spec directories themselves in place (removing
        # them breaks gio until something recreates them), -maxdepth 1 hands rm
        # each trashed entry once, and -exec ... + passes the names as real
        # arguments, so spaces, quotes, newlines and a leading "-" are all safe.
        #
        # The mount-boundary guarantee lives on rm, not on find: -xdev used to
        # be here, but it only stops *find* from descending, and at maxdepth 1
        # find never descends anyway — meanwhile rm -rf would happily recurse
        # through a mount point find had merely listed. --one-file-system is
        # the flag that actually holds the boundary.
        find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf --one-file-system -- {} +
        or set rc 1
    end
    return $rc
end
