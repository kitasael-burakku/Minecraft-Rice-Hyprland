function checkerrors
    clear

    set_color red
    echo "󰅚 System Error Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color normal

    set_color yellow
    echo "󰋊 Failed system services:"
    set_color normal
    systemctl --failed --no-pager

    echo ""

    set_color yellow
    echo "󰋊 Failed user services:"
    set_color normal
    systemctl --user --failed --no-pager

    echo ""

    set_color yellow
    echo "󰍛 Critical/errors from current boot:"
    set_color normal
    journalctl -b -p 3 --no-pager

    echo ""

    set_color yellow
    echo "󰍛 Important warnings from current boot:"
    set_color normal
    journalctl -b -p 4 --no-pager \
        | rg -i "error|fail|warn|amdgpu|sddm|pipewire|wireplumber|tpm|boot|random-seed|bluetooth|networkmanager" \
        || echo "No important warnings matched."

    echo ""

    set_color yellow
    echo "󰣇 Hyprland/Portal errors:"
    set_color normal

    journalctl --user -b -p 3 --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service \
        2>/dev/null \
        | rg -i "error|fail|failed|critical|denied" \
        || echo "No Hyprland/portal errors found."

    echo ""

    set_color yellow
    echo "󰣇 Hyprland/Portal startup info:"
    set_color normal

    journalctl --user -b --no-pager \
        -u xdg-desktop-portal.service \
        -u xdg-desktop-portal-hyprland.service \
        -u xdg-desktop-portal-gtk.service \
        2>/dev/null \
        | rg -i "Started Portal service|pipewire.*connected|screencopy.*successful|XDG_CURRENT_DESKTOP set to Hyprland" \
        || echo "No portal startup info found."

    echo ""

    set_color yellow
    echo "󰚌 Recent user coredumps:"
    set_color normal

    journalctl --user -b -p 3 --no-pager \
        | rg -i "dumped core|coredump|segfault" \
        || echo "No user coredumps found."

    echo ""

    set_color yellow
    echo "󰓅 Recent sudo/auth errors:"
    set_color normal

    journalctl -b --no-pager \
        | rg -i "authentication failure|sudo.*COMMAND|incorrect password|conversation failed" \
        || echo "No sudo/auth errors found."

    echo ""

    set_color green
    echo "✅ Error check complete."
    set_color normal

    echo ""

    set_color brblack
    read -P "Press Enter to exit..."
    set_color normal
end