# -----------------------------------
# Full Arch Linux update routine
# -----------------------------------

function sysupdate
    clear

    if not command -q yay
        set_color red
        echo "yay not found."
        set_color normal
        return 1
    end

    set_color cyan

    set line1 "󰚰 Arch Updates > Pacman"
    for char in (string split '' -- $line1)
        printf "%s" $char
        sleep 0.01
    end

    echo ""
    set_color normal

    sleep 0.2

    sudo pacman -Syu
    or begin
        set_color red
        echo "Pacman update failed. Aborting AUR update."
        set_color normal
        return 1
    end

    echo ""

    set_color magenta

    set line2 " AUR > yay apps"
    for char in (string split '' -- $line2)
        printf "%s" $char
        sleep 0.01
    end

    echo ""
    set_color normal

    sleep 0.2

    yay -Sua
    or begin
        set_color red
        echo "AUR update failed."
        set_color normal
        return 1
    end

    echo ""

    set_color green

    set line3 "󰏖  System is fully updated."
    for char in (string split '' -- $line3)
        printf "%s" $char
        sleep 0.015
    end

    echo ""
    set_color normal
end