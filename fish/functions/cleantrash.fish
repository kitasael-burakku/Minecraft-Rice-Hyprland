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

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W ffffff "󰮯  System Cleanup"
    _rui_mid $W
    _rui_row $W 686058 "Orphans · Package cache · Yay cache · Trash"
    _rui_bot $W
    echo ""

    read -p 'set_color b89458; echo -n "  Continue? [y/N] > "; set_color normal' confirm

    if test "$confirm" != "y" -a "$confirm" != "Y"
        echo ""
        set_color a85a48; echo "  Cancelled."; set_color normal
        return
    end

    # ── Orphan packages ───────────────────────────────────────────────────────
    _rui_section_plain b89458 "󰮯" "Orphan packages"

    set orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
        echo ""
        sudo pacman -Rns -- $orphans
    else
        _rui_skip "No orphan packages."
    end

    # ── Pacman temp downloads ─────────────────────────────────────────────────
    _rui_section_plain 6a96b0 "󰪺" "Pacman temporary downloads"

    set downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)
    if test (count $downloads) -gt 0
        printf "  %s\n" $downloads
        sudo rm -rf -- $downloads
        _rui_ok "Temporary downloads removed."
    else
        _rui_skip "No temporary downloads found."
    end

    # ── Pacman cache ──────────────────────────────────────────────────────────
    _rui_section_plain 6a96b0 "󰪺" "Pacman cache"

    if command -q paccache
        sudo paccache -r
    else
        _rui_skip "paccache not found."
    end

    # ── Yay cache ─────────────────────────────────────────────────────────────
    _rui_section_plain bd7fd4 "󰏗" "Yay cache"

    if command -q yay
        yay -Sc
    else
        _rui_skip "yay not found."
    end

    # ── Trash ─────────────────────────────────────────────────────────────────
    _rui_section_plain b89458 "󰩺" "User trash"

    set trash_files "$HOME/.local/share/Trash/files"
    set trash_info  "$HOME/.local/share/Trash/info"

    if command -q gio
        if gio trash --empty 2>/dev/null
            _rui_ok "Trash emptied."
        else
            test -d "$trash_files" && find "$trash_files" -mindepth 1 -exec rm -rf {} +
            test -d "$trash_info"  && find "$trash_info"  -mindepth 1 -exec rm -rf {} +
            _rui_ok "Trash emptied (fallback)."
        end
    else
        test -d "$trash_files" && find "$trash_files" -mindepth 1 -exec rm -rf {} +
        test -d "$trash_info"  && find "$trash_info"  -mindepth 1 -exec rm -rf {} +
        _rui_ok "Trash emptied (fallback)."
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
