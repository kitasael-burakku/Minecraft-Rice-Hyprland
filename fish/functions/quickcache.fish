function quickcache --description "Quick safe cache cleanup with animated confirmation"
    clear

    # ── Typing animation ──────────────────────────────────────────────────────
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

    # ── Box helpers ───────────────────────────────────────────────────────────
    set -l W 52

    function __qc_top -a w
        set_color 909090
        printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
        set_color normal
    end
    function __qc_mid -a w
        set_color 909090
        printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
        set_color normal
    end
    function __qc_bot -a w
        set_color 909090
        printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
        set_color normal
    end
    function __qc_row -a w color text
        set -l inner (math "$w - 2")
        set -l len (string length --visible "$text")
        set -l left (math "max(0, floor(($inner - $len) / 2))")
        set -l right (math "max(0, $inner - $len - $left)")
        set_color 909090; printf "  │"; printf "%*s" $left ""
        set_color $color; printf "%s" "$text"
        set_color 909090; printf "%*s│\n" $right ""
        set_color normal
    end
    function __qc_section -a color icon text
        echo ""
        set_color $color
        printf "  ── %s %s\n" "$icon" "$text"
        set_color normal
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    __qc_top $W
    __qc_row $W ffffff "󰪺  Quick Cache Cleanup"
    __qc_mid $W
    __qc_row $W 686058 "Safe removal of regenerable cache folders"
    __qc_bot $W
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

    set -l browser_targets
    for i in (seq 1 (count $browser_cmds))
        set -l cmd   $browser_cmds[$i]
        set -l cache $browser_caches[$i]
        if command -q $cmd; and test -d "$cache"
            set -a browser_targets "$cache"
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

    set_color 686058
    __quickcache_type "  Scanning known regenerable cache folders..." 0.01
    set_color normal
    echo ""

    set -l found 0
    for target in $targets
        if test -e "$target"
            set found 1
            set_color 686058; printf "  %-48s" (string replace $HOME "~" $target)
            set_color ffffff; echo (du -sh "$target" 2>/dev/null | cut -f1)
            set_color normal
        end
    end

    if test "$found" = 0
        set_color 6aab7a
        __quickcache_type "  ✓ No known cache folders found." 0.015
        set_color normal
        echo ""
        read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
        return 0
    end

    echo ""
    set_color a85a48
    __quickcache_type "  This will delete the folders listed above." 0.018
    set_color normal
    set_color 686058
    __quickcache_type "  These are expected to regenerate automatically." 0.012
    set_color normal

    echo ""
    read -p 'set_color b89458; echo -n "  Delete listed cache folders? [y/N] > "; set_color normal' confirm

    if not test "$confirm" = "y" -o "$confirm" = "Y"
        echo ""
        set_color 686058
        __quickcache_type "  Cancelled." 0.015
        set_color normal
        echo ""
        read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
        return 0
    end

    __qc_section 6a96b0 "󰆴" "Removing cache folders"
    echo ""

    for target in $targets
        if test -e "$target"
            set -l target_real (realpath "$target" 2>/dev/null)
            if test -z "$target_real"
                set_color a85a48; echo "  ✘ Skipping unsafe path: $target"; set_color normal
                continue
            end
            if string match -q -- "$HOME/.cache/*" "$target_real"; or test "$target_real" = "$HOME/.codex/.tmp"
                set_color 686058; printf "  Removing %-40s" (string replace $HOME "~" $target_real); set_color normal
                rm -rf -- "$target_real"
                set_color 6aab7a; echo "done"; set_color normal
            else
                set_color a85a48; echo "  ✘ Refusing unsafe path: $target_real"; set_color normal
            end
        end
    end

    # ── Cliphist ──────────────────────────────────────────────────────────────
    if type -q cliphist
        __qc_section bd7fd4 "󰅇" "Cliphist"
        set_color 686058
        __quickcache_type "  Clears clipboard history stored by cliphist." 0.012
        set_color normal
        echo ""
        read -p 'set_color b89458; echo -n "  Run cliphist wipe? [y/N] > "; set_color normal' clean_cliphist
        if test "$clean_cliphist" = "y" -o "$clean_cliphist" = "Y"
            cliphist wipe
            set_color 6aab7a; echo "  ✓ cliphist wiped."; set_color normal
        else
            set_color 686058; echo "  · Skipped."; set_color normal
        end
    end

    # ── npm ───────────────────────────────────────────────────────────────────
    if type -q npm
        __qc_section 6aab7a "" "npm cache"
        set_color 686058
        __quickcache_type "  Clears npm download cache." 0.012
        set_color normal
        echo ""
        read -p 'set_color b89458; echo -n "  Clean npm cache? [y/N] > "; set_color normal' clean_npm
        if test "$clean_npm" = "y" -o "$clean_npm" = "Y"
            npm cache clean --force
            set_color 6aab7a; echo "  ✓ npm cache cleaned."; set_color normal
        else
            set_color 686058; echo "  · Skipped."; set_color normal
        end
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    set_color 6aab7a
    __quickcache_type "  ✓ Quick cache cleanup complete." 0.018
    set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end