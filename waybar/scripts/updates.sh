#!/usr/bin/env bash
# ============================================================================
#  updates.sh — contador de actualizaciones para Waybar (pacman + AUR)
# ============================================================================
set -o pipefail

CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
NOTIFIED_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.notified"
FAILED_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.failed"
CACHE_TTL=300  # 5 minutos

# ── Permitir refresco forzado: updates.sh --force ────────────────────────────
if [[ "${1:-}" != "--force" && -f "$CACHE_FILE" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if (( age < CACHE_TTL )); then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# ── Escape JSON seguro para tooltips ─────────────────────────────────────────
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"   # backslash
    s="${s//\"/\\\"}"   # comillas
    printf '%s' "$s"
}

updates=0
aur=0
error_msg=""

# pacman (checkupdates de pacman-contrib no toca la base de datos real)
# checkupdates documenta sus códigos de salida: 0 = hay updates, 2 = no hay
# updates (caso normal, no es un fallo), cualquier otro (ej. 1: no pudo
# sincronizar la DB temporal — sin red, lock, etc.) es un fallo real.
if command -v checkupdates >/dev/null 2>&1; then
    cu_out="$(mktemp)"; cu_err="$(mktemp)"
    checkupdates >"$cu_out" 2>"$cu_err"
    cu_rc=$?
    updates=$(wc -l < "$cu_out")
    if (( cu_rc != 0 && cu_rc != 2 )); then
        error_msg="checkupdates: $(tr '\n' ' ' < "$cu_err" | sed 's/  */ /g; s/^ *//; s/ *$//')"
    fi
    rm -f "$cu_out" "$cu_err"
fi

# AUR — soporta yay o paru automáticamente
aur_helper=""
if command -v yay >/dev/null 2>&1; then
    aur_helper="yay"
elif command -v paru >/dev/null 2>&1; then
    aur_helper="paru"
fi

if [[ -n "$aur_helper" ]]; then
    # A diferencia de checkupdates, yay/paru -Qua sale con código 1 tanto en
    # el caso normal de "no hay updates AUR" como en un fallo real, y no hay
    # forma de distinguirlos por código de salida solo. Un fallo real (sin
    # red, RPC caído, etc.) sí imprime algo a stderr; "no hay updates" no
    # imprime nada. timeout matando el proceso (124) también cuenta como fallo.
    au_out="$(mktemp)"; au_err="$(mktemp)"
    timeout 20 "$aur_helper" -Qua >"$au_out" 2>"$au_err"
    au_rc=$?
    aur=$(wc -l < "$au_out")
    if (( au_rc == 124 )); then
        error_msg="${error_msg:+$error_msg; }$aur_helper: timeout (20s)"
    elif (( au_rc != 0 )) && [[ -s "$au_err" ]]; then
        error_msg="${error_msg:+$error_msg; }$aur_helper: $(tr '\n' ' ' < "$au_err" | sed 's/  */ /g; s/^ *//; s/ *$//')"
    fi
    rm -f "$au_out" "$au_err"
fi

# Sanitizar (por si wc devuelve vacío o timeout mata el proceso)
[[ "$updates" =~ ^[0-9]+$ ]] || updates=0
[[ "$aur"     =~ ^[0-9]+$ ]] || aur=0

total=$((updates + aur))

# ── Construir salida ─────────────────────────────────────────────────────────
if (( total == 0 )); then
    text="󰄬"
    tooltip="Sistema actualizado"
    css_class="updated"
else
    text="󰚰 $total"
    tooltip="󰣇 $updates pacman"
    if [[ -n "$aur_helper" ]]; then
        tooltip="$tooltip\n󰮯 $aur AUR ($aur_helper)"
    fi
    # marca visual si hay muchas actualizaciones pendientes
    if (( total >= 50 )); then
        css_class="critical"
    else
        css_class="pending"
    fi
fi

# Clases extra a devolver además de la de arriba (ej. "error"). Waybar acepta
# "class" como string o como array de strings en módulos custom.
classes=("$css_class")

if [[ -n "$error_msg" ]]; then
    text="$text 󰀦"
    tooltip="$tooltip\n⚠ $error_msg"
    classes+=("error")
fi

# ── Notificación de escritorio ────────────────────────────────────────────────
# Solo avisa cuando el total sube respecto al último aviso (no en cada
# refresco de caché), y se resetea a 0 en cuanto el sistema queda al día
# para que la próxima tanda de updates vuelva a notificar.
last_notified=0
[[ -f "$NOTIFIED_FILE" ]] && last_notified=$(<"$NOTIFIED_FILE")
[[ "$last_notified" =~ ^[0-9]+$ ]] || last_notified=0

if (( total > 0 && total > last_notified )) && command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Waybar" -i software-update-available \
        "󰚰 Actualizaciones disponibles" \
        "$updates pacman$( [[ -n "$aur_helper" ]] && printf ' · %s AUR (%s)' "$aur" "$aur_helper" )"
fi
printf '%s\n' "$total" > "$NOTIFIED_FILE"

# Igual que arriba pero para fallos: solo avisa al entrar en fallo (no en cada
# refresco mientras siga fallando) y se resetea en cuanto vuelve a funcionar.
was_failed=0
[[ -f "$FAILED_FILE" ]] && was_failed=$(<"$FAILED_FILE")
[[ "$was_failed" =~ ^(0|1)$ ]] || was_failed=0

if [[ -n "$error_msg" ]]; then
    if (( was_failed == 0 )) && command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical -a "Waybar" -i dialog-warning \
            "󰀦 Fallo comprobando actualizaciones" \
            "$error_msg"
    fi
    printf '1\n' > "$FAILED_FILE"
else
    printf '0\n' > "$FAILED_FILE"
fi

class_json=$(printf '"%s",' "${classes[@]}")
class_json="[${class_json%,}]"

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":${class_json}}"

# Escribir cache de forma atómica (evita que Waybar lea un archivo a medio escribir)
tmp="$(mktemp "${CACHE_FILE}.XXXXXX")"
printf '%s\n' "$result" > "$tmp"
mv -f "$tmp" "$CACHE_FILE"

printf '%s\n' "$result"