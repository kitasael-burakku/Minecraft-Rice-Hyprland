if status is-interactive; and command -q fzf
    fzf --fish | source
end

# The three FZF_*_OPTS blocks repeated the same --height/--layout/--border.
# It goes here once: fzf always reads this, so any manual invocation (e.g.
# the Projects function) inherits it too — previously that looked different
# from the keybound shortcuts.
set -gx FZF_DEFAULT_OPTS "
--height=80%
--layout=reverse
--border=rounded
"

# fd/bat/eza are optional: if one's missing, fzf falls back to the default
# command (find) and an empty preview instead of throwing 'command not found'
# inside the panel.
if command -q fd
    set -gx FZF_CTRL_T_COMMAND "fd . --type f --hidden --follow --exclude .git"
    set -gx FZF_ALT_C_COMMAND "fd . --type d --hidden --follow --exclude .git"
end

if command -q bat
    set -gx FZF_CTRL_T_OPTS "
--preview='test -f {} && bat --style=numbers --color=always --line-range=:500 -- {}'
--preview-window=right:60%
"
end

if command -q eza
    set -gx FZF_ALT_C_OPTS "
--preview='test -d {} && eza --tree --color=always --icons -- {} | head -200'
--preview-window=right:60%
"
end
