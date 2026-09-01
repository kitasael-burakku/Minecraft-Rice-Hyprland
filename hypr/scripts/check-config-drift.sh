#!/usr/bin/env bash
# ============================================================================
#  check-config-drift.sh — informational check (blocks nothing) for the class
#  of bug that dotbackup's sync direction makes easy to create: a reference
#  in one file that quietly stops matching reality in another.
#
#  Why this exists: dotbackup syncs ~/.config INTO the repo, so config changes
#  land as "dotfiles: backup <date>" commits with no stated intent. Nothing
#  compares the pieces against each other, so a half-finished migration can
#  sit broken for days. That is exactly what happened to the GTK layer in
#  August 2026 — matugen kept generating gtk-colors.css after nothing imported
#  it any more, theme-base.css was left dangling at a deleted theme, and the
#  icon theme drifted apart between GTK and Qt/Rofi. Every one of those was
#  mechanically detectable; nothing was looking.
#
#  Companion to check-template-parity.sh (same idiom: silent on success,
#  exit code = number of problems, surfaced by `kitasan doctor`). That one
#  checks the INSIDE of the color files; this one checks the wiring BETWEEN
#  files.
#
#  Five checks:
#    1. every @import in gtk.css resolves, and gtk.css isn't an nwg-look symlink
#    2. CursorTheme / GTKTheme name directories that actually exist
#    3. the five places that hardcode the icon theme agree
#    4. every file matugen generates has something that loads it
#    5. no broken symlinks in the config dirs this repo owns
# ============================================================================
set -u

# Overridable so the checks can be exercised against a fixture tree instead of
# the live config — that is how this script's own failure modes were verified.
BASE="${KITASAN_CONFIG_DIR:-$HOME/.config}"
problems=0

warn() {
    echo "  ⚠ $*"
    problems=$((problems + 1))
}
detail() { echo "      $*"; }

# Config dirs this repo publishes. Used to scope the searches so unrelated
# things under ~/.config (VSCodium's edit history, browser caches) can't
# create noise — that history in particular mentions every color file this
# rice has ever had, which would make check 4 useless.
REPO_DIRS=(cava fastfetch fish gtk-3.0 gtk-4.0 hypr hyprlock kitty matugen
           qt5ct qt6ct rofi swaync systemd waybar wlogout)

# ── 1. gtk.css: imports resolve, and the file is still ours ─────────────────
# gtk.css is a one-line "@import 'gtk-colors.css';" on both sides. nwg-look
# replaces it with a symlink to whatever GTK4 theme you pick in its GUI, which
# silently drops the color overlay — and dotbackup then follows the symlink and
# commits the theme's whole stylesheet into the repo.
for gtkdir in gtk-3.0 gtk-4.0; do
    css="$BASE/$gtkdir/gtk.css"

    # -L before -f on purpose: -f follows the link, so a symlink pointing at a
    # theme file that has since been uninstalled would otherwise be reported as
    # "doesn't exist" and bury the far more useful "nwg-look replaced this".
    if [ -L "$css" ]; then
        warn "gtk.css — $gtkdir/gtk.css is a symlink, not a real file"
        detail "-> $(readlink "$css")"
        [ -e "$css" ] || detail "(and the target no longer exists)"
        detail "nwg-look does this. Restore it with:"
        detail "printf \"@import 'gtk-colors.css';\\n\" > ~/.config/$gtkdir/gtk.css"
        continue
    fi

    if [ ! -f "$css" ]; then
        warn "gtk.css — $gtkdir/gtk.css doesn't exist"
        continue
    fi

    imports="$(grep -oP "@import\s+['\"]\K[^'\"]+" "$css" 2>/dev/null || true)"

    if [ -z "$imports" ]; then
        warn "gtk.css — $gtkdir/gtk.css has no @import"
        detail "it should pull in gtk-colors.css, or the palette never loads"
        continue
    fi

    while IFS= read -r imp; do
        [ -n "$imp" ] || continue
        case "$imp" in
            /*)  target="$imp" ;;
            \~*) target="$HOME${imp#\~}" ;;
            *)   target="$BASE/$gtkdir/$imp" ;;
        esac
        if [ ! -e "$target" ]; then
            warn "gtk.css — $gtkdir/gtk.css imports '$imp', which doesn't exist"
            detail "expected at: $target"
            detail "run: bash ~/.config/hypr/scripts/apply-static-colors.sh"
        fi
    done <<< "$imports"
done

# ── 2. Theme names point at directories that exist ──────────────────────────
# XCURSOR and GTK both match on the theme's DIRECTORY name and both are
# case-sensitive, so a theme renamed, uninstalled or capitalised differently
# fails silently: you just get the default arrow / the default theme.
ENV_LUA="$BASE/hypr/modules/environment.lua"
if [ -f "$ENV_LUA" ]; then
    cursor_theme="$(grep -oP '^CursorTheme\s*=\s*"\K[^"]+' "$ENV_LUA" 2>/dev/null || true)"
    gtk_theme="$(grep -oP '^GTKTheme\s*=\s*"\K[^"]+' "$ENV_LUA" 2>/dev/null || true)"

    if [ -n "$cursor_theme" ]; then
        found=""
        for d in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do
            [ -d "$d/$cursor_theme" ] && { found="$d/$cursor_theme"; break; }
        done
        if [ -z "$found" ]; then
            warn "CursorTheme — '$cursor_theme' isn't installed anywhere"
            detail "looked in /usr/share/icons, ~/.icons, ~/.local/share/icons"
            detail "the name must be the theme's DIRECTORY, and it is case-sensitive"
        fi
    fi

    if [ -n "$gtk_theme" ]; then
        found=""
        for d in /usr/share/themes "$HOME/.themes" "$HOME/.local/share/themes"; do
            [ -d "$d/$gtk_theme" ] && { found="$d/$gtk_theme"; break; }
        done
        if [ -z "$found" ]; then
            warn "GTKTheme — '$gtk_theme' isn't installed anywhere"
            detail "looked in /usr/share/themes, ~/.themes, ~/.local/share/themes"
        fi
    fi
fi

# ── 3. The icon theme is spelled the same in all five places ────────────────
# Two of the five (the settings.ini files) are written by nwg-look and are NOT
# versioned, so they're the ones most likely to drift away from the three the
# repo does ship. When they disagree, GTK apps and Qt/Rofi show different sets.
declare -a icon_names=() icon_where=()
add_icon() { [ -n "$2" ] && { icon_names+=("$2"); icon_where+=("$1"); }; }

for gtkdir in gtk-3.0 gtk-4.0; do
    ini="$BASE/$gtkdir/settings.ini"
    if [ -f "$ini" ]; then
        add_icon "$gtkdir/settings.ini" \
            "$(grep -oP '^gtk-icon-theme-name\s*=\s*\K.*' "$ini" 2>/dev/null | tr -d '\r' || true)"
    else
        warn "icon theme — $gtkdir/settings.ini not found"
        detail "nwg-look writes it and it isn't versioned; until it exists,"
        detail "GTK apps use the default icon theme while Qt/Rofi use their own"
    fi
done

for qt in qt5ct qt6ct; do
    conf="$BASE/$qt/$qt.conf"
    [ -f "$conf" ] && add_icon "$qt/$qt.conf" \
        "$(grep -oP '^icon_theme\s*=\s*\K.*' "$conf" 2>/dev/null | tr -d '\r' || true)"
done

rasi="$BASE/rofi/window-switcher.rasi"
[ -f "$rasi" ] && add_icon "rofi/window-switcher.rasi" \
    "$(grep -oP 'icon-theme:\s*"\K[^"]+' "$rasi" 2>/dev/null || true)"

if [ "${#icon_names[@]}" -gt 0 ]; then
    unique="$(printf '%s\n' "${icon_names[@]}" | sort -u)"
    if [ "$(printf '%s\n' "$unique" | wc -l)" -gt 1 ]; then
        warn "icon theme — the hardcoded names disagree"
        for i in "${!icon_names[@]}"; do
            detail "$(printf '%-28s %s' "${icon_where[$i]}" "${icon_names[$i]}")"
        done
        detail "all of them have to match or GTK and Qt/Rofi render different sets"
    else
        # They agree — but does the theme exist?
        theme="$(printf '%s' "$unique")"
        found=""
        for d in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do
            [ -d "$d/$theme" ] && { found="$d/$theme"; break; }
        done
        [ -z "$found" ] && {
            warn "icon theme — '$theme' is set everywhere but isn't installed"
            detail "looked in /usr/share/icons, ~/.icons, ~/.local/share/icons"
        }
    fi
fi

# ── 4. Everything matugen generates has a consumer ──────────────────────────
# The GTK bug in one line: matugen kept writing gtk-colors.css long after the
# @import that loaded it was gone. A generated file nobody reads is dead
# weight at best and a silently-broken feature at worst.
#
# "Consumer" = a non-comment line naming the file, inside the dirs above,
# excluding the file itself, the *.static.* mirrors, and the two scripts that
# WRITE these files (apply-static-colors.sh mentions every single one of them,
# so counting it would make this check always pass). config.toml's own
# input_path/output_path lines are excluded for the same reason — they name
# every output by construction, which silently made this check a no-op until
# it was tested against a known-broken tree. Its post_hook lines DO count:
# running a generated file is a legitimate way to consume it.
#
# Known limit: the match is by basename, so outputs that share one can mask
# each other — waybar/, swaync/ and wlogout/ all generate a "colors.css", and
# any one of the three keeps the other two looking alive. Verified: commenting
# out waybar's @import is NOT caught. What this check does catch is a file with
# no readers anywhere, which is the failure mode that actually happened (the
# GTK one, whose basename is unique). Narrowing it to per-directory matching
# was tried and rejected: hyprlock/colors.conf is loaded from hypr/hyprlock.conf
# as "source = $hyprlockDir/colors.conf", so a directory-scoped or
# path-literal match reports it as orphaned when it isn't.
MATUGEN_CONF="$BASE/matugen/config.toml"

# Loaded by convention, not by reference — no file can name these, so an
# absence of references is correct and must not be reported.
is_convention_loaded() {
    case "$1" in
        starship.toml)      return 0 ;;  # starship reads ~/.config/starship.toml by name
        theme-goldship.fish) return 0 ;; # fish sources every conf.d/*.fish on shell start
        *) return 1 ;;
    esac
}

if [ -f "$MATUGEN_CONF" ]; then
    outputs="$(grep -oP "output_path\s*=\s*'\K[^']+" "$MATUGEN_CONF" 2>/dev/null || true)"

    search_paths=()
    for d in "${REPO_DIRS[@]}"; do
        [ -d "$BASE/$d" ] && search_paths+=("$BASE/$d")
    done

    while IFS= read -r out; do
        [ -n "$out" ] || continue
        out_abs="${out/#\~/$HOME}"
        rel="${out_abs#"$HOME"/.config/}"   # display only; config.toml holds absolute paths
        base_name="$(basename "$out_abs")"

        is_convention_loaded "$base_name" && continue

        hits="$(grep -rIn --fixed-strings "$base_name" "${search_paths[@]}" 2>/dev/null \
                | grep -v "^$out_abs:" \
                | grep -v '\.static\.' \
                | grep -v 'apply-static-colors\.sh:' \
                | grep -v 'check-template-parity\.sh:' \
                | grep -v 'check-config-drift\.sh:' \
                | grep -vP ':\s*[0-9]+:\s*(#|//|--|/\*|\*)' \
                | grep -vP ':\s*[0-9]+:\s*(input_path|output_path)\s*=' \
                | head -1 || true)"

        if [ -z "$hits" ]; then
            warn "matugen output — nothing loads '$rel'"
            detail "matugen regenerates it on every wallpaper change, but no"
            detail "@import / include / source in the config refers to it"
        fi
    done <<< "$outputs"
fi

# ── 5. No broken symlinks in the dirs this repo owns ────────────────────────
# theme-base.css spent weeks pointing at a ~/.themes/ entry that had been
# deleted. Nothing complained because nothing read it any more — but a dangling
# symlink is always either a leftover or a genuinely broken load.
dangling=""
for d in "${REPO_DIRS[@]}"; do
    [ -d "$BASE/$d" ] || continue
    found="$(find "$BASE/$d" -xtype l 2>/dev/null || true)"
    [ -n "$found" ] && dangling+="$found"$'\n'
done

if [ -n "${dangling%$'\n'}" ]; then
    warn "broken symlinks in the config dirs"
    while IFS= read -r l; do
        [ -n "$l" ] || continue
        detail "$(printf '%-45s -> %s' "${l#"$BASE"/}" "$(readlink "$l")")"
    done <<< "${dangling%$'\n'}"
fi

exit "$problems"
