# Completion for `ec` — names come from the same table the function uses,
# so adding a target in functions/ec.fish is enough to cover both.
# -f: no file completion, the only valid candidates are the names.
complete -c ec -f

complete -c ec -a '(__ec_targets | string replace -ra "^(\S+)\s+(.*)\$" "\$1\t\$2")'
