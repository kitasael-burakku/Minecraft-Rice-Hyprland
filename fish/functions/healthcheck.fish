function healthcheck
    clear

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W ffffff "󰒋  System Health Check"
    _rui_mid $W
    _rui_row $W 686058 "System · Memory · Disk · Network · Temps"
    _rui_bot $W
    echo ""

    # ── System ────────────────────────────────────────────────────────────────
    _rui_section 6a96b0 "󰌢" "System"
    _rui_val "Host:"   (uname -n)
    _rui_val "Kernel:" (uname -r)
    _rui_val "Uptime:" (uptime -p)
    _rui_val "Shell:"  (basename $SHELL)

    # ── Memory ────────────────────────────────────────────────────────────────
    _rui_section 6a96b0 "󰍛" "Memory"
    free -h | awk '/Mem:/  { printf "  %-16s%s / %s\n", "RAM:", $3, $2 }
                  /Swap:/ { printf "  %-16s%s / %s\n", "Swap:", $3, $2 }'
    if swapon --show=NAME,SIZE,USED,TYPE 2>/dev/null | rg -q "zram"
        swapon --show=NAME,SIZE,USED,TYPE | rg "zram" | awk '{printf "  %-16s%s  used %s\n", "zram:", $2, $3}'
    else
        _rui_none "zram not detected."
    end

    # ── Updates ───────────────────────────────────────────────────────────────
    _rui_section b89458 "󰚰" "Updates"
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

    _rui_val "Pacman:" "$pacman_updates pending"
    _rui_val "AUR:"    "$aur_updates pending"

    if test "$pacman_updates" = "0" -a "$aur_updates" = "0"
        _rui_ok "System is up to date."
    else
        _rui_warn "Updates available."
    end

    # ── Orphans ───────────────────────────────────────────────────────────────
    _rui_section b89458 "󰮯" "Orphan packages"
    set orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
    else
        _rui_ok "No orphan packages."
    end

    # ── Pacnew / Pacsave ──────────────────────────────────────────────────────
    _rui_section b89458 "󰘓" "Pacnew / Pacsave"
    set pacfiles (find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null)
    if test (count $pacfiles) -gt 0
        printf "  %s\n" $pacfiles
    else
        _rui_ok "No pacnew/pacsave files."
    end

    # ── Failed services ───────────────────────────────────────────────────────
    _rui_section a85a48 "󰋊" "Failed services"
    set failed_system (systemctl --failed --no-legend 2>/dev/null)
    if test (count $failed_system) -gt 0
        printf "  %s\n" $failed_system
        if printf "%s\n" $failed_system | rg -q "tpm2|pcrproduct"
            _rui_warn "TPM failures detected — known issue."
        end
    else
        _rui_ok "No failed system services."
    end

    set failed_user (systemctl --user --failed --no-legend 2>/dev/null)
    if test (count $failed_user) -gt 0
        printf "  %s\n" $failed_user
    else
        _rui_ok "No failed user services."
    end

    # ── Boot errors ───────────────────────────────────────────────────────────
    _rui_section a85a48 "󰍛" "Boot errors"
    set boot_errors (journalctl -b -p 3 --no-pager 2>/dev/null)
    set error_count (printf "%s\n" $boot_errors | wc -l | string trim)

    _rui_val "Errors:" "$error_count this boot"

    if test "$error_count" = "0"
        _rui_ok "No critical boot errors."
    else if printf "%s\n" $boot_errors | rg -q "tpm2|pcrproduct|TPM key integrity"
        _rui_warn "Critical errors are mostly TPM — known issue."
        set non_tpm (printf "%s\n" $boot_errors | rg -i "random-seed|bluetooth|filesystem|nvme|amdgpu|i/o error|failed to mount|corrupt" | head -12)
        if test (count $non_tpm) -gt 0
            printf "  %s\n" $non_tpm
        else
            _rui_none "No extra non-TPM errors."
        end
    else
        printf "%s\n" $boot_errors | rg -i "fail|error|random-seed|bluetooth|filesystem|nvme|amdgpu" | head -12
    end

    # ── Disk ──────────────────────────────────────────────────────────────────
    _rui_section 6a96b0 "󰪺" "Disk"
    df -h / /boot 2>/dev/null | awk 'NR>1 {printf "  %-16s%s used of %s\n", $6":", $3, $2}'

    # ── Cache overview ────────────────────────────────────────────────────────
    _rui_section 686058 "󰪺" "Cache overview"
    for d in ~/.cache ~/.config ~/.local/share/Trash
        if test -d $d
            _rui_val (string replace $HOME "~" $d)":" (du -sh $d 2>/dev/null | cut -f1)
        end
    end

    # ── Network ───────────────────────────────────────────────────────────────
    _rui_section 6a96b0 "󰛟" "Network"
    if command -q nmcli
        nmcli -t -f DEVICE,TYPE,STATE connection show --active 2>/dev/null \
            | awk -F: '{printf "  %-16s%-12s%s\n", $1, $2, $3}'
    else
        ip -brief addr | awk '{printf "  %-16s%s\n", $1, $3}'
    end

    # ── Temperatures ──────────────────────────────────────────────────────────
    _rui_section 6a96b0 "󰔏" "Temperatures"
    if command -q sensors
        sensors | rg -i "tctl|edge|composite|junction|temp" || sensors
    else
        _rui_none "sensors not installed."
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color 909090; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    set_color 6aab7a; echo "  ✓ Health check complete."; set_color normal
    echo ""
    read -p 'set_color 686058; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
