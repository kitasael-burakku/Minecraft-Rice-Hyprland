# checkkeybinds — verificador de drift entre hypr/modules/keybinds.lua y
# KEYBINDS.txt. dotbackup ya avisa cuando keybinds.lua cambió pero
# KEYBINDS.txt no (el caso "se borró un bind y quedó documentado de más") —
# esto cubre el caso contrario: un bind nuevo que nunca se documentó.
#
# Deliberadamente conservador: extrae el literal de tecla de cada
# hl.bind(...) del código fuente (no traduce modmasks de hyprctl binds -j,
# que sería más frágil) y chequea que aparezca en KEYBINDS.txt. Los binds
# dinámicos (el for de workspaces, "mainMod .. key") no tienen un literal
# fijo y se saltan a propósito — no hay nada que revisar ahí. Cero falsos
# positivos es la prioridad; algún falso negativo (un bind real que no
# matchea por nombre) es aceptable.
function checkkeybinds
    clear

    set -l W 52
    set -l lua_file "$HOME/.config/hypr/modules/keybinds.lua"
    set -l doc_file "$HOME/Documents/KEYBINDS.txt"

    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰌌  Keybinds Drift Check"
    _rui_mid $W
    _rui_row $W brblack "keybinds.lua vs KEYBINDS.txt"
    _rui_bot $W
    echo ""

    if not test -f "$lua_file"
        _rui_bad "No se encontró $lua_file"
        return 1
    end
    if not test -f "$doc_file"
        _rui_bad "No se encontró $doc_file"
        return 1
    end

    _rui_section cyan "󰌌" "Binds sin documentar (posibles)"

    # Alias de nombres crudos de Hyprland -> texto amigable que ya usa
    # KEYBINDS.txt. Sin esto, RETURN/XF86Audio*/mouse:* siempre saldrían
    # como "no encontrados" aunque SÍ estén documentados, solo que con otro
    # nombre — puro ruido.
    set -l alias_keys RETURN XF86AudioRaiseVolume XF86AudioLowerVolume XF86AudioMute XF86AudioNext XF86AudioPause XF86AudioPlay XF86AudioPrev "mouse:272" "mouse:273" mouse_down mouse_up
    set -l alias_vals Enter "Volume +" "Volume -" Mute Next "Play/Pause" "Play/Pause" Previous "Left click" "Right click" "Scroll down" "Scroll up"

    set -l found 0
    set -l missing 0

    for raw in (grep -oP 'hl\.bind\(\s*\K[^,]+' "$lua_file")
        # Saltar binds dinámicos (el for de workspaces: ".. key", no un
        # literal fijo que se pueda chequear).
        if echo "$raw" | grep -qP '\.\.\s*\w+\s*$'
            continue
        end

        set -l key (echo "$raw" | grep -oP '"[^"]*"' | tr -d '"' | string join '')
        set -l last (string trim (string replace -r '^.*\+' '' -- "$key"))
        test -n "$last"; or continue

        set -l lookup "$last"
        set -l idx (contains -i -- "$last" $alias_keys)
        if test -n "$idx"
            set lookup $alias_vals[$idx]
        end

        if grep -qiF -- "$lookup" "$doc_file"
            set found (math $found + 1)
        else
            _rui_warn "Bind sin documentar: $last  (hl.bind en keybinds.lua)"
            set missing (math $missing + 1)
        end
    end

    if test $missing -eq 0
        _rui_none "Ningún bind nuevo detectado — $found coinciden con KEYBINDS.txt."
    end

    echo ""
    _rui_section brblack "󰋼" "Nota"
    echo "  Chequeo conservador: algunos binds legítimos con nombres poco"
    echo "  comunes pueden no matchear por casualidad. Un aviso de arriba no"
    echo "  es necesariamente un error, es una señal a revisar a mano."

    echo ""
    set_color green; echo "  ✓ Chequeo completo."; set_color normal
    echo ""
end
