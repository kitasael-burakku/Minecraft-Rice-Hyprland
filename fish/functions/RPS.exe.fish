# -----------------------------------
# RouletteRPS terminal launcher
# -----------------------------------

# ── Constantes globales del launcher ─────────────────────────────────────────

set -g __RPS_BOX_WIDTH 61          # ancho interior de la caja (entre los │)

# ── Helpers

function __rps_top
    set_color brblack
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    set_color normal
end

function __rps_mid
    set_color brblack
    echo "  ├─────────────────────────────────────────────────────────────┤"
    set_color normal
end

function __rps_bottom
    set_color brblack
    echo "  └─────────────────────────────────────────────────────────────┘"
    set_color normal
end

# __rps_raw: línea con texto ya coloreado/preformateado; solo añade bordes y padding
function __rps_raw
    set -l text $argv[1]
    set -l w $__RPS_BOX_WIDTH

    set -l len (string length --visible "$text")
    set -l pad (math "max(0, $w - $len)")

    set_color brblack
    printf "  │"
    printf "%s" "$text"
    printf "%*s" $pad ""
    printf "│\n"
    set_color normal
end

# __rps_empty: fila vacía dentro de la caja
function __rps_empty
    set_color brblack
    printf "  │%*s│\n" $__RPS_BOX_WIDTH ""
    set_color normal
end

# __rps_box_text: texto centrado con color, dentro de la caja
function __rps_box_text
    set -l color $argv[1]
    set -l text  $argv[2]
    set -l w     $__RPS_BOX_WIDTH

    set -l len   (string length --visible "$text")

    # Si el texto es más ancho que la caja, truncarlo con ellipsis
    if test $len -gt $w
        set text (string shorten --max $w --char "…" "$text")
        set len  (math "$w")
    end

    set -l left  (math "max(0, floor(($w - $len) / 2))")
    set -l right (math "max(0, $w - $len - $left)")

    set_color brblack; printf "  │"
    printf "%*s" $left ""
    set_color $color;  printf "%s" "$text"
    set_color brblack; printf "%*s" $right ""
    printf "│\n"
    set_color normal
end

# __rps_section: header de sección — cierra la caja anterior si la hay
function __rps_section
    set -l title $argv[1]
    echo ""
    __rps_top
    __rps_box_text cyan "$title"
    __rps_mid
end

# __rps_hint: fila de sugerencia dentro de la caja
# Layout interno: "  " (2) + "hint  " (6) + text (inner) + │
# inner = box_width - 2 - 6 = box_width - 8
function __rps_hint
    set -l text  $argv[1]
    set -l inner (math "$__RPS_BOX_WIDTH - 8")  # 2 spaces + "hint  " (6) = 8

    set text (string shorten --max $inner --char "…" "$text")

    set_color brblack; printf "  │  "
    set_color cyan;    printf "hint  "
    set_color brblack; printf "%-*s│\n" $inner "$text"
    set_color normal
end

# __rps_tag: fila de estado "✓/✗ label │ value"
# Layout interior (61): " "(1) + mark(1) + "  "(2) + label(15) + " │ "(3) + value(39) = 61
# value_w = BOX - 1 - 1 - 2 - label_w - 3 = BOX - label_w - 7
function __rps_tag
    set -l label $argv[1]
    set -l value $argv[2]
    set -l ok    $argv[3]

    set -l label_w 15
    set -l value_w (math "$__RPS_BOX_WIDTH - $label_w - 7")  # 1+mark(1)+"  "(2)+" │ "(3) = 7

    set value (string replace "$HOME" "~" "$value")
    set value (string shorten --max $value_w --char "…" "$value")

    set_color brblack; printf "  │ "

    if test "$ok" = ok
        set_color green;   printf "✓"
    else
        set_color red;     printf "✗"
    end

    set_color brblack; printf "  "
    set_color brwhite; printf "%-*s" $label_w "$label"
    set_color brblack; printf " │ "

    if test "$ok" = ok
        set_color white
    else
        set_color red
    end

    printf "%-*s" $value_w "$value"
    set_color brblack; printf "│\n"
    set_color normal
end

# __rps_bar: barra de progreso animada
# Uso: __rps_bar "label" [steps] [delay]
function __rps_bar
    set -l label $argv[1]
    set -l steps (if set -q argv[2]; echo $argv[2]; else; echo 20; end)
    set -l delay (if set -q argv[3]; echo $argv[3]; else; echo 0.018; end)

    # Layout interno (entre los dos │):
    # " "(1) + label(18) + " ["(2) + steps + "] "(2) + "OK"(2) + after_w = BOX
    # after_w = BOX - 1 - 18 - 2 - steps - 2 - 2 = BOX - 25 - steps
    set -l label_w 18
    set -l after_w (math "max(0, $__RPS_BOX_WIDTH - 25 - $steps)")

    set_color brblack; printf "  │ "
    set_color brwhite; printf "%-*s" $label_w "$label"
    set_color brblack; printf " ["

    for i in (seq 1 $steps)
        sleep $delay
        set_color cyan; printf "▪"
    end

    set_color brblack; printf "] "
    set_color green;   printf "OK"
    set_color brblack; printf "%*s│\n" (math "max(0, $after_w)") ""
    set_color normal
end

# ── Función principal ─────────────────────────────────────────────────────────

function RPS.exe
    clear

    set -l game_dir    "$HOME/Projects/ProjectRPS"
    set -l entry_file  "main.py"
    set -l rps_version "v0.2.0"
    set -l rps_build   "071"
    set -l rps_stage   "ALPHA"

    # ── Splash ───────────────────────────────────────────────────────────────

    echo ""
    __rps_top
    __rps_empty

    __rps_box_text white "██████╗ ██████╗ ███████╗   ███████╗██╗  ██╗███████╗"
    __rps_box_text white "██╔══██╗██╔══██╗██╔════╝   ██╔════╝╚██╗██╔╝██╔════╝"
    __rps_box_text white "██████╔╝██████╔╝███████╗   █████╗   ╚███╔╝ █████╗  "
    __rps_box_text white "██╔══██╗██╔═══╝ ╚════██║   ██╔══╝   ██╔██╗ ██╔══╝  "
    __rps_box_text white "██║  ██║██║     ███████║██╗███████╗██╔╝ ██╗███████╗"
    __rps_box_text white "╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝"

    __rps_empty
    __rps_box_text cyan "R O C K  ·  P A P E R  ·  S C I S S O R S"
    __rps_box_text brblack "Roulette Edition"
    __rps_empty
    __rps_mid

    # Fila de metadatos: version | build | stage
    # Layout interior (61 chars total):
    #  " "(1) + "ver "(4) + ver(10) + " │ "(3) + "build "(6) + build(7) + " │ "(3) + "stage "(6) + stage(21) = 61
    set_color brblack; printf "  │ "
    set_color brwhite; printf "ver "; set_color white;    printf "%-10s" "$rps_version"
    set_color brblack; printf " │ "
    set_color brwhite; printf "build "; set_color cyan;   printf "%-7s" "#$rps_build"
    set_color brblack; printf " │ "
    set_color brwhite; printf "stage "; set_color yellow; printf "%-21s" "$rps_stage"
    set_color brblack; printf "│\n"
    set_color normal

    __rps_bottom

    sleep 0.3

    # ── System check ─────────────────────────────────────────────────────────

    __rps_section "SYSTEM CHECK"

    sleep 0.08

    # Directorio del proyecto
    if test -d "$game_dir"
        __rps_tag "PROJECT DIR" "$game_dir" ok
    else
        __rps_tag "PROJECT DIR" "not found" fail
        __rps_hint "expected: ~/Projects/ProjectRPS"
        __rps_bottom
        set_color red; echo ""; echo "  [FAIL]  $game_dir not found"; set_color normal
        return 1
    end

    sleep 0.06

    # Cambio de directorio
    if not cd "$game_dir" 2>/dev/null
        __rps_tag "CHDIR" "permission denied" fail
        __rps_hint "check: ls -la ~/Projects"
        __rps_bottom
        return 1
    end

    set -l nice_pwd (string replace "$HOME" "~" (pwd))
    __rps_tag "WORKING DIR" "$nice_pwd" ok

    sleep 0.06

    # Entry point
    if test -f "$entry_file"
        __rps_tag "ENTRY POINT" "$entry_file" ok
    else
        __rps_tag "ENTRY POINT" "missing" fail
        __rps_hint "expected: $game_dir/main.py"
        __rps_bottom
        set_color red; echo ""; echo "  [FAIL]  $game_dir/$entry_file not found"; set_color normal
        cd "$HOME"; return 1
    end

    sleep 0.06

    # Runtime Python
    if command -q python3
        set -l pyver (python3 --version 2>/dev/null)
        __rps_tag "RUNTIME" "$pyver" ok
    else
        __rps_tag "RUNTIME" "python3 not found" fail
        __rps_hint "install: sudo pacman -S python"
        __rps_bottom
        cd "$HOME"; return 1
    end

    __rps_bottom

    sleep 0.2

    # ── Loading sequence ──────────────────────────────────────────────────────

    __rps_section "LOADING"

    __rps_bar "rules"
    __rps_bar "roulette chamber"
    __rps_bar "debt engine"
    __rps_bar "game assets"

    __rps_bottom

    sleep 0.15

    # ── Launch ────────────────────────────────────────────────────────────────

    echo ""
    __rps_top
    __rps_empty
    __rps_box_text yellow "> LAUNCHING RPS.EXE..."
    __rps_empty
    __rps_bottom
    echo ""

    sleep 0.5

    python3 "$entry_file"
    set -l exit_code $status

    cd "$HOME"

    # ── Exit report ───────────────────────────────────────────────────────────

    echo ""
    __rps_top
    __rps_empty

    switch $exit_code
        case 0
            __rps_box_text green  "SESSION ENDED CLEANLY"
            __rps_box_text brblack "exit code · $exit_code"

        case 1
            __rps_box_text red    "RUNTIME ERROR"
            __rps_box_text brblack "exit code · $exit_code"
            __rps_empty
            __rps_mid
            __rps_hint "check traceback or main.py"

        case 2
            __rps_box_text red    "BAD ARGUMENTS"
            __rps_box_text brblack "exit code · $exit_code"
            __rps_empty
            __rps_mid
            __rps_hint "check launch arguments"

        case 130
            __rps_box_text cyan   "INTERRUPTED BY USER"
            __rps_box_text brblack "Ctrl+C · exit code · $exit_code"

        case '*'
            __rps_box_text red    "EXITED WITH UNKNOWN ERROR"
            __rps_box_text brblack "exit code · $exit_code"
            __rps_empty
            __rps_mid
            __rps_hint "check terminal output above"
    end

    __rps_empty
    __rps_bottom
    echo ""

    return $exit_code
end