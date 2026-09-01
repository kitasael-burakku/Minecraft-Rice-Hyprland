# Theming

How color gets into every app, why GTK3 and GTK4 are handled differently, and why Steam games show up without icons in Rofi until you run one extra script.

For the actual gnome-look.org links to the theme assets referenced below (GTK theme, icon theme, cursor theme), see [Themes, icons, cursors and fonts](INSTALLATION.md#2-themes-icons-cursors-and-fonts) in the installation guide — this page is about how the pipeline uses them, not where to download them.

---

## Two tracks: static baseline vs. matugen

I change wallpapers often — based on mood or time of day — but I don't always want my color palette to follow. So dynamic theming is a real, fully wired feature; it's just **off by default**. A fresh clone boots with the static "Kitasan Glass" palette until you turn it on.

**Toggle:** `SUPER + SHIFT + W` runs `rofi/scripts/matugen_toggle.sh`. It flips a sentinel file (`~/.config/matugen/enabled`) and:
- **Turning on** generates colors right away from whatever wallpaper is currently active (or asks you to pick one, if it can't detect it) and notifies you via `notify-send`.
- **Turning off** restores the exact static values — bit for bit, no visual drift from the pre-toggle look.

**Which scheme:** the toggle above is binary (on/off); `SUPER + ALT + W` (`rofi/scripts/theme.sh`) is the other dimension — pick *which* of matugen's 9 Material You schemes to use (`tonal-spot` (the default), `vibrant`, `expressive`, `fidelity`, `content`, `neutral`, `fruit-salad`, `monochrome`, `rainbow`) while dynamic theming is on. The same list has a tenth entry, "Static", which is just the toggle-off path.

The chosen scheme is stored in `~/.config/matugen/scheme` and read by `matugen_reload.sh` on every subsequent regeneration, so it survives wallpaper changes until you pick a different one. `matugen_reload.sh` validates that file against the same whitelist and silently falls back to `scheme-tonal-spot` if it holds anything else, so a hand-edit can't feed matugen an invalid `-t`. Picking a scheme also *turns dynamic theming on* if it was off — choosing a profile implies wanting to see it.

> **`matugen/scheme` is local state, and gitignored** — like its sibling `matugen/enabled`. It holds one line, one of the nine scheme names above, and it's rewritten every time you switch profiles. It is deliberately *not* versioned: it says what the machine that wrote it last happened to be running, not anything about the rice's design, and leaving it tracked meant every scheme switch turned into a commit. A fresh clone has no such file, which is a supported state — `matugen_reload.sh` falls back to `scheme-tonal-spot`, the documented default, when it's missing. Nothing needs to be created by hand; `SUPER + ALT + W` or `kitasan theme <scheme>` writes it the first time you pick a profile.

The same thing is available headless as `kitasan theme <scheme>` (no `scheme-` prefix needed: `kitasan theme vibrant`).

**Pipeline:** applying a wallpaper (`SUPER + W`, or the `wallpaper.service` restore-on-start) calls `rofi/scripts/matugen_reload.sh`, which — only if the sentinel is present — runs `matugen` against the current wallpaper (extracting a frame with `ffmpeg` first if it's a video) using the templates and hooks declared in `matugen/config.toml`:

| Surface | Output | Reload mechanism |
|---|---|---|
| Rofi | `rofi/colors.rasi` | none needed — Rofi re-reads on next launch |
| Waybar | `waybar/colors.css` | `pkill -SIGUSR2 waybar` (reloads CSS without killing the bar) |
| Kitty | `kitty/colors/colors.conf` | `killall -SIGUSR1 kitty` |
| Wlogout | `wlogout/colors.css` | none needed — relaunched per invocation |
| Hyprlock | `hyprlock/colors.conf` | none needed — each lock is a fresh process |
| Hyprlock MPRIS progress bar | `hyprlock/scripts/music-colors.sh` | none needed — `sourced` by `player.sh` on each lock, same as `colors.conf` above |
| Hyprland borders | `hypr/dynamic-colors.sh` | run through `hyprctl eval` right after being generated (`hyprctl keyword` doesn't work against this Lua config — see [ARCHITECTURE.md](ARCHITECTURE.md#hyprland-in-lua)) |
| SwayNC | `swaync/colors.css` | `swaync-client -rs` |
| Starship | `starship.toml` | none needed — re-read on every prompt render |
| Fish | `fish/conf.d/theme-goldship.fish` | none possible — `conf.d/` is only sourced when a shell starts; new terminals pick it up automatically |
| GTK3 | `gtk-3.0/gtk-colors.css` | none possible — GTK only reads `gtk.css` at app launch; already-open apps keep their old colors. **Currently inert** — nothing imports this file any more, see [GTK theming](#gtk-theming) below |
| GTK4 | `gtk-4.0/gtk-colors.css` | same as GTK3, and inert for the same reason |
| Qt5 | `qt5ct/colors/kitasan-glass.conf` | none possible — same per-launch limitation as GTK |
| Qt6 | `qt6ct/colors/kitasan-glass.conf` | same as Qt5 (same template, different output path) |

That's **14 generated files from 12 templates** — GTK3/GTK4 share `gtk-colors.css`, and Qt5/Qt6 share `qt-colors.conf`, since in both cases the overrides are identical and only the destination differs.

Every generated file has a `*.static.*` counterpart (e.g. `rofi/colors.static.rasi`) that's the source of truth when dynamic theming is off, and what `matugen_toggle.sh` and `hypr/scripts/apply-static-colors.sh` restore when you turn it back off. Semantic colors (errors, critical states) follow the wallpaper too, kept consistent across every surface on purpose.

`hypr/scripts/check-template-parity.sh` (run by `kitasan doctor`) compares each template against its static mirror and reports any identifier that exists on one side only — the usual symptom of adding a color to the dynamic template and forgetting the static one. It's informational and blocks nothing.

> **Where the reload actually happens:** not in `matugen_reload.sh`. Each per-app reload is a `post_hook` on that template in `matugen/config.toml`; the script only resolves which image to feed matugen (extracting a frame with `ffmpeg` if the wallpaper is a video) and invokes it. If a surface stops reloading, the hook is what to look at.

**GTK/Qt are deliberately partial.** The GTK theme defines close to 90 color variables for very specific states (insensitive/backdrop/hover/unfocused/titlebar, mostly with a `_breeze` suffix). Re-tinting all of them blind wasn't worth the risk of a broken-looking widget somewhere; only the roles that define the palette's *identity* — background, foreground, selection, borders, and the semantic colors — are overridden, both under their base name and their `_breeze` variant. The Qt palette follows the same philosophy: it's a minimal diff over the stock `darker.conf` scheme (still shipped by `qt5ct`/`qt6ct`), touching only `WindowText`/`Text`/`Base`/`Window`/`Highlight`/`HighlightedText`/`AlternateBase` and leaving the other ~14 QPalette roles exactly as they were.

If you want to adapt this to your own palette instead of matugen's Material You output, edit the templates in `matugen/templates/` and their matching `*.static.*` baseline — everything downstream (hooks, toggle, sentinel) stays the same.

---

## GTK theming

> **This section was rewritten to match what the repo actually ships.** The GTK layer was reworked around the 2026-08-30 backup (`c87bfab`), together with the switch to a stock GTK theme. The two-`@import` chain described in earlier revisions of this document is no longer what's in the tree. See [Known inconsistency](#known-inconsistency-in-the-gtk-layer) at the end of this section for the loose ends that rework left behind.

**What ships today:** `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` are **byte-identical, self-contained colour files**. No `@import`, no theme chaining. Each declares the same palette twice, under two sets of names:

- the **libadwaita / GTK4** role names — `accent_color`, `window_bg_color`, `view_bg_color`, `headerbar_bg_color`, `card_bg_color`, `sidebar_bg_color`, `dialog_bg_color`, `popover_bg_color`, the `destructive_*` / `warning_*` / `success_*` semantics;
- the **classic GTK3 (Adwaita)** names — `theme_bg_color`, `theme_fg_color`, `theme_base_color`, `theme_selected_bg_color`, the `theme_unfocused_*` set, `insensitive_*`, `borders`, `error_color`.

Each toolkit ignores the other's names, so both sets coexist in one file and one file themes both. That's what makes the two copies identical — they aren't two configurations, they're the same configuration deployed twice.

This works because `GTKTheme` is now **`Adwaita-dark`** — stock GTK, no third-party theme to chain onto. The historical problem this section used to describe (GTK4 dropped support for the `GTK_THEME` env var that GTK3 still honors, so `~/.config/gtk-4.0/gtk.css` had to *contain* the theme rather than merely override it) went away with the third-party theme: there is no external stylesheet left to pull in on either side.

> ⚠️ **`nwg-look` will still overwrite `~/.config/gtk-4.0/gtk.css`** if you use its GUI to pick a GTK4 theme — it replaces the file with a direct symlink to the theme's own stylesheet. The palette above is then gone. Check with `head -3 ~/.config/gtk-4.0/gtk.css`: it should show the `/* Ryoku palette -> GTK ... */` comment, not theme CSS rules. This is worth checking **before a `dotbackup` run** too — the sync follows the symlink and commits the theme's entire stylesheet into the repo, which is how a previous drift got in.

**GTK4 dynamic theming was tried and reverted.** The GTK theme in use at the time painted most of its UI with literal hardcoded hex values rather than through the standard `@theme_bg_color`/`@theme_selected_bg_color` variables — it *declared* those names for compatibility but barely *used* them (`@theme_text_color` appeared exactly once across the entire stylesheet). Redefining them therefore had close to no visible effect on GTK4 apps. Making GTK4 genuinely follow the wallpaper would have meant patching literal hex strings inside a private copy of a third-party stylesheet — fragile, and silently broken by any theme update. That reasoning is what the current stock-Adwaita + one-palette-file arrangement replaces.

### Known inconsistency in the GTK layer

Documented rather than silently patched, because resolving it is a design decision, not a doc fix. As of this writing, three artifacts of the pre-rework chain are still in the tree and no longer do anything:

1. **`gtk-colors.css` is generated but never imported.** `matugen/config.toml` still declares the `[templates.gtk3]` and `[templates.gtk4]` outputs, and `apply-static-colors.sh` still copies `gtk-colors.static.css` over them. Since neither `gtk.css` imports that file any more, **GTK apps no longer follow the wallpaper at all** — the matugen GTK path is inert, not merely partial as it was before.
2. **`theme-base.css` is dead.** Nothing imports it. `apply-static-colors.sh` still tries to recreate the symlink from `GTKTheme`, but it only searches `~/.themes/` and `~/.local/share/themes/` — and `Adwaita-dark` lives in `/usr/share/themes/`, so the symlink is never refreshed. On the reference machine it is currently *dangling*, still pointing at a `~/.themes/Win11-Fantasy-Dark/` that no longer exists. Harmless only because nothing reads it.
3. **The header comment in `gtk.css` says "Rendered by matugen; do not edit."** No matugen template produces `gtk.css` — `config.toml` only ever writes `gtk-colors.css`. The file is hand-maintained despite what it says about itself.

If the intent is for GTK to follow the wallpaper again, the smallest fix is to restore an `@import 'gtk-colors.css';` line at the top of both `gtk.css` files and let the existing template pipeline resume. If the intent is a fixed GTK palette, then the two matugen GTK templates, the two `gtk-colors.static.css` files and the `theme-base.css` block in `apply-static-colors.sh` are all removable. **Neither was assumed here.**

---

## Qt theming

`qt5ct`/`qt6ct` read `qt5ct.conf`/`qt6ct.conf`, which point `color_scheme_path` at `qt5ct/colors/kitasan-glass.conf` / `qt6ct/colors/kitasan-glass.conf` — **hardcoded absolute paths** containing the original machine's username. This is the one thing in the Qt setup you must edit yourself after cloning (see [step 9 of INSTALLATION.md](INSTALLATION.md#9-fix-personal-paths)); without it, Qt apps silently fail to find the color scheme and fall back to a default palette.

`QT_QPA_PLATFORMTHEME=qt6ct` is what makes Qt apps actually read this config at all (set in `hypr/modules/environment.lua`).

---

## Swapping any of these themes for your own

1. Install your GTK/icon/cursor theme (see [INSTALLATION.md](INSTALLATION.md#2-themes-icons-cursors-and-fonts) for where to get them and where they go).
2. Update `CursorTheme` / `GTKTheme` in `hypr/modules/environment.lua`. `CursorTheme` must be the theme's **directory** name and is case-sensitive.
3. If you install a third-party GTK theme in place of stock `Adwaita-dark`, decide how it should combine with `gtk-3.0/gtk.css` / `gtk-4.0/gtk.css`. Those files are a self-contained palette today, not an overlay — a GTK4 theme needs its own stylesheet imported *before* the palette, or the palette will be all GTK4 gets. See [Known inconsistency](#known-inconsistency-in-the-gtk-layer) above; this is the part that is genuinely undecided in the current tree.
4. If you used `nwg-look` to apply the theme, check `gtk-4.0/gtk.css` afterwards — it overwrites that file (see the warning above).
5. Update `icon_theme=` in `qt5ct/qt5ct.conf` and `qt6ct/qt6ct.conf` if you changed the icon theme; Qt reads its icon theme from there, not from the GTK settings.

Icon themes mostly don't need a code change — `hypr/scripts/link-steam-icons.sh` writes into the universal `hicolor` fallback (see below), which works under any active icon theme. Two places do hardcode the name and have to be kept in sync with it: `rofi/window-switcher.rasi` (`configuration { icon-theme: "Slot-Gray-Dark-Icons"; }`, so its by-class lookup has something concrete to resolve against) and `icon_theme=` in `qt5ct.conf`/`qt6ct.conf`. The icon theme is still `Slot-Gray-Dark-Icons`; only the GTK theme and the cursor theme changed in the rework described above.

---

## Steam game icons

Steam writes `.desktop` launcher files for your library at `~/.local/share/applications/*.desktop` with an entry like:

```ini
Icon=steam_icon_945360
```

That name is **never materialized as an actual icon file anywhere** on a native Linux Steam install — Steam only caches real per-game artwork (`logo.png`, header, hero images, capsule art) under `~/.local/share/Steam/appcache/librarycache/<appid>/`. So Rofi (or any other launcher doing standard XDG icon-theme resolution) looks for `steam_icon_<appid>` in the active icon theme, its `Inherits=` chain, and the `hicolor` fallback — and never finds it, for any theme, because no icon theme is expected to ship per-game Steam icons. (Some community themes like Papirus/Ant-* hand-curate icons for popular game IDs under exactly this filename pattern — but that only covers whatever games the theme maintainer picked, not yours specifically.)

`hypr/scripts/link-steam-icons.sh` fixes this without touching anything Steam manages or duplicating any image data:

- For every `steam_icon_<appid>` referenced in `~/.local/share/applications/*.desktop`, it finds that game's `logo.png` inside `~/.local/share/Steam/appcache/librarycache/<appid>/` (searched at any depth, since Steam nests it under a changing CDN-hash subfolder).
- It creates a **symlink** — not a copy — at `~/.local/share/icons/hicolor/256x256/apps/steam_icon_<appid>.png` pointing at that `logo.png`.
- `hicolor` is the icon-theme spec's universal fallback, implicitly inherited by *every* theme — so this works regardless of which theme (`Slot-Gray-Dark-Icons` or anything you switch to later) is active, and never touches the theme's own files.
- It's idempotent: re-running it only adds symlinks for games it hasn't seen before.

It runs once per Hyprland session via `hl.exec_cmd(...)` in `hypr/modules/autostart.lua` — a plain one-shot, not a systemd service, since there's no daemon behavior to supervise (same reasoning as the `hyprctl setcursor` call next to it).

**Caveat:** `logo.png` is Steam's library *wordmark* art (often non-square, designed to float over a hero background), not a purpose-built square app icon — so it can look different from a typical launcher icon. Newly installed games won't have an icon until Steam has actually downloaded and cached that art at least once, and until you next log into Hyprland (or re-run the script by hand).
