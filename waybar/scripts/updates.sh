#!/usr/bin/env bash
# ============================================================================
#  updates.sh — update checker for Waybar (pacman + AUR)
# ----------------------------------------------------------------------------
#  Modes:
#    (no args)   JSON for Waybar, served from cache when it's still fresh
#    --force     refresh the cache first, then print the JSON
#                (this is what updates-check.service calls every 30 min)
#    --list      human-readable list of what would be updated (right click)
#    --plain     one-line plain-text summary, for notifications
#
#  The package list is cached alongside the JSON so --list is instant and
#  never re-runs the network check just to show what was already counted.
# ============================================================================
set -o pipefail

CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.cache"
PKGS_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.pkgs"
NOTIFIED_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.notified"
FAILED_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.failed"
PLAIN_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-updates.plain"
CACHE_TTL=300   # 5 minutes
FEW=12          # at most this many packages get listed inside the tooltip
MANY=50         # from here on the module goes "critical"

mode="${1:-}"

# ── Escaping ────────────────────────────────────────────────────────────────
# Two different jobs: JSON is the transport, Pango is what Waybar renders the
# tooltip with. A package name is never going to contain "<", but versions
# come from a network source and the whole widget breaks silently if one ever
# does, so both are applied.
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

pango_escape() {
    local s="$1"
    # The backslashes are load-bearing: since bash 5.2 an unescaped & in the
    # replacement of ${var//pat/repl} expands to the matched text, so "&lt;"
    # silently produced "<lt;" instead of an entity.
    s="${s//&/\&amp;}"
    s="${s//</\&lt;}"
    s="${s//>/\&gt;}"
    printf '%s' "$s"
}

# ── Kernel detection ────────────────────────────────────────────────────────
# A kernel update means the running system loses its modules until reboot, so
# it's worth calling out. Matched by name because the package isn't installed
# yet (sysupdate.fish can use the /usr/lib/modules trick precisely because
# there it already happened). Excludes the linux-* packages that aren't
# kernels: linux-firmware*, linux-api-headers, *-headers, docs, tools.
is_kernel_pkg() {
    local n="$1"
    [[ "$n" == linux || "$n" == linux-* ]] || return 1
    [[ "$n" == *headers* || "$n" == *firmware* || "$n" == *api* \
       || "$n" == *docs* || "$n" == *tools* ]] && return 1
    return 0
}

# ── The actual check ────────────────────────────────────────────────────────
# Fills: updates, aur, aur_helper, error_msg — and writes PKGS_FILE as TSV
# (source, name, old version, new version).
run_check() {
    updates=0
    aur=0
    error_msg=""
    local tmp_pkgs
    tmp_pkgs="$(mktemp "${PKGS_FILE}.XXXXXX")"

    # pacman (pacman-contrib's checkupdates doesn't touch the real database)
    # checkupdates documents its exit codes: 0 = updates available, 2 = no
    # updates (normal case, not a failure), anything else (e.g. 1: couldn't
    # sync the temp DB — no network, lock, etc.) is a real failure.
    if command -v checkupdates >/dev/null 2>&1; then
        local cu_out cu_err cu_rc
        cu_out="$(mktemp)"; cu_err="$(mktemp)"
        checkupdates >"$cu_out" 2>"$cu_err"
        cu_rc=$?
        updates=$(grep -c '[^[:space:]]' "$cu_out")
        if (( cu_rc != 0 && cu_rc != 2 )); then
            error_msg="checkupdates: $(tr '\n' ' ' < "$cu_err" | sed 's/  */ /g; s/^ *//; s/ *$//')"
        fi
        awk 'NF>=4 {print "pacman\t"$1"\t"$2"\t"$4}' "$cu_out" >>"$tmp_pkgs"
        rm -f "$cu_out" "$cu_err"
    else
        error_msg="checkupdates not found (install pacman-contrib)"
    fi

    # AUR — supports yay or paru automatically
    aur_helper=""
    if command -v yay >/dev/null 2>&1; then
        aur_helper="yay"
    elif command -v paru >/dev/null 2>&1; then
        aur_helper="paru"
    fi

    if [[ -n "$aur_helper" ]]; then
        # Unlike checkupdates, yay/paru -Qua exits with code 1 both in the
        # normal "no AUR updates" case and on a real failure, and there's no
        # way to tell them apart from the exit code alone. A real failure (no
        # network, RPC down, etc.) does print something to stderr; "no
        # updates" prints nothing. timeout killing the process (124) also
        # counts as a failure.
        local au_out au_err au_rc
        au_out="$(mktemp)"; au_err="$(mktemp)"
        timeout 20 "$aur_helper" -Qua >"$au_out" 2>"$au_err"
        au_rc=$?
        aur=$(grep -c '[^[:space:]]' "$au_out")
        if (( au_rc == 124 )); then
            error_msg="${error_msg:+$error_msg; }$aur_helper: timeout (20s)"
        elif (( au_rc != 0 )) && [[ -s "$au_err" ]]; then
            error_msg="${error_msg:+$error_msg; }$aur_helper: $(tr '\n' ' ' < "$au_err" | sed 's/  */ /g; s/^ *//; s/ *$//')"
        fi
        awk 'NF>=4 {print "aur\t"$1"\t"$2"\t"$4}' "$au_out" >>"$tmp_pkgs"
        rm -f "$au_out" "$au_err"
    fi

    # Sanitize (in case grep returns empty or timeout kills the process)
    [[ "$updates" =~ ^[0-9]+$ ]] || updates=0
    [[ "$aur"     =~ ^[0-9]+$ ]] || aur=0

    # Written atomically, same as the JSON cache: --list may be reading it
    mv -f "$tmp_pkgs" "$PKGS_FILE"
}

# ── Aligned "name  old → new" block, one line per package ──────────────────
# Takes the source filter as $1 ("pacman", "aur" or "" for all).
format_pkgs() {
    local want="$1"
    [[ -f "$PKGS_FILE" ]] || return 0
    awk -F'\t' -v want="$want" '
        want == "" || $1 == want {
            n[++c] = $2; o[c] = $3; v[c] = $4
            if (length($2) > wn) wn = length($2)
            if (length($3) > wo) wo = length($3)
        }
        END { for (i = 1; i <= c; i++) printf "%-*s  %*s → %s\n", wn, n[i], wo, o[i], v[i] }
    ' "$PKGS_FILE"
}

kernel_pkgs() {
    [[ -f "$PKGS_FILE" ]] || return 0
    local src name old new
    while IFS=$'\t' read -r src name old new; do
        is_kernel_pkg "$name" && printf '%s\n' "$name"
    done < "$PKGS_FILE"
}

# ── --list: the readable window behind the right click ──────────────────────
if [[ "$mode" == "--list" ]]; then
    # Only re-check if there's nothing cached at all; otherwise this must be
    # instant. The bar and this list then always agree on what they show.
    if [[ ! -f "$PKGS_FILE" ]]; then
        printf 'Checking for updates...\n' >&2
        run_check
    fi

    pac=$(awk -F'\t' '$1=="pacman"' "$PKGS_FILE" 2>/dev/null | grep -c '[^[:space:]]')
    au=$(awk -F'\t' '$1=="aur"' "$PKGS_FILE" 2>/dev/null | grep -c '[^[:space:]]')
    tot=$((pac + au))

    {
        if (( tot == 0 )); then
            printf '\n  System up to date — nothing to update.\n\n'
        else
            printf '\n  Pending updates — %d total (%d pacman, %d AUR)\n' "$tot" "$pac" "$au"
            if (( pac > 0 )); then
                printf '\n  PACMAN (%d)\n\n' "$pac"
                format_pkgs pacman | sed 's/^/    /'
            fi
            if (( au > 0 )); then
                printf '\n  AUR (%d)\n\n' "$au"
                format_pkgs aur | sed 's/^/    /'
            fi
            mapfile -t kern < <(kernel_pkgs)
            if (( ${#kern[@]} > 0 )); then
                printf '\n  Kernel update included (%s) — reboot after updating.\n' \
                    "$(IFS=', '; printf '%s' "${kern[*]}")"
            fi
            printf '\n  Run sysupdate (or left click the module) to apply.\n\n'
        fi
        printf '  Cache written: %s\n\n' \
            "$([[ -f "$PKGS_FILE" ]] && date -r "$PKGS_FILE" '+%Y-%m-%d %H:%M' || echo 'never')"
    } | if [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
            less -R -X
        else
            cat
        fi
    exit 0
fi

# ── Serve from cache unless forced ──────────────────────────────────────────
if [[ "$mode" != "--force" && -f "$CACHE_FILE" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if (( age < CACHE_TTL )); then
        if [[ "$mode" == "--plain" ]]; then
            # Written next to the JSON by the same run, so this never has to
            # re-derive the summary by parsing the widget's own output back.
            [[ -f "$PLAIN_FILE" ]] && { cat "$PLAIN_FILE"; exit 0; }
        else
            cat "$CACHE_FILE"
            exit 0
        fi
    fi
fi

run_check
total=$((updates + aur))
mapfile -t kern < <(kernel_pkgs)

# ── Build output ────────────────────────────────────────────────────────────
if (( total == 0 )); then
    text="󰄬"
    tooltip="System up to date"$'\n'"Last checked $(date '+%H:%M')"
    css_class="updated"
    plain="System up to date"
else
    text="󰚰 $total"
    if (( total >= MANY )); then css_class="critical"; else css_class="pending"; fi

    counts="$updates pacman"
    [[ -n "$aur_helper" ]] && counts="$counts · $aur AUR ($aur_helper)"
    plain="$total update$( (( total != 1 )) && printf s ) available — $counts"

    tooltip="$total update$( (( total != 1 )) && printf s ) available"$'\n'"$counts"

    if (( total <= FEW )); then
        # Few enough to read at a glance: show them right here, monospaced so
        # the version columns line up.
        tooltip="$tooltip"$'\n\n'"<tt>$(pango_escape "$(format_pkgs '')")</tt>"
    fi

    if (( ${#kern[@]} > 0 )); then
        tooltip="$tooltip"$'\n\n'"⚠ Kernel update ($(IFS=', '; printf '%s' "${kern[*]}")) — reboot after updating"
    fi

    if (( total > FEW )); then
        tooltip="$tooltip"$'\n\n'"Right click to view the packages that would be updated"
    fi
    tooltip="$tooltip"$'\n'"Left click to update · Middle click to re-check"
fi

classes=("$css_class")

if [[ -n "$error_msg" ]]; then
    text="$text 󰀦"
    tooltip="$tooltip"$'\n\n'"⚠ $(pango_escape "$error_msg")"
    plain="$plain (check failed: $error_msg)"
    classes+=("error")
fi

printf '%s\n' "$plain" > "$PLAIN_FILE"

if [[ "$mode" == "--plain" ]]; then
    printf '%s\n' "$plain"
    exit 0
fi

# ── Desktop notification ────────────────────────────────────────────────────
# Only alerts when the total rises above the last alert (not on every
# cache refresh), and resets to 0 as soon as the system is up to date so
# the next batch of updates triggers a notification again.
last_notified=0
[[ -f "$NOTIFIED_FILE" ]] && last_notified=$(<"$NOTIFIED_FILE")
[[ "$last_notified" =~ ^[0-9]+$ ]] || last_notified=0

if (( total > 0 && total > last_notified )) && command -v notify-send >/dev/null 2>&1; then
    body="$updates pacman$( [[ -n "$aur_helper" ]] && printf ' · %s AUR (%s)' "$aur" "$aur_helper" )"
    (( ${#kern[@]} > 0 )) && body="$body"$'\n'"Kernel update included — reboot after updating"
    notify-send -a "Waybar" -i software-update-available \
        "󰚰 Updates available" "$body"
fi
printf '%s\n' "$total" > "$NOTIFIED_FILE"

# Same as above but for failures: only alerts when entering a failed state
# (not on every refresh while it keeps failing) and resets as soon as it
# works again.
was_failed=0
[[ -f "$FAILED_FILE" ]] && was_failed=$(<"$FAILED_FILE")
[[ "$was_failed" =~ ^(0|1)$ ]] || was_failed=0

if [[ -n "$error_msg" ]]; then
    if (( was_failed == 0 )) && command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical -a "Waybar" -i dialog-warning \
            "󰀦 Failed to check for updates" "$error_msg"
    fi
    printf '1\n' > "$FAILED_FILE"
else
    printf '0\n' > "$FAILED_FILE"
fi

class_json=$(printf '"%s",' "${classes[@]}")
class_json="[${class_json%,}]"

result="{\"text\":\"$(json_escape "$text")\",\"tooltip\":\"$(json_escape "$tooltip")\",\"class\":${class_json}}"

# Write the cache atomically (avoids Waybar reading a half-written file)
tmp="$(mktemp "${CACHE_FILE}.XXXXXX")"
printf '%s\n' "$result" > "$tmp"
mv -f "$tmp" "$CACHE_FILE"

printf '%s\n' "$result"
