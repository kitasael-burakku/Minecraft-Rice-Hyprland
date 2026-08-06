# -----------------------------------
# Full Arch Linux update routine
# -----------------------------------

function sysupdate
    clear

    set -l W 40

    # ── Banner ────────────────────────────────────────────────────────────────
    echo ""
    _rui_top $W
    _rui_row $W brwhite "󰮯  Full Arch Update Routine"
    _rui_mid $W
    _rui_row $W brblack "Updates Pacman + AUR (yay / paru)"
    _rui_bot $W
    echo ""

    # ── Pre-check: espacio libre ─────────────────────────────────────────────
    # Es lo único de acá que puede dejar el sistema peor que antes: si / se
    # llena a mitad de la transacción, pacman queda a medias. Los paquetes se
    # descargan a /var/cache/pacman/pkg, que vive en /.
    set -l min_bytes (math "2 * 1024 * 1024 * 1024")
    set -l avail (df -B1 --output=avail / 2>/dev/null | tail -1 | string trim)

    if test -n "$avail"; and test "$avail" -lt "$min_bytes"
        _rui_bad "Poco espacio en /: "(math -s1 "$avail / 1024 / 1024 / 1024")" GiB libres (mínimo 2 GiB)"
        _rui_none "Liberá espacio primero — probá cleantrash o quickcache."
        return 1
    end
    _rui_ok "Espacio en /: "(math -s1 "$avail / 1024 / 1024 / 1024")" GiB libres"
    echo ""

    if not _rui_confirm "Continue?"
        echo ""
        set_color red
        echo "  Cancelled."
        set_color normal
        return
    end
    echo ""

    # ── Detectar AUR helper ──────────────────────────────────────────────────
    set -l aur_helper ""
    if command -q yay
        set aur_helper yay
    else if command -q paru
        set aur_helper paru
    else
        set_color red
        echo "  No AUR helper found (yay or paru required)."
        set_color normal
        return 1
    end

    _rui_section_plain cyan "󰚰" "Pacman"
    echo ""
    sleep 0.1
    sudo pacman -Syu
    or begin
        set_color red
        echo ""
        echo "  Pacman update failed. Aborting AUR update."
        set_color normal
        return 1
    end

    _rui_section_plain magenta "" "AUR — $aur_helper"
    echo ""
    sleep 0.1
    $aur_helper -Sua --diffmenu --editmenu
    or begin
        set_color red
        echo ""
        echo "  AUR update failed."
        set_color normal
        return 1
    end

    # ── Post-update ──────────────────────────────────────────────────────────
    # Justo después del update es cuando aparecen estas tres cosas, y son
    # exactamente los datos que healthcheck ya calcula — pero había que
    # acordarse de correrlo aparte. Los tres chequeos son de solo lectura.
    _rui_section_plain cyan "󰋼" "Post-update"

    set -l dirty 0

    # .pacnew/.pacsave — mismo find que usa healthcheck.fish
    set -l pacfiles (find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null)
    if test (count $pacfiles) -gt 0
        _rui_warn (count $pacfiles)" archivo(s) .pacnew/.pacsave en /etc"
        printf "      %s\n" $pacfiles
        set dirty 1
    end

    # Huérfanos — mismo pacman -Qtdq que usan healthcheck y checktrash
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        _rui_warn (count $orphans)" paquete(s) quedaron huérfanos — cleantrash los limpia"
        set dirty 1
    end

    # Reboot pendiente. Método agnóstico al paquete: si el directorio de
    # módulos del kernel que está corriendo ya no existe, es porque el kernel
    # se actualizó y el sistema sigue con uno que ya no tiene módulos en disco.
    # Sirve igual con linux-cachyos, -lts o el que sea, sin hardcodear nombres.
    if not test -d "/usr/lib/modules/"(uname -r)
        _rui_warn "Kernel actualizado ("(uname -r)" ya no tiene módulos) — reiniciá"
        set dirty 1
    end

    test "$dirty" -eq 0; and _rui_ok "Nada pendiente: sin .pacnew, sin huérfanos, sin reboot."

    echo ""
    set_color green
    echo "  󰏖  System fully updated."
    set_color normal
    echo ""
end
