#!/usr/bin/env bash
# ============================================================================
#  dashboard.sh — panorama del sistema en un vistazo, vía rofi (modi custom)
# ----------------------------------------------------------------------------
#  No recalcula nada que ya exista: lee los mismos caches que ya escriben
#  waybar/scripts/updates.sh (vía updates-check.timer) y
#  waybar/scripts/playerctl-watch.sh, llama a waybar/scripts/gpu.sh para el
#  dato de GPU, y usa el mismo hwmon-path-abs que waybar/config.jsonc para
#  la temperatura de CPU — cero lógica nueva de sensores, sólo un panel que
#  junta lo que ya se estaba calculando en otro lado.
#
#  El bloque "message" es sólo informativo (rofi lo pinta arriba de la
#  lista); las filas seleccionables de abajo son acciones rápidas — no hay
#  filas "informativas pero que no hacen nada al clickearlas".
# ============================================================================
set -u
set -o pipefail

UPDATES_CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
PLAYER_CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-playerctl.json"
GPU_SCRIPT="$HOME/.config/waybar/scripts/gpu.sh"
DOTFILES_REPO="$HOME/Projects/dotfiles"
HWMON_CPU="/sys/devices/pci0000:00/0000:00:18.3/hwmon"

# ── Recolectar datos (todo con fallback silencioso — un sensor que falla no
#    debe tirar abajo el resto del panel) ──────────────────────────────────

updates_text="?"
updates_count=0
if [ -f "$UPDATES_CACHE" ] && command -v jq >/dev/null 2>&1; then
    updates_text="$(jq -r '.tooltip // "?"' "$UPDATES_CACHE" 2>/dev/null | tr '\n' ' ')"
    cls="$(jq -r '.class // ""' "$UPDATES_CACHE" 2>/dev/null)"
    [ "$cls" = "pending" ] || [ "$cls" = "critical" ] && updates_count=1
fi

failed_sys="$(systemctl --failed --no-legend 2>/dev/null | wc -l)"
failed_usr="$(systemctl --user --failed --no-legend 2>/dev/null | wc -l)"
failed_total=$((failed_sys + failed_usr))

cpu_temp="?"
hwmon_dir=$(compgen -G "$HWMON_CPU/hwmon*" | head -n1)
if [ -n "$hwmon_dir" ] && [ -f "$hwmon_dir/temp1_input" ]; then
    raw="$(cat "$hwmon_dir/temp1_input" 2>/dev/null)"
    [[ "$raw" =~ ^[0-9]+$ ]] && cpu_temp=$(( raw / 1000 ))
fi

gpu_text="?"
if [ -x "$GPU_SCRIPT" ] && command -v jq >/dev/null 2>&1; then
    gpu_json="$("$GPU_SCRIPT" 2>/dev/null)"
    gpu_text="$(printf '%s' "$gpu_json" | jq -r '.text // "?"' 2>/dev/null)"
fi

disk_line="$(df -h --output=used,size,pcent / 2>/dev/null | awk 'NR==2 {printf "%s / %s (%s usado)", $1, $2, $3}')"
[ -z "$disk_line" ] && disk_line="?"

player_text="Sin reproductor activo"
if [ -f "$PLAYER_CACHE" ] && command -v jq >/dev/null 2>&1; then
    ptext="$(jq -r '.text // ""' "$PLAYER_CACHE" 2>/dev/null)"
    pstatus="$(jq -r '.alt // ""' "$PLAYER_CACHE" 2>/dev/null)"
    [ -n "$ptext" ] && player_text="$ptext [$pstatus]"
fi

backup_line="repo no encontrado en ~/Projects/dotfiles"
if [ -d "$DOTFILES_REPO/.git" ]; then
    backup_line="$(git -C "$DOTFILES_REPO" log -1 --format='%cr' 2>/dev/null)"
    [ -z "$backup_line" ] && backup_line="sin commits todavía"
fi

message="󰚰 Updates: ${updates_text}
󰋊 Downed services: ${failed_total}
󱃂 CPU: ${cpu_temp}°C    GPU: ${gpu_text}
󰋊 Disco (/): ${disk_line}
󰐊 Player: ${player_text}
󰊤 Last backup: ${backup_line}"

# ── Callback ────────────────────────────────────────────────────────────
if [ "${ROFI_RETV:-0}" = "1" ]; then
    chosen="${1:-}"
    case "$chosen" in
        *"Upgrade system"*)
            kitty --title kitasan-update -e fish -c 'kitasan update' &
            disown
            ;;
        *"See downed services"*)
            bash "$HOME/.config/rofi/scripts/systemd.sh" &
            disown
            ;;
        *"Run dotbackup"*)
            # Doble chequeo: la fila no debería aparecer sin dotbackup
            # instalado (ver el gate más abajo), pero no cuesta nada
            # defenderse acá también en vez de asumir.
            if command -v dotbackup >/dev/null 2>&1; then
                kitty --title dotbackup -e fish -c 'dotbackup' &
                disown
            fi
            ;;
        *"Play/Pause"*)
            playerctl play-pause 2>/dev/null
            ;;
    esac
    exit 0
fi

echo -en "\0prompt\x1f󰕮  Dashboard\n"
echo -en "\0no-custom\x1ftrue\n"
echo -en "\0message\x1f${message}\n"

[ "$updates_count" -gt 0 ] && echo "󰚰  Upgrade system now"
[ "$failed_total" -gt 0 ] && echo "󰋊  See downed services"
# command -v, no sólo "el repo existe": dotbackup es una herramienta
# personal (~/.local/bin/, no versionada — ver docs/ARCHITECTURE.md). Quien
# clone este repo va a tener el .git pero no el script; sin este chequeo,
# la fila aparecería igual y fallaría al tocarla.
[ -d "$DOTFILES_REPO/.git" ] && command -v dotbackup >/dev/null 2>&1 && echo "󰊤  Run dotbackup"
if [ -f "$PLAYER_CACHE" ] && command -v jq >/dev/null 2>&1; then
    has_player="$(jq -r '.text // ""' "$PLAYER_CACHE" 2>/dev/null)"
    [ -n "$has_player" ] && echo "󰐊  Play/Pause"
fi
