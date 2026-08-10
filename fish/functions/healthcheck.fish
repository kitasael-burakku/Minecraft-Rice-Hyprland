function healthcheck
    clear

    # Ver la nota en checkerrors: rg se usa en varias secciones y sin él el
    # reporte se llena de "command not found" en vez de fallar una sola vez.
    if not command -q rg
        _rui_bad "Falta ripgrep (rg) — pacman -S ripgrep"
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
    # Declaradas acá afuera a propósito: un "set -l" adentro del if quedaría
    # escopado al bloque y no se vería más abajo.
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
    # "count $boot_errors" contaba líneas, no eventos: un solo coredump
    # (systemd-coredump) imprime un backtrace de cientos de líneas como UN
    # evento, así que un par de crashes de waybar/swaync inflaban esto a
    # tres dígitos aunque hubiera 10 entradas reales en el journal.
    # --output=json emite un objeto JSON por evento en una sola línea (el
    # MESSAGE multilínea va con \n escapado adentro), así que contarlo con
    # "count" da el número real de eventos.
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
    # Antes era "df -h / /boot", que estaba mal por dos motivos: /boot no es un
    # montaje separado acá (solo lo es /boot/efi), así que df resolvía las dos
    # rutas al mismo filesystem y la sección imprimía "/" DOS veces — y el
    # segundo disco (/mnt/storage, 938G) no aparecía nunca.
    #
    # Ahora se autodetectan todos los filesystems reales excluyendo los
    # pseudo-FS, así un disco o un USB nuevo aparece solo sin tocar la función.
    # --output en vez de columnas posicionales ($6): con un device de nombre
    # largo df parte la línea y el awk posicional se descoloca.
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
