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
    if contains -- $argv[1] -h --help
        echo "checkkeybinds — regenerate or verify KEYBINDS.txt from keybinds.lua"
        echo "Usage: checkkeybinds [--write|--apply]"
        echo "  no flag   verify only, writes nothing"
        echo "  --write   regenerate KEYBINDS.txt (--apply is a synonym)"
        return 0
    end

    for arg in $argv
        if not contains -- $arg --write --apply
            _rui_bad "checkkeybinds: unknown argument '$arg'"
            _rui_none "usage: checkkeybinds [--write|--apply]"
            return 2
        end
    end

    set -l gen "$HOME/.config/hypr/scripts/generate-keybinds-doc.sh"

    if not test -x "$gen"
        _rui_bad "Generator not found or not executable: $gen"
        return 127
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
        # The generator's exit status used to be discarded, so a failed
        # regeneration still printed "✓ KEYBINDS.txt regenerated." and
        # returned 0 — the report claimed a state it had not verified.
        bash "$gen"
        set -l rc $status
        echo ""
        if test $rc -eq 0
            _rui_verdict ok "KEYBINDS.txt regenerated."
            return 0
        end
        _rui_verdict bad "Regeneration failed (exit $rc) — KEYBINDS.txt left untouched."
        return 20
    end

    # --check writes nothing: 0 means the doc matches keybinds.lua, non-zero
    # means it is stale. A missing/unreadable keybinds.lua also lands here,
    # which is why the message says "outdated or unreadable" rather than
    # asserting the file is merely stale.
    if bash "$gen" --check >/dev/null 2>&1
        _rui_verdict ok "KEYBINDS.txt is up to date with keybinds.lua."
        return 0
    end

    _rui_verdict warn "KEYBINDS.txt is outdated or unreadable — run 'checkkeybinds --write'."
    return 10
end
