function checktrash
    clear

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W ffffff "󰮯  Package & Trash Report"
    _rui_mid $W
    _rui_row $W 686058 "Orphans · Cache · Journal · Trash"
    _rui_bot $W
    echo ""

    # ── Orphan packages ───────────────────────────────────────────────────────
    _rui_section b89458 "󰮯" "Orphan packages"
    set orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
    else
        _rui_none "No orphan packages."
    end

    # ── Pacman cache ──────────────────────────────────────────────────────────
    _rui_section 6a96b0 "󰪺" "Pacman cache"
    _rui_val "Size:" (sudo du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1) 24

    set downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)
    if test (count $downloads) -gt 0
        echo ""
        set_color b89458; echo "  Temporary downloads:"; set_color normal
        printf "  %s\n" $downloads
        echo ""
        _rui_val "Temp size:" (sudo du -ch $downloads 2>/dev/null | tail -n 1 | cut -f1) 24
    else
        _rui_none "No temporary downloads."
    end

    # ── Yay cache ─────────────────────────────────────────────────────────────
    _rui_section bd7fd4 "󰏗" "Yay cache"
    if test -d ~/.cache/yay
        _rui_val "Size:" (du -sh ~/.cache/yay | cut -f1) 24
    else
        _rui_none "No yay cache found."
    end

    # ── Journal ───────────────────────────────────────────────────────────────
    _rui_section 6aab7a "󰍛" "Journal"
    _rui_val "Disk usage:" (journalctl --disk-usage 2>/dev/null | string replace -r '.*: ' '') 24

    # ── User trash ────────────────────────────────────────────────────────────
    _rui_section b89458 "󰩺" "User trash"
    if test -d ~/.local/share/Trash
        _rui_val "Size:" (du -sh ~/.local/share/Trash 2>/dev/null | cut -f1) 24
        set trash_count (find ~/.local/share/Trash/files -mindepth 1 2>/dev/null | wc -l | string trim)
        if test "$trash_count" -gt 0
            _rui_val "Items:" "$trash_count" 24
        else
            _rui_none "Trash is empty."
        end
    else
        _rui_none "Trash folder not found."
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
