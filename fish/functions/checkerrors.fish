function checkerrors
    clear

    # ── Palette ───────────────────────────────────────────────────────────────
    set -l W 52

    function __ce_top -a w
        set_color 909090
        printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
        set_color normal
    end
    function __ce_mid -a w
        set_color 909090
        printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
        set_color normal
    end
    function __ce_bot -a w
        set_color 909090
        printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
        set_color normal
    end
    function __ce_row -a w color text
        set -l inner (math "$w - 2")
        set -l len (string length --visible "$text")
        set -l left (math "max(0, floor(($inner - $len) / 2))")
        set -l right (math "max(0, $inner - $len - $left)")
        set_color 909090; printf "  │"; printf "%*s" $left ""
        set_color $color; printf "%s" "$text"
        set_color 909090; printf "%*s│\n" $right ""
        set_color normal
    end
    function __ce_section -a color icon text
        echo ""
        set_color $color
        printf "  ── %s %s\n" "$icon" "$text"
        set_color 686058
        printf "  ──────────────────────────────────────────────────\n"
        set_color normal
    end
    function __ce_none -a text
        set_color 686058; echo "  · $text"; set_color normal
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    __ce_top $W
    __ce_row $W ffffff "󰅚  System Error Check"
    __ce_mid $W
    __ce_row $W 686058 "journalctl · systemd · portals · coredumps"
    __ce_bot $W
    echo ""

    # ── Failed system services ────────────────────────────────────────────────
    __ce_section b89458 "󰋊" "Failed system services"
    systemctl --failed --no-pager

    # ── Failed user services ──────────────────────────────────────────────────
    __ce_section b89458 "󰋊" "Failed user services"
    systemctl --user --failed --no-pager

    # ── Critical errors ───────────────────────────────────────────────────────
    __ce_section a85a48 "󰍛" "Critical errors — current boot"
    journalctl -b -p 3 --no-pager

    # ── Important warnings ────────────────────────────────────────────────────
    __ce_section b89458 "󰍛" "Important warnings — current boot"
    journalctl -b -p 4 --no-pager \
        | rg -i "error|fail|warn|amdgpu|sddm|pipewire|wireplumber|tpm|boot|random-seed|bluetooth|networkmanager" \
        || __ce_none "No important warnings matched."

    # ── Hyprland / Portal errors ──────────────────────────────────────────────
    __ce_section 6a96b0 "󰣇" "Hyprland / Portal errors"
    journalctl --user -b -p 3 --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service \
        2>/dev/null \
        | rg -i "error|fail|failed|critical|denied" \
        || __ce_none "No Hyprland/portal errors found."

    # ── Portal startup info ───────────────────────────────────────────────────
    __ce_section 6a96b0 "󰣇" "Portal startup info"
    journalctl --user -b --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service \
        2>/dev/null \
        | rg -i "Started Portal service|pipewire.*connected|screencopy.*successful|XDG_CURRENT_DESKTOP set to Hyprland" \
        || __ce_none "No portal startup info found."

    # ── Coredumps ─────────────────────────────────────────────────────────────
    __ce_section a85a48 "󰚌" "Recent user coredumps"
    journalctl --user -b -p 3 --no-pager \
        | rg -i "dumped core|coredump|segfault" \
        || __ce_none "No coredumps found."

    # ── Auth errors ───────────────────────────────────────────────────────────
    __ce_section b89458 "󰓅" "Recent sudo / auth errors"
    journalctl -b --no-pager \
        | rg -i "authentication failure|sudo.*COMMAND|incorrect password|conversation failed" \
        || __ce_none "No sudo/auth errors found."

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    set_color 6aab7a; echo "  ✓ Error check complete."; set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
