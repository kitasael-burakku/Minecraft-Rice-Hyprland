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
    # True-color hex values. On terminals that report no 24-bit support we fall
    # back to named colors (cyan / yellow / white / red …) so the viewer still
    # looks right everywhere. Fish also approximates hex to the closest palette
    # color on its own, but the explicit fallback keeps things predictable.
    if test "$COLORTERM" = truecolor -o "$COLORTERM" = 24bit
        set -g __kb_border  ffffff   
        set -g __kb_muted   b4b4b3 
        set -g __kb_accent  ff4d4d  
        set -g __kb_section ff8080   
        set -g __kb_key     ffffff
        set -g __kb_desc    e0e0e0
        set -g __kb_error   ff0033
    else
        # Fallback estándar: Colores ANSI brillantes nativos
        set -g __kb_border  brblack
        set -g __kb_muted   brblack
        set -g __kb_accent  cyan
        set -g __kb_section magenta
        set -g __kb_key     white
        set -g __kb_desc    brwhite
        set -g __kb_error   red
    end
    
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

    # Floating window size — keep in sync with the centring maths below.
    set -l win_w 590
    set -l win_h 1000

    set -g __kb_window_addr (hyprctl activewindow -j | jq -r '.address')
    set -g __kb_was_floating (hyprctl activewindow -j | jq -r '.floating')

    if test -z "$__kb_window_addr" -o "$__kb_window_addr" = "null"
        return 0
    end

    hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'on', window = 'address:$__kb_window_addr' }))" >/dev/null 2>&1
    hyprctl eval "hl.dispatch(hl.dsp.window.resize({ x = $win_w, y = $win_h, window = 'address:$__kb_window_addr' }))" >/dev/null 2>&1

    set -l mon (hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height)"' | head -n 1)

    if test -n "$mon"
        set -l mx (echo $mon | awk '{print $1}')
        set -l my (echo $mon | awk '{print $2}')
        set -l mw (echo $mon | awk '{print $3}')
        set -l mh (echo $mon | awk '{print $4}')

        set -l x (math "$mx + (($mw - $win_w) / 2)")
        set -l y (math "$my + (($mh - $win_h) / 2)")

        hyprctl eval "hl.dispatch(hl.dsp.window.move({ x = $x, y = $y, window = 'address:$__kb_window_addr' }))" >/dev/null 2>&1
    end
end

function __keybinds_restore_window
    command -q hyprctl; or return 0

    if test -z "$__kb_window_addr" -o "$__kb_window_addr" = "null"
        return 0
    end

    if test "$__kb_was_floating" = "false"
        hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'off', window = 'address:$__kb_window_addr' }))" >/dev/null 2>&1
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
end
