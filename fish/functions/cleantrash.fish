function cleantrash
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

    if not _rui_confirm "Continue?"
        echo ""
        set_color red; echo "  Cancelled."; set_color normal
        return
    end

    # ── Orphan packages ───────────────────────────────────────────────────────
    _rui_section_plain yellow "󰮯" "Orphan packages"

    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
        echo ""
        sudo pacman -Rns -- $orphans
    else
        _rui_skip "No orphan packages."
    end

    # ── Pacman temp downloads ─────────────────────────────────────────────────
    _rui_section_plain cyan "󰪺" "Pacman temporary downloads"

    set -l downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)
    if test (count $downloads) -gt 0
        printf "  %s\n" $downloads
        sudo rm -rf -- $downloads
        _rui_ok "Temporary downloads removed."
    else
        _rui_skip "No temporary downloads found."
    end

    # ── Pacman cache ──────────────────────────────────────────────────────────
    _rui_section_plain cyan "󰪺" "Pacman cache"

    if command -q paccache
        sudo paccache -r
    else
        _rui_skip "paccache not found."
    end

    # ── Yay cache ─────────────────────────────────────────────────────────────
    _rui_section_plain magenta "󰏗" "Yay cache"

    if command -q yay
        yay -Sc
    else
        _rui_skip "yay not found."
    end

    # ── Trash ─────────────────────────────────────────────────────────────────
    _rui_section_plain yellow "󰩺" "User trash"

    set -l trash_files "$HOME/.local/share/Trash/files"
    set -l trash_info "$HOME/.local/share/Trash/info"

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
    set_color brblack
    printf "  ────────────────────────────────────────────────────\n"
    set_color normal
    set_color green; echo "  ✓ System cleanup complete."; set_color normal
    echo ""
    read -p 'set_color brblack; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
