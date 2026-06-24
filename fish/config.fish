if status is-interactive
    set -g fish_greeting
    
    starship init fish | source
   
    thefuck --alias | source

    fastfetch
end

# Created by pipx / local user binaries
fish_add_path "$HOME/.local/bin"