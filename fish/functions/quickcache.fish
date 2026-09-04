# ── Typing animation ─────────────────────────────────────────────────────────
# Defined at file level, not inside quickcache: in there it still ended up in
# the global scope (fish has no real nested functions) but got redefined on
# every call and survived exit with nothing to clean it up. quickcache has
# three different "return"s, so cleaning it up on each one would be fragile.
# Same approach as __rps_* in RPS.exe.fish and _rui_* in report-ui.fish.
function __quickcache_type
    set -l text "$argv[1]"
    set -l delay 0.012
    if test (count $argv) -ge 2
        set delay "$argv[2]"
    end
    for char in (string split '' -- "$text")
        printf "%s" "$char"
        sleep "$delay"
    end
    echo ""
end

function quickcache --description "Quick safe cache cleanup with animated confirmation"
    # Takes no arguments; rejecting them rather than ignoring them keeps the
    # contract identical across every function in this directory.
    if test (count $argv) -gt 0
        if contains -- $argv[1] -h --help
            echo "quickcache — Quick, safe cleanup of regenerable cache folders."
            echo "Usage: quickcache   (takes no arguments)"
            return 0
        end
        _rui_bad "quickcache: unexpected argument '$argv[1]'"
        _rui_none "usage: quickcache   (takes no arguments)"
        return 2
    end

    clear

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰪺  Quick Cache Cleanup"
    _rui_mid $W
    _rui_row $W brblack "Safe removal of regenerable cache folders"
    _rui_bot $W
    echo ""

    # ── Browser detection ─────────────────────────────────────────────────────
    set -l browser_cmds   zen-browser  firefox  chromium  google-chrome-stable  brave  vivaldi  opera  thorium-browser
    set -l browser_caches \
        "$HOME/.cache/zen" \
        "$HOME/.cache/mozilla" \
        "$HOME/.cache/chromium" \
        "$HOME/.cache/google-chrome" \
        "$HOME/.cache/BraveSoftware" \
        "$HOME/.cache/vivaldi" \
        "$HOME/.cache/opera" \
        "$HOME/.cache/thorium"

    # Deleting the cache of an OPEN browser can leave the profile
    # inconsistent: the process holds open file descriptors against those
    # files and rewrites them on close. So besides checking that the binary
    # exists and the cache is there, it also checks that it isn't running.
    set -l browser_targets
    set -l browser_skipped
    for i in (seq 1 (count $browser_cmds))
        set -l cmd   $browser_cmds[$i]
        set -l cache $browser_caches[$i]
        if command -q $cmd; and test -d "$cache"
            if pgrep -x -- $cmd >/dev/null 2>&1
                set -a browser_skipped "$cmd"
            else
                set -a browser_targets "$cache"
            end
        end
    end

    set -l targets \
        $browser_targets \
        "$HOME/.cache/spotify" \
        "$HOME/.cache/thumbnails" \
        "$HOME/.cache/mesa_shader_cache" \
        "$HOME/.cache/yay" \
        "$HOME/.cache/pip" \
        "$HOME/.cache/electron" \
        "$HOME/.cache/go-build" \
        "$HOME/.cache/cliphist" \
        "$HOME/.codex/.tmp"

    set_color brblack
    __quickcache_type "  Scanning known regenerable cache folders..." 0.01
    set_color normal
    echo ""

    set -l found 0
    for target in $targets
        if test -e "$target"
            set found 1
            set_color brblack; printf "  %-48s" (string replace $HOME "~" $target)
            set_color brwhite; echo (du -sh "$target" 2>/dev/null | cut -f1)
            set_color normal
        end
    end

    if test (count $browser_skipped) -gt 0
        echo ""
        for cmd in $browser_skipped
            _rui_skip "Skipped $cmd's cache — it's running, close it first"
        end
    end

    if test $found -eq 0
        set_color green
        __quickcache_type "  ✓ No known cache folders found." 0.015
        set_color normal
        echo ""
        _rui_pause
        return 0
    end

    echo ""
    set_color red
    __quickcache_type "  This will delete the folders listed above." 0.018
    set_color normal
    set_color brblack
    __quickcache_type "  These are expected to regenerate automatically." 0.012
    set_color normal

    echo ""
    if not _rui_confirm "Delete listed cache folders?"
        echo ""
        set_color brblack
        __quickcache_type "  Cancelled." 0.015
        set_color normal
        echo ""
        _rui_pause
        return 1
    end

    _rui_section_plain cyan "󰆴" "Removing cache folders"
    echo ""

    # Anything the safety guard refuses, or any rm that fails, has to reach
    # the verdict at the bottom — otherwise the run ends on a green tick that
    # describes a cleanup which did not happen.
    set -l failures 0

    for target in $targets
        if test -e "$target"
            set -l target_real (realpath "$target" 2>/dev/null)
            if test -z "$target_real"
                set_color red; echo "  ✘ Skipping unresolvable path: $target"; set_color normal
                set failures (math $failures + 1)
                continue
            end
            if string match -q -- "$HOME/.cache/*" "$target_real"; or test "$target_real" = "$HOME/.codex/.tmp"
                set_color brblack; printf "  Removing %-40s" (string replace $HOME "~" $target_real); set_color normal
                if rm -rf -- "$target_real"
                    set_color green; echo "done"; set_color normal
                else
                    set_color red; echo "failed"; set_color normal
                    set failures (math $failures + 1)
                end
            else
                set_color red; echo "  ✘ Refusing unsafe path: $target_real"; set_color normal
                set failures (math $failures + 1)
            end
        end
    end

    # ── Cliphist ──────────────────────────────────────────────────────────────
    if command -q cliphist
        _rui_section_plain magenta "󰅇" "Cliphist"
        set_color brblack
        __quickcache_type "  Clears clipboard history stored by cliphist." 0.012
        set_color normal
        echo ""
        if _rui_confirm "Run cliphist wipe?"
            if cliphist wipe
                _rui_ok "cliphist wiped."
            else
                _rui_warn "cliphist wipe failed."
                set failures (math $failures + 1)
            end
        else
            set_color brblack; echo "  · Skipped."; set_color normal
        end
    end

    # ── npm ───────────────────────────────────────────────────────────────────
    if command -q npm
        _rui_section_plain green "" "npm cache"
        set_color brblack
        __quickcache_type "  Clears npm download cache." 0.012
        set_color normal
        echo ""
        if _rui_confirm "Clean npm cache?"
            if npm cache clean --force
                _rui_ok "npm cache cleaned."
            else
                _rui_warn "npm cache clean failed."
                set failures (math $failures + 1)
            end
        else
            set_color brblack; echo "  · Skipped."; set_color normal
        end
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    if test $failures -gt 0
        _rui_verdict warn "Cache cleanup finished with $failures problem(s) — see above."
        _rui_pause
        return 20
    end

    _rui_verdict ok "Quick cache cleanup complete."
    _rui_pause
    return 0
end
