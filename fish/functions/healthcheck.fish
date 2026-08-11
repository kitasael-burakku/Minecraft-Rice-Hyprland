function healthcheck
    clear

    # See the note in checkerrors: rg is used in several sections and
    # without it the report fills up with "command not found" instead of
    # failing once.
    if not command -q rg
        _rui_bad "Missing ripgrep (rg) — pacman -S ripgrep"
        return 127
    end

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰒋  System Health Check"
    _rui_mid $W
    _rui_row $W brblack "System · Memory · Disk · Network · Temps"
    _rui_bot $W
    echo ""

    # ── System ────────────────────────────────────────────────────────────────
    _rui_section cyan "󰌢" "System"
    _rui_val "Host:"   (uname -n)
    _rui_val "Kernel:" (uname -r)
    _rui_val "Uptime:" (uptime -p)
    _rui_val "Shell:"  (basename $SHELL)

    # ── Memory ────────────────────────────────────────────────────────────────
    _rui_section cyan "󰍛" "Memory"
    free -h | awk '/Mem:/  { printf "  %-16s%s / %s\n", "RAM:", $3, $2 }
                  /Swap:/ { printf "  %-16s%s / %s\n", "Swap:", $3, $2 }'
    if swapon --show=NAME,SIZE,USED,TYPE 2>/dev/null | rg -q "zram"
        swapon --show=NAME,SIZE,USED,TYPE | rg "zram" | awk '{printf "  %-16s%s  used %s\n", "zram:", $2, $3}'
    else
        _rui_none "zram not detected."
    end

    # ── Updates ───────────────────────────────────────────────────────────────
    _rui_section yellow "󰚰" "Updates"
    # Declared out here on purpose: a "set -l" inside the if would be
    # scoped to that block and wouldn't be visible further down.
    set -l pacman_updates
    set -l aur_updates
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
    _rui_section yellow "󰮯" "Orphan packages"
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "  %s\n" $orphans
    else
        _rui_ok "No orphan packages."
    end

    # ── Pacnew / Pacsave ──────────────────────────────────────────────────────
    _rui_section yellow "󰘓" "Pacnew / Pacsave"
    set -l pacfiles (find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null)
    if test (count $pacfiles) -gt 0
        printf "  %s\n" $pacfiles
    else
        _rui_ok "No pacnew/pacsave files."
    end

    # ── Failed services ───────────────────────────────────────────────────────
    _rui_section red "󰋊" "Failed services"
    set -l failed_system (systemctl --failed --no-legend 2>/dev/null)
    if test (count $failed_system) -gt 0
        printf "  %s\n" $failed_system
        if printf "%s\n" $failed_system | rg -q "tpm2|pcrproduct"
            _rui_warn "TPM failures detected — known issue."
        end
    else
        _rui_ok "No failed system services."
    end

    set -l failed_user (systemctl --user --failed --no-legend 2>/dev/null)
    if test (count $failed_user) -gt 0
        printf "  %s\n" $failed_user
    else
        _rui_ok "No failed user services."
    end

    # ── Boot errors ───────────────────────────────────────────────────────────
    _rui_section red "󰍛" "Boot errors"
    set -l boot_errors (journalctl -b -p 3 --no-pager 2>/dev/null)
    # "count $boot_errors" was counting lines, not events: a single coredump
    # (systemd-coredump) prints a backtrace of hundreds of lines as ONE
    # event, so a couple of waybar/swaync crashes inflated this to three
    # digits even with only 10 real entries in the journal.
    # --output=json emits one JSON object per event on a single line (the
    # multiline MESSAGE goes in with \n escaped inside), so counting it with
    # "count" gives the real number of events.
    set -l error_count (journalctl -b -p 3 --no-pager --output=json 2>/dev/null | count)

    _rui_val "Errors:" "$error_count this boot"

    if test "$error_count" = "0"
        _rui_ok "No critical boot errors."
    else if printf "%s\n" $boot_errors | rg -q "tpm2|pcrproduct|TPM key integrity"
        _rui_warn "Critical errors are mostly TPM — known issue."
        set -l non_tpm (printf "%s\n" $boot_errors | rg -i "random-seed|bluetooth|filesystem|nvme|amdgpu|i/o error|failed to mount|corrupt" | head -12)
        if test (count $non_tpm) -gt 0
            printf "  %s\n" $non_tpm
        else
            _rui_none "No extra non-TPM errors."
        end
    else
        printf "%s\n" $boot_errors | rg -i "fail|error|random-seed|bluetooth|filesystem|nvme|amdgpu" | head -12
    end

    # ── Disk ──────────────────────────────────────────────────────────────────
    #
    # Used to be "df -h / /boot", which was wrong for two reasons: /boot
    # isn't a separate mount here (only /boot/efi is), so df resolved both
    # paths to the same filesystem and the section printed "/" TWICE — and
    # the second disk (/mnt/storage, 938G) never showed up at all.
    #
    # Now all real filesystems are auto-detected, excluding the pseudo-FS,
    # so a new disk or USB drive shows up on its own without touching the
    # function. --output instead of positional columns ($6): with a
    # long-named device df wraps the line and the positional awk gets thrown
    # off.
    _rui_section cyan "󰪺" "Disk"
    df -h --output=target,used,size,pcent \
        -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs 2>/dev/null \
        | awk 'NR>1 {printf "  %-16s%s used of %s (%s)\n", $1":", $2, $3, $4}'

    # ── Cache overview ────────────────────────────────────────────────────────
    _rui_section brblack "󰪺" "Cache overview"
    for d in ~/.cache ~/.config ~/.local/share/Trash
        if test -d $d
            _rui_val (string replace $HOME "~" $d)":" (du -sh $d 2>/dev/null | cut -f1)
        end
    end

    # ── Network ───────────────────────────────────────────────────────────────
    _rui_section cyan "󰛟" "Network"
    if command -q nmcli
        nmcli -t -f DEVICE,TYPE,STATE connection show --active 2>/dev/null \
            | awk -F: '{printf "  %-16s%-12s%s\n", $1, $2, $3}'
    else
        ip -brief addr | awk '{printf "  %-16s%s\n", $1, $3}'
    end

    # ── Temperatures ──────────────────────────────────────────────────────────
    _rui_section cyan "󰔏" "Temperatures"
    if command -q sensors
        sensors | rg -i "tctl|edge|composite|junction|temp" || sensors
    else
        _rui_none "sensors not installed."
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color brblack; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    set_color green; echo "  ✓ Health check complete."; set_color normal
    echo ""
    read -p 'set_color brblack; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
