# Completado de `ec` — los nombres salen de la misma tabla que usa la función,
# así que agregar un target en functions/ec.fish alcanza para las dos cosas.
# -f: sin completado de archivos, los únicos candidatos válidos son los nombres.
complete -c ec -f

complete -c ec -a '(__ec_targets | string replace -ra "^(\S+)\s+(.*)\$" "\$1\t\$2")'
