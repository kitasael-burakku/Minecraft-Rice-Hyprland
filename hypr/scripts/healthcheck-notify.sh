#!/usr/bin/env bash
# ============================================================================
#  healthcheck-notify.sh — variante no interactiva de `healthcheck` (fish)
# ----------------------------------------------------------------------------
#  fish/functions/healthcheck.fish está pensado para correr en una terminal:
#  dibuja cajas ASCII y termina con un "Press Enter to exit" que colgaría
#  para siempre si un timer lo invocara directo. Este script reusa los
#  mismos chequeos de solo lectura (huérfanos, updates, pacnew/pacsave,
#  servicios fallidos, reboot pendiente, errores críticos de arranque) pero
#  sin dibujar nada — si no encuentra nada, sale en silencio; si encuentra
#  algo, un único notify-send con el resumen. Pensado para
#  healthcheck-notify.timer (diario).
# ============================================================================

set -u
set -o pipefail

ISSUES=()

# ── Huérfanos ─────────────────────────────────────────────────────────────
orphans=$(pacman -Qtdq 2>/dev/null | wc -l)
[ "$orphans" -gt 0 ] && ISSUES+=("󰮯 $orphans paquete(s) huérfano(s)")

# ── Updates pendientes (mismo umbral "critical" que ya usa
#    waybar/scripts/updates.sh: 50 — por debajo de eso es ruido diario, no
#    algo que amerite una notificación) ──────────────────────────────────
pacman_updates=0
command -v checkupdates >/dev/null 2>&1 && pacman_updates=$(checkupdates 2>/dev/null | wc -l)
aur_updates=0
if command -v yay >/dev/null 2>&1; then
    aur_updates=$(yay -Qua 2>/dev/null | wc -l)
elif command -v paru >/dev/null 2>&1; then
    aur_updates=$(paru -Qua 2>/dev/null | wc -l)
fi
total_updates=$((pacman_updates + aur_updates))
[ "$total_updates" -ge 50 ] && ISSUES+=("󰚰 $total_updates actualizaciones pendientes (pacman+AUR)")

# ── Pacnew / Pacsave ──────────────────────────────────────────────────────
pacfiles=$(find /etc -name '*.pacnew' -o -name '*.pacsave' 2>/dev/null | wc -l)
[ "$pacfiles" -gt 0 ] && ISSUES+=("󰘓 $pacfiles archivo(s) .pacnew/.pacsave en /etc")

# ── Servicios fallidos ────────────────────────────────────────────────────
failed_system=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
failed_user=$(systemctl --user --failed --no-legend 2>/dev/null | wc -l)
[ "$failed_system" -gt 0 ] && ISSUES+=("󰋊 $failed_system servicio(s) del sistema fallidos")
[ "$failed_user" -gt 0 ] && ISSUES+=("󰋊 $failed_user servicio(s) de usuario fallidos")

# ── Reboot pendiente (mismo criterio que sysupdate.fish: el kernel que
#    corre ya no tiene su directorio de módulos en disco) ─────────────────
if [ ! -d "/usr/lib/modules/$(uname -r)" ]; then
    ISSUES+=("󰜉 kernel actualizado ($(uname -r) sin módulos) — reinicio pendiente")
fi

# ── Errores críticos de arranque, filtrando el ruido conocido de TPM (mismo
#    criterio que healthcheck.fish) ───────────────────────────────────────
boot_errors="$(journalctl -b -p 3 --no-pager 2>/dev/null)"
if [ -n "$boot_errors" ]; then
    non_tpm=$(printf '%s\n' "$boot_errors" | grep -viE 'tpm2|pcrproduct|TPM key integrity' | grep -c .)
    [ "$non_tpm" -gt 0 ] && ISSUES+=("󰍛 $non_tpm error(es) crítico(s) de arranque (no-TPM)")
fi

# ── Reportar ──────────────────────────────────────────────────────────────
if [ "${#ISSUES[@]}" -eq 0 ]; then
    exit 0
fi

body="$(printf '%s\n' "${ISSUES[@]}")"
command -v notify-send >/dev/null 2>&1 && notify-send -u normal -i dialog-warning "Healthcheck" "$body"
