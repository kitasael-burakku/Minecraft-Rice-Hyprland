#!/usr/bin/env bash
# ============================================================================
#  updates.sh — contador de actualizaciones para Waybar (pacman + AUR)
# ============================================================================
set -o pipefail

CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
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

# pacman (checkupdates de pacman-contrib no toca la base de datos real)
if command -v checkupdates >/dev/null 2>&1; then
    updates=$(checkupdates 2>/dev/null | wc -l)
fi

# AUR — soporta yay o paru automáticamente
aur_helper=""
if command -v yay >/dev/null 2>&1; then
    aur_helper="yay"
elif command -v paru >/dev/null 2>&1; then
    aur_helper="paru"
fi

if [[ -n "$aur_helper" ]]; then
    aur=$(timeout 20 "$aur_helper" -Qua 2>/dev/null | wc -l)
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

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":\"$css_class\"}"

# Escribir cache de forma atómica (evita que Waybar lea un archivo a medio escribir)
tmp="$(mktemp "${CACHE_FILE}.XXXXXX")"
printf '%s\n' "$result" > "$tmp"
mv -f "$tmp" "$CACHE_FILE"

printf '%s\n' "$result"