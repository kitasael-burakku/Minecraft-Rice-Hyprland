# -----------------------------------
# Full Arch Linux update routine
# -----------------------------------

function sysupdate
    clear

    # ── Palette (stone/minecraft) ─────────────────────────────────────────────
    set -l C_RESET  (set_color normal)
    set -l C_BOLD   (set_color --bold ffffff)
    set -l C_DIM    (set_color 686058)
    set -l C_GREEN  (set_color 6aab7a)
    set -l C_RED    (set_color a85a48)
    set -l C_YELLOW (set_color b89458)
    set -l C_CYAN   (set_color 6a96b0)
    set -l C_BORDER (set_color 909090)

    set -l W 40

    # ── Box helpers ───────────────────────────────────────────────────────────
    function __su_top -a w
        set_color 909090
        printf "  ┌"
        for i in (seq 1 (math "$w - 2")); printf "─"; end
        printf "┐\n"
        set_color normal
    end

    function __su_mid -a w
        set_color 909090
        printf "  ├"
        for i in (seq 1 (math "$w - 2")); printf "─"; end
        printf "┤\n"
        set_color normal
    end

    function __su_bot -a w
        set_color 909090
        printf "  └"
        for i in (seq 1 (math "$w - 2")); printf "─"; end
        printf "┘\n"
        set_color normal
    end

    function __su_row -a w color text
        set -l inner (math "$w - 2")
        set -l len (string length --visible "$text")
        set -l left (math "max(0, floor(($inner - $len) / 2))")
        set -l right (math "max(0, $inner - $len - $left)")
        set_color 909090
        printf "  │"
        printf "%*s" $left ""
        set_color $color
        printf "%s" "$text"
        set_color 909090
        printf "%*s│\n" $right ""
        set_color normal
    end

    function __su_section -a w color text
        echo ""
        set_color $color
        printf "  ── %s\n" "$text"
        set_color normal
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    __su_top $W
    __su_row $W ffffff "󰮯  Full Arch Update Routine"
    __su_mid $W
    __su_row $W 686058 "Updates Pacman + AUR packages"
    __su_bot $W
    echo ""

    read -p 'set_color b89458; echo -n "  Continue? [y/N] > "; set_color normal' confirm
    echo ""

    if test "$confirm" != "y" -a "$confirm" != "Y"
        set_color a85a48
        echo "  Cancelled."
        set_color normal
        return
    end

    if not command -q yay
        set_color a85a48
        echo "  yay not found."
        set_color normal
        return 1
    end

    __su_section $W 6a96b0 "󰚰 Pacman"
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

    __su_section $W bd7fd4 " AUR — yay"
    echo ""
    sleep 0.1
    yay -Sua
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
