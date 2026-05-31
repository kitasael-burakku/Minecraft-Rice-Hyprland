if status is-interactive
end

set -g fish_greeting

starship init fish | source

bind \cr history-pager

# Created by pipx / local user binaries
fish_add_path "$HOME/.local/bin"