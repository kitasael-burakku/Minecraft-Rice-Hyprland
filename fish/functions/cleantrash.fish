function cleantrash
    clear

    # ── Palette ───────────────────────────────────────────────────────────────
    set -l C_RESET  (set_color normal)
    set -l C_BOLD   (set_color --bold ffffff)
    set -l C_DIM    (set_color 686058)
    set -l C_GREEN  (set_color 6aab7a)
    set -l C_RED    (set_color a85a48)
    set -l C_YELLOW (set_color b89458)
    set -l C_CYAN   (set_color 6a96b0)
    set -l C_BORDER (set_color 909090)

    set -l W 52

    # ── Box helpers ───────────────────────────────────────────────────────────
    function __ct_top -a w
        set_color 909090
        printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
        set_color normal
    end
    function __ct_mid -a w
        set_color 909090
        printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
        set_color normal
    end
    function __ct_bot -a w
        set_color 909090
        printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
        set_color normal
    end
    function __ct_row -a w color text
        set -l inner (math "$w - 2")
        set -l len (string length --visible "$text")
        set -l left (math "max(0, floor(($inner - $len) / 2))")
        set -l right (math "max(0, $inner - $len - $left)")
        set_color 909090; printf "  │"; printf "%*s" $left ""
        set_color $color; printf "%s" "$text"
        set_color 909090; printf "%*s│\n" $right ""
        set_color normal
    end
    function __ct_section -a color icon text
        echo ""
        set_color $color
        printf "  ── %s %s\n" "$icon" "$text"
        set_color normal
    end
    function __ct_ok -a text
        set_color 6aab7a; echo "  ✓ $text"; set_color normal
    end
    function __ct_skip -a text
        set_color 686058; echo "  · $text"; set_color normal
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    __ct_top $W
    __ct_row $W ffffff "󰮯  System Cleanup"
    __ct_mid $W
    __ct_row $W 686058 "Orphans · Package cache · Yay cache · Trash"
    __ct_bot $W
    echo ""

    read -p 'set_color b89458; echo -n "  Continue? [y/N] > "; set_color normal' confirm

    if test "$confirm" != "y" -a "$confirm" != "Y"
        echo ""
        set_color a85a48; echo "  Cancelled."; set_color normal
        return
    end

    # ── Orphan packages ───────────────────────────────────────────────────────
    __ct_section b89458 "󰮯" "Orphan packages"

    set orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
        echo ""
        sudo pacman -Rns -- $orphans
    else
        __ct_skip "No orphan packages."
    end

    # ── Pacman temp downloads ─────────────────────────────────────────────────
    __ct_section 6a96b0 "󰪺" "Pacman temporary downloads"

    set downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)
    if test (count $downloads) -gt 0
        printf "  %s\n" $downloads
        sudo rm -rf -- $downloads
        __ct_ok "Temporary downloads removed."
    else
        __ct_skip "No temporary downloads found."
    end

    # ── Pacman cache ──────────────────────────────────────────────────────────
    __ct_section 6a96b0 "󰪺" "Pacman cache"

    if command -q paccache
        sudo paccache -r
    else
        __ct_skip "paccache not found."
    end

    # ── Yay cache ─────────────────────────────────────────────────────────────
    __ct_section bd7fd4 "󰏗" "Yay cache"

    if command -q yay
        yay -Sc
    else
        __ct_skip "yay not found."
    end

    # ── Trash ─────────────────────────────────────────────────────────────────
    __ct_section b89458 "󰩺" "User trash"

    set trash_files "$HOME/.local/share/Trash/files"
    set trash_info  "$HOME/.local/share/Trash/info"

    if command -q gio
        if gio trash --empty 2>/dev/null
            __ct_ok "Trash emptied."
        else
            test -d "$trash_files" && find "$trash_files" -mindepth 1 -exec rm -rf {} +
            test -d "$trash_info"  && find "$trash_info"  -mindepth 1 -exec rm -rf {} +
            __ct_ok "Trash emptied (fallback)."
        end
    else
        test -d "$trash_files" && find "$trash_files" -mindepth 1 -exec rm -rf {} +
        test -d "$trash_info"  && find "$trash_info"  -mindepth 1 -exec rm -rf {} +
        __ct_ok "Trash emptied (fallback)."
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090
    printf "  ────────────────────────────────────────────────────\n"
    set_color normal
    set_color 6aab7a; echo "  ✓ System cleanup complete."; set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
