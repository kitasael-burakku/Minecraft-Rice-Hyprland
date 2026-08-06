function __keybinds_viewer --description "Interactive Hyprland keybinds viewer"
    clear

    set -l doc $argv[1]

    if test -z "$doc"
        if test -f "$HOME/Documents/KEYBINDS.txt"
            set doc "$HOME/Documents/KEYBINDS.txt"
        else if test -f "$HOME/Projects/dotfiles/KEYBINDS.txt"
            set doc "$HOME/Projects/dotfiles/KEYBINDS.txt"
        else
            set doc "$HOME/Documents/KEYBINDS.txt"
        end
    end

    if not test -f "$doc"
        set_color red
        echo "KEYBINDS.txt not found: $doc"
        set_color normal
        echo "Usage: keybinds /path/to/KEYBINDS.txt"
        return 1
    end

    # ── Color palette ──────────────────────────────────────────────────────
    # Nombres ANSI, igual que report-ui.fish: los resuelve la terminal, así que
    # el visor sigue la paleta de kitty (que matugen regenera con el wallpaper)
    # en vez de traer la suya congelada.
    #
    # Antes esto era un if sobre $COLORTERM con una rama hex y otra ANSI. Se
    # fue: la detección es frágil ($COLORTERM suele venir vacío por SSH/tmux
    # aunque la terminal sí soporte 24 bits) y en esta máquina la rama de
    # fallback no se ejecutaba nunca, o sea que estaba sin probar. Un solo
    # camino, el que anda en todas partes.
    set -g __kb_border  brblack
    set -g __kb_muted   brblack
    set -g __kb_accent  cyan
    set -g __kb_section yellow
    set -g __kb_key     brwhite
    set -g __kb_desc    white
    set -g __kb_error   red


    # ── Settings ─────────────────────────────────────────────────────────────
    set -l width 74
    set -l page 1

    set -l sections (awk '
        /^[A-Z0-9 \/]+[[:space:]]*$/ { title=$0; next }
        /^-+[[:space:]]*$/ && title != "" {
            gsub(/[[:space:]]+$/, "", title)
            print title
            title=""
        }
    ' "$doc")

    set -l total (count $sections)

    if test $total -eq 0
        set_color $__kb_error
        echo "No sections found in: $doc"
        set_color normal
        return 1
    end

    # ── Input without bullets ────────────────────────────────────────────────

    # Estado del tty tal como estaba antes de entrar al visor. __kb_getch pone
    # la terminal en raw mode y la restaura al salir, pero si cortás con Ctrl+C
    # justo en el medio ese restore nunca corre y te quedás sin echo ni line
    # editing. El handler de abajo usa esta copia para dejarla como estaba.
    set -g __kb_saved_tty (stty -g 2>/dev/null)

    function __kb_on_int --on-signal INT
        test -n "$__kb_saved_tty"; and stty $__kb_saved_tty 2>/dev/null
        __keybinds_restore_window
        __keybinds_cleanup
        echo ""
    end

    function __kb_getch
        set -l old_tty (stty -g)
        stty -echo -icanon min 1 time 0
        set -l ch (dd bs=1 count=1 2>/dev/null)
        stty $old_tty
        echo "$ch"
    end

    # ── Box helpers ──────────────────────────────────────────────────────────

    function __kb_line -a width
        set_color $__kb_border
        printf "  ┌"
        for i in (seq 1 (math "$width - 2"))
            printf "─"
        end
        printf "┐\n"
        set_color normal
    end

    function __kb_mid -a width
        set_color $__kb_border
        printf "  ├"
        for i in (seq 1 (math "$width - 2"))
            printf "─"
        end
        printf "┤\n"
        set_color normal
    end

    function __kb_bottom -a width
        set_color $__kb_border
        printf "  └"
        for i in (seq 1 (math "$width - 2"))
            printf "─"
        end
        printf "┘\n"
        set_color normal
    end

    function __kb_raw -a width text
        set -l inner (math "$width - 2")
        set text (string shorten --max $inner --char "…" -- "$text")
        set -l len (string length --visible "$text")
        set -l pad (math "max(0, $inner - $len)")

        set_color $__kb_border
        printf "  │"
        printf "%s" "$text"
        printf "%*s" $pad ""
        printf "│\n"
        set_color normal
    end

    function __kb_text -a width color text
        set -l inner (math "$width - 2")
        set text (string shorten --max $inner --char "…" -- "$text")
        set -l len (string length --visible "$text")
        set -l left (math "max(0, floor(($inner - $len) / 2))")
        set -l right (math "max(0, $inner - $len - $left)")

        set_color $__kb_border
        printf "  │"
        printf "%*s" $left ""
        set_color $color
        printf "%s" "$text"
        set_color $__kb_border
        printf "%*s" $right ""
        printf "│\n"
        set_color normal
    end

    function __kb_pair -a width key desc
        set -l inner (math "$width - 2")
        set -l key_width 25
        set -l desc_width (math "$inner - $key_width - 7")

        set key (string shorten --max $key_width --char "…" -- "$key")
        set desc (string shorten --max $desc_width --char "…" -- "$desc")

        set_color $__kb_border
        printf "  │  "
        set_color $__kb_key
        printf "%-25s" "$key"
        set_color $__kb_border
        printf "  →  "
        set_color $__kb_desc
        printf "%-*s" $desc_width "$desc"
        set_color $__kb_border
        printf "│\n"
        set_color normal
    end

    function __kb_hint -a width
        set -l inner (math "$width - 2")
        set -l label "  h/k prev   j/l next   :<space> search   q quit"
        set -l len (string length -- "$label")
        set -l pad (math "max(0, $inner - $len)")

        set_color $__kb_border
        printf "  │  "

        set_color $__kb_accent
        printf "h/k"
        set_color $__kb_muted
        printf " prev   "

        set_color $__kb_accent
        printf "j/l"
        set_color $__kb_muted
        printf " next   "

        set_color $__kb_accent
        printf ":<space>"
        set_color $__kb_muted
        printf " search   "

        set_color $__kb_accent
        printf "q"
        set_color $__kb_muted
        printf " quit"

        set_color $__kb_border
        printf "%*s│\n" $pad ""
        set_color normal
    end

    # ── Document parsing ─────────────────────────────────────────────────────

    function __kb_entries -a doc section
        awk -v target="$section" '
            /^[A-Z0-9 \/]+[[:space:]]*$/ { candidate=$0; next }

            /^-+[[:space:]]*$/ && candidate != "" {
                if (insec) exit

                title=candidate
                gsub(/[[:space:]]+$/, "", title)

                insec=(title == target)
                candidate=""
                next
            }

            insec {
                if ($0 !~ /^[[:space:]]*$/) print
            }
        ' "$doc"
    end

    # ── Draw normal page ─────────────────────────────────────────────────────

    function __kb_draw -a doc width page total
        set -l sections $argv[5..-1]
        set -l section $sections[$page]

        clear
        echo ""

        __kb_line $width
        __kb_text $width $__kb_accent "KEYBINDS"
        __kb_text $width $__kb_muted "Hyprland Control Manual"
        __kb_mid $width
        __kb_raw $width "  Page  : $page / $total"
        __kb_raw $width "  Mod   : SUPER (Tecla Windows/Options)"
        __kb_mid $width
        __kb_text $width $__kb_section "$section"
        __kb_mid $width

        set -l found 0

        for line in (__kb_entries "$doc" "$section")
            set found 1

            if string match -qr '\s{2,}' -- "$line"
                set -l key (string replace -r '\s{2,}.*$' '' -- "$line")
                set -l desc (string replace -r '^.*?\s{2,}' '' -- "$line")
                __kb_pair $width "$key" "$desc"
            else
                __kb_raw $width "  $line"
            end
        end

        if test $found -eq 0
            __kb_text $width $__kb_muted "No entries found"
        end

        __kb_mid $width
        __kb_hint $width
        __kb_bottom $width
    end

    # ── Search mode ──────────────────────────────────────────────────────────

    function __kb_search -a doc width query
        set query (string trim -- "$query")
        set query (string replace -r '^:' '' -- "$query")
        set query (string trim -- "$query")

        clear
        echo ""

        __kb_line $width
        __kb_text $width $__kb_accent "KEYBINDS"
        __kb_text $width $__kb_muted "Search Results"
        __kb_mid $width
        __kb_raw $width "  Query : $query"
        __kb_mid $width

        set -l current_section ""
        set -l found 0
        set -l count 0

        while read -l line
            if string match -qr '^[A-Z0-9 /]+[[:space:]]*$' -- "$line"
                set current_section (string trim -- "$line")
                continue
            end

            if string match -qr '^-+[[:space:]]*$' -- "$line"
                continue
            end

            if test -z (string trim -- "$line")
                continue
            end

            if string match -qi "*$query*" -- "$line"
                set found 1
                set count (math "$count + 1")

                __kb_text $width $__kb_section "$current_section"

                if string match -qr '\s{2,}' -- "$line"
                    set -l key (string replace -r '\s{2,}.*$' '' -- "$line")
                    set -l desc (string replace -r '^.*?\s{2,}' '' -- "$line")
                    __kb_pair $width "$key" "$desc"
                else
                    __kb_raw $width "  $line"
                end

                __kb_mid $width
            end
        end < "$doc"

        if test $found -eq 0
            __kb_text $width $__kb_error "No results found"
        else
            __kb_raw $width "  $count match(es)"
        end

        __kb_mid $width
        __kb_raw $width "  Press h/j/k/l/q to return"
        __kb_bottom $width

        while true
            set -l key (__kb_getch)

            switch "$key"
                case h j k l q
                    break
            end
        end
    end

    # ── Search prompt ────────────────────────────────────────────────────────

    function __kb_search_prompt
        set -g __kb_query ""

        echo ""
        printf "  : " > /dev/tty

        read -l query

        set query (string trim -- "$query")
        set query (string replace -r '^:' '' -- "$query")
        set query (string trim -- "$query")

        set -g __kb_query "$query"
    end

    # ── Key reader ───────────────────────────────────────────────────────────

    function __kb_read_key
        set -l key (__kb_getch)

        switch "$key"
            case h k
                echo prev

            case j l
                echo next

            case q
                echo quit

            case ':'
                set -l cmd (__kb_getch)

                if test "$cmd" = " "
                    echo search
                else
                    echo none
                end

            case '*'
                echo none
        end
    end

    # ── Main loop ──────────────────────────────────────────────────────────────

    while true
        __kb_draw "$doc" $width $page $total $sections

        set -l action (__kb_read_key)

        switch "$action"
            case next
                if test $page -lt $total
                    set page (math "$page + 1")
                else
                    set page 1
                end

            case prev
                if test $page -gt 1
                    set page (math "$page - 1")
                else
                    set page $total
                end

            case search
                __kb_search_prompt

                if test -n "$__kb_query"
                    __kb_search "$doc" $width "$__kb_query"
                end

            case quit
                clear
                return 0
        end
    end
end

# ─────────────────────────────────────────────────────────────────────────────
# Floating current-terminal wrapper
# ─────────────────────────────────────────────────────────────────────────────

function __keybinds_prepare_window
    command -q hyprctl; or return 0
    command -q jq; or return 0

    # Antes esto iba a /dev/null: un error de Lua acá quedaba invisible para
    # siempre (mismo criterio que el fix de rofi/scripts/window-switcher.sh).
    set -l runtime_dir /tmp
    set -q XDG_RUNTIME_DIR; and set runtime_dir "$XDG_RUNTIME_DIR"
    set -l log "$runtime_dir/keybinds-float.log"

    # Floating window size — keep in sync with the centring maths below.
    set -l win_w 590
    set -l win_h 1000

    set -g __kb_window_addr (hyprctl activewindow -j | jq -r '.address')
    set -g __kb_was_floating (hyprctl activewindow -j | jq -r '.floating')

    if test -z "$__kb_window_addr" -o "$__kb_window_addr" = "null"
        return 0
    end

    hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'set', window = 'address:$__kb_window_addr' }))" >>"$log" 2>&1
    hyprctl eval "hl.dispatch(hl.dsp.window.resize({ x = $win_w, y = $win_h, window = 'address:$__kb_window_addr' }))" >>"$log" 2>&1

    set -l mon (hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height)"' | head -n 1)

    if test -n "$mon"
        set -l mx (echo $mon | awk '{print $1}')
        set -l my (echo $mon | awk '{print $2}')
        set -l mw (echo $mon | awk '{print $3}')
        set -l mh (echo $mon | awk '{print $4}')

        set -l x (math "$mx + (($mw - $win_w) / 2)")
        set -l y (math "$my + (($mh - $win_h) / 2)")

        hyprctl eval "hl.dispatch(hl.dsp.window.move({ x = $x, y = $y, window = 'address:$__kb_window_addr' }))" >>"$log" 2>&1
    end
end

function __keybinds_restore_window
    command -q hyprctl; or return 0

    set -l runtime_dir /tmp
    set -q XDG_RUNTIME_DIR; and set runtime_dir "$XDG_RUNTIME_DIR"
    set -l log "$runtime_dir/keybinds-float.log"

    if test -z "$__kb_window_addr" -o "$__kb_window_addr" = "null"
        return 0
    end

    if test "$__kb_was_floating" = "false"
        # "toggle", no "off": en este punto la ventana está floating de
        # verdad (la forzamos con "set" en prepare_window), así que
        # alterna a tiled — mismo vocabulario que ya usa
        # hypr/modules/keybinds.lua para el mismo caso (set/toggle, no on/off).
        hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'toggle', window = 'address:$__kb_window_addr' }))" >>"$log" 2>&1
    end
end

# Fish no tiene scope real para funciones/variables anidadas — todo lo
# definido dentro de __keybinds_viewer/__keybinds_prepare_window queda
# global y persiste después de cerrar el visor. Se borra todo por nombre.
function __keybinds_cleanup
    # __kb_on_int va en la lista: si quedara colgado, el próximo Ctrl+C en una
    # shell normal dispararía el restore de una ventana que ya no existe.
    for fn in __kb_getch __kb_line __kb_mid __kb_bottom __kb_raw __kb_text __kb_pair __kb_hint __kb_entries __kb_draw __kb_search __kb_search_prompt __kb_read_key __kb_on_int
        functions -q $fn; and functions -e $fn
    end
    for v in __kb_border __kb_muted __kb_accent __kb_section __kb_key __kb_desc __kb_error __kb_query __kb_window_addr __kb_was_floating __kb_saved_tty
        set -e $v 2>/dev/null
    end
end

function keybinds --description "Open keybinds viewer in current terminal as floating window"
    if test "$argv[1]" = -h -o "$argv[1]" = --help
        echo "keybinds — interactive Hyprland keybinds viewer"
        echo ""
        echo "Usage: keybinds [/path/to/KEYBINDS.txt]"
        echo "  Defaults to ~/Documents/KEYBINDS.txt, then ~/Projects/dotfiles/KEYBINDS.txt"
        echo ""
        echo "Controls:  h/k prev   j/l next   :<space> search   q quit"
        return 0
    end

    clear
    __keybinds_prepare_window
    __keybinds_viewer $argv
    __keybinds_restore_window
    __keybinds_cleanup
end
