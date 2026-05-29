fzf --fish | source

set -gx FZF_CTRL_T_COMMAND "fd . --type f --hidden --follow --exclude .git"
set -gx FZF_ALT_C_COMMAND "fd . --type d --hidden --follow --exclude .git"

set -gx FZF_CTRL_T_OPTS "
--height=80%
--layout=reverse
--border
--preview='test -f {} && bat --style=numbers --color=always --line-range=:500 -- {}'
--preview-window=right:60%
"

set -gx FZF_ALT_C_OPTS "
--height=80%
--layout=reverse
--border
--preview='test -d {} && eza --tree --color=always --icons -- {} | head -200'
--preview-window=right:60%
"

set -gx FZF_CTRL_R_OPTS "
--height=80%
--layout=reverse
--border
"