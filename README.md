# Minecraft-Rice-Hyprland

My personal Hyprland configuration inspired by Minecraft, running on CachyOS.

This project is **NOT an automatic installer**, **NOT a universal configuration**, and **does NOT guarantee compatibility with all systems**.

> You can do whatever you want with this dotfile — if you don't want to install or use a configuration, you simply don't have to copy it.

> 🎨 **Dynamic theming via matugen, off by default.**
> The base palette ("Kitasan Glass") is hardcoded and intentional — that's what you get on a fresh clone. Toggle `SUPER + SHIFT + W` and it derives a Material You palette from your current wallpaper across every app instead. See [External Additions](#external-additions).

---

## Screenshots

### Desktop
![Desktop](docs/screenshots/desktop.jpg)

### Rofi + SwayNC
![Rofi-Swaync](docs/screenshots/rofi.jpg)

### Window  Switcher
![Rofi-Window-switcher](docs/screenshots/window-minimiser.jpg)

### Wallpaper Picker
![Wallpaper-picker](docs/screenshots/wallpaper-picker.jpg)

### Video Wallpaper Picker
![Wallpaper-picker](docs/screenshots/video-wallpaper-picker.jpg)

### Image Wallpaper Picker
![Wallpaper-picker](docs/screenshots/Image_wallpaperpicker.jpg)

### Keybinds And Btop
![Keybinds](docs/screenshots/keybinds.jpg)

### Hyprlock
![Hyprlock](docs/screenshots/hyprlock.jpg)

---

## Where to start?

This repository is designed for two types of people:

**If you're coming from Windows or are new to Linux →**
Read the [Command Reference](#command-reference) section first, then [Before You Begin](#before-you-begin), and then follow the README in order.

**If you already know Linux and dotfiles →**
Go straight to [Repo Structure](#repo-structure), [Hyprland in Lua](#hyprland-in-lua), and [Things You Must Change](#things-you-must-change).

---

## Why this repository exists

I came to Linux from Windows looking for more control over my system. I started with Arch, made a lot of mistakes, learned from all of them, and eventually migrated to CachyOS where I built this rice.

Most modern configurations use automatic installers that hide how everything works under the hood. This repository takes the opposite approach.

The idea is not to copy everything and hope it works. The idea is:

```text
Read → Understand → Adapt → Learn → Build your own configuration
```

Here you'll find real paths, real scripts, and decisions made for a daily-use system. Some things will work right away, others will require modifications — and that's precisely where the learning happens.

If you're looking for a one-click install, this repository probably isn't for you.
If you want to understand what each file does before running it, then it probably is.

---

## Who is this for?

This may be useful if:

- You're coming from Windows and want to learn Linux from the inside out.
- You want to understand how a real rice is organized and built.
- You're interested in Hyprland, Wayland, and dotfiles.
- You prefer to understand what you install before running it.
- You like modifying and adapting configurations to your own system.

It's probably NOT for you if:

- You're looking for a fully automatic installer.
- You don't want to edit configuration files.
- You expect guaranteed compatibility without making changes.

---

## Hardware used

```
CPU: AMD Ryzen 7 8700F
GPU: AMD Radeon RX 7600 8GB
RAM: 16GB DDR5
Monitor: 1920x1080 @ 200Hz
OS: CachyOS
```

This configuration was developed and tested on this hardware. Some parts depend specifically on AMD.

> 🚫 **Laptop support**

> Minecraft Rice Hyprland is primarily developed and tested on desktop hardware.

> While most components should work on laptops, laptop-specific functionality is currently outside the project's scope.

>> This includes features such as:

>> Battery management
>> Brightness controls
>> Power profiles
>> Laptop function keys
>> Touchpad gestures beyond the included configuration
>> Vendor-specific utilities
>> Suspend/resume tuning

> Contributions adding optional laptop support are welcome.

---

## Tools used

| Tool | Function |
|---|---|
| Hyprland (Lua) | Modular window manager |
| Waybar | Status bar with taskbar (`wlr/taskbar`), inline audio slider (`pulseaudio/slider`), and media player controls |
| Rofi | Launcher, clipboard selector, two-level wallpaper selector (Videos / Images, each with its own theme), decorative power menu, and window switcher with minimize/restore (`ALT + TAB`) |
| matugen | Dynamic theming engine — off by default, toggled with `SUPER + SHIFT + W`, see [External Additions](#external-additions) |
| Kitty | Terminal |
| Fish + Starship | Shell with custom prompt — includes `starship.toml` with "Floating Stone Bubbles" theme (Minecraft shader palette) |
| Fastfetch | System info on terminal open |
| Hyprlock | Lock screen |
| SwayNC | Notification center |
| Wlogout | Session menu |
| mpvpaper | Video wallpaper (loops mp4/mkv/webm/mov) |
| awww | Static image wallpaper (replaces swww) |
| cava | Audio visualizer — includes config, custom GLSL shaders, and themes (agua, solarized_dark, tricolor) |
| Qylock | Minecraft-style SDDM theme |
| MINEGRUB | Minecraft-style GRUB theme |

> Qylock: https://github.com/Darkkal44/qylock
> MINEGRUB: https://github.com/Lxtharia/minegrub-theme

---

## Features

- Hyprland configuration split into Lua modules inside `hypr/modules/`, including an animation system with curves and springs under the custom name " 流 水   ·   R Y Ū S U I   M O T I O N " (`animations.lua`).
- Unified color palette **Kitasan Glass · Universal Dark** applied across Waybar CSS, Kitty, Fish shell, Rofi `.rasi` themes, StarShip prompt, and SwayNC — desaturated acentos (cyan `#7ab8b8`, azul gris `#8098a8`, rojo apagado `#b85c50`, arena `#c8b898`) over near-black backgrounds, designed to work with any wallpaper without clashing.
- Autostart for animated wallpaper with `mpvpaper`, Waybar, SwayNC, Hypridle, Polkit, clipboard, and udiskie.
- Two-level wallpaper selector as native Rofi script mode, shortcut `SUPER + W`. Opens a type selector (Videos / Images, each sourced from a different directory) before showing the thumbnail grid — each level uses its own `.rasi` theme. Thumbnail generation runs in the background and never blocks the menu. Applying a wallpaper feeds matugen for dynamic theming when it's enabled — see [Rofi — Wallpaper Selector](#rofi--wallpaper-selector) and [External Additions](#external-additions).
- Waybar with modules for disk, audio, clock, workspaces, tray, updates (with direct access to `sysupdate`), network, temperature, CPU, memory, and a power button connected to a mini Rofi menu. Includes a `wlr/taskbar` with app icons in the center bubble, and an inline `pulseaudio/slider` for quick volume control.
- Rofi as application launcher, clipboard history selector, decorative power menu (the different font in that menu is intentional; the actual session is handled by Wlogout), and window switcher (`ALT + TAB`) — lists all open windows with minimize/restore: click an active window to minimize it to `special:minimized`, click a minimized one to restore it to the current workspace.
- Kitty with Fish as shell, custom color theme "Kitasan-Ship Minecraft Edition" (palette of Creeper greens, stone grays, redstone reds), and Fastfetch image support via Kitty's graphics protocol.
- Fish with Starship, "Minecraft Overworld" palette applied to shell syntax, random rotation between 9 Fastfetch presets, modern aliases, and custom maintenance/diagnostic functions plus an interactive keybind viewer — see [Fish Functions](#fish-functions).
- cava with custom config (pipewire, noncurses, 60fps), three swappable themes (`agua`, `solarized_dark`, `tricolor`) and six custom GLSL shaders for visual mode.
- Hyprlock with minimalist layout (clock, date, user, password) plus a small MPRIS block (source, title/artist, progress bar) that follows the dynamic color pipeline — see [External Additions](#external-additions).
- SwayNC with notification center, quick controls, and `goldship` theme.
- Wlogout with lock, logout, suspend, shutdown, hibernate, and reboot actions — this is the system's real session menu.
- Hot-swappable Hyprland layout (dwindle / master / scrolling), with `scrolling` as the default.
- Shortcuts for screenshots, color picker, multimedia control, floating with auto-resize, Waybar reload, and system tools.
- The fuck: typo corrector integrated into Fish.

---

## Repo Structure

```text
.
├── assets/             # demo.mp4 and other assets for the GitHub Pages site
├── cava/               # Config, GLSL shaders and themes for the audio visualizer
├── docs/screenshots/   # Rice screenshots
├── fastfetch/          # jsonc configs, logos and visual presets
├── fish/               # config.fish, functions, aliases and Fish shell themes
├── hypr/               # Hyprland Lua, modules, hypridle.conf and base hyprlock.conf
├── hyprlock/           # Lock screen layout, colors, wallpaper and scripts
├── index.html          # Source for the GitHub Pages site
├── KEYBINDS.txt         # Keybind reference used by the `keybinds` fish function
├── kitty/              # Kitty configuration and colors
├── LICENSE
├── matugen/            # Dynamic (Material You) theming templates and config
├── rofi/               # Launcher, clipboard, two-level wallpaper selector (wallpaper_launcher.sh → wallpaper_rofi.sh → wallpaper_grid.sh), power menu, and window switcher (window-switcher.sh + window-switcher.rasi)
├── starship.static.toml # Starship config (prompt); copy to ~/.config/starship.toml (starship.toml itself is generated/gitignored)
├── swaync/             # Notification center config, styles, icons and theme
├── waybar/             # Waybar config, CSS and scripts
└── wlogout/            # Layout, CSS, icons and shutdown/session scripts
```

Each folder goes inside `~/.config/` on your system, except `docs/`, `assets/`, `index.html`, `KEYBINDS.txt` (goes to `~/Documents/KEYBINDS.txt`), and `starship.static.toml` (which goes to `~/.config/starship.toml`, not under its own name — see [Manual Installation](#manual-installation)).

---

## Dependencies

Package names may vary depending on your enabled repositories. Check each package before installing it.

### Recommended base for Arch / CachyOS

```bash
sudo pacman -Syu
sudo pacman -S \
  hyprland waybar kitty fish starship fastfetch rofi-wayland \
  hyprlock hypridle swaync wlogout \
  pipewire wireplumber pavucontrol playerctl \
  networkmanager network-manager-applet \
  bluez bluez-utils blueman \
  wl-clipboard cliphist grim slurp swappy \
  nautilus btop udiskie polkit-kde-agent \
  jq curl imagemagick libnotify ffmpeg ffmpegthumbnailer \
  pacman-contrib reflector fzf fd bat eza zoxide ripgrep \
  lm_sensors ttf-jetbrains-mono-nerd\
  thefuck bottom
```

> If you use CachyOS you can download Zen-Browser from pacman packages:
```bash
sudo pacman -S zen-browser-bin
```

### AUR or to verify

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
```bash
yay -S zen-browser-bin
```

## IMPORTANT: IF YOU INSTALL THINGS FROM THE AUR, CAREFULLY REVIEW WHAT WILL BE INSTALLED.

`awww` is the image wallpaper backend used by this rice. `swww` is **not used** — `awww` replaced it entirely. Install `awww` from the AUR.

**Marked as to verify:**

- `hyprland-lua`: this rice uses `hypr/hyprland.lua` with `hl.*` calls, not classic `hyprland.conf`. Verify the correct package or method for your version of Hyprland.
- `hyprshutdown`: appears as an optional fallback in a keybind.
- `Future-black-cursors`, `Colloid-cursors`, SDDM Minecraft, Minegrub: install or replace according to your system.
- `obs`, `brave`, `vscodium`: personal applications tied to keybinds, not requirements of the base environment.
- `awww`: required by the Rofi wallpaper selector to apply static images. `swww` is not used in this rice — `awww` replaced it. `matugen` is required if you want dynamic theming — see [External Additions](#external-additions); the rest of the rice works fine without it.

---

## Before You Begin

> ⚠️ Make a backup of your current configuration before copying any files.

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

> ⚠️ Check personal paths, wallpapers, sensors, and programs before logging into Hyprland.

---

## Manual Installation

This repo is not plug-and-play.

```bash
git clone https://github.com/kitasael-burakku/Minecraft-Rice-Hyprland.git ~/dotfiles
cd ~/dotfiles
```

Copy the folders you want to use:

```bash
mkdir -p ~/.config
cp -r hypr waybar rofi kitty fish fastfetch hyprlock swaync wlogout cava matugen ~/.config/
cp starship.static.toml ~/.config/starship.toml

mkdir -p ~/Documents
cp ~/dotfiles/KEYBINDS.txt ~/Documents/KEYBINDS.txt
```

The per-app color files (`rofi/colors.rasi`, `waybar/colors.css`, `kitty/colors/colors.conf`, etc.) aren't in the repo — they're generated. Populate them with the static "Kitasan Glass" baseline:

```bash
bash ~/.config/hypr/scripts/apply-static-colors.sh
```

Dynamic wallpaper-driven theming is off by default; toggle it later with `SUPER + SHIFT + W` — see [External Additions](#external-additions).

### Wallpapers

Video wallpapers are **not included** in this repo due to file size limits. Place your own video wallpapers here:

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

Give execution permissions to the scripts:

```bash
chmod +x ~/.config/waybar/scripts/*.sh
chmod +x ~/.config/rofi/launcher.sh
chmod +x ~/.config/swaync/scripts/*.sh
chmod +x ~/.config/wlogout/scripts/*.sh
chmod +x ~/.config/hyprlock/scripts/*.sh
chmod +x ~/.config/rofi/scripts/*.sh
chmod +x ~/.config/hypr/scripts/*.sh
```

If you want to use Fish as your default shell:

```bash
chsh -s /usr/bin/fish
```

Before logging into Hyprland, check paths, monitors, sensors, wallpaper, and programs. If something doesn't exist on your system, Hyprland may start incomplete or some shortcuts won't do anything.

---

## Hyprland in Lua

The main configuration is at:

```text
hypr/hyprland.lua
```

That file loads modules:

```lua
require("modules.environment")
require("modules.monitors")
require("modules.input")
require("modules.animations")
require("modules.decoration")
require("modules.layout")
require("modules.windowrules")
require("modules.programs")
require("modules.keybinds")
require("modules.misc")
require("modules.autostart")
```

The order is intentional, not alphabetical: `environment` loads first (env vars other modules may depend on), `programs` loads before `keybinds` (which reads the global `Programs` table), and `autostart` loads last.

> This is **not the classic `hyprland.conf` format**. You need Lua support for Hyprland to be working in your installation. If your Hyprland only reads `hyprland.conf`, this configuration will not load as-is.

Key files:

- `hypr/modules/programs.lua` — terminal, file manager and launcher (global `Programs` table used by `keybinds.lua`).
- `hypr/modules/keybinds.lua` — keyboard shortcuts, screenshots, multimedia and session.
- `hypr/modules/autostart.lua` — services and programs that launch with Hyprland.
- `hypr/modules/monitors.lua` — output, resolution, position, and scale hardcoded for my machine (`HDMI-A-1`, `1920x1080@200Hz`) — see [Things You Must Change](#things-you-must-change) for how to switch it to automatic detection instead.
- `hypr/modules/input.lua` — keyboard layout, sensitivity, and per-device config placeholder.
- `hypr/modules/environment.lua` — Wayland, Qt, Electron, and AMD environment variables.
- `hypr/modules/decoration.lua` — gaps, borders, rounding, opacity, shadow and blur. Border colors are hardcoded here as the static fallback, but get overwritten live via `hyprctl eval` when matugen is enabled — see [External Additions](#external-additions).
- `hypr/modules/layout.lua` — configuration for the three layouts (dwindle, master, scrolling); the active default is `scrolling`. Can be hot-swapped with `SUPER + SHIFT + D/M/O`.
- `hypr/modules/animations.lua` — custom curves and springs system (" 流 水   ·   R Y Ū S U I   M O T I O N ") for windows, fades, layers, workspaces, and zoom.
- `hypr/modules/windowrules.lua` — window and layer rules (blur/alpha/animation for SwayNC, Rofi, Wlogout).
- `hypr/modules/misc.lua` — miscellaneous settings, includes disabling Hyprland's random wallpaper/logo.
- `hypr/modules/private.lua` (optional, not tracked — see `hypr/modules/private.example.lua` for the template) — personal programs/autostart commands/keybinds you don't want in the public repo. `programs.lua`, `autostart.lua`, and `keybinds.lua` all `pcall(require, "modules.private")`, so everything works fine if this file doesn't exist; copy the example and fill it in if you want the extra hooks.

---

## Rofi — Wallpaper Selector

The wallpaper selector is a two-level Rofi picker built entirely as native Rofi script mode, without depending on any external project. It's tied to `SUPER + W` and orchestrated by a wrapper script that chains two independent Rofi instances:

```
SUPER + W
      ↓
wallpaper_launcher.sh               ← entry point (called from keybind)
      ↓
rofi (wallpaper-type-select.rasi)   ← level 0: choose type
  │   󰎁  Video
  │   󰉏  Imagen
      ↓ (selection written to ${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next)
rofi (wallpaper-picker.rasi)        ← level 1: thumbnail grid
  │   [thumb] [thumb] [thumb] ...
      ↓
applies wallpaper + matugen_reload
```

**Scripts involved:**

- `rofi/scripts/wallpaper_launcher.sh` — entry point called by the keybind. Runs the type selector, waits for it to close, reads the chosen directory from `${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next`, then opens the grid picker with the correct theme. This sequential approach (blocking Rofi instances) is what makes the two-level flow reliable.
- `rofi/scripts/wallpaper_rofi.sh` — runs as the script mode modi for the type selector. On selection, writes the target directory and prompt label to `${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next` and exits cleanly.
- `rofi/scripts/wallpaper_grid.sh` — runs as the script mode modi for the thumbnail grid. Lists wallpapers from the chosen directory with their thumbnails as icons. On selection, applies the wallpaper and calls `matugen_reload.sh`.
- `rofi/scripts/generate-thumbs.sh` — generates `.jpg` thumbnails for both `WALLPAPER_DIR_VIDEO` and `WALLPAPER_DIR_IMG` into `~/.cache/rofi-wallpapers/thumbs`. Runs in the background when the picker opens — never blocks the menu.
- `rofi/scripts/matugen_reload.sh` — called after applying a wallpaper. Gated by the `~/.config/matugen/enabled` sentinel (off by default on a fresh clone); `ENABLE_DYNAMIC_COLORS=1` bypasses that gate purely for manual testing — see [External Additions](#external-additions).

**Directories:**

| Variable | Default | Contents |
|---|---|---|
| `WALLPAPER_DIR_VIDEO` | `~/Videos/Wallpapers` | Videos (`mp4`, `mkv`, `mov`, `webm`) and images |
| `WALLPAPER_DIR_IMG` | `~/Pictures/Wallpapers` | Static images only (`jpg`, `png`, `webp`, `gif`) |

Both can be overridden by exporting the variable before the launcher runs.

**Applying wallpapers:** handled by `hypr/scripts/apply-wallpaper.sh`, the single place these flags live (shared by the picker and by `autostart.lua`'s restore-on-start):
- Video formats → relaunches `mpvpaper` with `--loop-file=inf --no-audio --hwdec=auto`
- Image formats → `awww img` with transition

**Themes:**
- Type selector uses `rofi/wallpaper-type-select.rasi` (compact list, imports `colors.rasi` like every other Rofi theme)
- Grid picker uses `rofi/wallpaper-picker.rasi` (4-column thumbnail grid)

The keybind in `hypr/modules/programs.lua` calls `wallpaper_launcher.sh` directly, not `wallpaper_rofi.sh`. If you point the keybind at the wrong script, only the type selector opens and nothing happens after you choose.

---

## Cava — Audio Visualizer

The `cava/` folder includes three components:

- **`config`** — configures cava with pipewire method, noncurses output at 60fps in mono mode (averaged).
- **`themes/`** — three color palettes: `agua` (blues), `solarized_dark`, and `tricolor`. To activate a theme, copy its contents into the `[color]` block of `cava/config`.
- **`shaders/`** — six GLSL shaders for cava's visual mode: `bar_spectrum.frag`, `eye_of_phi.frag`, `northern_lights.frag`, `spectrogram.frag`, `winamp_line_style_spectrum.frag`, and `pass_through.vert`. To use them, enable the `ngl` method in the `[output]` section of `cava/config` and point `shader` to the path of the `.frag` you want.

> Shaders require cava to be compiled with OpenGL support (`ngl`). Check your package before enabling them.

---

## External Additions

I'm fairly purist about this: I change wallpapers often (based on mood or time of day), but I don't always want my color palette to follow. So dynamic theming is a real, fully wired feature — it's just **off by default**. A fresh clone boots with the static "Kitasan Glass" palette until you turn it on.

**Toggle:** `SUPER + SHIFT + W` runs `rofi/scripts/matugen_toggle.sh`. It flips a sentinel file (`~/.config/matugen/enabled`) and:
- **Turning on** generates colors right away from whatever wallpaper is currently active (or asks you to pick one, if it can't detect it) and notifies you via `notify-send`.
- **Turning off** restores the exact static values — bit for bit, no visual drift from the pre-toggle look.

**Pipeline:** applying a wallpaper (`SUPER + W`, or the autostart hook seeding colors from the default video wallpaper at login) calls `rofi/scripts/matugen_reload.sh`, which — only if the sentinel is present — runs `matugen` against the current wallpaper (extracting a frame with `ffmpeg` first if it's a video) using the templates and hooks declared in `matugen/config.toml`:

| Surface | Output | Reload mechanism |
|---|---|---|
| Rofi | `rofi/colors.rasi` | none needed — Rofi re-reads on next launch |
| Waybar | `waybar/colors.css` | `pkill -SIGUSR2 waybar` (reloads CSS without killing the bar) |
| Kitty | `kitty/colors/colors.conf` | `killall -SIGUSR1 kitty` |
| Wlogout | `wlogout/colors.css` | none needed — relaunched per invocation |
| Hyprlock | `hyprlock/colors.conf` | none needed — each lock is a fresh process |
| Hyprland borders | `hypr/dynamic-colors.sh` | run through `hyprctl eval` right after being generated (`hyprctl keyword` doesn't work against this Lua config) |
| SwayNC | `swaync/colors.css` | `swaync-client -rs` |
| Starship | `starship.toml` | none needed — re-read on every prompt render |
| Fish | `fish/conf.d/theme-goldship.fish` | none possible — `conf.d/` is only sourced when a shell starts; new terminals pick it up automatically |

Every generated file has a `*.static.*` counterpart (e.g. `rofi/colors.static.rasi`) that's the source of truth when dynamic theming is off, and what `matugen_toggle.sh` restores when you turn it back off. Semantic colors (errors, critical states) follow the wallpaper too, kept consistent across every surface on purpose.

If you want to adapt this to your own palette instead of matugen's Material You output, edit the templates in `matugen/templates/` and their matching `*.static.*` baseline — everything downstream (hooks, toggle, sentinel) stays the same.

---

## Fish Functions

### Aliases

Aliases defined in `fish/conf.d/tools.fish`:

**CLI replacements** — modern tools mapped to familiar names:

| Alias | Replaces | Notes |
|---|---|---|
| `cat` | `bat` | Plain style, no paging |
| `less` | `bat` | With paging |
| `ls` / `ll` / `la` | `eza` | Icons + directory-first |
| `move` / `copy` / `copyr` | `mv` / `cp` / `cp -r` | Interactive + verbose |
| `remove` / `remover` | `rm` / `rm -r` | Interactive + verbose |

**System maintenance:**

| Alias | Does |
|---|---|
| `mirrors` | Refreshes mirrorlist via reflector (fastest 20 HTTPS mirrors) |
| `fixkeys` | Reinstalls archlinux-keyring |
| `failed` / `userfailed` | Lists failed systemd services |
| `jerrors` | Shows boot errors from journalctl (priority 3) |
| `disks` | `lsblk -f` — disk layout with filesystems |
| `temps` | Live sensor watch every 2s |

**Config shortcuts** — open a config folder directly in VSCodium:

```fish
ecfish      ecwaybar    echypr      ecswaync
eckitty     echyprlock  ecrofi      ecwlogout
eccava      ecfastfetch ecstarship
```

### Functions

Beyond aliases and external tool integrations, Fish includes custom functions invocable as commands:

- `sysupdate` — updates pacman and AUR (yay) in one pass, with animated output. This is the same thing that runs when you click the `custom/updates` module in Waybar.
- `quickcache` — quick cleanup of known app caches (browser, Spotify, Electron, etc.) — browser detection is automatic, only cleans what's actually installed, with confirmation before deleting.
- `checktrash` / `cleantrash` — the first only reports what can be cleaned (orphan packages, caches, trash); the second actually cleans it, with confirmation.
- `checkerrors` — diagnoses failed services, journalctl errors (including Hyprland/portals), and recent coredumps. Read-only, changes nothing.
- `healthcheck` — quick overview of the entire system in one screen: kernel, memory/zram, pending updates, orphan packages, `.pacnew`/`.pacsave` files, failed services, boot errors, disk, network, and temperatures. Unlike `checkerrors`, it does not show full logs — it only counts and flags what needs attention.
- `keybinds` — opens an interactive viewer for `KEYBINDS.txt` directly in the terminal, with vim-style navigation (`h/j/k/l`), search (`:` + space), and section pagination. While open, it automatically floats and centers the terminal window.
- `fastfetch` (the function, not the binary) — picks a preset from `fastfetch/config*.jsonc` using a weighted shuffle bag (rarer presets show up less often); the bag reshuffles once exhausted, so a repeat across that boundary is possible.

> ⚠️ `keybinds` depends on `KEYBINDS.txt` maintaining an exact format: section header in UPPERCASE, a line of only dashes below it, and entries as `KEY    Description` with at least two spaces between columns. If you edit that file manually, respect the format or the viewer will stop recognizing sections.

---

## Things You Must Change

At minimum, review before using:

- `hypr/hyprlock.conf` — change `$hyprlockDir` to your real path (`/home/your-username/.config/hyprlock`).
- `hypr/scripts/apply-wallpaper.sh` — change `DEFAULT_WALLPAPER` to a wallpaper you actually have. This is the only place the default lives; `hypr/modules/autostart.lua` just calls this script to restore the last wallpaper you picked (or this default, on a fresh clone).
- `hypr/modules/environment.lua` and `hypr/modules/autostart.lua` — both define the same cursor theme; if you change it, update it in both files to avoid them going out of sync.
- `hypr/modules/input.lua` — mouse and keyboard are configured with real device names (`Logitech G203 LIGHTSYNC Gaming Mouse`, `Shinetek Technology USB Gaming Keyboard`); change them to yours, or remove the `hl.device` blocks if you don't need per-device sensitivity.
- `hypr/modules/programs.lua` — change `kitty`, `nautilus`, `zen-browser`, the launcher, or `windowswitcher` command if you use other apps or a different Rofi theme path.
- `rofi/scripts/window-switcher.sh` — the `MINIMIZED_WS` variable defaults to `special:minimized`; change it if you use a different special workspace name.
- `hypr/modules/keybinds.lua` — change `obs`, screenshot paths, and commands you don't use.
- `fish/conf.d/tools.fish` — the `ec*` aliases (`ecswaync`, `echypr`, etc.) open the corresponding folder in `codium` (VSCodium); change the editor if you use another one.
- `hypr/modules/monitors.lua` — fixes output, resolution, position and scale for this machine (`HDMI-A-1`, `1920x1080@200Hz`). This is the one you're most likely to need to change before Hyprland even starts — set it to your own monitor, or switch to `output = ""`, `mode = "preferred"`, `position = "auto"`, `scale = "auto"` for automatic detection.
- `waybar/config.jsonc` — change `hwmon-path-abs`/`input-filename` to the correct sensor for your machine.
- `hyprlock/layouts/layout.conf` — points to `hyprlock/wallpapers/current.png`, which always mirrors whatever wallpaper you last picked (see `apply-wallpaper.sh` above); `2.png` is only the static fallback used to bootstrap `current.png` on a fresh clone. Nothing to change here unless you want a different fallback image.
- `fastfetch/config*.jsonc` — change logos, images and presets if you don't want to use the included assets.

To find all personal paths at once:

```bash
rg "/home/|your-username|kitasa-elburakku|wallpaper|hwmon|Future-black|Colloid" .
```

---

## Scripts and Commands Used in This Rice

- **Hyprland/Wayland:** `hyprctl`, `hyprlock`, `hypridle`, `waybar`, `swaync`, `swaync-client`, `wlogout`, `awww`, `matugen`
- **Audio/media:** `wpctl`, `pavucontrol`, `playerctl`, `cava`
- **Screenshots/clipboard:** `hyprshot`, `grim`, `slurp`, `swappy`, `wl-copy`, `wl-paste`, `cliphist`, `hyprpicker`
- **System:** `systemctl`, `loginctl`, `pacman`, `yay`, `checkupdates`, `paccache`, `journalctl`, `lm_sensors`
- **Network/GUI:** `nm-connection-editor`, `blueman-manager`, `nwg-look`
- **Terminal/shell:** `kitty`, `fish`, `starship`, `fastfetch`, `fzf`, `fd`, `bat`, `eza`, `zoxide`, `ripgrep`
- **Utilities:** `curl`, `jq`, `imagemagick`/`magick`, `ffmpeg`, `ffmpegthumbnailer`, `libnotify`/`notify-send`, `udiskie`, `reflector`

---

## Notes for Beginners

- Don't blindly copy everything. Start with one folder, test it, then move on to the next.
- If a command fails, run it manually in the terminal to see the actual error.
- Paths with `/home/your-username/...` are examples. Replace them with your actual username or use `$HOME` when the program supports it.
- Icons depend on Nerd Fonts. If you see squares or strange symbols, install and select a Nerd Font in your terminal.
- Waybar may break the temperature module if your hardware sensor is different from mine.
- Fish functions run real tasks like updating packages and cleaning caches. Read them before using them.
- `hyprlock/scripts/` has 4 files, all MPRIS-related via `playerctl` — no network calls: `playerlayout4.sh` (source/title/artist), `music-progress.sh` (progress bar), and their matugen-generated color pair (`music-colors.sh` / `music-colors.static.sh`) — see [External Additions](#external-additions).
- Some settings are tailored specifically to my hardware, my programs, and my workflow.

---

## Command Reference

> This section is for people coming from Windows or just starting out with Linux. If you already know these, feel free to skip it.

### git clone

```bash
git clone https://github.com/user/repository.git
```

Downloads a repository from GitHub to your computer, preserving the change history. It's equivalent to downloading a ZIP but better.

---

### cd

```bash
cd ~/dotfiles
```

Changes the current directory (folder) in the terminal. `cd ~/.config` enters the configuration folder.

---

### mkdir

```bash
mkdir -p ~/.config
```

Creates directories. The `-p` flag avoids errors if the folder already exists.

---

### cp and cp -r

```bash
cp file.txt destination/        # copies a file
cp -r hypr waybar ~/.config/    # copies entire folders (recursive)
```

Without `-r`, Linux won't copy directories.

---

### chmod +x

```bash
chmod +x script.sh
```

Adds execution permissions. Required to run `.sh` scripts as programs.

---

### chsh

```bash
chsh -s /usr/bin/fish
```

Changes the user's default shell. After logging out and back in, Fish will open automatically instead of Bash.

---

### rg (ripgrep)

```bash
rg "wallpaper" .
```

Searches for text inside files. Very useful for finding personal paths, usernames, sensors, and variables in configs.

---

### sudo

```bash
sudo pacman -S package
```

Runs a command with administrator permissions. Only use it when you understand what the command does.

---

### pacman

```bash
sudo pacman -S package      # install
sudo pacman -Rns package    # remove with unneeded dependencies
sudo pacman -Syu            # update the entire system
```

Package manager for Arch Linux and CachyOS.

---

### yay

```bash
yay -S package
```

Installs packages from the AUR (Arch User Repository). Works similar to pacman but accesses community-maintained software.

---

### Why is there no automatic installer?

Copying files manually lets you understand where each configuration lives, which program uses each file, detect errors more easily, and modify specific parts without depending on automatic scripts.

Manual installation requires more work, but teaches you much more about how the system actually works.

---

## External Credits

- Hyprland, Waybar, Rofi, Kitty, Fish, Starship, Fastfetch, Hyprlock, Hypridle, Wlogout, and SwayNC belong to their respective projects.
- The Rofi wallpaper selector (`rofi/scripts/wallpaper_launcher.sh` + `wallpaper_rofi.sh` + `wallpaper_grid.sh`) is original work: a two-level picker built as native Rofi script mode, chaining two independent Rofi instances with state passed via `${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next`. Replaces the previous Quickshell-based version.
- [matugen](https://github.com/InioX/matugen) is the dynamic theming engine behind the optional wallpaper-driven color pipeline — see [External Additions](#external-additions).
- Some presets in `fastfetch/config*.jsonc` are adapted from the official Fastfetch project examples.
- Minecraft is property of Mojang/Microsoft. The aesthetic used here is fan-made/personal.
- SDDM Minecraft, Minegrub, cursors, wallpapers, icons, logos, and character images are external assets unless otherwise noted.
- Nerd Fonts and JetBrains Mono Nerd Font belong to their respective authors.

If you reuse this rice, keep the credits for the projects and assets you use.

---

## Project Status

Personal rice in progress. May contain paths, decisions, and dependencies very specific to my system. Use it as learning material and as a base to build your own configuration.

---

## Project Philosophy

My goal is not to build a perfect configuration, but one that I can understand, maintain, and modify without depending on external tools or unnecessary layers of abstraction.

I prefer:

- Modular configuration over giant files.
- Manual installation over magic scripts.
- Understanding over copying.
- Simplicity over unnecessary complexity.
- Learning over automating.

If this repository helps you learn something about Linux, Hyprland, Waybar, Fish, or dotfiles, then it has already fulfilled its purpose.

---