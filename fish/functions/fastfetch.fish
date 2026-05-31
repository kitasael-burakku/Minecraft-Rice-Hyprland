function fastfetch
    if not command -q fastfetch
        echo "fastfetch not found"
        return 1
    end

    set -l configs $HOME/.config/fastfetch/config*.jsonc
    set -l count (count $configs)

    if test $count -eq 0
        command fastfetch
        return
    end

    if test $count -eq 1
        command fastfetch --config "$configs[1]"
        return
    end

    set -l idx_file "$HOME/.config/fastfetch/.last_idx"
    set -l last 0

    if test -f "$idx_file"
        set last (string trim < "$idx_file")
    end

    set -l idx (random 1 $count)

    while test "$idx" = "$last"
        set idx (random 1 $count)
    end

    printf "%s\n" "$idx" > "$idx_file"

    command fastfetch --config "$configs[$idx]"
end