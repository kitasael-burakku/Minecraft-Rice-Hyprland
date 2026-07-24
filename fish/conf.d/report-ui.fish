# ~/.config/fish/conf.d/report-ui.fish
# Helpers de dibujo compartidos por los "reportes" de terminal:
# healthcheck, checkerrors, checktrash, cleantrash, quickcache, sysupdate.
#
# Antes cada script tenía su propia copia casi idéntica de estas funciones
# (con prefijos __ce_/__ctr_/__ct_/__hc_/__qc_/__su_ solo para no chocar
# entre sí). Como las funciones de fish son globales, un solo juego alcanza.

function _rui_top -a w
    set_color 909090
    printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
    set_color normal
end

function _rui_mid -a w
    set_color 909090
    printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
    set_color normal
end

function _rui_bot -a w
    set_color 909090
    printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
    set_color normal
end

function _rui_row -a w color text
    set -l inner (math "$w - 2")
    set -l len (string length --visible "$text")
    set -l left (math "max(0, floor(($inner - $len) / 2))")
    set -l right (math "max(0, $inner - $len - $left)")
    set_color 909090; printf "  │"; printf "%*s" $left ""
    set_color $color; printf "%s" "$text"
    set_color 909090; printf "%*s│\n" $right ""
    set_color normal
end

# Encabezado de sección con divisor debajo (checkerrors/checktrash/healthcheck)
function _rui_section -a color icon text
    echo ""
    set_color $color
    printf "  ── %s %s\n" "$icon" "$text"
    set_color 686058
    printf "  ──────────────────────────────────────────────────\n"
    set_color normal
end

# Encabezado de sección sin divisor (cleantrash/quickcache/sysupdate)
function _rui_section_plain -a color icon text
    echo ""
    set_color $color
    if test -n "$icon"
        printf "  ── %s %s\n" "$icon" "$text"
    else
        printf "  ── %s\n" "$text"
    end
    set_color normal
end

# Fila "label: valor" — tercer argumento opcional cambia el ancho del label (default 16)
function _rui_val -a label value
    set -l width 16
    if set -q argv[3]
        set width $argv[3]
    end
    set_color 686058; printf "  %-*s" $width "$label"
    set_color ffffff; echo "$value"
    set_color normal
end

function _rui_ok -a text
    set_color 6aab7a; echo "  ✓ $text"; set_color normal
end

function _rui_warn -a text
    set_color b89458; echo "  ⚠ $text"; set_color normal
end

function _rui_bad -a text
    set_color a85a48; echo "  ✘ $text"; set_color normal
end

function _rui_none -a text
    set_color 686058; echo "  · $text"; set_color normal
end

function _rui_skip -a text
    set_color 686058; echo "  · $text"; set_color normal
end
