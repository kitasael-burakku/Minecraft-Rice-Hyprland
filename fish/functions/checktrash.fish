function checktrash
    clear

    set -l W 52

    function __ctr_top -a w
        set_color 909090
        printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
        set_color normal
    end
    function __ctr_mid -a w
        set_color 909090
        printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
        set_color normal
    end
    function __ctr_bot -a w
        set_color 909090
        printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
        set_color normal
    end
    function __ctr_row -a w color text
        set -l inner (math "$w - 2")
        set -l len (string length --visible "$text")
        set -l left (math "max(0, floor(($inner - $len) / 2))")
        set -l right (math "max(0, $inner - $len - $left)")
        set_color 909090; printf "  │"; printf "%*s" $left ""
        set_color $color; printf "%s" "$text"
        set_color 909090; printf "%*s│\n" $right ""
        set_color normal
    end
    function __ctr_section -a color icon text
        echo ""
        set_color $color
        printf "  ── %s %s\n" "$icon" "$text"
        set_color 686058
        printf "  ──────────────────────────────────────────────────\n"
        set_color normal
    end
    function __ctr_val -a label value
        set_color 686058; printf "  %-24s" "$label"
        set_color ffffff; echo "$value"
        set_color normal
    end
    function __ctr_none -a text
        set_color 686058; echo "  · $text"; set_color normal
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    __ctr_top $W
    __ctr_row $W ffffff "󰮯  Package & Trash Report"
    __ctr_mid $W
    __ctr_row $W 686058 "Orphans · Cache · Journal · Trash"
    __ctr_bot $W
    echo ""

    # ── Orphan packages ───────────────────────────────────────────────────────
    __ctr_section b89458 "󰮯" "Orphan packages"
    set orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
    else
        __ctr_none "No orphan packages."
    end

    # ── Pacman cache ──────────────────────────────────────────────────────────
    __ctr_section 6a96b0 "󰪺" "Pacman cache"
    __ctr_val "Size:" (sudo du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)

    set downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)
    if test (count $downloads) -gt 0
        echo ""
        set_color b89458; echo "  Temporary downloads:"; set_color normal
        printf "  %s\n" $downloads
        echo ""
        __ctr_val "Temp size:" (sudo du -ch $downloads 2>/dev/null | tail -n 1 | cut -f1)
    else
        __ctr_none "No temporary downloads."
    end

    # ── Yay cache ─────────────────────────────────────────────────────────────
    __ctr_section bd7fd4 "󰏗" "Yay cache"
    if test -d ~/.cache/yay
        __ctr_val "Size:" (du -sh ~/.cache/yay | cut -f1)
    else
        __ctr_none "No yay cache found."
    end

    # ── Journal ───────────────────────────────────────────────────────────────
    __ctr_section 6aab7a "󰍛" "Journal"
    __ctr_val "Disk usage:" (journalctl --disk-usage 2>/dev/null | string replace -r '.*: ' '')

    # ── User trash ────────────────────────────────────────────────────────────
    __ctr_section b89458 "󰩺" "User trash"
    if test -d ~/.local/share/Trash
        __ctr_val "Size:" (du -sh ~/.local/share/Trash 2>/dev/null | cut -f1)
        set trash_count (find ~/.local/share/Trash/files -mindepth 1 2>/dev/null | wc -l | string trim)
        if test "$trash_count" -gt 0
            __ctr_val "Items:" "$trash_count"
        else
            __ctr_none "Trash is empty."
        end
    else
        __ctr_none "Trash folder not found."
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
