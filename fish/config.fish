function fastfetch
    if not command -q fastfetch
        echo "fastfetch not found"
        return 1
    end

    set -l base "$HOME/.config/fastfetch"

    # Probabilidades ponderadas (legendarias)
    set -l weighted \
        "$base/config.jsonc:10" \
        "$base/config2.jsonc:8" \
        "$base/config3.jsonc:8" \
        "$base/config4.jsonc:5" \
        "$base/config5.jsonc:4" \
        "$base/config6.jsonc:3" \
        "$base/config7.jsonc:2.5" \
        "$base/config8.jsonc:1.5" \
        "$base/config9.jsonc:1.1"

    set -l pool

    # Construir pool ponderado
    for item in $weighted
        set -l file (string split ":" $item)[1]
        set -l weight (string split ":" $item)[2]

        # Multiplica por 2 para soportar 0.5
        set -l repeats (math "$weight * 2")

        for i in (seq $repeats)
            set pool $pool $file
        end
    end

    set -l count (count $pool)

    if test $count -eq 0
        command fastfetch
        return
    end

    set -l idx_file "$base/.last_fastfetch"
    set -l last ""

    if test -f "$idx_file"
        set last (string trim < "$idx_file")
    end

    set -l selected $pool[(random 1 $count)]

    # Evitar repetición consecutiva
    while test "$selected" = "$last"
        set selected $pool[(random 1 $count)]
    end

    printf "%s\n" "$selected" > "$idx_file"

    command fastfetch --config "$selected"
end

if status is-interactive
    set -g fish_greeting

    starship init fish | source

    command -q thefuck; and thefuck --alias | source

end

# Created by pipx / local user binaries
fish_add_path "$HOME/.local/bin"