# ~/.config/fish/functions/kitasan.fish
# "kitasan" — CLI unificado para el rice. No agrega lógica nueva de fondo:
# es pegamento sobre lo que ya existía suelto (healthcheck/quickcache/
# cleantrash/sysupdate como funciones fish, theme.sh/systemd.sh/wallpaper
# como scripts de rofi, check-template-parity.sh/generate-keybinds-doc.sh
# como chequeos de hypr/scripts/) — la idea es tener una sola puerta de
# entrada en vez de acordarse de 8 nombres sueltos.
#
#   kitasan health          → healthcheck
#   kitasan clean           → quickcache (rápido, sin sudo)
#   kitasan clean --deep    → cleantrash (huérfanos + cache de pacman, con sudo)
#   kitasan update          → sysupdate
#   kitasan theme           → selector de perfil visual (rofi)
#   kitasan theme <scheme>  → fija el esquema directo, sin rofi (ej: vibrant)
#   kitasan wall             → selector de wallpaper por terminal (fzf, sin rofi)
#   kitasan mode             → normal/focus/gaming/cinema, selector rofi
#   kitasan mode <perfil>    → fija el perfil directo, sin rofi
#   kitasan doctor           → paridad de templates + drift de keybinds +
#                               servicios systemd caídos + huérfanos (solo lectura)
#   kitasan dashboard        → panorama del sistema (updates/temps/disco/reproductor), rofi
#   kitasan diskbackup        → espejo a /mnt/storage (repos + temas + privados)
#   kitasan diskbackup --check → solo mira si hay algo pendiente, no escribe nada
#   kitasan menu              → todo lo de arriba, elegido desde un rofi

function __kitasan_doctor
    clear
    set -l W 56

    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰓙  kitasan doctor"
    _rui_mid $W
    _rui_row $W brblack "Paridad · Keybinds · Servicios · Huérfanos"
    _rui_bot $W
    echo ""

    _rui_section cyan "󰃟" "Paridad plantilla/estático (matugen)"
    set -l parity_out (bash "$HOME/.config/hypr/scripts/check-template-parity.sh" 2>&1)
    if test -z "$parity_out"
        _rui_ok "Todas las plantillas dinámicas y sus estáticos coinciden."
    else
        printf "%s\n" $parity_out
    end

    _rui_section cyan "󰌌" "Documentación de keybinds"
    if bash "$HOME/.config/hypr/scripts/generate-keybinds-doc.sh" --check >/dev/null 2>&1
        _rui_ok "KEYBINDS.txt está al día con keybinds.lua."
    else
        _rui_warn "KEYBINDS.txt desactualizado — corré 'checkkeybinds --write'."
    end

    _rui_section red "󰋊" "Servicios systemd caídos"
    set -l failed_sys (systemctl --failed --no-legend 2>/dev/null)
    set -l failed_usr (systemctl --user --failed --no-legend 2>/dev/null)
    if test (count $failed_sys) -eq 0 -a (count $failed_usr) -eq 0
        _rui_ok "Sin servicios fallidos (sistema ni usuario)."
    else
        printf "  %s\n" $failed_sys $failed_usr
    end

    _rui_section yellow "󰮯" "Paquetes huérfanos"
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -eq 0
        _rui_ok "Sin paquetes huérfanos."
    else
        printf "  %s\n" $orphans
        _rui_none "Limpiar con: kitasan clean --deep"
    end

    _rui_section cyan "󰋊" "Backup a /mnt/storage (diskbackup)"
    set -l disk_out (~/.local/bin/diskbackup --check 2>&1)
    set -l disk_status $status
    switch $disk_status
        case 0
            _rui_ok "Repos, temas y archivos privados al día en el segundo disco."
        case 2
            _rui_warn "Hay cambios sin respaldar en /mnt/storage."
            # Sin anchor ^: la línea real arranca con el código de color ANSI
            # antes de los espacios, así que anclar al inicio nunca matchea.
            printf "%s\n" $disk_out | grep -E "    [~+] "
            _rui_none "Actualizar con: kitasan diskbackup"
        case '*'
            _rui_warn "/mnt/storage no está montado — sin backup posible ahora mismo."
    end

    echo ""
    set_color brblack; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    echo ""
    read -p 'set_color brblack; echo -n "  Press Enter to exit..."; set_color normal' __discard
end

function __kitasan_wall
    for dep in fd fzf
        if not command -q $dep
            set_color red; echo "kitasan wall: falta '$dep'"; set_color normal
            return 127
        end
    end

    set -l dirs ~/Pictures/Wallpapers ~/Videos/Wallpapers
    set -l selected (
        fd . $dirs --max-depth 1 --type f --color=never 2>/dev/null \
            | fzf --height=60% --border=rounded --prompt=" 󰸉 Wallpaper > " \
                  --preview 'file {}' --preview-window=down:2:wrap
    )

    test -n "$selected"; or return 1

    bash "$HOME/.config/hypr/scripts/apply-wallpaper.sh" "$selected"
    and nohup bash "$HOME/.config/rofi/scripts/matugen_reload.sh" "$selected" >/dev/null 2>&1 &
    disown
end

function __kitasan_theme
    if test (count $argv) -eq 0
        bash "$HOME/.config/rofi/scripts/theme.sh"
        return $status
    end

    set -l scheme "scheme-$argv[1]"
    set -l valid scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot scheme-vibrant
    if not contains -- "$scheme" $valid
        set_color red; echo "kitasan theme: esquema desconocido '$argv[1]'"; set_color normal
        set_color brblack; echo "    válidos: content expressive fidelity fruit-salad monochrome neutral rainbow tonal-spot vibrant"; set_color normal
        return 1
    end

    mkdir -p "$HOME/.config/matugen"
    printf '%s' "$scheme" > "$HOME/.config/matugen/scheme"
    touch "$HOME/.config/matugen/enabled"

    set -l wall
    if test -f "$HOME/.config/hypr/.current-wallpaper"
        set wall (cat "$HOME/.config/hypr/.current-wallpaper")
    end
    if test -z "$wall" -o ! -f "$wall"
        set_color yellow; echo "kitasan theme: esquema guardado ($scheme) — elegí un wallpaper para generar colores."; set_color normal
        return 0
    end

    bash "$HOME/.config/rofi/scripts/matugen_reload.sh" "$wall"
    set_color green; echo "kitasan theme: perfil visual → $scheme"; set_color normal
end

function __kitasan_menu
    set -l choice (printf '󰕮  Dashboard\n󰒋  Health\n󰃣  Clean\n󰚰  Update\n󰸌  Theme\n󰸉  Wallpaper\n󰙀  Mode\n󰓙  Doctor\n󰋊  Diskbackup' \
        | rofi -dmenu -p "kitasan" -theme "$HOME/.config/rofi/clipboard.rasi")
    test -n "$choice"; or return 0

    switch "$choice"
        case '*Dashboard*'
            rofi -show dashboard -modi "dashboard:$HOME/.config/rofi/scripts/dashboard.sh" -theme "$HOME/.config/rofi/clipboard.rasi"
        case '*Health*'
            kitty --title kitasan-health -e fish -c 'kitasan health'
        case '*Clean*'
            kitty --title kitasan-clean -e fish -c 'kitasan clean'
        case '*Update*'
            kitty --title kitasan-update -e fish -c 'kitasan update'
        case '*Theme*'
            __kitasan_theme
        case '*Wallpaper*'
            # Ya estamos en rofi — el picker nativo (grid con thumbnails) es
            # mejor UX acá que el fzf de terminal de `kitasan wall`.
            bash "$HOME/.config/rofi/scripts/wallpaper_launcher.sh"
        case '*Mode*'
            bash "$HOME/.config/rofi/scripts/mode.sh"
        case '*Doctor*'
            kitty --title kitasan-doctor -e fish -c 'kitasan doctor'
        case '*Diskbackup*'
            kitty --title kitasan-diskbackup -e fish -c 'kitasan diskbackup'
    end
end

function kitasan --description "CLI unificado del rice — health/clean/update/theme/wall/doctor/menu"
    if test (count $argv) -eq 0
        set_color brwhite; echo "kitasan — CLI unificado del rice"; set_color normal
        echo ""
        echo "  kitasan health           chequeo de salud del sistema"
        echo "  kitasan clean            limpieza rápida de cache"
        echo "  kitasan clean --deep     huérfanos + cache de pacman (sudo)"
        echo "  kitasan update           update completo (pacman + AUR)"
        echo "  kitasan theme [esquema]  perfil visual — sin argumento abre el selector rofi"
        echo "  kitasan wall             selector de wallpaper por terminal (fzf)"
        echo "  kitasan mode [perfil]    normal/focus/gaming/cinema — sin argumento abre el selector rofi"
        echo "  kitasan doctor           paridad + keybinds + servicios + huérfanos"
        echo "  kitasan dashboard        panorama del sistema (updates/temps/disco/reproductor), rofi"
        echo "  kitasan diskbackup       espejo a /mnt/storage (repos + temas + privados)"
        echo "  kitasan diskbackup --check   solo mira si hay algo pendiente, no escribe nada"
        echo "  kitasan menu             todo lo de arriba, elegido desde rofi"
        return 1
    end

    set -l sub $argv[1]
    set -l rest $argv[2..]

    switch "$sub"
        case health
            healthcheck
        case clean
            if contains -- --deep $rest
                cleantrash
            else
                quickcache
            end
        case update
            sysupdate
        case theme
            __kitasan_theme $rest
        case wall
            __kitasan_wall
        case mode
            if test (count $rest) -eq 0
                bash "$HOME/.config/rofi/scripts/mode.sh"
            else
                bash "$HOME/.config/hypr/scripts/desktop-mode.sh" $rest[1]
            end
        case doctor
            __kitasan_doctor
        case diskbackup
            ~/.local/bin/diskbackup $rest
        case dashboard
            rofi -show dashboard -modi "dashboard:$HOME/.config/rofi/scripts/dashboard.sh" -theme "$HOME/.config/rofi/clipboard.rasi"
        case menu
            __kitasan_menu
        case '*'
            set_color red; echo "kitasan: subcomando desconocido '$sub'"; set_color normal
            set_color brblack; echo "    correr 'kitasan' sin argumentos para ver la lista"; set_color normal
            return 1
    end
end
