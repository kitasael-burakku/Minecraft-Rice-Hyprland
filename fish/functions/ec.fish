# ~/.config/fish/functions/ec.fish
# "edit config" — abre un config en el editor y recicla las terminales.
#
# Reemplaza las ~12 aliases ecswaync/echypr/ecwaybar/... que eran todas la
# misma línea con otra ruta. Los nombres viejos siguen existiendo como
# envoltorios en conf.d/tools.fish, así que la memoria muscular no se rompe.
# Agregar un config nuevo ahora es una línea en __ec_targets.

# Tabla nombre→ruta(s). Una entrada por línea, rutas separadas por espacios.
# Está en una función y no en una variable global para no ocupar entorno en
# cada shell: solo se evalúa cuando se llama a ec o a su completion.
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
    # starship se edita en la plantilla + el estático, nunca en el generado
    # ~/.config/starship.toml, que matugen pisa en cada cambio de wallpaper.
    echo "starship   $HOME/.config/matugen/templates/starship.toml $HOME/.config/starship.static.toml"
end

function __ec_names
    __ec_targets | while read -l line
        echo (string split -f1 " " -- (string replace -ra ' +' ' ' -- $line))
    end
end

function ec --description "Abrir un config en el editor (ec <TAB> para la lista)"
    set -l editor codium
    set -q EC_EDITOR; and set editor $EC_EDITOR

    if test (count $argv) -eq 0
        set_color brwhite; echo "ec — abrir un config en el editor"; set_color normal
        echo ""
        printf "  %s\n" (__ec_names | string join " ")
        echo ""
        set_color brblack; echo "  uso: ec <nombre>   ·   editor: $editor (override: \$EC_EDITOR)"; set_color normal
        return 1
    end

    if not command -q $editor
        set_color red; echo "ec: no se encontró '$editor'"; set_color normal
        return 127
    end

    set -l paths
    for name in $argv
        set -l row (__ec_targets | string match -r "^$name\s.*")
        if test -z "$row"
            set_color red; echo "ec: target desconocido '$name'"; set_color normal
            set_color brblack; echo "    disponibles: "(__ec_names | string join " "); set_color normal
            return 1
        end
        set -l fields (string split -n " " -- (string replace -ra ' +' ' ' -- $row))
        set -a paths $fields[2..]
    end

    for p in $paths
        if not test -e "$p"
            set_color yellow; echo "ec: aviso, no existe $p"; set_color normal
        end
    end

    # Mismo comportamiento que las aliases viejas: "&& pkill kitty" para que las
    # terminales levanten el tema nuevo. Ojo que esto también mata la terminal
    # desde la que llamaste a ec — es lo que ya hacía ecswaync y compañía, así
    # que se mantiene tal cual.
    $editor $paths
    and pkill kitty
end
