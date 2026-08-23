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
| GTK3 | `gtk-3.0/gtk-colors.css` | none possible — GTK only reads `gtk.css` at app launch; already-open apps keep their old colors |
| GTK4 | `gtk-4.0/gtk-colors.css` | same as GTK3 — see [GTK theming](#gtk-theming) below for why this file is structured differently from GTK3's |
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

GTK3 and GTK4 are handled differently because **GTK4 dropped support for the `GTK_THEME` environment variable** that GTK3 still honors.

- **GTK3** (`gtk-3.0/gtk.css`): `GTK_THEME` (set from `GTKTheme` in `hypr/modules/environment.lua`) already loads the base theme. `gtk.css` here only needs `@import 'gtk-colors.css';` — a thin color overlay on top of whatever theme is installed.
- **GTK4** (`gtk-4.0/gtk.css`): there's no env var to lean on, so `~/.config/gtk-4.0/gtk.css` **has to contain the theme itself**, not just an override. The intended content of that file is exactly two lines:

  ```css
  @import 'theme-base.css';
  @import 'gtk-colors.css';
  ```

  `theme-base.css` is a symlink to the actual installed theme's `gtk-4.0/gtk.css` (not versioned — it's a third-party file, and an absolute symlink with a hardcoded username wouldn't survive a clone on another machine anyway). `hypr/scripts/apply-static-colors.sh` recreates **that symlink** on every run, reading the theme name from `GTKTheme` in `environment.lua` so it doesn't need its own hardcoded copy of the name; it searches both `~/.themes/` and `~/.local/share/themes/`.

> ⚠️ **`nwg-look` will break this, and the repair is manual.** If you use `nwg-look`'s GUI to pick a GTK4 theme, it overwrites `~/.config/gtk-4.0/gtk.css` with a direct symlink to the theme's own file — correct for *just* applying the theme, but it silently drops the `gtk-colors.css` overlay this rice relies on.
>
> `apply-static-colors.sh` does **not** repair this: it only ever writes `theme-base.css` and `gtk-colors.css`, never `gtk.css` itself. Restore the two lines by hand:
>
> ```bash
> printf "@import 'theme-base.css';\n@import 'gtk-colors.css';\n" > ~/.config/gtk-4.0/gtk.css
> bash ~/.config/hypr/scripts/apply-static-colors.sh   # re-points theme-base.css
> ```
>
> Check whether you're currently in the broken state with `head -3 ~/.config/gtk-4.0/gtk.css` — if it shows theme CSS rules instead of the two `@import`s, it's been overwritten.

> ⚠️ **Known state of this repo:** `gtk-4.0/gtk.css` as committed here is currently the overwritten variant — a byte-for-byte copy of Win11-Fantasy-Dark's own 7955-line stylesheet, which is what `dotbackup` picked up by following the `nwg-look` symlink. `gtk-3.0/gtk.css` is fine. If you clone this repo, replace `gtk-4.0/gtk.css` with the two `@import` lines above rather than copying it as-is.

**GTK4 dynamic theming was tried and reverted.** The shipped GTK theme paints most of its UI with literal hardcoded hex values in its CSS rules rather than through the standard `@theme_bg_color`/`@theme_selected_bg_color`/etc. variables — it *declares* those variable names, for compatibility, but barely *uses* them (`@theme_text_color` appears exactly once across the entire stylesheet, confirmed with `grep -oE '@[a-z_]+_color' gtk.css`). Redefining those variables via `gtk-colors.css` therefore has close to no visible effect on GTK4 apps. Making GTK4 apps genuinely follow the wallpaper would mean patching literal hex strings inside a private copy of the theme's own CSS — fragile, breaks silently on any theme update — and wasn't judged worth it. GTK3 apps *do* follow the wallpaper correctly, since GTK3 themes generally use the theme variables as intended.

---

## Qt theming

`qt5ct`/`qt6ct` read `qt5ct.conf`/`qt6ct.conf`, which point `color_scheme_path` at `qt5ct/colors/kitasan-glass.conf` / `qt6ct/colors/kitasan-glass.conf` — **hardcoded absolute paths** containing the original machine's username. This is the one thing in the Qt setup you must edit yourself after cloning (see [step 9 of INSTALLATION.md](INSTALLATION.md#9-fix-personal-paths)); without it, Qt apps silently fail to find the color scheme and fall back to a default palette.

`QT_QPA_PLATFORMTHEME=qt6ct` is what makes Qt apps actually read this config at all (set in `hypr/modules/environment.lua`).

---

## Swapping any of these themes for your own

1. Install your GTK/icon/cursor theme (see [INSTALLATION.md](INSTALLATION.md#2-themes-icons-cursors-and-fonts) for where to get them and where they go).
2. Update `CursorTheme` / `GTKTheme` in `hypr/modules/environment.lua`.
3. Re-run `hypr/scripts/apply-static-colors.sh` — it re-derives the GTK4 `theme-base.css` symlink from the new `GTKTheme` value automatically.
4. If you used `nwg-look` to apply the GTK theme, also restore `gtk-4.0/gtk.css` by hand (see the warning above) — step 3 does not do that part.
5. Update `icon_theme=` in `qt5ct/qt5ct.conf` and `qt6ct/qt6ct.conf` if you changed the icon theme; Qt reads its icon theme from there, not from the GTK settings.

Icon themes mostly don't need a code change — `hypr/scripts/link-steam-icons.sh` writes into the universal `hicolor` fallback (see below), which works under any active icon theme. Two places do hardcode the name and have to be kept in sync with it: `rofi/window-switcher.rasi` (`configuration { icon-theme: "Slot-Gray-Dark-Icons"; }`, so its by-class lookup has something concrete to resolve against) and `icon_theme=` in `qt5ct.conf`/`qt6ct.conf`.

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
