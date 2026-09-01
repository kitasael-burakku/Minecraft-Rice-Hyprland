#!/usr/bin/env bash
# ============================================================================
#  check-personal-paths.sh — the "did I actually adapt this to my machine?"
#  audit. Surfaced as `kitasan doctor --fresh-clone`.
#
#  docs/INSTALLATION.md § 9 is a table of fifteen things that are hardcoded to
#  one specific machine. It is the highest-risk step in the whole install and
#  it arrives as homework: nothing tells you which rows you still owe. This
#  script answers that mechanically.
#
#  It does NOT compare against the original author's values. It checks that
#  every machine-specific value RESOLVES ON THIS MACHINE — a monitor mode the
#  display actually supports, an hwmon path that exists, a wallpaper that is
#  really there. That way it is worth running on a fork *and* on the machine
#  the rice was written on, where it stays quiet until something breaks (a
#  monitor swap, a renamed device, a deleted wallpaper).
#
#  Same idiom as its two siblings: writes nothing, prints only problems, exit
#  code is the number of problems found.
#
#  The checks that need a running compositor (monitor mode, input devices) are
#  skipped with a note when hyprctl can't reach one, so this is still usable
#  from a TTY on a first boot.
# ============================================================================
set -u

BASE="${KITASAN_CONFIG_DIR:-$HOME/.config}"
problems=0

warn()   { echo "  ⚠ $*"; problems=$((problems + 1)); }
detail() { echo "      $*"; }
note()   { echo "  · $*"; }

REPO_DIRS=(cava fastfetch fish gtk-3.0 gtk-4.0 hypr hyprlock kitty matugen
           qt5ct qt6ct rofi swaync systemd waybar wlogout)

# Hyprland's own naming: lowercase, every run of non-alphanumerics collapsed
# to a single dash. `hyprctl devices` prints this form; input.lua uses the
# human-readable one, so both sides get normalised before comparing.
slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }

have_hypr=0
if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors -j >/dev/null 2>&1; then
    have_hypr=1
fi

# ── 1. Absolute paths hardcoded to somebody else's home ─────────────────────
# The single most common fork breakage: qt5ct/qt6ct store color_scheme_path as
# an absolute path with the username baked in, and Qt silently falls back to a
# default palette when it doesn't resolve.
search_paths=()
for d in "${REPO_DIRS[@]}"; do
    [ -d "$BASE/$d" ] && search_paths+=("$BASE/$d")
done

if [ "${#search_paths[@]}" -gt 0 ]; then
    # "user" / "youruser" / "your-username" are documented placeholders, not
    # anyone's home: keybinds.lua and autostart.lua both use
    # `os.getenv("HOME") or "/home/user"` as a fallback. Excluded, or this
    # check cries wolf on a correctly configured machine.
    foreign="$(grep -rIoh --exclude-dir=__pycache__ -P '/home/\K[a-z_][a-z0-9_-]*' \
                 "${search_paths[@]}" 2>/dev/null | sort -u \
                 | grep -vx "$USER" | grep -vxE 'user|youruser|your-username' || true)"
    if [ -n "$foreign" ]; then
        warn "hardcoded paths — files still point at another user's home"
        while IFS= read -r u; do
            [ -n "$u" ] || continue
            detail "/home/$u/ (you are '$USER'), referenced in:"
            grep -rIl --exclude-dir=__pycache__ -F "/home/$u/" "${search_paths[@]}" 2>/dev/null \
                | sed "s|$BASE/|        |" | head -8
        done <<< "$foreign"
    fi
fi

# ── 2. The monitor mode is one this display can actually do ─────────────────
# monitors.lua uses output = "" (all outputs), so the output name needs no
# checking — but the mode is a fixed "WxH@RRHz" string. Hyprland falls back
# silently when it isn't available, which looks like "my refresh rate is wrong"
# and never like a config error.
MON_LUA="$BASE/hypr/modules/monitors.lua"
if [ -f "$MON_LUA" ]; then
    mode="$(grep -oP '^\s*mode\s*=\s*"\K[^"]+' "$MON_LUA" 2>/dev/null | head -1 || true)"
    case "$mode" in
        ""|preferred|highrr|highres|auto) ;;   # not a literal mode, nothing to verify
        *)
            if [ "$have_hypr" -eq 1 ]; then
                if ! hyprctl monitors -j 2>/dev/null | python3 -c "
import json,sys
want=sys.argv[1]
mons=json.load(sys.stdin)
print('yes' if any(want in m.get('availableModes',[]) for m in mons) else 'no')
" "$mode" 2>/dev/null | grep -q yes; then
                    warn "monitors.lua — no connected display offers mode '$mode'"
                    detail "Hyprland will silently fall back to something else."
                    detail "Available on this machine:"
                    hyprctl monitors -j 2>/dev/null | python3 -c "
import json,sys
for m in json.load(sys.stdin):
    modes=m.get('availableModes',[])[:4]
    print('        %s: %s%s' % (m['name'], ', '.join(modes), ' …' if len(m.get('availableModes',[]))>4 else ''))
" 2>/dev/null
                    detail "or use mode = \"preferred\" to let Hyprland decide"
                fi
            else
                note "monitor mode not checked — no running Hyprland to ask"
            fi
            ;;
    esac
fi

# ── 3. The per-device input blocks actually match a device ──────────────────
# Two separate failures, both silent:
#
#   a) The name isn't in slug form. Hyprland matches devices on the slugified
#      name that `hyprctl devices` prints, NOT the manufacturer's display name.
#      A block with the display name is ignored outright — and `hyprctl eval`
#      still answers "ok", because it validates the call, not the match. This
#      is not a guess: it was verified on 2026-09-01 by setting scroll_factor
#      through both forms and reading it back from `hyprctl devices -j`. The
#      display name left it untouched; the slug changed it. Two blocks in this
#      repo had been dead since they were written.
#
#   b) The name is a valid slug but nothing by that name is plugged in.
#
# (a) is checked without needing a compositor, which matters: it is a typo
# class, not a hardware fact.
IN_LUA="$BASE/hypr/modules/input.lua"
if [ -f "$IN_LUA" ]; then
    dev_names="$(grep -oP '^\s*name\s*=\s*"\K[^"]+' "$IN_LUA" 2>/dev/null || true)"
    if [ -n "$dev_names" ]; then
        present=""
        [ "$have_hypr" -eq 1 ] && \
            present="$(hyprctl devices 2>/dev/null | grep -oP '^\t\t\K[a-z0-9][a-z0-9-]*$' | sort -u || true)"

        checked_hw=0
        while IFS= read -r dn; do
            [ -n "$dn" ] || continue
            dn_slug="$(slug "$dn")"

            if [ "$dn" != "$dn_slug" ]; then
                warn "input.lua — device name '$dn' is not in slug form"
                detail "Hyprland matches the name \`hyprctl devices\` prints, so this"
                detail "block is silently ignored — no error, and eval still says ok"
                detail "use: name = \"$dn_slug\""
                continue
            fi

            if [ "$have_hypr" -eq 1 ]; then
                checked_hw=1
                if ! printf '%s\n' "$present" | grep -qx "$dn_slug"; then
                    warn "input.lua — no connected device is named '$dn'"
                    detail "its per-device settings are being ignored"
                    detail "connected: $(printf '%s' "$present" | tr '\n' ' ' | cut -c1-160)"
                fi
            fi
        done <<< "$dev_names"

        [ "$have_hypr" -eq 0 ] && [ "$checked_hw" -eq 0 ] && \
            note "input devices not checked against hardware — no running Hyprland"
    fi
fi

# ── 4. The CPU temperature sensor path exists, in both copies ───────────────
# waybar/config.jsonc and rofi/scripts/dashboard.sh hardcode the same hwmon
# path separately. Fixing one and not the other is the documented trap.
WB="$BASE/waybar/config.jsonc"
DASH="$BASE/rofi/scripts/dashboard.sh"
hw_wb=""; hw_dash=""
[ -f "$WB" ]   && hw_wb="$(grep -oP '"hwmon-path-abs"\s*:\s*"\K[^"]+' "$WB" 2>/dev/null | head -1 || true)"
[ -f "$DASH" ] && hw_dash="$(grep -oP '^HWMON_CPU="\K[^"]+' "$DASH" 2>/dev/null | head -1 || true)"

[ -n "$hw_wb" ] && [ ! -d "$hw_wb" ] && {
    warn "waybar hwmon — '$hw_wb' doesn't exist on this machine"
    detail "the CPU temperature module will stay empty"
    detail "find yours with: for h in /sys/class/hwmon/hwmon*; do echo \"\$h \$(cat \$h/name)\"; done"
}
[ -n "$hw_dash" ] && [ ! -d "$hw_dash" ] && \
    warn "dashboard hwmon — '$hw_dash' doesn't exist on this machine"
[ -n "$hw_wb" ] && [ -n "$hw_dash" ] && [ "$hw_wb" != "$hw_dash" ] && {
    warn "hwmon — waybar and dashboard.sh disagree on the sensor path"
    detail "waybar/config.jsonc:      $hw_wb"
    detail "rofi/scripts/dashboard.sh: $hw_dash"
}

# ── 5. The default wallpaper is a file that exists ──────────────────────────
# Video wallpapers are gitignored, so on a fresh clone this points at something
# that was never distributed.
AW="$BASE/hypr/scripts/apply-wallpaper.sh"
if [ -f "$AW" ]; then
    dw="$(grep -oP '^DEFAULT_WALLPAPER="\K[^"]+' "$AW" 2>/dev/null | head -1 || true)"
    dw="${dw//\$HOME/$HOME}"
    [ -n "$dw" ] && [ ! -f "$dw" ] && {
        warn "DEFAULT_WALLPAPER — '$dw' doesn't exist"
        detail "video wallpapers aren't distributed with the repo; point this"
        detail "at one you actually have (hypr/scripts/apply-wallpaper.sh)"
    }
fi

# ── 6. The wallpaper picker's directories exist ─────────────────────────────
for pair in "WALLPAPER_DIR_IMG:$HOME/Pictures/Wallpapers" "WALLPAPER_DIR_VIDEO:$HOME/Videos/Wallpapers"; do
    var="${pair%%:*}"; def="${pair#*:}"
    dir="${!var:-$def}"
    [ -d "$dir" ] || {
        warn "wallpapers — '$dir' doesn't exist"
        detail "the picker reads it; override with \$$var if yours lives elsewhere"
    }
done

# ── 7. Qt's color scheme path resolves ──────────────────────────────────────
for qt in qt5ct qt6ct; do
    conf="$BASE/$qt/$qt.conf"
    [ -f "$conf" ] || continue
    csp="$(grep -oP '^color_scheme_path=\K.*' "$conf" 2>/dev/null | tr -d '\r' | head -1 || true)"
    [ -n "$csp" ] || continue
    [ -f "$csp" ] || {
        warn "$qt — color_scheme_path points at a file that doesn't exist"
        detail "$csp"
        detail "Qt apps silently fall back to a default palette. Fix the path,"
        detail "then run: bash ~/.config/hypr/scripts/apply-static-colors.sh"
    }
done

# ── 8. The programs the keybinds launch are installed ───────────────────────
# Only the plain single-command entries — the rofi ones are shell pipelines
# whose real dependency is rofi itself, already covered by the session coming up.
PROG_LUA="$BASE/hypr/modules/programs.lua"
if [ -f "$PROG_LUA" ]; then
    missing=""
    while IFS= read -r line; do
        key="${line%%|*}"; cmd="${line#*|}"
        case "$cmd" in *' '*|*'$'*|*'|'*) continue ;; esac
        command -v "$cmd" >/dev/null 2>&1 || missing+="        $key = $cmd"$'\n'
    done < <(grep -oP '^\s*\K(\w+)(?=\s*=\s*")' "$PROG_LUA" 2>/dev/null | while read -r k; do
                 v="$(grep -oP "^\\s*$k\\s*=\\s*\"\\K[^\"]+" "$PROG_LUA" | head -1)"
                 printf '%s|%s\n' "$k" "$v"
             done)
    [ -n "$missing" ] && {
        warn "programs.lua — commands that aren't installed"
        printf '%s' "$missing"
        detail "their keybinds will do nothing until you install them or"
        detail "change the entry in hypr/modules/programs.lua"
    }
fi

# ── 9. The fork's own checkout path ─────────────────────────────────────────
# dotbackup-remind.sh and dashboard.sh both assume ~/Projects/dotfiles.
for f in "hypr/scripts/dotbackup-remind.sh:REPO" "rofi/scripts/dashboard.sh:DOTFILES_REPO"; do
    file="$BASE/${f%%:*}"; var="${f#*:}"
    [ -f "$file" ] || continue
    repo="$(grep -oP "^$var=\"\\K[^\"]+" "$file" 2>/dev/null | head -1 || true)"
    repo="${repo//\$HOME/$HOME}"
    [ -n "$repo" ] && [ ! -d "$repo" ] && {
        warn "${f%%:*} — the repo path '$repo' doesn't exist"
        detail "only matters if you keep your own fork checked out; otherwise"
        detail "skip dotbackup-remind.timer entirely"
    }
done

# ── 10. $USER_PRETTY ────────────────────────────────────────────────────────
# Has a documented fallback to $USER, so this is a note, not a fault.
if [ -z "${USER_PRETTY:-}" ]; then
    note "\$USER_PRETTY isn't set — Starship and Fastfetch fall back to \$USER"
    detail "set your own with: set -Ux USER_PRETTY \"Your Name\""
fi

exit "$problems"
