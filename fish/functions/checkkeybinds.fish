# checkkeybinds — used to be a best-effort drift checker (substring matching
# between hl.bind(...) and KEYBINDS.txt, with false negatives accepted on
# purpose). Replaced by hypr/scripts/generate-keybinds-doc.sh, which
# generates KEYBINDS.txt DIRECTLY from keybinds.lua (reading the "-- "
# comment above each bind as its description) — there can be no drift
# because there aren't two sources of truth, only one that regenerates.

# This function is now a thin wrapper: --check (writes nothing, just warns
# if regeneration is needed) by default, and actually regenerates with
# `checkkeybinds --write` or `checkkeybinds --apply`.
function checkkeybinds --description "Regenerate/verify KEYBINDS.txt from keybinds.lua"
    set -l gen "$HOME/.config/hypr/scripts/generate-keybinds-doc.sh"

    if not test -x "$gen"
        _rui_bad "$gen not found"
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
        _rui_ok "KEYBINDS.txt regenerated."
    else
        if bash "$gen" --check
            _rui_ok "KEYBINDS.txt is up to date with keybinds.lua."
        else
            _rui_warn "KEYBINDS.txt is outdated — run 'checkkeybinds --write' to regenerate it."
        end
    end

    echo ""
end
