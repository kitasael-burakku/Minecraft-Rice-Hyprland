function cleantrash
    clear

    set_color red
    echo "󰮯 System Cleanup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "This will remove orphan packages, clean package caches,"
    echo "remove pacman temporary downloads, clean yay cache,"
    echo "and empty your user trash."
    set_color normal

    echo ""
    read -P "Continue? [y/N] > " confirm

    if test "$confirm" != "y" -a "$confirm" != "Y"
        set_color brblack
        echo "Cancelled."
        set_color normal
        return
    end

    echo ""

    set_color yellow
    echo "󰮯 Removing orphan packages:"
    set_color normal

    set orphans (pacman -Qtdq 2>/dev/null)

    if test (count $orphans) -gt 0
        printf "%s\n" $orphans
        sudo pacman -Rns $orphans
    else
        echo "No orphan packages."
    end

    echo ""

    set_color yellow
    echo "󰪺 Removing pacman temporary downloads:"
    set_color normal

    set downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)

    if test (count $downloads) -gt 0
        printf "%s\n" $downloads
        sudo rm -rf -- $downloads
        set_color green
        echo "Temporary pacman downloads removed."
        set_color normal
    else
        echo "No temporary pacman downloads found."
    end

    echo ""

    set_color cyan
    echo "󰪺 Cleaning pacman cache:"
    set_color normal

    if command -q paccache
        sudo paccache -r
    else
        echo "paccache not found."
    end

    echo ""

    set_color magenta
    echo "󰏗 Cleaning yay cache:"
    set_color normal

    if command -q yay
        yay -Sc
    else
        echo "yay not found."
    end

    echo ""

    set_color yellow
    echo "󰩺 Emptying user trash:"
    set_color normal

    set trash_files "$HOME/.local/share/Trash/files"
    set trash_info "$HOME/.local/share/Trash/info"

    if command -q gio
        if gio trash --empty 2>/dev/null
            echo "Trash emptied."
        else
            if test -d "$trash_files"
                find "$trash_files" -mindepth 1 -exec rm -rf {} +
            end

            if test -d "$trash_info"
                find "$trash_info" -mindepth 1 -exec rm -rf {} +
            end

            echo "Trash emptied using fallback method."
        end
    else
        if test -d "$trash_files"
            find "$trash_files" -mindepth 1 -exec rm -rf {} +
        end

        if test -d "$trash_info"
            find "$trash_info" -mindepth 1 -exec rm -rf {} +
        end

        echo "Trash emptied using fallback method."
    end

    echo ""

    set_color green
    echo "✅ System cleanup complete."
    set_color normal

    echo ""
    set_color brblack
    read -P "Press Enter to exit..."
    set_color normal
end