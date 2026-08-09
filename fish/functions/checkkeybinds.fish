# checkkeybinds — antes era un verificador de drift best-effort (matcheo de
# substrings entre hl.bind(...) y KEYBINDS.txt, con falsos negativos
# aceptados a propósito). Reemplazado por
# hypr/scripts/generate-keybinds-doc.sh, que genera KEYBINDS.txt
# DIRECTAMENTE desde keybinds.lua (leyendo el comentario "-- " de arriba de
# cada bind como descripción) — no puede haber drift porque no hay dos
# fuentes de verdad, sólo una que se regenera.

# Esta función ahora es un wrapper fino: --check (no escribe nada, sólo
# avisa si haría falta regenerar) por defecto, y regenera de verdad con
# `checkkeybinds --write` o `checkkeybinds --apply`.
function checkkeybinds --description "Regenerar/verificar KEYBINDS.txt desde keybinds.lua"
    set -l gen "$HOME/.config/hypr/scripts/generate-keybinds-doc.sh"

    if not test -x "$gen"
        _rui_bad "No se encontró $gen"
        return 1
    end

    clear
    set -l W 52

    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰌌  Keybinds Doc"
    _rui_mid $W
    _rui_row $W brblack "generate-keybinds-doc.sh — Source: keybinds.lua"
    _rui_bot $W
    echo ""

    if contains -- --write $argv; or contains -- --apply $argv
        bash "$gen"
        echo ""
        _rui_ok "KEYBINDS.txt regenerado."
    else
        if bash "$gen" --check
            _rui_ok "KEYBINDS.txt está al día con keybinds.lua."
        else
            _rui_warn "KEYBINDS.txt desactualizado — corré 'checkkeybinds --write' para regenerarlo."
        end
    end

    echo ""
end
