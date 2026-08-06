if status is-interactive; and command -q fzf
    fzf --fish | source
end

# Los tres bloques FZF_*_OPTS repetían el mismo --height/--layout/--border.
# Va una sola vez acá: fzf lo lee siempre, así que también lo hereda cualquier
# invocación a mano (por ejemplo la función Projects), que antes quedaba con
# otro aspecto que los atajos.
set -gx FZF_DEFAULT_OPTS "
--height=80%
--layout=reverse
--border=rounded
"

# fd/bat/eza son opcionales: si falta alguno, fzf cae al comando por defecto
# (find) y al preview vacío en vez de tirar 'command not found' adentro del
# panel.
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
