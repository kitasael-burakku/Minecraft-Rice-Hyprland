function healthcheck
    clear

    function __hc_section
        echo ""
        set_color yellow
        echo "$argv[1]"
        set_color normal
    end

    function __hc_ok
        set_color green
        echo "✅ $argv"
        set_color normal
    end

    function __hc_warn
        set_color yellow
        echo "⚠️  $argv"
        set_color normal
    end

    function __hc_bad
        set_color red
        echo "❌ $argv"
        set_color normal
    end

    set_color cyan
    echo "󰒋 System Health Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color normal

    __hc_section "󰌢 System:"
    echo "Host:   "(uname -n)
    echo "Kernel: "(uname -r)
    echo "Uptime: "(uptime -p)
    echo "Shell:  $SHELL"

    __hc_section "󰍛 Memory:"
    free -h | awk '/Mem:/ {print "RAM:    used "$3" / "$2} /Swap:/ {print "Swap:   used "$3" / "$2}'

    if swapon --show=NAME,SIZE,USED,TYPE | rg -q "zram"
        swapon --show=NAME,SIZE,USED,TYPE | rg "zram"
    else
        echo "zram:   not detected"
    end

    __hc_section "󰚰 Updates:"
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

    echo "Pacman: $pacman_updates"
    echo "AUR:    $aur_updates"

    if test "$pacman_updates" = "0" -a "$aur_updates" = "0"
        __hc_ok "System packages are up to date."
    else
        __hc_warn "Updates available."
    end

    __hc_section "󰮯 Orphan packages:"
    set orphans (pacman -Qtdq 2>/dev/null)

    if test (count $orphans) -gt 0
        printf "%s\n" $orphans
    else
        __hc_ok "No orphan packages."
    end

    __hc_section "󰘓 Pacnew / Pacsave:"
    set pacfiles (find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null)

    if test (count $pacfiles) -gt 0
        printf "%s\n" $pacfiles
    else
        __hc_ok "No pacnew/pacsave files found."
    end

    __hc_section "󰋊 Failed systemd services:"
    set failed_system (systemctl --failed --no-legend 2>/dev/null)

    if test (count $failed_system) -gt 0
        printf "%s\n" $failed_system

        if printf "%s\n" $failed_system | rg -q "tpm2|pcrproduct"
            __hc_warn "TPM failures detected. Known issue in your setup."
        end
    else
        __hc_ok "No failed system services."
    end

    __hc_section "󰋊 Failed user services:"
    set failed_user (systemctl --user --failed --no-legend 2>/dev/null)

    if test (count $failed_user) -gt 0
        printf "%s\n" $failed_user
    else
        __hc_ok "No failed user services."
    end

    __hc_section "󰍛 Boot errors summary:"
    set boot_errors (journalctl -b -p 3 --no-pager 2>/dev/null)
    set error_count (printf "%s\n" $boot_errors | wc -l | string trim)

    echo "Errors this boot: $error_count"

    if test "$error_count" = "0"
        __hc_ok "No critical boot errors."
    else if printf "%s\n" $boot_errors | rg -q "tpm2|pcrproduct|TPM key integrity"
        __hc_warn "Critical errors are mostly TPM known issue."

        set non_tpm_errors (printf "%s\n" $boot_errors | rg -i "random-seed|bluetooth|filesystem|nvme|amdgpu|i/o error|failed to mount|corrupt" | head -12)

        if test (count $non_tpm_errors) -gt 0
            printf "%s\n" $non_tpm_errors
        else
            echo "No extra non-TPM critical errors matched."
        end
    else
        printf "%s\n" $boot_errors | rg -i "fail|error|random-seed|bluetooth|filesystem|nvme|amdgpu" | head -12
    end

    __hc_section "󰪺 Disk usage:"
    df -h / /boot 2>/dev/null

    __hc_section "󰪺 Cache overview:"
    if test -d ~/.cache
        du -sh ~/.cache 2>/dev/null
    end

    if test -d ~/.config
        du -sh ~/.config 2>/dev/null
    end

    if test -d ~/.local/share/Trash
        du -sh ~/.local/share/Trash 2>/dev/null
    end

    __hc_section "󰛟 Network:"
    if command -q nmcli
        nmcli -t -f DEVICE,TYPE,STATE connection show --active 2>/dev/null | string replace -a ":" "  "
    else
        ip -brief addr
    end

    __hc_section "󰔏 Temperatures:"
    if command -q sensors
        sensors | rg -i "tctl|edge|composite|junction|temp" || sensors
    else
        echo "sensors not installed."
    end

    echo ""
    set_color green
    echo "✅ Health check complete."
    set_color normal

    echo ""
    set_color brblack
    read -P "Press Enter to exit..."
    set_color normal
end