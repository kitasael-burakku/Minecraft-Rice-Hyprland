#!/usr/bin/env bash
# ============================================================================
#  healthcheck-notify.sh — non-interactive variant of `healthcheck` (fish)
# ----------------------------------------------------------------------------
#  fish/functions/healthcheck.fish is meant to run in a terminal: it draws
#  ASCII boxes and ends with a "Press Enter to exit" that would hang
#  forever if a timer invoked it directly. This script reuses the same
#  read-only checks (orphans, updates, pacnew/pacsave, failed services,
#  pending reboot, critical boot errors) but without drawing anything — if
#  it finds nothing, it exits silently; if it finds something, a single
#  notify-send with the summary. Meant for healthcheck-notify.timer (daily).
# ============================================================================

set -u
set -o pipefail

ISSUES=()

# ── Orphans ─────────────────────────────────────────────────────────────
orphans=$(pacman -Qtdq 2>/dev/null | wc -l)
[ "$orphans" -gt 0 ] && ISSUES+=("󰮯 $orphans orphan package(s)")

# ── Pending updates (same "critical" threshold already used by
#    waybar/scripts/updates.sh: 50 — below that it's daily noise, not
#    something worth a notification) ──────────────────────────────────
pacman_updates=0
command -v checkupdates >/dev/null 2>&1 && pacman_updates=$(checkupdates 2>/dev/null | wc -l)
aur_updates=0
if command -v yay >/dev/null 2>&1; then
    aur_updates=$(yay -Qua 2>/dev/null | wc -l)
elif command -v paru >/dev/null 2>&1; then
    aur_updates=$(paru -Qua 2>/dev/null | wc -l)
fi
total_updates=$((pacman_updates + aur_updates))
[ "$total_updates" -ge 50 ] && ISSUES+=("󰚰 $total_updates pending updates (pacman+AUR)")

# ── Pacnew / Pacsave ──────────────────────────────────────────────────────
pacfiles=$(find /etc -name '*.pacnew' -o -name '*.pacsave' 2>/dev/null | wc -l)
[ "$pacfiles" -gt 0 ] && ISSUES+=("󰘓 $pacfiles .pacnew/.pacsave file(s) in /etc")

# ── Failed services ────────────────────────────────────────────────────
failed_system=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
failed_user=$(systemctl --user --failed --no-legend 2>/dev/null | wc -l)
[ "$failed_system" -gt 0 ] && ISSUES+=("󰋊 $failed_system failed system service(s)")
[ "$failed_user" -gt 0 ] && ISSUES+=("󰋊 $failed_user failed user service(s)")

# ── Pending reboot (same approach as sysupdate.fish: the running kernel
#    no longer has its module directory on disk) ─────────────────
if [ ! -d "/usr/lib/modules/$(uname -r)" ]; then
    ISSUES+=("󰜉 kernel updated ($(uname -r) has no modules) — reboot pending")
fi

# ── Critical boot errors, filtering out the known TPM noise (same
#    approach as healthcheck.fish) ───────────────────────────────────
# --output=json: a multiline coredump is ONE event in journalctl, but
# "grep -c ." on the plain text counted every line of the backtrace as a
# separate error (same bug already fixed in healthcheck.fish). json emits
# one object per event on a single line no matter how many lines the
# MESSAGE has, so grep -c on that counts real events.
non_tpm=$(journalctl -b -p 3 --no-pager --output=json 2>/dev/null | grep -viE 'tpm2|pcrproduct|TPM key integrity' | grep -c .)
[ "$non_tpm" -gt 0 ] && ISSUES+=("󰍛 $non_tpm critical boot error(s) (non-TPM)")

# ── Report ──────────────────────────────────────────────────────────────
if [ "${#ISSUES[@]}" -eq 0 ]; then
    exit 0
fi

body="$(printf '%s\n' "${ISSUES[@]}")"
command -v notify-send >/dev/null 2>&1 && notify-send -u normal -i dialog-warning "Healthcheck" "$body"
