function checktrash
    set_color yellow
    echo "󰮯 Orphan packages:"
    set_color normal

    set orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        printf "%s\n" $orphans
    else
        echo "No orphan packages."
    end

    echo ""

    set_color cyan
    echo "󰪺 Pacman cache:"
    set_color normal
    sudo du -sh /var/cache/pacman/pkg 2>/dev/null

    echo ""

    set_color cyan
    echo "󰪺 Pacman temporary downloads:"
    set_color normal

    set downloads (find /var/cache/pacman/pkg -maxdepth 1 -name 'download-*' 2>/dev/null)

    if test (count $downloads) -gt 0
        printf "%s\n" $downloads
        echo ""
        sudo du -ch $downloads 2>/dev/null | tail -n 1
    else
        echo "No temporary pacman downloads found."
    end

    echo ""

    set_color magenta
    echo "󰏗 Yay cache:"
    set_color normal

    if test -d ~/.cache/yay
        du -sh ~/.cache/yay
    else
        echo "No yay cache found."
    end

    echo ""

    set_color green
    echo "󰍛 Journal size:"
    set_color normal
    journalctl --disk-usage

    echo ""

    set_color yellow
    echo "󰩺 User trash:"
    set_color normal

    if test -d ~/.local/share/Trash
        du -sh ~/.local/share/Trash 2>/dev/null

        set trash_files (find ~/.local/share/Trash/files -mindepth 1 2>/dev/null)
        set trash_info (find ~/.local/share/Trash/info -mindepth 1 2>/dev/null)

        set trash_count (math (count $trash_files) + (count $trash_info))

        if test $trash_count -gt 0
            echo "Trash items: $trash_count"
        else
            echo "Trash is empty."
        end
    else
        echo "Trash folder not found."
    end

    echo ""

    set_color brblack
    read -P "Press Enter to exit..."
    set_color normal
end