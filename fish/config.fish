function fastfetch
    if not command -q fastfetch
        echo "fastfetch not found"
        return 1
    end

    set -l base "$HOME/.config/fastfetch"

    # Configuración y pesos
    set -l weighted \
        "$base/config.jsonc:12" \
        "$base/config2.jsonc:10" \
        "$base/config3.jsonc:7" \
        "$base/config4.jsonc:5" \
        "$base/config5.jsonc:3" \
        "$base/config6.jsonc:2" \
        "$base/config7.jsonc:1" \
        "$base/config8.jsonc:0.5" \
        "$base/config9.jsonc:0.25"

    set -l bag_file "$base/.fastfetch_bag"

    # Si la bolsa no existe o está vacía (conteo real de entradas no vacías,
    # no tamaño de archivo: al vaciarse, "printf %s\n $bag" con $bag vacío
    # igual escribe 1 byte de salto de línea — "test -s" daba falso positivo
    # de "no vacío", y ademas fish parsea ese byte como una lista de UN
    # elemento vacío (count=1), no una lista vacía — de ahí que se chequee
    # también que la primera entrada no sea la cadena vacía).
    set -l needs_refill 1
    if test -f "$bag_file"
        set -l probe (cat "$bag_file")
        if test (count $probe) -gt 0 -a -n "$probe[1]"
            set needs_refill 0
        end
    end
    if test "$needs_refill" -eq 1
        set -l bag

        for item in $weighted
            set -l file (string split ":" $item)[1]
            set -l weight (string split ":" $item)[2]

            # Multiplicador para convertir decimales en enteros
            set -l repeats (math "ceil($weight * 8)")

            for i in (seq $repeats)
                set bag $bag $file
            end
        end

        # Mezclar la bolsa
        set -l shuffled
        while test (count $bag) -gt 0
            set -l idx (random 1 (count $bag))
            set shuffled $shuffled $bag[$idx]
            set -e bag[$idx]
        end

        printf "%s\n" $shuffled > "$bag_file"
    end

    # Leer la bolsa
    set -l bag (cat "$bag_file")

    # Tomar el primero
    set -l selected $bag[1]

    # Eliminar el primero
    set bag $bag[2..]

    printf "%s\n" $bag > "$bag_file"

    command fastfetch --config "$selected"
end

if status is-interactive
    set -g fish_greeting

    if command -q starship
        starship init fish | source
    end

    if command -q thefuck
        function fuck --description "Carga thefuck recién en el primer uso (arranque instantáneo)"
            functions -e fuck
            thefuck --alias | source
            fuck $argv
        end
    end

    fastfetch

end

# Created by pipx / local user binaries
#
# -g y no universal: antes esto convivía con una fish_user_paths universal
# guardada en fish_variables con el mismo valor, o sea la ruta estaba definida
# en dos lugares y solo uno de los dos es visible en los dotfiles. Queda este,
# que se lee acá y se puede versionar; la universal se borró.
fish_add_path -g "$HOME/.local/bin"