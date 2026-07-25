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

    # Si la bolsa no existe o está vacía, crearla
    if not test -s "$bag_file"
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

end

# Created by pipx / local user binaries
fish_add_path "$HOME/.local/bin"