# -----------------------------------
# Full Arch Linux update routine
# -----------------------------------

function sysupdate
    clear

    set -l W 40

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W ffffff "󰮯  Full Arch Update Routine"
    _rui_mid $W
    _rui_row $W 686058 "Updates Pacman + AUR (yay / paru)"
    _rui_bot $W
    echo ""

    read -p 'set_color b89458; echo -n "  Continue? [y/N] > "; set_color normal' confirm
    echo ""

    if test "$confirm" != "y" -a "$confirm" != "Y"
        set_color a85a48
        echo "  Cancelled."
        set_color normal
        return
    end

    # ── Detectar AUR helper ──────────────────────────────────────────────────
    set -l aur_helper ""
    if command -q yay
        set aur_helper yay
    else if command -q paru
        set aur_helper paru
    else
        set_color a85a48
        echo "  No AUR helper found (yay or paru required)."
        set_color normal
        return 1
    end

    _rui_section_plain 6a96b0 "" "󰚰 Pacman"
    echo ""
    sleep 0.1
    sudo pacman -Syu
    or begin
        set_color a85a48
        echo ""
        echo "  Pacman update failed. Aborting AUR update."
        set_color normal
        return 1
    end

    _rui_section_plain bd7fd4 "" " AUR — $aur_helper"
    echo ""
    sleep 0.1
    $aur_helper -Sua
    or begin
        set_color a85a48
        echo ""
        echo "  AUR update failed."
        set_color normal
        return 1
    end

    echo ""
    set_color 6aab7a
    echo "  󰏖  System fully updated."
    set_color normal
    echo ""
end
