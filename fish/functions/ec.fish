# ~/.config/fish/functions/ec.fish
# "edit config" — opens a config in the editor and recycles the terminals.
#
# Replaces the ~12 ecswaync/echypr/ecwaybar/... aliases that were all the
# same line with a different path. The old names still exist as wrappers in
# conf.d/tools.fish, so muscle memory doesn't break. Adding a new config is
# now one line in __ec_targets.

# name→path(s) table. One entry per line, paths separated by spaces.
# It's a function and not a global variable to avoid taking up environment
# space in every shell: it's only evaluated when ec or its completion is
# called.
#
# NOTE: if you add a target here, ALSO add the name to the alias loop in
# conf.d/tools.fish, or `ec <name>` will work but `ec<name>` won't.
# (That's exactly what happened with matugen.)
function __ec_targets
    echo "swaync     $HOME/.config/swaync"
    echo "hypr       $HOME/.config/hypr"
    echo "waybar     $HOME/.config/waybar"
    echo "fish       $HOME/.config/fish"
    echo "kitty      $HOME/.config/kitty"
    echo "hyprlock   $HOME/.config/hyprlock"
    echo "rofi       $HOME/.config/rofi"
    echo "wlogout    $HOME/.config/wlogout"
    echo "cava       $HOME/.config/cava"
    echo "fastfetch  $HOME/.config/fastfetch"
    echo "matugen    $HOME/.config/matugen"
    # starship is edited in the template + the static one, never in the
    # generated ~/.config/starship.toml, which matugen overwrites on every
    # wallpaper change.
    echo "starship   $HOME/.config/matugen/templates/starship.toml $HOME/.config/starship.static.toml"
end

function __ec_names
    __ec_targets | while read -l line
        echo (string split -f1 " " -- (string replace -ra ' +' ' ' -- $line))
    end
end

function ec --description "Open a config in the editor (ec <TAB> for the list)"
    set -l editor codium
    set -q EC_EDITOR; and set editor $EC_EDITOR

    if test (count $argv) -eq 0
        set_color brwhite; echo "ec — open a config in the editor"; set_color normal
        echo ""
        printf "  %s\n" (__ec_names | string join " ")
        echo ""
        set_color brblack; echo "  usage: ec <name>   ·   editor: $editor (override: \$EC_EDITOR)"; set_color normal
        return 1
    end

    if not command -q $editor
        set_color red; echo "ec: '$editor' not found"; set_color normal
        return 127
    end

    set -l paths
    for name in $argv
        set -l row (__ec_targets | string match -r "^$name\s.*")
        if test -z "$row"
            set_color red; echo "ec: unknown target '$name'"; set_color normal
            set_color brblack; echo "    available: "(__ec_names | string join " "); set_color normal
            return 1
        end
        set -l fields (string split -n " " -- (string replace -ra ' +' ' ' -- $row))
        set -a paths $fields[2..]
    end

    for p in $paths
        if not test -e "$p"
            set_color yellow; echo "ec: warning, $p doesn't exist"; set_color normal
        end
    end

    # Same behavior as the old aliases: "&& pkill kitty" so the terminals
    # pick up the new theme. Note that this also kills the terminal you
    # called ec from — that's what ecswaync and friends already did, so it's
    # kept as-is.
    $editor $paths
    and pkill kitty
end
