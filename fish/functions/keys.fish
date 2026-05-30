function keys
    if test -f "$HOME/Documents/KEYBINDS.txt"
        bat "$HOME/Documents/KEYBINDS.txt"
    else
        echo "KEYBINDS.txt not found in ~/Documents"
    end
end