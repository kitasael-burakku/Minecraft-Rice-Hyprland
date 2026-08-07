#!/usr/bin/env bash
# ============================================================================
#  generate-keybinds-doc.sh — regenera ~/Documents/KEYBINDS.txt desde
#  hypr/modules/keybinds.lua (+ el bind privado de hypr/modules/private.lua,
#  si existe), en vez de mantenerlo a mano y esperar a que checkkeybinds.fish
#  avise del drift a posteriori.
# ----------------------------------------------------------------------------
#  Convención que este script asume (ya era la dominante en keybinds.lua
#  antes de escribir esto): la descripción de un bind es el/los comentario(s)
#  "-- " inmediatamente arriba de su hl.bind(...) — varias líneas "--"
#  consecutivas se concatenan en una sola descripción, y de ahí se deriva un
#  label CORTO (ver shorten_desc(): primera cláusula natural — hasta el
#  primer " — "/": "/". " — o un tope duro de 60 caracteres). KEYBINDS.txt
#  es referencia rápida, no documentación; la prosa completa sigue en el
#  comentario fuente, no se pierde, sólo no se vuelca entera acá (antes sí
#  se volcaba entera, y con comentarios largos rompía el visor TUI de
#  fish/functions/keybinds.fish — caja de ancho fijo, ver los commits que
#  siguieron a este mismo cambio). Si varios binds comparten un bloque de
#  comentario (p.ej. las 4 direcciones de "Infinite Desktop — Navigation"),
#  todos heredan la MISMA descripción — es una limitación conocida y
#  aceptada (mismo criterio que ya declara checkkeybinds.fish sobre sus
#  propios falsos negativos: mejor ser conservador y correcto la mayoría de
#  las veces que inventar).
#
#  Lo que NO intenta parsear (y por diseño no hace falta): el cuerpo de
#  binds con function() ... end (CTRL+ALT+V, SUPER+SHIFT+S) — sólo se lee
#  el primer argumento (la tecla), nunca la acción, así que la forma del
#  callback no importa. El loop dinámico de workspaces (`for i = 1, 10 do`)
#  SÍ está hardcodeado como caso especial porque su tecla no es un literal.
#
#  Caso raro no cubierto: un comentario indentado DENTRO del cuerpo de un
#  function() ... end (ej. los dos "-- está en..." de SUPER+SHIFT+S) puede
#  quedar pegado como pending_desc si el bind siguiente no tiene comentario
#  propio Y no hay un separador de sección entre medio — no ocurre hoy
#  (siempre hay banner o comentario propio de por medio), pero si algún día
#  aparece un bind sin descripción justo después de una función con
#  comentarios internos, revisar a mano antes de confiar ciegamente.
#
#  Uso: generate-keybinds-doc.sh [--check]
#    --check   no escribe nada; sale 1 si el KEYBINDS.txt actual difiere de
#              lo que generaría (para un hook de dotbackup/CI a futuro).
# ============================================================================

set -u
set -o pipefail

KEYBINDS_LUA="$HOME/.config/hypr/modules/keybinds.lua"
PRIVATE_LUA="$HOME/.config/hypr/modules/private.lua"
OUT="$HOME/Documents/KEYBINDS.txt"

AWK_PROGRAM='
BEGIN {
    section = (section_init == "") ? "" : section_init
    banner_buf = ""
    pending_desc = ""
    last_was_comment = 0
    in_ws_loop = 0
}

function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

# KEYBINDS.txt es referencia rápida (y el visor TUI de fish/functions/keybinds.fish
# tiene una caja de ancho fijo) — no el lugar para la prosa explicativa
# completa que sí tiene sentido al lado del código. Se queda con la primera
# cláusula natural (hasta el primer " — ", ": " o ". ", lo que aparezca
# antes) como label corto; si ninguno aparece cerca (o aparece más allá del
# tope), un corte duro cortando en el último espacio (nunca a mitad de
# palabra) como red de seguridad. La prosa completa sigue viviendo en el
# comentario fuente — esto no la pierde, sólo no la vuelca entera acá.
#
# MAXLEN=38 no es arbitrario: keybinds.fish dibuja la descripción en una
# caja de ancho fijo (width=74) con columna de tecla de 25 — eso deja
# exactamente desc_width=40 caracteres reales para la descripción
# (__kb_pair, fish/functions/keybinds.fish). Si el label generado acá fuera
# más largo, la TUI lo recortaría IGUAL con su propio "…" — dos cortes
# encimados, uno de los cuales es inútil. 38 deja 2 de margen sobre esos 40
# para que el corte que se vea sea siempre este, nunca el de la TUI. Si
# alguna vez cambian esas constantes en keybinds.fish, este número tiene
# que moverse con ellas — no hay una sola fuente de verdad para los dos
# (bash acá, fish allá), así que quedaron desincronizados una vez ya
# (ver el historial de este archivo) y puede volver a pasar.
function shorten_desc(desc,    cut, best, p, maxlen) {
    maxlen = 38
    best = length(desc)

    p = index(desc, " — ")
    if (p > 0 && p - 1 < best) best = p - 1

    p = index(desc, ": ")
    if (p > 0 && p - 1 < best) best = p - 1

    p = index(desc, ". ")
    if (p > 0 && p - 1 < best) best = p - 1

    cut = trim(substr(desc, 1, best))

    if (length(cut) > maxlen) {
        cut = substr(cut, 1, maxlen)
        p = length(cut)
        while (p > 20 && substr(cut, p, 1) != " ") p--
        if (p > 20) cut = substr(cut, 1, p - 1)
        cut = trim(cut) "…"
    }

    return cut
}

function prettify_key(raw,    n, parts, i, out, tok, lower) {
    if (raw == "mouse:272")  return "Left click"
    if (raw == "mouse:273")  return "Right click"
    if (raw == "mouse_down") return "Scroll down"
    if (raw == "mouse_up")   return "Scroll up"
    if (raw == "XF86AudioRaiseVolume") return "Volume +"
    if (raw == "XF86AudioLowerVolume") return "Volume -"
    if (raw == "XF86AudioMute")        return "Mute"
    if (raw == "XF86AudioNext")        return "Next"
    if (raw == "XF86AudioPause")       return "Play/Pause"
    if (raw == "XF86AudioPlay")        return "Play/Pause"
    if (raw == "XF86AudioPrev")        return "Previous"

    n = split(raw, parts, /[ \t]*\+[ \t]*/)
    out = ""
    for (i = 1; i <= n; i++) {
        tok = trim(parts[i])
        if (tok == "") continue
        lower = tolower(tok)
        if (lower == "return")      tok = "Enter"
        else if (lower == "space")  tok = "Space"
        else if (lower == "escape") tok = "Escape"
        else if (lower == "delete") tok = "Delete"
        else if (lower == "left")   tok = "Left"
        else if (lower == "right")  tok = "Right"
        else if (lower == "up")     tok = "Up"
        else if (lower == "down")   tok = "Down"
        else if (length(tok) == 1)  tok = toupper(tok)
        out = (out == "") ? tok : out " + " tok
    }
    return out
}

function emit(key, desc) {
    if (section == "") section = "(SIN SECCION)"
    printf "%s\t%s\t%s\n", section, key, shorten_desc(desc)
}

# separador puro de banner (posible cierre de un bloque de nombre)
/^-+[ \t]*$/ {
    if (banner_buf != "") {
        section = banner_buf
        banner_buf = ""
        pending_desc = ""
    }
    last_was_comment = 0
    next
}

# línea de nombre dentro de un banner
/^----[ \t]+[A-Za-z]/ {
    name = $0
    gsub(/^----[ \t]*/, "", name)
    gsub(/[ \t]*-+[ \t]*$/, "", name)
    name = trim(name)
    banner_buf = (banner_buf == "") ? name : banner_buf " — " name
    last_was_comment = 0
    next
}

# loop dinámico de workspaces — caso especial, no parseable línea a línea
/^for i = 1, 10 do/ { in_ws_loop = 1; last_was_comment = 0; next }
in_ws_loop && /^end[ \t]*$/ {
    in_ws_loop = 0
    emit("SUPER + 1-0", "Cambiar a workspace 1-10")
    emit("SUPER + SHIFT + 1-0", "Mover ventana a workspace 1-10")
    pending_desc = ""
    last_was_comment = 0
    next
}
in_ws_loop { next }

# comentario descriptivo — varias líneas "--" consecutivas se acumulan en
# una sola descripción; una línea "--" que NO sigue a otro comentario
# arranca un bloque nuevo (pisa lo anterior, no se le suma). Tolera
# indentación (private.lua vive indentado dentro de una tabla Lua; keybinds.lua
# no, pero el mismo patrón cubre ambos sin necesitar dos regex distintas).
/^[ \t]*--[ \t]/ {
    text = $0
    sub(/^[ \t]*--[ \t]*/, "", text)
    text = trim(text)
    if (last_was_comment) {
        pending_desc = pending_desc " " text
    } else {
        pending_desc = text
    }
    last_was_comment = 1
    next
}

# bind real
/hl\.bind\(/ {
    line = $0
    if (match(line, /hl\.bind\([ \t]*(mainMod[ \t]*\.\.[ \t]*)?"([^"]*)"/)) {
        matched = substr(line, RSTART, RLENGTH)
        has_mainmod = (matched ~ /mainMod/)
        qstart = index(matched, "\"")
        qrest = substr(matched, qstart + 1)
        qend = index(qrest, "\"")
        raw = trim(substr(qrest, 1, qend - 1))
        sub(/^\+[ \t]*/, "", raw)

        full = has_mainmod ? ("SUPER + " raw) : raw
        key = prettify_key(full)
        desc = (pending_desc != "") ? pending_desc : "(sin descripción)"
        emit(key, desc)
    }
    # pending_desc NO se limpia acá a propósito: varios binds sin comentario
    # propio, seguidos, bajo un mismo bloque explicativo (ver ejemplo de
    # Navigation/Pan arriba), heredan la misma descripción. Sí se limpia al
    # cruzar a una sección nueva (regla del separador de banner, arriba).
    last_was_comment = 0
    next
}

# cualquier otra línea (código, blancos, cuerpos de function() ... end):
# no toca pending_desc, sólo corta la racha de comentarios consecutivos.
{ last_was_comment = 0 }
'

# ── Pasada 1: keybinds.lua público ────────────────────────────────────────
rows="$(awk "$AWK_PROGRAM" "$KEYBINDS_LUA")"

# ── Pasada 2: binds privados (opcional — private.lua no está versionado) ──
if [ -f "$PRIVATE_LUA" ]; then
    private_rows="$(awk -v section_init="BINDS PRIVADOS" "$AWK_PROGRAM" "$PRIVATE_LUA")"
    [ -n "$private_rows" ] && rows="$rows"$'\n'"$private_rows"
fi

# ── Render: agrupar por sección en el orden de primera aparición ─────────
render() {
    printf '%s\n' "$rows" | awk -F'\t' '
        NF < 3 { next }
        !( $1 in seen ) { order[++n] = $1; seen[$1] = 1 }
        { keys[$1] = keys[$1] $2 "\x1f" $3 "\x1e" }
        END {
            print "KEYBINDS"
            print "========"
            print ""
            print "Main modifier: SUPER (Tecla Windows / Options)"
            print ""
            print "Generado automáticamente por hypr/scripts/generate-keybinds-doc.sh"
            print "desde hypr/modules/keybinds.lua — no editar a mano, se pisa en el"
            print "próximo regenerado. Para documentar un bind nuevo, agregá un"
            print "comentario \"-- descripción\" arriba de su hl.bind(...) y volvé a"
            print "correr este script."
            print ""
            for (i = 1; i <= n; i++) {
                sec = order[i]
                print ""
                print sec
                u = ""
                for (j = 1; j <= length(sec); j++) u = u "-"
                print u
                print ""
                split(keys[sec], entries, "\x1e")
                for (j = 1; j in entries; j++) {
                    if (entries[j] == "") continue
                    split(entries[j], kv, "\x1f")
                    printf "%-26s %s\n", kv[1], kv[2]
                }
            }
        }
    '
}

if [ "${1:-}" = "--check" ]; then
    if diff -q <(render) "$OUT" >/dev/null 2>&1; then
        exit 0
    else
        echo "KEYBINDS.txt está desactualizado respecto a keybinds.lua — correr generate-keybinds-doc.sh" >&2
        exit 1
    fi
fi

render > "$OUT"
echo "$OUT regenerado ($(printf '%s\n' "$rows" | grep -c $'\t') binds documentados)."
