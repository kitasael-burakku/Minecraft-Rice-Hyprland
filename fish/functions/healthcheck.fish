function healthcheck
    clear

    set -l W 52

    # ── Box helpers ───────────────────────────────────────────────────────────
    function __hc_top -a w
        set_color 909090
        printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
        set_color normal
    end
    function __hc_mid -a w
        set_color 909090
        printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
        set_color normal
    end
    function __hc_bot -a w
        set_color 909090
        printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
        set_color normal
    end
    function __hc_row -a w color text
        set -l inner (math "$w - 2")
        set -l len (string length --visible "$text")
        set -l left (math "max(0, floor(($inner - $len) / 2))")
        set -l right (math "max(0, $inner - $len - $left)")
        set_color 909090; printf "  │"; printf "%*s" $left ""
        set_color $color; printf "%s" "$text"
        set_color 909090; printf "%*s│\n" $right ""
        set_color normal
    end
    function __hc_section -a color icon text
        echo ""
        set_color $color
        printf "  ── %s %s\n" "$icon" "$text"
        set_color 686058
        printf "  ──────────────────────────────────────────────────\n"
        set_color normal
    end
    function __hc_val -a label value
        set_color 686058; printf "  %-16s" "$label"
        set_color ffffff; echo "$value"
        set_color normal
    end
    function __hc_ok -a text
        set_color 6aab7a; echo "  ✓ $text"; set_color normal
    end
    function __hc_warn -a text
        set_color b89458; echo "  ⚠ $text"; set_color normal
    end
    function __hc_bad -a text
        set_color a85a48; echo "  ✘ $text"; set_color normal
    end
    function __hc_none -a text
        set_color 686058; echo "  · $text"; set_color normal
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    __hc_top $W
    __hc_row $W ffffff "󰒋  System Health Check"
    __hc_mid $W
    __hc_row $W 686058 "System · Memory · Disk · Network · Temps"
    __hc_bot $W
    echo ""

    # ── System ────────────────────────────────────────────────────────────────
    __hc_section 6a96b0 "󰌢" "System"
    __hc_val "Host:"   (uname -n)
    __hc_val "Kernel:" (uname -r)
    __hc_val "Uptime:" (uptime -p)
    __hc_val "Shell:"  (basename $SHELL)

    # ── Memory ────────────────────────────────────────────────────────────────
    __hc_section 6a96b0 "󰍛" "Memory"
    free -h | awk '/Mem:/  { printf "  %-16s%s / %s\n", "RAM:", $3, $2 }
                  /Swap:/ { printf "  %-16s%s / %s\n", "Swap:", $3, $2 }'
    if swapon --show=NAME,SIZE,USED,TYPE 2>/dev/null | rg -q "zram"
        swapon --show=NAME,SIZE,USED,TYPE | rg "zram" | awk '{printf "  %-16s%s  used %s\n", "zram:", $2, $3}'
    else
        __hc_none "zram not detected."
    end

    # ── Updates ───────────────────────────────────────────────────────────────
    __hc_section b89458 "󰚰" "Updates"
    if command -q checkupdates
        set pacman_updates (checkupdates 2>/dev/null | wc -l | string trim)
    else
        set pacman_updates "?"
    end
    if command -q yay
        set aur_updates (yay -Qua 2>/dev/null | wc -l | string trim)
    else
        set aur_updates "?"
    end

    __hc_val "Pacman:" "$pacman_updates pending"
    __hc_val "AUR:"    "$aur_updates pending"

    if test "$pacman_updates" = "0" -a "$aur_updates" = "0"
        __hc_ok "System is up to date."
    else
        __hc_warn "Updates available."
    end

    # ── Orphans ───────────────────────────────────────────────────────────────
    __hc_section b89458 "󰮯" "Orphan packages"
    set orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
    else
        __hc_ok "No orphan packages."
    end

    # ── Pacnew / Pacsave ──────────────────────────────────────────────────────
    __hc_section b89458 "󰘓" "Pacnew / Pacsave"
    set pacfiles (find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null)
    if test (count $pacfiles) -gt 0
        printf "  %s\n" $pacfiles
    else
        __hc_ok "No pacnew/pacsave files."
    end

    # ── Failed services ───────────────────────────────────────────────────────
    __hc_section a85a48 "󰋊" "Failed services"
    set failed_system (systemctl --failed --no-legend 2>/dev/null)
    if test (count $failed_system) -gt 0
        printf "  %s\n" $failed_system
        if printf "%s\n" $failed_system | rg -q "tpm2|pcrproduct"
            __hc_warn "TPM failures detected — known issue."
        end
    else
        __hc_ok "No failed system services."
    end

    set failed_user (systemctl --user --failed --no-legend 2>/dev/null)
    if test (count $failed_user) -gt 0
        printf "  %s\n" $failed_user
    else
        __hc_ok "No failed user services."
    end

    # ── Boot errors ───────────────────────────────────────────────────────────
    __hc_section a85a48 "󰍛" "Boot errors"
    set boot_errors (journalctl -b -p 3 --no-pager 2>/dev/null)
    set error_count (printf "%s\n" $boot_errors | wc -l | string trim)

    __hc_val "Errors:" "$error_count this boot"

    if test "$error_count" = "0"
        __hc_ok "No critical boot errors."
    else if printf "%s\n" $boot_errors | rg -q "tpm2|pcrproduct|TPM key integrity"
        __hc_warn "Critical errors are mostly TPM — known issue."
        set non_tpm (printf "%s\n" $boot_errors | rg -i "random-seed|bluetooth|filesystem|nvme|amdgpu|i/o error|failed to mount|corrupt" | head -12)
        if test (count $non_tpm) -gt 0
            printf "  %s\n" $non_tpm
        else
            __hc_none "No extra non-TPM errors."
        end
    else
        printf "%s\n" $boot_errors | rg -i "fail|error|random-seed|bluetooth|filesystem|nvme|amdgpu" | head -12
    end

    # ── Disk ──────────────────────────────────────────────────────────────────
    __hc_section 6a96b0 "󰪺" "Disk"
    df -h / /boot 2>/dev/null | awk 'NR>1 {printf "  %-16s%s used of %s\n", $6":", $3, $2}'

    # ── Cache overview ────────────────────────────────────────────────────────
    __hc_section 686058 "󰪺" "Cache overview"
    for d in ~/.cache ~/.config ~/.local/share/Trash
        if test -d $d
            __hc_val (string replace $HOME "~" $d)":" (du -sh $d 2>/dev/null | cut -f1)
        end
    end

    # ── Network ───────────────────────────────────────────────────────────────
    __hc_section 6a96b0 "󰛟" "Network"
    if command -q nmcli
        nmcli -t -f DEVICE,TYPE,STATE connection show --active 2>/dev/null \
            | awk -F: '{printf "  %-16s%-12s%s\n", $1, $2, $3}'
    else
        ip -brief addr | awk '{printf "  %-16s%s\n", $1, $3}'
    end

    # ── Temperatures ──────────────────────────────────────────────────────────
    __hc_section 6a96b0 "󰔏" "Temperatures"
    if command -q sensors
        sensors | rg -i "tctl|edge|composite|junction|temp" || sensors
    else
        __hc_none "sensors not installed."
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    set_color 6aab7a; echo "  ✓ Health check complete."; set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
