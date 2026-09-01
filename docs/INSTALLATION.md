# Installation

This is the complete, ordered path from a bare Arch/CachyOS install to a working session. Each step exists because a later one depends on it — follow them in order the first time.

> This repo is **not plug-and-play**. See [Who Is This For](../README.md#who-is-this-for) before you start. Steps [0](#0-back-up-your-current-configuration) through [10](#10-shell-and-first-login) below are the whole thing; everything else on this page is context for why each step exists.

> 🚫 **Desktop-first.** This rice is developed and tested on desktop hardware (see [Hardware & Compatibility](../README.md#hardware--compatibility)). Laptop-specific concerns — battery, brightness, power profiles, function keys, touchpad gestures, suspend/resume — are out of scope.

---

## 0. Back up your current configuration

```bash
mkdir -p ~/backup-configs

cp -r \
  ~/.config/hypr \
  ~/.config/waybar \
  ~/.config/kitty \
  ~/.config/fish \
  ~/.config/rofi \
  ~/.config/fastfetch \
  ~/.config/hyprlock \
  ~/.config/swaync \
  ~/.config/wlogout \
  ~/backup-configs 2>/dev/null
```

If something goes wrong you'll be able to restore your previous configuration easily.

> ⚠️ Read the files before copying them.
> ⚠️ Don't run scripts you don't understand.
> ⚠️ Check personal paths, wallpapers, sensors, and programs before logging into Hyprland — see [step 9](#9-fix-personal-paths) below.

---

## 1. Dependencies

> Package names may vary depending on your enabled repositories. Check each package before installing it.

> `rofi-wayland` (the old community fork with native Wayland support) is gone from the repos — Wayland support was merged into upstream `rofi` itself, so plain `rofi` is what you want now. The list below already reflects this.

**Recommended base for Arch / CachyOS**

```bash
sudo pacman -Syu
sudo pacman -S \
  hyprland waybar kitty fish starship fastfetch rofi \
  hyprlock hypridle swaync wlogout \
  pipewire wireplumber pavucontrol playerctl libpulse \
  networkmanager \
  bluez bluez-utils blueman \
  wl-clipboard cliphist grim slurp swappy \
  nautilus btop udiskie polkit-kde-agent \
  jq imagemagick libnotify ffmpeg ffmpegthumbnailer \
  pacman-contrib reflector fzf fd bat eza zoxide ripgrep \
  lm_sensors ttf-iosevkaterm-nerd \
  thefuck bottom python python-evdev bash \
  power-profiles-daemon qt5ct qt6ct
```

**Wired to a keybind or a Waybar click, but not required for the session to come up:**

```bash
sudo pacman -S yazi duf calcurse
```

> `yazi` is `SUPER + CTRL + F`, `duf` is the Waybar disk module's click action, `calcurse` is the clock's. Without them the session starts fine, those three actions just do nothing.

> `power-profiles-daemon` is a **system** service (`sudo systemctl enable --now power-profiles-daemon`), not a user one — it backs both the Waybar module and `kitasan mode`. `qt5ct`/`qt6ct` are what actually read `qt5ct.conf`/`qt6ct.conf` — without them, Qt apps ignore the theming in `qt5ct/`/`qt6ct/` entirely. `libpulse` is what provides `pactl`, used unguarded by Waybar's audio module (right-click to mute) — listed explicitly here rather than relying on it arriving transitively through `pavucontrol`. `python-evdev` is what the Infinite Desktop daemon reads raw input with (see [step 7](#7-infinite-desktop--input-group)).

> **The font is Iosevka, not JetBrains Mono.** Kitty, Waybar, SwayNC and every Rofi theme ask for `IosevkaTerm Nerd Font` / `IosevkaTerm Nerd Font Propo` by name — `ttf-iosevkaterm-nerd` is the package that provides both. Earlier revisions of this rice used JetBrains Mono; nothing references it any more.

> If you use CachyOS you can download Zen-Browser from pacman packages:
> ```bash
> sudo pacman -S zen-browser-bin
> ```

**An AUR helper, before the next block**

The next block uses `yay -S`, so you need `yay` (or `paru`) installed first. On CachyOS both are plain pacman packages, not an AUR bootstrap:

```bash
sudo pacman -S yay
# o paru 
```

On vanilla Arch, `yay`/`paru` aren't in the official repos — you'd build one from the AUR manually first (`git clone` + `makepkg -si` against `base-devel`) before the block below works. `waybar/scripts/updates.sh` and `sysupdate` fall back from `yay` to `paru` if only the latter is installed, so either is fine.

```bash
# --> Yay installation
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay 
makepkg -si
cd ..
```

```bash
# --> Paru installation
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

**AUR or to verify**

```bash
yay -S \
  mpvpaper \
  hyprshot \
  hyprpicker \
  nwg-look \
  vscodium-bin \
  cava \
  awww \
  matugen
```

> If you don't use CachyOS you can download Zen-Browser from AUR packages:
> ```bash
> yay -S zen-browser-bin
> ```

> ⚠️ **If you install things from the AUR, carefully review what will be installed.**
>
> `awww` is the image wallpaper backend used by this rice. `swww` is **not used** — `awww` replaced it entirely.
>
> "AUR" here is a loose label for "not in the base block above" — on CachyOS, `mpvpaper`, `hyprpicker`, `nwg-look`, `cava`, `awww`, and `matugen` are all actually in the `cachyos`/`cachyos-extra-znver4` repos, not the AUR proper; only `vscodium-bin` is genuine AUR on every distro. On vanilla Arch, more of this list (including `awww`) really does come from the AUR. Either way `yay -S` works for both cases — just know you're not necessarily pulling from AUR just because the command is `yay`.

> The Rofi web hub (`SUPER + SHIFT + /`, see [ARCHITECTURE.md](ARCHITECTURE.md#rofi-web-hub)) needs **no extra packages** — it's a static Rofi menu over `rofi/websites.conf`, and it opens pages with whatever `Programs.browser` already points at.

<details>
<summary><b>Marked as "to verify" — click to expand</b></summary>
<br>

- `hyprland-lua`: this rice uses `hypr/hyprland.lua` with `hl.*` calls, not classic `hyprland.conf`. Verify the correct package or method for your version of Hyprland — see the [Hyprland in Lua](ARCHITECTURE.md#hyprland-in-lua) section for why this matters.
- `hyprshutdown`: appears as an optional fallback in a keybind.
- `obs`, `brave`, `vscodium`: personal applications tied to keybinds, not requirements of the base environment.
- `awww`: required by the Rofi wallpaper selector to apply static images. `matugen` is required if you want dynamic theming — see [THEMING.md](THEMING.md); the rest of the rice works fine without it.

</details>

---

## 2. Themes, icons, cursors and fonts

This is the part the base dependency list above doesn't cover: the actual visual assets the configs reference by name. Skipping this step is the single most common way to end up with a desktop that "looks wrong" after copying every config file correctly — the configs assume these are already installed.

| Kind | Name used in this rice | Where it's referenced | Get it |
|---|---|---|---|
| GTK theme | **Adwaita-dark** | `hypr/modules/environment.lua` (`GTKTheme`), `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini` | **Nothing to install** — stock GTK, ships in `/usr/share/themes/` with GTK itself |
| GTK theme (previous, still referenced in some code comments) | Win11-Fantasy-Dark, and before it Colorful-Dark-GTK | historical — see [THEMING.md § GTK theming](THEMING.md#gtk-theming) | [gnome-look.org/p/2307588](https://www.gnome-look.org/p/2307588) / [p/2091032](https://www.gnome-look.org/p/2091032) |
| Icon theme | **ryoku-folders** | `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`, `qt5ct/qt5ct.conf`, `qt6ct/qt6ct.conf`, `rofi/window-switcher.rasi` | Personal/hand-installed into `~/.local/share/icons/`. Any icon theme works — just use the same name in all five places |
| Cursor theme | **Vimix-white-cursors** | `hypr/modules/environment.lua` (`CursorTheme`), `gtk-3.0/settings.ini` | `vimix-cursors` — a package, not a manual download. Installs to `/usr/share/icons/Vimix-white-cursors/` |
| Monospace / UI font | **IosevkaTerm Nerd Font** (and its `Propo` variant) | Kitty, Waybar, SwayNC, every Rofi theme | `ttf-iosevkaterm-nerd` (already in the pacman list above) |
| GTK UI font | Adwaita Sans | `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini` | `adwaita-fonts` (Arch repos) |

> The `gtk-3.0/settings.ini` / `gtk-4.0/settings.ini` referenced above are **not shipped by this repo** — only `gtk.css` and `gtk-colors.static.css` are (that's all `dotbackup` tracks from those two folders; see [ARCHITECTURE.md](ARCHITECTURE.md#dotbackup--repo-sync)). `settings.ini` is what a tool like `nwg-look` writes for you locally, on your own machine, per the instructions right below — you'll generate it, not clone it.

If you'd rather pick your own instead of these exact ones, browse the categories directly:

- Icon themes — [gnome-look.org/browse?cat=132](https://www.gnome-look.org/browse?cat=132)
- GTK3/4 themes — [gnome-look.org/browse?cat=135](https://www.gnome-look.org/browse?cat=135)
- Cursors — [gnome-look.org/browse?cat=107](https://www.gnome-look.org/browse?cat=107)

**Where to install them:**

```bash
mkdir -p ~/.themes ~/.icons ~/.local/share/icons
# GTK themes go in ~/.themes/<Theme-Name>/ (or ~/.local/share/themes/)
# Icon themes go in ~/.icons/<Theme-Name>/ (or ~/.local/share/icons/)
# Cursor themes go in ~/.icons/<Theme-Name>/ as well
```

After installing, apply them with `nwg-look` (already in the AUR list above) rather than editing GTK settings files by hand — it keeps `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` consistent. Then update the two names this repo hardcodes so they match what you installed:

- `hypr/modules/environment.lua` — `CursorTheme` and `GTKTheme`
- `hypr/scripts/link-steam-icons.sh` mentions the icon theme only in a comment (it doesn't hardcode the name in logic — it writes to the universal `hicolor` fallback instead, see [THEMING.md](THEMING.md#steam-game-icons)), so no code change is needed there if you pick a different icon theme.
- `qt5ct/qt5ct.conf`, `qt6ct/qt6ct.conf` and `rofi/window-switcher.rasi` **do** hardcode it, and have to match what `nwg-look` wrote into `settings.ini`. Those `settings.ini` files aren't versioned, so a fresh clone won't have them — set the theme with `nwg-look`, then make the three versioned files agree.

> ⚠️ **Cursor theme names are case-sensitive.** `CursorTheme` in `environment.lua` has to match the *directory name* the theme installs as (`Vimix-white-cursors` here), not its pretty `Name=` from `index.theme`. If the cursor silently stays the default after logging in, check `ls /usr/share/icons ~/.icons ~/.local/share/icons` against what `environment.lua` says — a packaged theme lands in the first of those three, a hand-installed one in the other two.

> ⚠️ **Known trap:** `nwg-look` writes `~/.config/gtk-4.0/gtk.css` as a direct symlink to the theme's own `gtk.css`, overwriting the one-line `@import` this rice ships there. **`apply-static-colors.sh` does not undo this** — it never writes `gtk.css` at all. Restore it with `printf "@import 'gtk-colors.css';\n" > ~/.config/gtk-4.0/gtk.css`, and check the file before running `dotbackup`, or the theme's whole stylesheet gets committed in its place. See [THEMING.md § GTK theming](THEMING.md#gtk-theming).

---

## 3. Clone and copy configs

```bash
git clone https://github.com/kitasael-burakku/Minecraft-Rice-Hyprland.git ~/dotfiles
cd ~/dotfiles
```

Copy the folders you want to use:

```bash
mkdir -p ~/.config
cp -r hypr waybar rofi kitty fish fastfetch hyprlock swaync wlogout cava matugen \
      gtk-3.0 gtk-4.0 qt5ct qt6ct systemd ~/.config/
cp starship.static.toml ~/.config/starship.toml
cp starship.static.toml ~/.config/starship.static.toml

mkdir -p ~/Documents
cp ~/dotfiles/KEYBINDS.txt ~/Documents/KEYBINDS.txt
```

Every top-level folder in the repo maps to the same name under `~/.config/`, **except** `docs/`, `README.md`, `LICENSE`, `KEYBINDS.txt` (→ `~/Documents/`), and `starship.static.toml` (which goes to `~/.config/` **twice**: renamed to `starship.toml`, *and* under its own name — `hypr/scripts/apply-static-colors.sh` reads the latter back every time you restore the static baseline, e.g. after toggling matugen off with `SUPER + SHIFT + W`. Skipping the second copy means that restore silently no-ops for Starship only, and the dynamic prompt colors get stuck).

---

## 4. Bootstrap generated color files

The per-app color files (`rofi/colors.rasi`, `waybar/colors.css`, `kitty/colors/colors.conf`, `gtk-3.0/gtk-colors.css`, `qt5ct/colors/kitasan-glass.conf`, etc.) aren't in the repo — they're generated, and gitignored. Populate them with the static "Kitasan Glass" baseline:

```bash
bash ~/.config/hypr/scripts/apply-static-colors.sh
```

It writes 14 color files from their `*.static.*` counterparts and seeds `hyprlock/wallpapers/current.png` from the versioned `2.png` if no wallpaper has been picked yet.

This has to run **before** step 6 (enabling services) — some of those services read the files this step creates. Dynamic wallpaper-driven theming is off by default; toggle it later with `SUPER + SHIFT + W` — see [THEMING.md](THEMING.md).

> This script does **not** write `gtk-3.0/gtk.css` or `gtk-4.0/gtk.css`. Those are shipped by the repo as a single `@import 'gtk-colors.css';` line and a plain copy is all they need — what the script writes is the `gtk-colors.css` that line pulls in. See [THEMING.md § GTK theming](THEMING.md#gtk-theming).

---

## 5. Make scripts executable

```bash
chmod +x ~/.config/waybar/scripts/*.sh ~/.config/waybar/scripts/cursor-zone.py
chmod +x ~/.config/rofi/launcher.sh
chmod +x ~/.config/swaync/scripts/*.sh
chmod +x ~/.config/wlogout/scripts/*.sh
chmod +x ~/.config/hyprlock/scripts/player.sh
chmod +x ~/.config/hypr/scripts/*.sh
chmod +x ~/.config/hypr/infinite_desktop/floating_tile_toggle.py \
          ~/.config/hypr/infinite_desktop/move_window.py \
          ~/.config/hypr/infinite_desktop/move_window_tiled.py \
          ~/.config/hypr/infinite_desktop/navigate_windows.py \
          ~/.config/hypr/infinite_desktop/resize_window.py

# rofi/scripts/ — everything EXCEPT web_common.sh (see the note below)
find ~/.config/rofi/scripts -name '*.sh' ! -name 'web_common.sh' -exec chmod +x {} +
chmod 644 ~/.config/rofi/scripts/web_common.sh
```

> ⚠️ **Do not `chmod +x` the whole of `rofi/scripts/`.** Rofi treats every executable file in a script-mode directory as a mode of its own, and `web_common.sh` is a sourced helper, not a mode — it is committed at `644` deliberately. The `find` above is why it's not a plain `chmod +x *.sh`.

> `waybar/scripts/cursor-zone.py` **does** need the executable bit: `config.jsonc` runs it as `exec: ~/.config/waybar/scripts/cursor-zone.py`, with no `python3` prefix.

> `hyprlock/scripts/` only needs `player.sh` executable — `music-colors.sh` and `music-colors.static.sh` are `source`d, never run directly, and are committed at `644` on purpose. `hypr_ipc.py` and `infinite_desktop_core.py` aren't in the list above either, for the same reason: both are imported or invoked as `python3 <path>`, so the executable bit is never consulted.

---

## 6. Enable the systemd units

Copying the files into `~/.config/systemd/user/` is **not** enough by itself — each unit's `[Install]` block only takes effect once you `enable` it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now \
  waybar.service swaync.service hypridle.service udiskie.service \
  awww.service wallpaper.service cliphist-text.service cliphist-image.service \
  infinite-desktop.service playerctl-watch.service polkit-agent.service \
  kb-layout-notify.service

systemctl --user enable --now \
  updates-check.timer thumbs-refresh.timer healthcheck-notify.timer dotbackup-remind.timer
```

> `hyprland-session.service` is **not** in that list — it has no `[Install]` block on purpose, it's only ever started by `hypr/modules/autostart.lua` when Hyprland itself launches. See [ARCHITECTURE.md](ARCHITECTURE.md#session-lifecycle) for why the architecture is split this way.

> `kb-layout-notify.service` shows a popup when the keyboard layout changes — only useful if you actually have more than one layout configured in `hypr/modules/input.lua` (`grp:alt_shift_toggle` is what switches them). Skip it if you don't; nothing else depends on it.

> `dotbackup-remind.timer` only makes sense if you keep your own fork checked out and want a reminder when `~/.config` drifts from it (see `hypr/scripts/dotbackup-remind.sh`). If that's not your workflow, skip enabling that one timer — nothing else depends on it.

---

## 7. Infinite Desktop — input group

The Infinite Desktop scripts read raw `/dev/input` events, which requires your user to be in the `input` group:

```bash
sudo usermod -aG input $USER
```

Log out and log back in (or reboot) for the new group membership to take effect. For implementation details, see the original [Infinite Desktop project](https://github.com/sarodscommits/hyprland-infinitie-desktop-v2) by **sarodscommits**.

---

## 8. Wallpapers

Video wallpapers are **not included** in this repo due to file size limits. Place your own here:

```bash
mkdir -p ~/Videos/Wallpapers
# Place your .mp4 .mkv .mov .webm files here
```

For static image wallpapers, the ones used in this rice come from [NischalDawadi/Wallpapers](https://github.com/NischalDawadi/Wallpapers). Full credit to the original author.

```bash
mkdir -p ~/Pictures
git clone https://github.com/NischalDawadi/Wallpapers.git ~/Pictures/Wallpapers
```

> The wallpaper picker expects videos in `~/Videos/Wallpapers/` and images in `~/Pictures/Wallpapers/`. Both paths can be overridden by exporting `WALLPAPER_DIR_VIDEO` and `WALLPAPER_DIR_IMG` before launching the picker.

---

## 9. Fix personal paths

This repo runs on one specific machine and was never meant to be copied byte-for-byte. Before logging into Hyprland, review and edit:

| File | What to change |
|---|---|
| `hypr/modules/monitors.lua` | Resolution, position, scale. `output` is already `""` (all outputs), so the name needs no editing — but `mode` is the literal `1920x1080@200.00Hz`, and Hyprland falls back silently when a display can't do it. Switch to `mode = "preferred"`, `position = "auto"`, `scale = "auto"` for automatic detection instead |
| `hypr/modules/input.lua` | Keyboard/mouse device names. Use the **slug** from `hyprctl devices` (`logitech-g203-lightsync-gaming-mouse`), never the pretty name — Hyprland matches on the slug, and a block that doesn't match is ignored without any error. `kitasan doctor --fresh-clone` flags both mistakes |
| `hypr/scripts/apply-wallpaper.sh` | `DEFAULT_WALLPAPER` — a wallpaper you actually have. This is the only place the default lives; `autostart.lua` just calls this script |
| `hypr/modules/environment.lua` | `CursorTheme` / `GTKTheme` — see [step 2](#2-themes-icons-cursors-and-fonts) if you installed different ones. Also `HostnamePretty`, exported as `$HOSTNAME_PRETTY` and rendered by the Starship prompt and several Fastfetch presets |
| `hypr/modules/programs.lua` | Terminal, file manager, browser, launcher — change if you use different apps. `browser` is also the single source of `$BROWSER`, which the web hub resolves against |
| `waybar/config.jsonc` | `hwmon-path-abs` — the correct sensor path for your machine |
| `rofi/scripts/dashboard.sh` | Same `hwmon-path-abs` sensor path as Waybar, hardcoded separately — both need fixing or the CPU temperature row won't work |
| `qt5ct/qt5ct.conf` & `qt6ct/qt6ct.conf` | `color_scheme_path` — a hardcoded absolute path; point it at your own `$HOME` or Qt apps silently fail to find the color scheme |
| `hypr/modules/keybinds.lua` | `obs`, screenshot paths, and any command you don't use |
| `fish/conf.d/tools.fish` | The `ec*` aliases open folders in `codium` — change the editor if you use another one |
| `rofi/scripts/window-switcher.sh` | `MINIMIZED_WS` defaults to `special:minimized` — change if you use a different special workspace name |
| `hypr/scripts/dotbackup-remind.sh` & `systemd/user/dotbackup-remind.timer` | Assumes a fork checked out at `~/Projects/dotfiles`. `rofi/scripts/dashboard.sh` hardcodes the same path for its "last backup" row — see [step 6](#6-enable-the-systemd-units) |
| `rofi/websites.conf` | The web hub's page list — personal bookmarks, replace with your own (`[Category]` sections, `Name \| URL` lines) |
| `swaync/config.json` | The notification centre's `label` widget text is a personal string |
| `fastfetch/*.jsonc` | Personal logos and ASCII art under `fastfetch/fastfetchlogo/`; the weighted preset list lives in `fish/config.fish` |

> **Check your work:** `kitasan doctor --fresh-clone` reports which of the rows above still don't resolve on your machine — a monitor mode your display can't do, an hwmon path that doesn't exist, a wallpaper that isn't there, a `color_scheme_path` still pointing at someone else's home. It writes nothing. Run it after editing, and again after your first login (two of its checks need a running Hyprland and are skipped without one).

**One optional variable that is not in the repo at all:** `$USER_PRETTY`. Starship and five Fastfetch presets render it if it exists and fall back to `$USER` if it doesn't — it lives in `fish/fish_variables`, which is gitignored. Set your own with:

```fish
set -Ux USER_PRETTY "Your Name"
```

Find the hardcoded paths all at once:

```bash
rg "/home/|your-username|kitasa-elburakku|wallpaper|hwmon|ryoku-folders|Vimix|Adwaita-dark" .
```

---

## 10. Shell and first login

If you want Fish as your default shell:

```bash
chsh -s /usr/bin/fish
```

Log into Hyprland. If something doesn't exist on your system, Hyprland may start incomplete, or some shortcuts won't do anything — that's expected until step 9 is fully done.

---

## 11. Hyprland plugins (optional)

This rice loads two **external** Hyprland plugins — [hyprglass](https://github.com/hyprnux/hyprglass) and [hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors). Neither is code from this repository; both are third-party projects with their own authors and licenses. Only their *configuration* lives here, in `hypr/plugins/`.

This step is genuinely optional and comes last on purpose: `hyprpm` builds each plugin against the Hyprland you are actually running, so it wants a working Hyprland first. Skip it and the session still comes up — you just don't get the glass material or the cursor motion. The config files guard on the plugin being loaded and return early when it isn't.

```bash
hyprpm update        # sync hyprpm's headers with your Hyprland (asks for sudo)

hyprpm add https://github.com/hyprnux/hyprglass
hyprpm enable hyprglass

hyprpm add https://github.com/virtcode/hypr-dynamic-cursors
hyprpm enable dynamic-cursors

hyprpm list          # confirm both show `enabled: true`
```

Then relogin, or `hyprpm reload -n` to load them into the running session.

> `hyprpm` ships with Hyprland — there is nothing extra to install for it. It builds the plugins from source and stores the resulting `.so` files in `/var/cache/hyprpm/$USER/`, which is root-owned: `add`, `update` and `remove` need `sudo`, `reload` does not.

> **`hypr/modules/autostart.lua` runs `hyprpm reload -n` on every `hyprland.start`**, so the plugins load themselves on each login once they're built. It deliberately does *not* run `hyprpm update` — that needs `sudo` and would hang the session start on a password prompt nothing can answer.

> ⚠️ **After every Hyprland update, run `hyprpm update` by hand.** A plugin built against the old ABI refuses to load. Until you do, the two plugins simply don't load and everything else works normally — that's what the guards in `hypr/plugins/*.lua` are for.

> `hypr-dynamic-cursors` is **`x86_64`-only** (it uses Hyprland's function-hook API), and on Nvidia GPUs it forces software cursors because of driver limitations. `hyprglass` needs Hyprland's shadow decoration present in the render pipeline and auto-enables it at load. Full requirements, options and attribution: [PLUGINS.md](PLUGINS.md).

---

## Verification

A correct install looks like this:

```bash
systemctl --user --failed          # should be empty
systemctl --user is-active waybar.service hypridle.service swaync.service
```

- Waybar is visible with all modules rendering (not blank/missing icons). **Only the centre island shows at rest** — moving the cursor into the top-left or top-right third of the screen reveals the other two. That's the cursor-zone behaviour, not a broken bar; see [ARCHITECTURE.md](ARCHITECTURE.md#waybar--three-islands-and-the-cursor-zones).
- `SUPER + W` opens the wallpaper picker; picking one changes the desktop background.
- `SUPER + SHIFT + /` opens the Rofi web hub; picking a category then a page opens it in your browser.
- GTK apps (e.g. `nautilus`) render with the installed theme, not the GTK default (Adwaita fallback look) — if they don't, see [Troubleshooting](#troubleshooting).
- `SUPER + F4` opens the `kitasan` menu; `kitasan doctor` reports clean (template parity, config drift, keybinds doc, failed services, orphans). On a fresh clone the drift section will flag the missing `gtk-*/settings.ini` until you've run `nwg-look` — see [step 2](#2-themes-icons-cursors-and-fonts).
- If you did [step 11](#11-hyprland-plugins-optional): `hyprpm list` shows both plugins as `enabled: true`, translucent windows have a visible glass bezel, and the cursor tilts as you move it. None of this is required for a correct install — see [PLUGINS.md](PLUGINS.md).

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Rofi/Waybar/Kitty show no colors, or an error about a missing file | Step 4 (bootstrap colors) wasn't run, or was run before the folders existed |
| `systemctl --user is-enabled <unit>` says `disabled` after copying the units | `[Install]` blocks don't self-activate — re-run step 6's `enable --now` |
| Hyprland doesn't start, or ignores the whole config | Your Hyprland build doesn't support the native Lua config API (`hl.*`) — see [ARCHITECTURE.md](ARCHITECTURE.md#hyprland-in-lua) |
| Wallpaper picker errors on `awww` | You installed `swww` instead — this rice uses `awww`, not `swww` |
| GTK4 apps suddenly lose the theme after using `nwg-look` | `nwg-look` overwrote `~/.config/gtk-4.0/gtk.css` with a direct theme symlink. `apply-static-colors.sh` does **not** repair this — restore the one `@import` line by hand, see [THEMING.md](THEMING.md#gtk-theming) |
| GTK apps and Qt/Rofi show different icon sets | The icon theme name disagrees between `gtk-*/settings.ini` (written by `nwg-look`, not versioned) and `qt5ct.conf` / `qt6ct.conf` / `rofi/window-switcher.rasi`. Make all five say the same thing, see [step 2](#2-themes-icons-cursors-and-fonts) |
| Steam games have no icon in Rofi's launcher | Expected on a fresh clone until Steam has actually cached art for those games — see [THEMING.md](THEMING.md#steam-game-icons) |
| CPU temperature row is empty in Waybar/dashboard | `hwmon-path-abs` in `waybar/config.jsonc` and `rofi/scripts/dashboard.sh` still point at the original machine's sensor — fix both, see step 9 |
| Waybar's left/right modules never appear | Expected at rest — move the cursor into the top-left or top-right third to reveal them. If they never appear at all, `cursor-zone.py` isn't executable (step 5) or it couldn't reach Hyprland's socket; `journalctl --user -u waybar` shows it. The centre island renders either way |
| Rofi shows odd extra modes, or the web hub misbehaves | `rofi/scripts/web_common.sh` got the executable bit — Rofi picks up every executable in a script-mode directory as a mode. `chmod 644` it, see step 5 |
| The mouse cursor is the default X arrow, not the installed theme | `CursorTheme` in `environment.lua` doesn't match the theme's installed **directory** name (case-sensitive) — see step 2 |
| Text renders with fallback glyphs / boxes | `ttf-iosevkaterm-nerd` isn't installed — the configs name `IosevkaTerm Nerd Font` explicitly, they don't ask for a generic monospace |
| No glass effect on windows, and no cursor tilt, after a Hyprland update | The plugins are built against the old ABI and refuse to load. `hyprpm update`, then relogin — see [step 11](#11-hyprland-plugins-optional) |
| The glass effect only appears while dragging a window | Hyprland's `blur:new_optimizations` cache is hiding it. hyprglass sets `noblur` on glassed windows to prevent exactly this; check `manage_window_blur` hasn't been set to `0` in `hypr/plugins/hyprglass.lua` — see [PLUGINS.md](PLUGINS.md#hyprglass) |
| Hyprland starts but the whole Lua config seems ignored, right after adding a plugin | A plugin config file was edited without its guard. Reading `hl.plugin.<name>.*` when the plugin isn't loaded aborts the entire config, not just that file — see [PLUGINS.md § How plugins are wired in](PLUGINS.md#how-plugins-are-wired-into-this-rice) |

---

## Appendix — command reference for beginners

<details>
<summary><b>📖 Click to expand</b> — for people coming from Windows or just starting out with Linux (skip if you already know these)</summary>

### git clone

```bash
git clone https://github.com/user/repository.git
```

Downloads a repository from GitHub to your computer, preserving the change history. It's equivalent to downloading a ZIP but better.

### cd

```bash
cd ~/dotfiles
```

Changes the current directory (folder) in the terminal. `cd ~/.config` enters the configuration folder.

### mkdir

```bash
mkdir -p ~/.config
```

Creates directories. The `-p` flag avoids errors if the folder already exists.

### cp and cp -r

```bash
cp file.txt destination/        # copies a file
cp -r hypr waybar ~/.config/    # copies entire folders (recursive)
```

Without `-r`, Linux won't copy directories.

### chmod +x

```bash
chmod +x script.sh
```

Adds execution permissions. Required to run `.sh` scripts as programs.

### chsh

```bash
chsh -s /usr/bin/fish
```

Changes the user's default shell. After logging out and back in, Fish will open automatically instead of Bash.

### rg (ripgrep)

```bash
rg "wallpaper" .
```

Searches for text inside files. Very useful for finding personal paths, usernames, sensors, and variables in configs.

### sudo

```bash
sudo pacman -S package
```

Runs a command with administrator permissions. Only use it when you understand what the command does.

### pacman

```bash
sudo pacman -S package      # install
sudo pacman -Rns package    # remove with unneeded dependencies
sudo pacman -Syu            # update the entire system
```

Package manager for Arch Linux and CachyOS.

### yay

```bash
yay -S package
```

Installs packages from the AUR (Arch User Repository). Works similar to pacman but accesses community-maintained software.

> ⚠️ The AUR contains community-maintained packages. Always inspect the `PKGBUILD` before installing software you don't trust.

### sudo usermod -aG input $USER

```bash
sudo usermod -aG input $USER
```

Adds your current user to the `input` group. The Infinite Desktop scripts need direct access to Linux input devices (mouse and keyboard) — this grants the required permissions. Breaking it down:

- `sudo` — runs the command with administrator privileges.
- `usermod` — modifies an existing user account.
- `-a` — appends the change without removing the user from other groups.
- `-G input` — adds the user to the `input` group.
- `$USER` — expands to the name of the currently logged-in user.

> ⚠️ You must log out and log back in (or reboot) before the new group membership takes effect.

### Why is there no automatic installer?

Copying files manually lets you understand where each configuration lives, which program uses each file, detect errors more easily, and modify specific parts without depending on automatic scripts.

Manual installation requires more work, but teaches you much more about how the system actually works.

</details>
