function checkerrors
    clear

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W ffffff "󰅚  System Error Check"
    _rui_mid $W
    _rui_row $W 686058 "journalctl · systemd · portals · coredumps"
    _rui_bot $W
    echo ""

    # ── Failed system services ────────────────────────────────────────────────
    _rui_section b89458 "󰋊" "Failed system services"
    systemctl --failed --no-pager

    # ── Failed user services ──────────────────────────────────────────────────
    _rui_section b89458 "󰋊" "Failed user services"
    systemctl --user --failed --no-pager

    # ── Critical errors ───────────────────────────────────────────────────────
    _rui_section a85a48 "󰍛" "Critical errors — current boot"
    journalctl -b -p 3 --no-pager

    # ── Important warnings ────────────────────────────────────────────────────
    _rui_section b89458 "󰍛" "Important warnings — current boot"
    journalctl -b -p 4 --no-pager \
        | rg -i "error|fail|warn|amdgpu|sddm|pipewire|wireplumber|tpm|boot|random-seed|bluetooth|networkmanager" \
        || _rui_none "No important warnings matched."

    # ── Hyprland / Portal errors ──────────────────────────────────────────────
    _rui_section 6a96b0 "󰣇" "Hyprland / Portal errors"
    journalctl --user -b -p 3 --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service \
        2>/dev/null \
        | rg -i "error|fail|failed|critical|denied" \
        || _rui_none "No Hyprland/portal errors found."

    # ── Portal startup info ───────────────────────────────────────────────────
    _rui_section 6a96b0 "󰣇" "Portal startup info"
    journalctl --user -b --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service \
        2>/dev/null \
        | rg -i "Started Portal service|pipewire.*connected|screencopy.*successful|XDG_CURRENT_DESKTOP set to Hyprland" \
        || _rui_none "No portal startup info found."

    # ── Coredumps ─────────────────────────────────────────────────────────────
    _rui_section a85a48 "󰚌" "Recent user coredumps"
    journalctl --user -b -p 3 --no-pager \
        | rg -i "dumped core|coredump|segfault" \
        || _rui_none "No coredumps found."

    # ── Auth errors ───────────────────────────────────────────────────────────
    _rui_section b89458 "󰓅" "Recent sudo / auth errors"
    journalctl -b --no-pager \
        | rg -i "authentication failure|sudo.*COMMAND|incorrect password|conversation failed" \
        || _rui_none "No sudo/auth errors found."

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    set_color 6aab7a; echo "  ✓ Error check complete."; set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
