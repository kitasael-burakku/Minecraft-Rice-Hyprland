# -----------------------------------
# Full Arch Linux update routine
# -----------------------------------

function sysupdate
    clear

    set -l W 40

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰮯  Full Arch Update Routine"
    _rui_mid $W
    _rui_row $W brblack "Updates Pacman + AUR (yay / paru)"
    _rui_bot $W
    echo ""

    # ── Pre-check: free space ─────────────────────────────────────────────
    # This is the only thing here that can leave the system worse off than
    # before: if / fills up mid-transaction, pacman is left half-done.
    # Packages get downloaded to /var/cache/pacman/pkg, which lives on /.
    set -l min_bytes (math "2 * 1024 * 1024 * 1024")
    set -l avail (df -B1 --output=avail / 2>/dev/null | tail -1 | string trim)

    if test -n "$avail"; and test "$avail" -lt "$min_bytes"
        _rui_bad "Low space on /: "(math -s1 "$avail / 1024 / 1024 / 1024")" GiB free (minimum 2 GiB)"
        _rui_none "Free up space first — try cleantrash or quickcache."
        return 1
    end
    _rui_ok "Space on /: "(math -s1 "$avail / 1024 / 1024 / 1024")" GiB free"
    echo ""

    if not _rui_confirm "Continue?"
        echo ""
        set_color red
        echo "  Cancelled."
        set_color normal
        return
    end
    echo ""

    # ── Detect AUR helper ──────────────────────────────────────────────────
    set -l aur_helper ""
    if command -q yay
        set aur_helper yay
    else if command -q paru
        set aur_helper paru
    else
        set_color red
        echo "  No AUR helper found (yay or paru required)."
        set_color normal
        return 1
    end

    _rui_section_plain cyan "󰚰" "Pacman"
    echo ""
    sleep 0.1
    sudo pacman -Syu
    or begin
        set_color red
        echo ""
        echo "  Pacman update failed. Aborting AUR update."
        set_color normal
        return 1
    end

    _rui_section_plain magenta "" "AUR — $aur_helper"
    echo ""
    sleep 0.1
    $aur_helper -Sua --diffmenu --editmenu
    or begin
        set_color red
        echo ""
        echo "  AUR update failed."
        set_color normal
        return 1
    end

    # ── Post-update ──────────────────────────────────────────────────────────
    # These three things show up right after the update, and they're
    # exactly the data healthcheck already computes — but you had to
    # remember to run it separately. All three checks are read-only.
    _rui_section_plain cyan "󰋼" "Post-update"

    set -l dirty 0

    # .pacnew/.pacsave — same find healthcheck.fish uses
    set -l pacfiles (find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null)
    if test (count $pacfiles) -gt 0
        _rui_warn (count $pacfiles)" .pacnew/.pacsave file(s) in /etc"
        printf "      %s\n" $pacfiles
        set dirty 1
    end

    # Orphans — same pacman -Qtdq healthcheck and checktrash use
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        _rui_warn (count $orphans)" package(s) left orphaned — cleantrash removes them"
        set dirty 1
    end

    # Pending reboot. Package-agnostic method: if the running kernel's
    # module directory no longer exists, it's because the kernel was
    # updated and the system is still on one with no modules left on disk.
    # Works the same with linux-cachyos, -lts or whatever, no hardcoded names.
    if not test -d "/usr/lib/modules/"(uname -r)
        _rui_warn "Kernel updated ("(uname -r)" no longer has modules) — reboot"
        set dirty 1
    end

    test "$dirty" -eq 0; and _rui_ok "Nothing pending: no .pacnew, no orphans, no reboot."

    echo ""
    set_color green
    echo "  󰏖  System fully updated."
    set_color normal
    echo ""
end
