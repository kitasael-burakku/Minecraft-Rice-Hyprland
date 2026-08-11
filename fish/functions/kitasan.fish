# ~/.config/fish/functions/kitasan.fish
# "kitasan" — unified CLI for the rice. Doesn't add any new logic underneath:
# it's glue over what already existed loose (healthcheck/quickcache/
# cleantrash/sysupdate as fish functions, theme.sh/systemd.sh/wallpaper
# as rofi scripts, check-template-parity.sh/generate-keybinds-doc.sh
# as checks in hypr/scripts/) — the idea is one single entry point instead
# of having to remember 8 loose names.
#
#   kitasan health          → healthcheck
#   kitasan clean           → quickcache (fast, no sudo)
#   kitasan clean --deep    → cleantrash (orphans + pacman cache, with sudo)
#   kitasan update          → sysupdate
#   kitasan theme           → visual profile picker (rofi)
#   kitasan theme <scheme>  → sets the scheme directly, no rofi (e.g. vibrant)
#   kitasan wall             → terminal wallpaper picker (fzf, no rofi)
#   kitasan mode             → normal/focus/gaming/cinema, rofi picker
#   kitasan mode <perfil>    → sets the profile directly, no rofi
#   kitasan doctor           → template parity + keybinds drift +
#                               downed systemd services + orphans (read-only)
#   kitasan dashboard        → system overview (updates/temps/disk/player), rofi
#   kitasan diskbackup        → mirror to /mnt/storage (repos + themes + private files)
#   kitasan diskbackup --check → just checks if anything's pending, writes nothing
#   kitasan menu              → all of the above, chosen from a rofi

function __kitasan_doctor
    clear
    set -l W 56

    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰓙  kitasan doctor"
    _rui_mid $W
    _rui_row $W brblack "Parity · Keybinds · Services · Orphans"
    _rui_bot $W
    echo ""

    _rui_section cyan "󰃟" "Template/static parity (matugen)"
    set -l parity_out (bash "$HOME/.config/hypr/scripts/check-template-parity.sh" 2>&1)
    if test -z "$parity_out"
        _rui_ok "All dynamic templates match their statics."
    else
        printf "%s\n" $parity_out
    end

    _rui_section cyan "󰌌" "Keybinds documentation"
    if bash "$HOME/.config/hypr/scripts/generate-keybinds-doc.sh" --check >/dev/null 2>&1
        _rui_ok "KEYBINDS.txt is up to date with keybinds.lua."
    else
        _rui_warn "KEYBINDS.txt is outdated — run 'checkkeybinds --write'."
    end

    _rui_section red "󰋊" "Downed systemd services"
    set -l failed_sys (systemctl --failed --no-legend 2>/dev/null)
    set -l failed_usr (systemctl --user --failed --no-legend 2>/dev/null)
    if test (count $failed_sys) -eq 0 -a (count $failed_usr) -eq 0
        _rui_ok "No failed services (system or user)."
    else
        printf "  %s\n" $failed_sys $failed_usr
    end

    _rui_section yellow "󰮯" "Orphan packages"
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -eq 0
        _rui_ok "No orphan packages."
    else
        printf "  %s\n" $orphans
        _rui_none "Clean up with: kitasan clean --deep"
    end

    _rui_section cyan "󰋊" "Backup to /mnt/storage (diskbackup)"
    # diskbackup is a personal tool (~/.local/bin/, NOT versioned in this
    # repo — same approach as dotbackup, see docs/ARCHITECTURE.md).
    # If someone clones this rice, this script simply doesn't exist there:
    # degrade gracefully here, don't assume it's present. command -v (not
    # test -x on a fixed path) to stay consistent with how dashboard.sh
    # checks for dotbackup — search $PATH, not a hardcoded location.
    if not command -v diskbackup >/dev/null 2>&1
        _rui_none "diskbackup isn't installed (personal tool, not versioned)."
    else
        set -l disk_out (diskbackup --check 2>&1)
        set -l disk_status $status
        switch $disk_status
            case 0
                _rui_ok "Repos, themes and private files up to date on the second disk."
            case 2
                _rui_warn "There are unbacked-up changes in /mnt/storage."
                # No ^ anchor: the actual line starts with the ANSI color
                # code before the spaces, so anchoring to the start never
                # matches.
                printf "%s\n" $disk_out | grep -E "    [~+] "
                _rui_none "Update with: kitasan diskbackup"
            case '*'
                _rui_warn "/mnt/storage isn't mounted — no backup possible right now."
        end
    end

    echo ""
    set_color brblack; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    echo ""
    read -p 'set_color brblack; echo -n "  Press Enter to exit..."; set_color normal' __discard
end

function __kitasan_wall
    for dep in fd fzf
        if not command -q $dep
            set_color red; echo "kitasan wall: missing '$dep'"; set_color normal
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
        set_color red; echo "kitasan theme: unknown scheme '$argv[1]'"; set_color normal
        set_color brblack; echo "    valid: content expressive fidelity fruit-salad monochrome neutral rainbow tonal-spot vibrant"; set_color normal
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
        set_color yellow; echo "kitasan theme: scheme saved ($scheme) — pick a wallpaper to generate colors."; set_color normal
        return 0
    end

    bash "$HOME/.config/rofi/scripts/matugen_reload.sh" "$wall"
    set_color green; echo "kitasan theme: visual profile → $scheme"; set_color normal
end

function __kitasan_menu
    set -l entries '󰕮  Dashboard' '󰒋  Health' '󰃣  Clean' '󰚰  Update' '󰸌  Theme' '󰸉  Wallpaper' '󰙀  Mode' '󰓙  Doctor'
    # diskbackup is personal, not versioned (see __kitasan_doctor) — only
    # shows up in the menu if it actually exists on this machine.
    command -v diskbackup >/dev/null 2>&1; and set -a entries '󰋊  Diskbackup'

    set -l choice (printf '%s\n' $entries | rofi -dmenu -p "kitasan" -theme "$HOME/.config/rofi/clipboard.rasi")
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
            # Already in rofi — the native picker (grid with thumbnails) is
            # better UX here than the terminal fzf from `kitasan wall`.
            bash "$HOME/.config/rofi/scripts/wallpaper_launcher.sh"
        case '*Mode*'
            bash "$HOME/.config/rofi/scripts/mode.sh"
        case '*Doctor*'
            kitty --title kitasan-doctor -e fish -c 'kitasan doctor'
        case '*Diskbackup*'
            kitty --title kitasan-diskbackup -e fish -c 'kitasan diskbackup'
    end
end

function kitasan --description "Unified rice CLI — health/clean/update/theme/wall/doctor/menu"
    if test (count $argv) -eq 0
        set_color brwhite; echo "kitasan — unified rice CLI"; set_color normal
        echo ""
        echo "  kitasan health           system health check"
        echo "  kitasan clean            quick cache cleanup"
        echo "  kitasan clean --deep     orphans + pacman cache (sudo)"
        echo "  kitasan update           full update (pacman + AUR)"
        echo "  kitasan theme [scheme]   visual profile — no argument opens the rofi picker"
        echo "  kitasan wall             terminal wallpaper picker (fzf)"
        echo "  kitasan mode [profile]   normal/focus/gaming/cinema — no argument opens the rofi picker"
        echo "  kitasan doctor           parity + keybinds + services + orphans"
        echo "  kitasan dashboard        system overview (updates/temps/disk/player), rofi"
        echo "  kitasan diskbackup       mirror to /mnt/storage (repos + themes + private files)"
        echo "  kitasan diskbackup --check   just checks if anything's pending, writes nothing"
        echo "  kitasan menu             all of the above, chosen from rofi"
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
            if not command -v diskbackup >/dev/null 2>&1
                set_color red; echo "kitasan diskbackup: not installed on this system"; set_color normal
                set_color brblack; echo "    it's a personal tool, not versioned in the repo (see docs/ARCHITECTURE.md)"; set_color normal
                return 127
            end
            diskbackup $rest
        case dashboard
            rofi -show dashboard -modi "dashboard:$HOME/.config/rofi/scripts/dashboard.sh" -theme "$HOME/.config/rofi/clipboard.rasi"
        case menu
            __kitasan_menu
        case '*'
            set_color red; echo "kitasan: unknown subcommand '$sub'"; set_color normal
            set_color brblack; echo "    run 'kitasan' with no arguments to see the list"; set_color normal
            return 1
    end
end
