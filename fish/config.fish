function fastfetch
    if not command -q fastfetch
        echo "fastfetch not found"
        return 1
    end

    set -l base "$HOME/.config/fastfetch"

    # Configs and weights
    set -l weighted \
        "$base/kitasan.jsonc:12" \
        "$base/goldship.jsonc:10" \
        "$base/yani.jsonc:8" \
        "$base/Yani-Neko.jsonc:7" \
        "$base/arch.jsonc:5" \
        "$base/microfetch.jsonc:4" \
        "$base/lfs.jsonc:3" \
        "$base/cachyos.jsonc:2" \
        "$base/hyprmc.jsonc:1" \
        "$base/kitasan_ascii.jsonc:0.5" \
        "$base/duki.jsonc:0.25"

    set -l bag_file "$base/.fastfetch_bag"

    # If the bag doesn't exist or is empty (real count of non-empty entries,
    # not file size: once emptied, "printf %s\n $bag" with an empty $bag
    # still writes 1 newline byte — "test -s" gave a false positive of
    # "not empty", and fish also parses that byte as a list of ONE empty
    # element (count=1), not an empty list — hence also checking that the
    # first entry isn't the empty string).
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

            # Multiplier to convert decimals into integers
            set -l repeats (math "ceil($weight * 8)")

            for i in (seq $repeats)
                set bag $bag $file
            end
        end

        # Shuffle the bag
        set -l shuffled
        while test (count $bag) -gt 0
            set -l idx (random 1 (count $bag))
            set shuffled $shuffled $bag[$idx]
            set -e bag[$idx]
        end

        printf "%s\n" $shuffled > "$bag_file"
    end

    # Read the bag
    set -l bag (cat "$bag_file")

    # Take the first one
    set -l selected $bag[1]

    # Remove the first one
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
        function fuck --description "Loads thefuck only on first use (instant startup)"
            functions -e fuck
            thefuck --alias | source
            fuck $argv
        end
    end
end

# Created by pipx / local user binaries
#
# -g and not universal: this used to coexist with a universal fish_user_paths
# stored in fish_variables with the same value, meaning the path was defined
# in two places and only one of them is visible in the dotfiles. This one
# stays, readable here and versionable; the universal one was deleted.
fish_add_path -g "$HOME/.local/bin"