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
    if set -q EC_EDITOR; and test -n "$EC_EDITOR"
        set editor $EC_EDITOR
    end

    # -h/--help is the same listing as the no-argument form, but asking for it
    # deliberately is a success, not the usage error that a bare `ec` reports.
    if contains -- $argv[1] -h --help
        set_color brwhite; echo "ec — open a config in the editor"; set_color normal
        echo ""
        printf "  %s\n" (__ec_names | string join " ")
        echo ""
        set_color brblack; echo "  usage: ec <name>   ·   editor: $editor (override: \$EC_EDITOR)"; set_color normal
        return 0
    end

    if test (count $argv) -eq 0
        set_color brwhite; echo "ec — open a config in the editor"; set_color normal
        echo ""
        printf "  %s\n" (__ec_names | string join " ")
        echo ""
        set_color brblack; echo "  usage: ec <name>   ·   editor: $editor (override: \$EC_EDITOR)"; set_color normal
        return 2
    end

    if not command -q $editor
        set_color red; echo "ec: '$editor' not found"; set_color normal
        return 127
    end

    set -l paths
    for name in $argv
        # $name used to be interpolated straight into a regex, so a target
        # containing a regex metacharacter (".", "+", "[") matched the wrong
        # row or nothing at all. Compare the parsed first field literally
        # instead — no pattern language involved.
        set -l row ""
        for line in (__ec_targets)
            set -l fields (string split -n " " -- (string replace -ra ' +' ' ' -- $line))
            if test (count $fields) -ge 2; and test "$fields[1]" = "$name"
                set row $line
                break
            end
        end
        if test -z "$row"
            set_color red; echo "ec: unknown target '$name'"; set_color normal
            set_color brblack; echo "    available: "(__ec_names | string join " "); set_color normal
            return 2
        end
        set -l fields (string split -n " " -- (string replace -ra ' +' ' ' -- $row))
        set -a paths $fields[2..]
    end

    for p in $paths
        if not test -e "$p"
            set_color yellow; echo "ec: warning, $p doesn't exist"; set_color normal
        end
    end

    # Same behavior as the old aliases.
    $editor $paths
    set -l rc $status

    # "&& pkill kitty" so the terminals pick up the new theme. Note that this
    # also kills the terminal you called ec from — that's what ecswaync and
    # friends already did, so it's kept as-is. pkill's own status (1 when it
    # matched nothing) must not become ec's result, hence the capture above.
    if test $rc -eq 0
        pkill kitty
    end
    return $rc
end
