# ~/.config/fish/conf.d/report-ui.fish
# Helpers de dibujo compartidos por los "reportes" de terminal:
# healthcheck, checkerrors, checktrash, cleantrash, quickcache, sysupdate.
#
# Antes cada script tenía su propia copia casi idéntica de estas funciones
# (con prefijos __ce_/__ctr_/__ct_/__hc_/__qc_/__su_ solo para no chocar
# entre sí). Como las funciones de fish son globales, un solo juego alcanza.
#
# Colores: nombres ANSI, nunca hex. Los resuelve la terminal, así que los
# reportes siguen la paleta de kitty — que matugen ya regenera con el
# wallpaper — en vez de quedar congelados en una paleta propia. Es lo que ya
# hacía RPS.exe.fish. Convención en uso:
#   brblack = bordes y texto atenuado   brwhite = títulos y valores
#   green   = ok      yellow = aviso    red = error
#   cyan    = sección informativa       magenta = sección AUR/yay

function _rui_top -a w
    set_color brblack
    printf "  ┌"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┐\n"
    set_color normal
end

function _rui_mid -a w
    set_color brblack
    printf "  ├"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┤\n"
    set_color normal
end

function _rui_bot -a w
    set_color brblack
    printf "  └"; for i in (seq 1 (math "$w - 2")); printf "─"; end; printf "┘\n"
    set_color normal
end

function _rui_row -a w color text
    set -l inner (math "$w - 2")
    set -l len (string length --visible "$text")
    set -l left (math "max(0, floor(($inner - $len) / 2))")
    set -l right (math "max(0, $inner - $len - $left)")
    set_color brblack; printf "  │"; printf "%*s" $left ""
    set_color $color; printf "%s" "$text"
    set_color brblack; printf "%*s│\n" $right ""
    set_color normal
end

# Encabezado de sección con divisor debajo (checkerrors/checktrash/healthcheck)
function _rui_section -a color icon text
    echo ""
    set_color $color
    printf "  ── %s %s\n" "$icon" "$text"
    set_color brblack
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
    set_color brblack; printf "  %-*s" $width "$label"
    set_color brwhite; echo "$value"
    set_color normal
end

# Confirmación [y/N]. Devuelve 0 solo con "y"/"Y"; cualquier otra cosa
# (incluido Enter vacío y Ctrl+D) es "no".
#
# Antes cleantrash, quickcache y sysupdate repetían cada uno el read -p entero
# y encima con tres idiomas distintos para el mismo chequeo: dos con
# `!= y -a != Y` y uno con `not test = y -o = Y`.
#
# El prompt va por --prompt-str en vez del `read -p '<código fish>'` de antes:
# ese -p evaluaba una cadena de código en cada llamada, acá alcanza con pasar
# el texto ya coloreado.
function _rui_confirm -a text
    set -l label "  $text [y/N] > "
    set -l prompt (set_color yellow)"$label"(set_color normal)

    read --prompt-str="$prompt" -l reply
    or return 1

    string match -qr '^[yY]$' -- (string trim -- "$reply")
end

function _rui_ok -a text
    set_color green; echo "  ✓ $text"; set_color normal
end

function _rui_warn -a text
    set_color yellow; echo "  ⚠ $text"; set_color normal
end

function _rui_bad -a text
    set_color red; echo "  ✘ $text"; set_color normal
end

function _rui_none -a text
    set_color brblack; echo "  · $text"; set_color normal
end

# _rui_skip era una copia byte a byte de _rui_none. Se mantiene el nombre
# porque cleantrash/quickcache lo usan y "skip" se lee mejor ahí.
function _rui_skip -a text
    _rui_none $text
end
