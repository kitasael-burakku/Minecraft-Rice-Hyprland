# ── Typing animation ─────────────────────────────────────────────────────────
# Definida a nivel de archivo, no adentro de quickcache: ahí quedaba igual en el
# scope global (fish no tiene funciones anidadas de verdad) pero se redefinía en
# cada llamada y sobrevivía a la salida sin que nadie la borrara. quickcache
# tiene tres "return" distintos, así que limpiarla en cada uno sería frágil.
# Mismo criterio que __rps_* en RPS.exe.fish y _rui_* en report-ui.fish.
function __quickcache_type
    set -l text "$argv[1]"
    set -l delay 0.012
    if test (count $argv) -ge 2
        set delay "$argv[2]"
    end
    for char in (string split '' -- "$text")
        printf "%s" "$char"
        sleep "$delay"
    end
    echo ""
end

function quickcache --description "Quick safe cache cleanup with animated confirmation"
    clear

    set -l W 52

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰪺  Quick Cache Cleanup"
    _rui_mid $W
    _rui_row $W brblack "Safe removal of regenerable cache folders"
    _rui_bot $W
    echo ""

    # ── Browser detection ─────────────────────────────────────────────────────
    set -l browser_cmds   zen-browser  firefox  chromium  google-chrome-stable  brave  vivaldi  opera  thorium-browser
    set -l browser_caches \
        "$HOME/.cache/zen" \
        "$HOME/.cache/mozilla" \
        "$HOME/.cache/chromium" \
        "$HOME/.cache/google-chrome" \
        "$HOME/.cache/BraveSoftware" \
        "$HOME/.cache/vivaldi" \
        "$HOME/.cache/opera" \
        "$HOME/.cache/thorium"

    # Borrarle el cache a un navegador ABIERTO puede dejarle el perfil
    # inconsistente: el proceso tiene descriptores abiertos contra esos
    # archivos y los reescribe al cerrar. Por eso además de que el binario
    # exista y el cache esté ahí, se chequea que no esté corriendo.
    set -l browser_targets
    set -l browser_skipped
    for i in (seq 1 (count $browser_cmds))
        set -l cmd   $browser_cmds[$i]
        set -l cache $browser_caches[$i]
        if command -q $cmd; and test -d "$cache"
            if pgrep -x -- $cmd >/dev/null 2>&1
                set -a browser_skipped "$cmd"
            else
                set -a browser_targets "$cache"
            end
        end
    end

    set -l targets \
        $browser_targets \
        "$HOME/.cache/spotify" \
        "$HOME/.cache/thumbnails" \
        "$HOME/.cache/mesa_shader_cache" \
        "$HOME/.cache/yay" \
        "$HOME/.cache/pip" \
        "$HOME/.cache/electron" \
        "$HOME/.cache/go-build" \
        "$HOME/.cache/cliphist" \
        "$HOME/.codex/.tmp"

    set_color brblack
    __quickcache_type "  Scanning known regenerable cache folders..." 0.01
    set_color normal
    echo ""

    set -l found 0
    for target in $targets
        if test -e "$target"
            set found 1
            set_color brblack; printf "  %-48s" (string replace $HOME "~" $target)
            set_color brwhite; echo (du -sh "$target" 2>/dev/null | cut -f1)
            set_color normal
        end
    end

    if test (count $browser_skipped) -gt 0
        echo ""
        for cmd in $browser_skipped
            _rui_skip "Omitido el cache de $cmd — está corriendo, cerralo primero"
        end
    end

    if test "$found" = 0
        set_color green
        __quickcache_type "  ✓ No known cache folders found." 0.015
        set_color normal
        echo ""
        read -p 'set_color brblack; echo -n "  Press Enter to exit..."; set_color normal' __discard
        return 0
    end

    echo ""
    set_color red
    __quickcache_type "  This will delete the folders listed above." 0.018
    set_color normal
    set_color brblack
    __quickcache_type "  These are expected to regenerate automatically." 0.012
    set_color normal

    echo ""
    if not _rui_confirm "Delete listed cache folders?"
        echo ""
        set_color brblack
        __quickcache_type "  Cancelled." 0.015
        set_color normal
        echo ""
        read -p 'set_color brblack; echo -n "  Press Enter to exit..."; set_color normal' __discard
        return 0
    end

    _rui_section_plain cyan "󰆴" "Removing cache folders"
    echo ""

    for target in $targets
        if test -e "$target"
            set -l target_real (realpath "$target" 2>/dev/null)
            if test -z "$target_real"
                set_color red; echo "  ✘ Skipping unsafe path: $target"; set_color normal
                continue
            end
            if string match -q -- "$HOME/.cache/*" "$target_real"; or test "$target_real" = "$HOME/.codex/.tmp"
                set_color brblack; printf "  Removing %-40s" (string replace $HOME "~" $target_real); set_color normal
                rm -rf -- "$target_real"
                set_color green; echo "done"; set_color normal
            else
                set_color red; echo "  ✘ Refusing unsafe path: $target_real"; set_color normal
            end
        end
    end

    # ── Cliphist ──────────────────────────────────────────────────────────────
    if type -q cliphist
        _rui_section_plain magenta "󰅇" "Cliphist"
        set_color brblack
        __quickcache_type "  Clears clipboard history stored by cliphist." 0.012
        set_color normal
        echo ""
        if _rui_confirm "Run cliphist wipe?"
            cliphist wipe
            set_color green; echo "  ✓ cliphist wiped."; set_color normal
        else
            set_color brblack; echo "  · Skipped."; set_color normal
        end
    end

    # ── npm ───────────────────────────────────────────────────────────────────
    if type -q npm
        _rui_section_plain green "" "npm cache"
        set_color brblack
        __quickcache_type "  Clears npm download cache." 0.012
        set_color normal
        echo ""
        if _rui_confirm "Clean npm cache?"
            npm cache clean --force
            set_color green; echo "  ✓ npm cache cleaned."; set_color normal
        else
            set_color brblack; echo "  · Skipped."; set_color normal
        end
    end

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color brblack; printf "  ────────────────────────────────────────────────────\n"; set_color normal
    set_color green
    __quickcache_type "  ✓ Quick cache cleanup complete." 0.018
    set_color normal
    echo ""
    read -p 'set_color brblack; echo -n "  Press Enter to exit..."; set_color normal' __discard
end
