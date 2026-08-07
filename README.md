<div align="center">

# ⛏️ Minecraft-Rice-Hyprland

**A personal, heavily-customized Hyprland rice with a Minecraft-inspired look — built for CachyOS, configured in Lua, and meant to be read before it's used.**

![Hyprland](https://img.shields.io/badge/WM-Hyprland-89b4fa?style=for-the-badge&logo=hyprland&logoColor=white)
![OS](https://img.shields.io/badge/OS-Arch%20%2F%20CachyOS-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)
![Config](https://img.shields.io/badge/Config-Lua-2c2d72?style=for-the-badge&logo=lua&logoColor=white)
![Status](https://img.shields.io/badge/Status-Personal%20Rice-orange?style=for-the-badge)
![Plug and Play](https://img.shields.io/badge/Plug%20%26%20Play-NO-critical?style=for-the-badge)
![License](https://img.shields.io/badge/License-See%20LICENSE-lightgrey?style=for-the-badge)

<img src="docs/screenshots/desktop.jpg" alt="Desktop preview" width="850"/>

</div>

<br>

> ### The Philosophy
> This is **not an automatic installer** and **not a universal configuration** — it does **not** guarantee compatibility with your system. It's built around one idea:
>
> **Read → Understand → Adapt → Learn → Build your own configuration.**
>
> You can do whatever you want with this dotfile. If you don't want to install or use it, you simply don't have to copy it.

> 🎨 **Dynamic theming via matugen — off by default.** The base palette ("Kitasan Glass") is hardcoded and intentional; that's what you get on a fresh clone. Toggle `SUPER + SHIFT + W` and every app derives a Material You palette from your current wallpaper instead. See [External Additions](#external-additions-dynamic-theming).

> 🖱️ **Infinite Desktop via a Python script**, letting you pan and navigate a boundless canvas of floating windows. Built by **sarodscommits** — full credit in [External Credits](#external-credits).

<br>

## ✨ Repository highlights

- 🎛️ **Session managed by `systemd --user`**, not loose background processes — every daemon (Waybar, SwayNC, Hypridle, clipboard, wallpaper daemon, etc.) is a real unit with `Restart=`, its own journal, and a clean start/stop lifecycle tied to `graphical-session.target`
- ⌨️ **`kitasan` — one CLI for the whole rice**: health checks, cache cleanup, updates, visual theme switching, desktop modes, and a system dashboard, all under one command with Fish completions
- 🎨 Opt-in Material You theming that propagates across **13 app surfaces** through matugen — including GTK3/GTK4 and Qt5/Qt6, not just the terminal-adjacent apps
- 🚀 A handful of purpose-built Rofi tools beyond the launcher — Wi-Fi, Bluetooth, audio device, MPRIS player picker, quick power menu, service manager, visual theme picker, and a system dashboard, all native Rofi script mode
- 🖱️ Custom two-level Rofi wallpaper picker (video / image, each with its own theme) — built from scratch as native Rofi script mode, no external project
- 🌀 Hand-tuned custom animation system, "流水 · Ryūsui Motion" (curves & springs)
- 🪟 **Infinite Desktop** — pan and navigate a boundless floating-window canvas, now itself a supervised systemd service
- 🐟 Custom Fish functions for health checks, maintenance, and an interactive keybind viewer — `KEYBINDS.txt` is generated from `keybinds.lua`, not maintained by hand
- 🎮 Minecraft-themed boot experience: Qylock (SDDM) + MINEGRUB (GRUB)

<br>

## 🚀 Quick Features

| Feature | Included |
|---|---|
| Lua-based Hyprland configuration | ✅ |
| Session & daemons managed by `systemd --user` | ✅ |
| `kitasan` unified CLI (health / clean / update / theme / mode / dashboard) | ✅ |
| Desktop modes — normal / focus / gaming / cinema | ✅ |
| Waybar (taskbar, audio slider, media controls) | ✅ |
| Dynamic theming via matugen — Rofi, Waybar, Kitty, GTK3/4, Qt5/6, and more (opt-in) | ✅ |
| Rofi quick actions — Wi-Fi, Bluetooth, audio, MPRIS, power, services, dashboard | ✅ |
| Two-level wallpaper picker (video / image) | ✅ |
| Infinite Desktop (floating canvas mode) | ✅ |
| Custom Fish functions, aliases & completions | ✅ |
| Window switcher with minimize/restore | ✅ |
| cava audio visualizer with GLSL shaders | ✅ |
| Hyprlock with MPRIS now-playing block | ✅ |
| Minecraft-themed SDDM / GRUB | ✅ |
| Automatic one-click installer | ❌ *(by design — see [The Philosophy](#the-philosophy))* |

<br>

---

## 📚 Table of Contents

- [Where to Start](#where-to-start)
- [Why This Repository Exists](#why-this-repository-exists)
- [Who Is This For](#who-is-this-for)
- [Repository Tour](#repository-tour)
- [Architecture](#architecture)
- [Screenshots](#screenshots)
- [Hardware & Compatibility](#hardware-compatibility)
- [Tools Used](#tools-used)
- [Features](#features)
- [Repo Structure](#repo-structure)
- [Getting Started](#getting-started)
  - [Dependencies](#dependencies)
  - [Before You Begin](#before-you-begin)
  - [Manual Installation](#manual-installation)
  - [Wallpapers](#wallpapers)
- [Configuration Deep Dive](#configuration-deep-dive)
  - [Hyprland in Lua](#hyprland-in-lua)
  - [systemd — Session & Services](#systemd-session-services)
  - [kitasan — Unified CLI](#kitasan-unified-cli)
  - [Rofi — Wallpaper Selector](#rofi-wallpaper-selector)
  - [Rofi — Quick Actions](#rofi-quick-actions)
  - [Cava — Audio Visualizer](#cava-audio-visualizer)
  - [External Additions — Dynamic Theming](#external-additions-dynamic-theming)
  - [Fish Functions](#fish-functions)
- [Things You Must Change](#things-you-must-change)
- [Scripts and Commands Used in This Rice](#scripts-and-commands-used-in-this-rice)
- [Notes for Beginners](#notes-for-beginners)
- [Command Reference](#command-reference)
- [External Credits](#external-credits)
- [Project Status](#project-status)
- [Project Philosophy](#project-philosophy)

---

## Where to Start

This repository is written for two types of people:

| If you... | Start here |
|---|---|
| Are coming from Windows, or are new to Linux | [Command Reference](#command-reference) → [Before You Begin](#before-you-begin) → then follow the README in order |
| Already know Linux and dotfiles | [Repo Structure](#repo-structure) → [Hyprland in Lua](#hyprland-in-lua) → [Things You Must Change](#things-you-must-change) |

---

## Why This Repository Exists

I came to Linux from Windows looking for more control over my system. I started with Arch, made a lot of mistakes, learned from all of them, and eventually migrated to CachyOS, where I built this rice.

Most modern configurations use automatic installers that hide how everything works under the hood. This repository takes the opposite approach — the idea is not to copy everything and hope it works.

Here you'll find real paths, real scripts, and decisions made for a daily-use system. Some things will work right away, others will require modifications — and that's precisely where the learning happens.

> If you're looking for a one-click install, this repository probably isn't for you.
> If you want to understand what each file does before running it, then it probably is.

---

## Who Is This For

**This may be useful if:**
- You're coming from Windows and want to learn Linux from the inside out
- You want to understand how a real rice is organized and built
- You're interested in Hyprland, Wayland, and dotfiles
- You prefer to understand what you install before running it
- You like modifying and adapting configurations to your own system

**It's probably NOT for you if:**
- You're looking for a fully automatic installer
- You don't want to edit configuration files
- You expect guaranteed compatibility without making changes

---

## Repository Tour

A quick map before you go any further — what lives where, and what it's for.

| Folder / File | What it is |
|---|---|
| `hypr/` | Core Hyprland configuration — Lua modules, `hypridle.conf`, base `hyprlock.conf`, and the maintenance/orchestration scripts (`hypr/scripts/`) |
| `systemd/user/` | `systemd --user` unit files that supervise the session — `hyprland-session.service` plus every daemon (Waybar, SwayNC, Hypridle, clipboard, wallpaper, etc.) and 4 background timers. See [systemd — Session & Services](#systemd-session-services) |
| `waybar/` | Status bar config, CSS, and scripts |
| `rofi/` | Launcher, clipboard picker, two-level wallpaper selector, power menu, window switcher, and the quick-action scripts (Wi-Fi, Bluetooth, audio, MPRIS, theme, service manager, dashboard) |
| `kitty/` | Terminal configuration and colors |
| `fish/` | Shell config, functions (including `kitasan`), aliases, themes, and completions |
| `hyprlock/` | Lock screen layout, colors, wallpaper, and MPRIS scripts |
| `swaync/` | Notification center config, styles, and icons |
| `wlogout/` | Session menu layout, CSS, icons, and shutdown scripts |
| `matugen/` | Dynamic (Material You) theming templates and config — 14 templates covering 13 app surfaces |
| `gtk-3.0/` / `gtk-4.0/` | GTK theme override chain (`gtk.css` importing the active theme + matugen-driven color overrides) — see [External Additions](#external-additions-dynamic-theming) |
| `qt5ct/` / `qt6ct/` | Qt palette config (`qt5ct.conf`/`qt6ct.conf`) and the matugen-driven `kitasan-glass` color scheme |
| `cava/` | Audio visualizer config, GLSL shaders, and themes |
| `fastfetch/` | jsonc configs, logos, and visual presets |
| `docs/screenshots/` | Rice screenshots |
| `assets/` | Assets for the GitHub Pages site (e.g. `demo.mp4`) |
| `index.html` | Source for the GitHub Pages site |
| `KEYBINDS.txt` | Keybind reference, generated from `hypr/modules/keybinds.lua` by `hypr/scripts/generate-keybinds-doc.sh` — read by the `keybinds` Fish function |
| `starship.static.toml` | Starship prompt config — copied to `~/.config/starship.toml` |
| `LICENSE` | License file |

> Every folder above goes inside `~/.config/` on your system — **except** `docs/`, `assets/`, `index.html`, `KEYBINDS.txt` (→ `~/Documents/KEYBINDS.txt`), and `starship.static.toml` (→ `~/.config/starship.toml`, not under its own name). Full details in [Manual Installation](#manual-installation).

---

## Architecture

Two diagrams: how the **session and its daemons boot/shut down** (systemd), and how the pieces **talk to each other at runtime** — from Hyprland launching everything, to a wallpaper change flowing through the theming pipeline.

### Session lifecycle — `systemd --user`

Every daemon in this rice is a real systemd unit, not a loose background process. Hyprland's Lua layer only has to trigger **one** thing; systemd owns the rest.

```text
Hyprland compositor
      │
      │  hl.on("hyprland.start")   ← hypr/modules/autostart.lua (the ONLY
      ▼                              Lua→systemd touchpoint left)
systemctl --user start hyprland-session.service
      │
      │  Wants= / BindsTo= graphical-session.target
      ▼
graphical-session.target  (native systemd target, RefuseManualStart=yes —
│                           can only be pulled up by something that Wants it)
│
│  WantedBy=graphical-session.target, declared by each unit's own [Install]
├──▶ waybar.service              ├──▶ cliphist-text.service
├──▶ swaync.service              ├──▶ cliphist-image.service
├──▶ hypridle.service            ├──▶ infinite-desktop.service
├──▶ udiskie.service             ├──▶ playerctl-watch.service
├──▶ awww.service                └──▶ polkit-agent.service
└──▶ wallpaper.service (oneshot — restores the last wallpaper, kicks matugen)

+ timers.target → updates-check.timer, thumbs-refresh.timer,
                  healthcheck-notify.timer, dotbackup-remind.timer

hl.on("hyprland.shutdown") → systemctl --user stop graphical-session.target
      → every unit above (PartOf=graphical-session.target) stops in cascade
```

Each unit ships with `Restart=`, its own `journalctl --user -u <unit>` log, and `[Install] WantedBy=graphical-session.target` — but **that `[Install]` line alone doesn't start anything**; you still need to `systemctl --user enable` the units after installing (see [systemd — Session & Services](#systemd-session-services) and [Manual Installation](#manual-installation)).

### Runtime — apps talking to each other

```text
                         ┌───────────────────────────┐
                         │          Hyprland          │
                         │    (hypr/hyprland.lua)     │
                         └──────────────┬──────────────┘
                                        │ loads modules
        ┌─────────────┬─────────────────┼─────────────────┬─────────────┐
        ▼             ▼                 ▼                 ▼             ▼
     Waybar         Rofi            Hyprlock           Wlogout        SwayNC
  (status bar,   (launcher /       (lock screen)      (session menu) (notifications)
   quick-action    wallpaper /
   scripts)        window switcher /
                    quick actions)
                     │
                     │  SUPER + W                    SUPER + F4 / F5
                     ▼                                     ▼
          wallpaper_launcher.sh                    kitasan menu / dashboard
                     │                              (Rofi frontend for health,
        ┌────────────┴────────────┐                  clean, update, theme,
        ▼                         ▼                   mode, and service mgmt)
 apply-wallpaper.sh        matugen_reload.sh   (only runs if the
 (mpvpaper / awww)                │              matugen sentinel is ON)
                                   ▼
                                matugen
                          (Material You engine)
                                   │
   ┌────────┬────────┬────────┬───┼────┬────────┬─────────┬────────────────┐
   ▼        ▼        ▼        ▼   ▼    ▼        ▼         ▼                ▼
 Rofi    Waybar   Kitty   Hyprlock SwayNC Wlogout GTK3/4   Qt5/6    Starship / Fish /
colors   colors   colors  colors  colors colors  colors   colors  Hyprland borders
                                                                    (hyprctl eval)

   cava (audio visualizer)  ──  independent, reads Pipewire directly
   Fastfetch                ──  triggered by Fish on every new Kitty terminal
   Infinite Desktop scripts ──  Python, systemd-supervised, hooked into
                                 Hyprland through keybinds.lua
```

Every generated color file has a `*.static.*` counterpart that's the source of truth when dynamic theming is off — see [External Additions](#external-additions-dynamic-theming) for the full surface-by-surface breakdown (13 surfaces now, GTK/Qt included).

---

## Screenshots

<div align="center">
<img src="docs/screenshots/desktop.jpg" alt="Desktop" width="850"/>
<br><sub><b>Desktop</b></sub>
</div>

<br>

<table>
<tr>
<td width="50%"><img src="docs/screenshots/rofi.jpg" alt="Rofi + SwayNC"/><br><sub align="center"><b>Rofi + SwayNC</b></sub></td>
<td width="50%"><img src="docs/screenshots/window-minimiser.jpg" alt="Window Switcher"/><br><sub align="center"><b>Window Switcher</b></sub></td>
</tr>
<tr>
<td width="50%"><img src="docs/screenshots/wallpaper-picker.jpg" alt="Wallpaper Picker"/><br><sub align="center"><b>Wallpaper Picker</b></sub></td>
<td width="50%"><img src="docs/screenshots/video-wallpaper-picker.jpg" alt="Video Wallpaper Picker"/><br><sub align="center"><b>Video Wallpaper Picker</b></sub></td>
</tr>
<tr>
<td width="50%"><img src="docs/screenshots/Image_wallpaperpicker.jpg" alt="Image Wallpaper Picker"/><br><sub align="center"><b>Image Wallpaper Picker</b></sub></td>
<td width="50%"><img src="docs/screenshots/keybinds.jpg" alt="Keybinds and Btop"/><br><sub align="center"><b>Keybinds and Btop</b></sub></td>
</tr>
</table>

<div align="center">
<img src="docs/screenshots/hyprlock.jpg" alt="Hyprlock" width="850"/>
<br><sub><b>Hyprlock</b></sub>
</div>

> 💡 **Presentation idea:** `assets/demo.mp4` already exists for the GitHub Pages site. A short clip of it converted into a looping GIF (e.g. `docs/screenshots/demo.gif`) dropped at the top of this section would let visitors see the wallpaper picker, the animations, and dynamic theming switching live — before reading a single line of config.

---

## Hardware & Compatibility

```text
CPU: AMD Ryzen 7 8700F
GPU: AMD Radeon RX 7600 8GB
RAM: 16GB DDR5
Monitor: 1920x1080 @ 200Hz
OS: CachyOS
```

This configuration was developed and tested on this hardware. Some parts depend specifically on AMD.

> 🚫 **Laptop support**
>
> Minecraft Rice Hyprland is primarily developed and tested on desktop hardware. While most components should work on laptops, the following is currently outside the project's scope:
> - Battery management
> - Brightness controls
> - Power profiles
> - Laptop function keys
> - Touchpad gestures beyond the included configuration
> - Vendor-specific utilities
> - Suspend/resume tuning
>
> Contributions adding optional laptop support are welcome.

---

## Tools Used

| Tool | Function |
|---|---|
| Hyprland (Lua) | Modular window manager |
| `systemd --user` | Supervises every daemon — Waybar, SwayNC, Hypridle, clipboard, wallpaper, Infinite Desktop, and 4 background timers, all as real units tied to `graphical-session.target`. See [systemd — Session & Services](#systemd-session-services) |
| `kitasan` (Fish function) | Unified CLI for the whole rice — health checks, cache cleanup, updates, theme/mode switching, dashboard. See [kitasan — Unified CLI](#kitasan-unified-cli) |
| Waybar | Status bar with taskbar (`wlr/taskbar`), inline audio slider (`pulseaudio/slider`), and media player controls |
| Rofi | Launcher, clipboard selector, two-level wallpaper selector (Videos / Images, each with its own theme), decorative power menu, window switcher with minimize/restore (`ALT + TAB`), and quick-action tools (Wi-Fi, Bluetooth, audio, MPRIS, service manager, theme picker, dashboard). See [Rofi — Quick Actions](#rofi-quick-actions) |
| matugen | Dynamic theming engine — off by default, toggled with `SUPER + SHIFT + W`, propagates to 13 app surfaces including GTK3/4 and Qt5/6. See [External Additions](#external-additions-dynamic-theming) |
| power-profiles-daemon | CPU power profile switching (`balanced`/`performance`/`power-saver`) — driven by the Waybar module and by `kitasan mode` |
| Kitty | Terminal |
| Fish + Starship | Shell with custom prompt — includes `starship.toml` with "Floating Stone Bubbles" theme (Minecraft shader palette) |
| Fastfetch | System info on terminal open |
| Hyprlock | Lock screen |
| SwayNC | Notification center |
| Wlogout | Session menu |
| mpvpaper | Video wallpaper (loops mp4/mkv/webm/mov) |
| awww | Static image wallpaper (replaces swww) |
| cava | Audio visualizer — includes config, custom GLSL shaders, and themes (agua, solarized_dark, tricolor) |
| Infinite Desktop | Floating desktop tiled style — see [External Additions](#external-additions-dynamic-theming) |
| Qylock | Minecraft-style SDDM theme — [Darkkal44/qylock](https://github.com/Darkkal44/qylock) |
| MINEGRUB | Minecraft-style GRUB theme — [Lxtharia/minegrub-theme](https://github.com/Lxtharia/minegrub-theme) |

---

## Features

<details open>
<summary><b>🪟 Window Manager & Motion</b></summary>
<br>

- Hyprland configuration split into Lua modules inside `hypr/modules/`, including an animation system with curves and springs under the custom name **" 流 水 · R Y Ū S U I  M O T I O N "** (`animations.lua`).
- Hot-swappable Hyprland layout (dwindle / master / scrolling), with `scrolling` as the default.
- Window and layer rules for blur/alpha/animation (SwayNC, Rofi, Wlogout).
- Shortcuts for screenshots, color picker, multimedia control, floating with auto-resize, Waybar reload, and system tools.
- Session daemons (animated wallpaper, Waybar, SwayNC, Hypridle, Polkit, clipboard, udiskie, Infinite Desktop) are `systemd --user` units, not raw autostart processes — Hyprland's Lua layer just starts `hyprland-session.service`, which pulls in every enabled unit via `graphical-session.target`. See [systemd — Session & Services](#systemd-session-services).

</details>

<details open>
<summary><b>🎛️ System Management</b></summary>
<br>

- **`kitasan`** — a single Fish CLI covering health checks, cache cleanup, full system updates, visual theme switching, desktop modes, and a system dashboard, with Fish completions for every subcommand. `kitasan menu` (`SUPER + F4`) puts all of it behind a Rofi picker. See [kitasan — Unified CLI](#kitasan-unified-cli).
- **Desktop modes** (`kitasan mode` / normal, focus, gaming, cinema) toggle DND, blur/animations, idle timeouts, and the power profile together, applied live via `hyprctl eval` — no relogin needed, and they don't persist across one either (by design).
- **Dashboard** (`SUPER + F5`) — pending updates, failed services, CPU/GPU temps, disk usage, current MPRIS track, and last dotfiles backup, all in one Rofi panel with quick actions attached to each row.
- Every daemon that used to be a loose background process is now a supervised `systemd --user` unit with `Restart=` and a real journal — see [systemd — Session & Services](#systemd-session-services).

</details>

<details open>
<summary><b>📊 Status Bar & Notifications</b></summary>
<br>

- Waybar with modules for disk, audio, clock, workspaces, tray, updates (with direct access to `sysupdate`), network, temperature, CPU, memory, and a power button connected to a mini Rofi menu.
- Includes a `wlr/taskbar` with app icons in the center bubble, and an inline `pulseaudio/slider` for quick volume control.
- SwayNC with notification center, quick controls, and `goldship` theme.
- Actionable notifications: a background timer refreshes the pending-updates count every 30 minutes, and past a threshold you get a notification with an **"Update now"** action button — no need to open a terminal first.

</details>

<details open>
<summary><b>🚀 Launcher & Wallpapers</b></summary>
<br>

- Rofi as application launcher, clipboard history selector, decorative power menu (the different font in that menu is intentional; the actual session is handled by Wlogout), and window switcher (`ALT + TAB`) — lists all open windows with minimize/restore: click an active window to minimize it to `special:minimized`, click a minimized one to restore it to the current workspace.
- Two-level wallpaper selector as native Rofi script mode, shortcut `SUPER + W`. Opens a type selector (Videos / Images, each sourced from a different directory) before showing the thumbnail grid — each level uses its own `.rasi` theme. Thumbnail generation runs in the background and never blocks the menu. Applying a wallpaper feeds matugen for dynamic theming when it's enabled — see [Rofi — Wallpaper Selector](#rofi-wallpaper-selector) and [External Additions](#external-additions-dynamic-theming).
- A quick power menu (`SUPER + SHIFT + ESCAPE`) — lock/suspend/logout/reboot/shutdown from a 5-line Rofi list, faster than opening full-screen Wlogout for the common case. Hibernate stays Wlogout-only.

</details>

<details open>
<summary><b>🌐 Rofi Quick Actions</b></summary>
<br>

- Wi-Fi, Bluetooth, and audio device pickers — list, connect/disconnect, and set default, all via `nmcli`/`bluetoothctl`/`wpctl`, no GTK settings windows.
- MPRIS player picker — pick which player to control when more than one is running, then Play/Pause/Next/Previous.
- Visual theme picker (`SUPER + ALT + W`) — choose between 6 matugen color schemes or the static "Kitasan Glass" baseline, independent of the on/off toggle.
- Service manager (`SUPER + F3`) — list `systemd --user` units (failed ones first), start/stop/restart, or jump straight into `journalctl -f` for one.
- See [Rofi — Quick Actions](#rofi-quick-actions) for the full list and the scripts behind each one.

</details>

<details open>
<summary><b>🎨 Theming</b></summary>
<br>

- Unified color palette **Kitasan Glass · Universal Dark** applied across Waybar CSS, Kitty, Fish shell, Rofi `.rasi` themes, Starship prompt, SwayNC, GTK3/4, and Qt5/6 — desaturated accents (cyan `#7ab8b8`, blue-gray `#8098a8`, muted red `#b85c50`, sand `#c8b898`) over near-black backgrounds, designed to work with any wallpaper without clashing.
- GTK/Qt theming is deliberately conservative: only the color roles that define the palette's identity (background, foreground, selection, borders, semantic colors) are overridden — not a full re-theme of every widget state. See [External Additions](#external-additions-dynamic-theming).

</details>

<details open>
<summary><b>🖥️ Terminal & Shell</b></summary>
<br>

- Kitty with Fish as shell, custom color theme "Kitasan-Ship Minecraft Edition" (palette of Creeper greens, stone grays, redstone reds), and Fastfetch image support via Kitty's graphics protocol.
- Fish with Starship, "Minecraft Overworld" palette applied to shell syntax, random rotation between 9 Fastfetch presets, modern aliases, and custom maintenance/diagnostic functions plus an interactive keybind viewer — see [Fish Functions](#fish-functions).
- The fuck: typo corrector integrated into Fish.

</details>

<details open>
<summary><b>🔒 Lock Screen & Session</b></summary>
<br>

- Hyprlock with minimalist layout (clock, date, user, password) plus a small MPRIS block (source, title/artist, progress bar) that follows the dynamic color pipeline — see [External Additions](#external-additions-dynamic-theming).
- Wlogout with lock, logout, suspend, shutdown, hibernate, and reboot actions — this is the system's real session menu.

</details>

<details open>
<summary><b>🎵 Audio Visualizer</b></summary>
<br>

- cava with custom config (pipewire, noncurses, 60fps), three swappable themes (`agua`, `solarized_dark`, `tricolor`) and six custom GLSL shaders for visual mode.

</details>

<details open>
<summary><b>🪐 Infinite Desktop</b></summary>
<br>

- A powerful script that transforms your Hyprland workspace into an "infinite" canvas. It lets you pan all floating windows simultaneously with your mouse and navigate between them with keyboard shortcuts, creating a dynamic, boundless desktop experience.

</details>

---

## Repo Structure

```text
.
├── assets/             # demo.mp4 and other assets for the GitHub Pages site
├── cava/               # Config, GLSL shaders and themes for the audio visualizer
├── docs/screenshots/   # Rice screenshots
├── fastfetch/          # jsonc configs, logos and visual presets
├── fish/               # config.fish, functions (incl. kitasan), aliases, completions and Fish shell themes
├── gtk-3.0/            # gtk.css override chain + matugen-driven color file
├── gtk-4.0/            # gtk.css override chain + matugen-driven color file (GTK4 has no GTK_THEME env var — this IS the theme)
├── hypr/               # Hyprland Lua, modules, hypridle.conf, base hyprlock.conf, and hypr/scripts/ (autostart helpers, systemd-adjacent tooling)
├── hyprlock/           # Lock screen layout, colors, wallpaper and scripts
├── index.html          # Source for the GitHub Pages site
├── KEYBINDS.txt        # Keybind reference, generated from keybinds.lua — used by the `keybinds` fish function
├── kitty/              # Kitty configuration and colors
├── LICENSE
├── matugen/            # Dynamic (Material You) theming templates and config — 14 templates, 13 app surfaces
├── qt5ct/              # Qt5 palette config + matugen-driven color scheme
├── qt6ct/              # Qt6 palette config + matugen-driven color scheme
├── rofi/               # Launcher, clipboard, two-level wallpaper selector (wallpaper_launcher.sh → wallpaper_rofi.sh → wallpaper_grid.sh), power menu, window switcher, and quick-action scripts (Wi-Fi, Bluetooth, audio, MPRIS, theme, service manager, dashboard) — see rofi/scripts/
├── starship.static.toml # Starship config (prompt); copy to ~/.config/starship.toml (starship.toml itself is generated/gitignored)
├── swaync/             # Notification center config, styles, icons and theme
├── systemd/user/       # systemd --user units: hyprland-session.service, every daemon, and 4 background timers
├── waybar/             # Waybar config, CSS and scripts
└── wlogout/            # Layout, CSS, icons and shutdown/session scripts
```

Each folder goes inside `~/.config/` on your system, except `docs/`, `assets/`, `index.html`, `KEYBINDS.txt` (goes to `~/Documents/KEYBINDS.txt`), and `starship.static.toml` (which goes to `~/.config/starship.toml`, not under its own name — see [Manual Installation](#manual-installation)).

---

## Getting Started

### Dependencies

> Package names may vary depending on your enabled repositories. Check each package before installing it.

**Recommended base for Arch / CachyOS**

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
  thefuck bottom python python-evdev bash jq \
  power-profiles-daemon qt5ct qt6ct
```

> `power-profiles-daemon` is a **system** service (`sudo systemctl enable --now power-profiles-daemon`), not a user one — it backs both the Waybar module and `kitasan mode`. `qt5ct`/`qt6ct` are what actually read `qt5ct.conf`/`qt6ct.conf` — without them, Qt apps ignore the theming in `qt5ct/`/`qt6ct/` entirely.

> If you use CachyOS you can download Zen-Browser from pacman packages:
> ```bash
> sudo pacman -S zen-browser-bin
> ```

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
> `awww` is the image wallpaper backend used by this rice. `swww` is **not used** — `awww` replaced it entirely. Install `awww` from the AUR.

<details>
<summary><b>Marked as "to verify" — click to expand</b></summary>
<br>

- `hyprland-lua`: this rice uses `hypr/hyprland.lua` with `hl.*` calls, not classic `hyprland.conf`. Verify the correct package or method for your version of Hyprland.
- `hyprshutdown`: appears as an optional fallback in a keybind.
- `Future-black-cursors`, `Colloid-cursors`, SDDM Minecraft, Minegrub: install or replace according to your system.
- `obs`, `brave`, `vscodium`: personal applications tied to keybinds, not requirements of the base environment.
- `awww`: required by the Rofi wallpaper selector to apply static images. `swww` is not used in this rice — `awww` replaced it. `matugen` is required if you want dynamic theming — see [External Additions](#external-additions-dynamic-theming); the rest of the rice works fine without it.

</details>

---

### Before You Begin

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

### Manual Installation

This repo is not plug-and-play.

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

mkdir -p ~/Documents
cp ~/dotfiles/KEYBINDS.txt ~/Documents/KEYBINDS.txt
```

The per-app color files (`rofi/colors.rasi`, `waybar/colors.css`, `kitty/colors/colors.conf`, `gtk-3.0/gtk-colors.css`, `qt5ct/colors/kitasan-glass.conf`, etc.) aren't in the repo — they're generated. Populate them with the static "Kitasan Glass" baseline:

```bash
bash ~/.config/hypr/scripts/apply-static-colors.sh
```

Dynamic wallpaper-driven theming is off by default; toggle it later with `SUPER + SHIFT + W` — see [External Additions](#external-additions-dynamic-theming).

Give execution permissions to the scripts:

```bash
chmod +x ~/.config/waybar/scripts/*.sh
chmod +x ~/.config/rofi/launcher.sh
chmod +x ~/.config/swaync/scripts/*.sh
chmod +x ~/.config/wlogout/scripts/*.sh
chmod +x ~/.config/hyprlock/scripts/*.sh
chmod +x ~/.config/rofi/scripts/*.sh
chmod +x ~/.config/hypr/scripts/*.sh
chmod +x ~/.config/hypr/infinite_desktop/infinite-desktop.sh ~/.config/hypr/infinite_desktop/floating_tile_toggle.py ~/.config/hypr/infinite_desktop/move_window_tiled.py ~/.config/hypr/infinite_desktop/navigate_windows.py ~/.config/hypr/infinite_desktop/resize_window.py
```

Enable the systemd units — copying the files into `~/.config/systemd/user/` is not enough by itself, `[Install]` blocks only take effect once you `enable` them:

```bash
systemctl --user daemon-reload
systemctl --user enable --now \
  waybar.service swaync.service hypridle.service udiskie.service \
  awww.service wallpaper.service cliphist-text.service cliphist-image.service \
  infinite-desktop.service playerctl-watch.service polkit-agent.service

systemctl --user enable --now \
  updates-check.timer thumbs-refresh.timer healthcheck-notify.timer dotbackup-remind.timer
```

> `hyprland-session.service` is *not* in that list — it has no `[Install]` block on purpose, it's only ever started by `hypr/modules/autostart.lua` when Hyprland itself launches. See [systemd — Session & Services](#systemd-session-services) for why the architecture is split this way.

If you want to use Fish as your default shell:

```bash
chsh -s /usr/bin/fish
```

Before logging into Hyprland, check paths, monitors, sensors, wallpaper, and programs. If something doesn't exist on your system, Hyprland may start incomplete or some shortcuts won't do anything.

After your installation activate the infinite desktop script

## Infinite Desktop

> For implementation details and upstream documentation, see the original
> [Infinite Desktop project](https://github.com/sarodscommits/hyprland-infinitie-desktop-v2).

1. Add your user to the `input` group: 

```bash
sudo usermod -aG input $USER
```

Log out and log back in (or reboot your system) for the new group membership to take effect.

---

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

## Configuration Deep Dive

### Hyprland in Lua

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

> ⚠️ This is **not the classic `hyprland.conf` format**. You need Lua support for Hyprland to be working in your installation. If your Hyprland only reads `hyprland.conf`, this configuration will not load as-is.

**Key files:**

| File | Purpose |
|---|---|
| `hypr/modules/programs.lua` | Terminal, file manager and launcher (global `Programs` table used by `keybinds.lua`) |
| `hypr/modules/keybinds.lua` | Keyboard shortcuts, screenshots, multimedia and session |
| `hypr/modules/autostart.lua` | Deliberately thin now — starts `hyprland-session.service` (which pulls in every systemd-managed daemon, see [systemd — Session & Services](#systemd-session-services)), sets the cursor theme, and runs any private autostart commands. Everything that used to be a raw `hl.exec_cmd` background job lives in `systemd/user/` instead |
| `hypr/modules/monitors.lua` | Output, resolution, position, and scale hardcoded for my machine (`HDMI-A-1`, `1920x1080@200Hz`) — see [Things You Must Change](#things-you-must-change) to switch to automatic detection |
| `hypr/modules/input.lua` | Keyboard layout, sensitivity, and per-device config placeholder |
| `hypr/modules/environment.lua` | Wayland, Qt, Electron, and AMD environment variables |
| `hypr/modules/decoration.lua` | Gaps, borders, rounding, opacity, shadow and blur. Border colors are hardcoded here as the static fallback, but get overwritten live via `hyprctl eval` when matugen is enabled |
| `hypr/modules/layout.lua` | Configuration for the three layouts (dwindle, master, scrolling); the active default is `scrolling`. Hot-swappable with `SUPER + SHIFT + D/M/O` |
| `hypr/modules/animations.lua` | Custom curves and springs system (" 流 水 · R Y Ū S U I  M O T I O N ") for windows, fades, layers, workspaces, and zoom |
| `hypr/modules/windowrules.lua` | Window and layer rules (blur/alpha/animation for SwayNC, Rofi, Wlogout) |
| `hypr/modules/misc.lua` | Miscellaneous settings, including disabling Hyprland's random wallpaper/logo |
| `hypr/modules/private.lua` *(optional, not tracked)* | Personal programs/autostart/keybinds you don't want public — see `hypr/modules/private.example.lua` for the template. `programs.lua`, `autostart.lua`, and `keybinds.lua` all `pcall(require, "modules.private")`, so everything works fine if this file doesn't exist |

---

### systemd — Session & Services

Every daemon this rice needs — Waybar, SwayNC, Hypridle, the clipboard watchers, the wallpaper daemon, udiskie, Polkit, playerctl's watcher, and Infinite Desktop — is a real `systemd --user` unit under `systemd/user/`, not a background process launched by Hyprland's Lua and left to fend for itself.

**Why a `.service` for a compositor daemon at all?** Restart-on-crash, a real `journalctl --user -u <unit>` log instead of output vanishing into nowhere, and a single, predictable teardown path — instead of "reload Waybar" meaning `pkill` + relaunch by hand.

**The bootstrap chain:**

```text
hypr/modules/autostart.lua (hl.on("hyprland.start"))
      │
      ▼
systemctl --user start hyprland-session.service
      │  Wants= / BindsTo= graphical-session.target
      ▼
graphical-session.target        ← native systemd target (ships with systemd itself)
      │  Wants= (from each unit's own [Install] WantedBy=, once enabled)
      ▼
waybar / swaync / hypridle / udiskie / awww / wallpaper /
cliphist-text / cliphist-image / infinite-desktop /
playerctl-watch / polkit-agent  (+ maly, if you add a private daemon the same way)
```

`hyprland-session.service` itself is intentionally minimal:

```ini
[Unit]
Description=Hyprland graphical session
BindsTo=graphical-session.target
Wants=graphical-session.target
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/true
RemainAfterExit=yes
```

It has no `[Install]` section on purpose — it's not meant to be `enable`d, only started directly by Hyprland at `hyprland.start`. `graphical-session.target` refuses to be started manually (`RefuseManualStart=yes`, a systemd default); it can only be pulled up by something that `Wants=` it, which is exactly what this service does.

Every daemon unit declares `PartOf=graphical-session.target` — that's a **lifecycle** relation (stop the target, and everything with `PartOf=` on it stops too), not a start trigger. The actual start trigger is each unit's `[Install] WantedBy=graphical-session.target`, which only takes effect once you run `systemctl --user enable` on it (see [Manual Installation](#manual-installation)). Copying the unit files into `~/.config/systemd/user/` is not enough by itself — `is-enabled` will say `disabled` until you do.

Teardown is symmetric: `hl.on("hyprland.shutdown")` runs `systemctl --user stop graphical-session.target`, which stops every `PartOf=` unit in cascade.

**Timers** (`timers.target`, also need `enable --now`):

| Timer | Runs | Why |
|---|---|---|
| `updates-check.timer` | Every 30 min | Refreshes the pacman+AUR update count in the background, instead of Waybar's own polling triggering the (slow) check itself |
| `thumbs-refresh.timer` | Daily | Pre-generates wallpaper thumbnails so the picker never has to generate them on open |
| `healthcheck-notify.timer` | Daily | Silent unless it finds something — orphan packages, failed services, low disk space |
| `dotbackup-remind.timer` | Weekly | Only meaningful if you maintain your own fork the way this repo's author does (see `hypr/scripts/dotbackup-remind.sh`) — notifies if `~/.config` diverged from your local clone. Safe to disable if that's not your workflow |

**No `hyprland-session.target`.** A dedicated target was considered and deliberately not built — `hyprland-session.service` bootstrapping the native `graphical-session.target` is the standard pattern non-DE-integrated Wayland compositors use, it already comes with `Requires=basic.target` (sockets, D-Bus, etc.) for free, and every `xdg-desktop-portal-*`/`gvfs-*` unit the desktop portals need is already `PartOf=` the same target. A second target would add a layer without solving anything the native one doesn't already handle.

---

### kitasan — Unified CLI

Before this existed, `healthcheck`, `quickcache`, `cleantrash`, and `sysupdate` were four separate Fish functions you had to remember by name. `kitasan` (`fish/functions/kitasan.fish`) is a thin wrapper over all of them plus the newer systemd/theming/mode tooling, with Fish completions (`fish/completions/kitasan.fish`) for every subcommand and argument.

```text
kitasan health           → healthcheck
kitasan clean            → quickcache (fast, no sudo)
kitasan clean --deep     → cleantrash (orphans + pacman cache, needs sudo)
kitasan update           → sysupdate
kitasan theme [scheme]   → visual profile picker — Rofi if no argument, direct if you pass one (e.g. `kitasan theme vibrant`)
kitasan wall             → wallpaper picker over fzf, for when you don't want Rofi
kitasan mode [profile]   → normal / focus / gaming / cinema — see below
kitasan doctor           → template parity + keybinds drift + failed services + orphans, all read-only
kitasan dashboard        → same panel as `SUPER + F5`, launched from a terminal
kitasan menu             → all of the above, picked from Rofi (same as `SUPER + F4`)
```

**Desktop modes** (`kitasan mode`, or from `kitasan menu`) bundle DND, blur/animations, idle timeout, and the power profile into one live-applied state, each via the mechanism that actually supports it — `hyprctl eval` for blur/animations (the same one used for dynamic border colors, and it survives a plain `hyprctl reload`), `swaync-client -dn/-df` for DND, and either `systemctl --user stop/start hypridle.service` or a raw `hypridle -c` process with a longer-timeout config for the idle behavior:

| Mode | Effect |
|---|---|
| `normal` | Everything as installed |
| `focus` | DND on, idle timeout stretched to 30 min (lock) / 60 min (DPMS off) |
| `gaming` | Blur and animations off, DND on, power profile set to `performance` |
| `cinema` | Waybar hidden, DND on, Hypridle stopped entirely (no auto-lock, no DPMS-off) |

Modes don't persist across a relogin on purpose — `hyprland.start` re-runs the Lua modules fresh (blur/animations back on) and restarts `hypridle.service`/`waybar.service` from scratch, so you never boot back into `gaming` by accident.

---

### Rofi — Wallpaper Selector

The wallpaper selector is a two-level Rofi picker built entirely as native Rofi script mode, without depending on any external project. It's tied to `SUPER + W` and orchestrated by a wrapper script that chains two independent Rofi instances:

```text
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
- `rofi/scripts/matugen_reload.sh` — called after applying a wallpaper. Gated by the `~/.config/matugen/enabled` sentinel (off by default on a fresh clone); `ENABLE_DYNAMIC_COLORS=1` bypasses that gate purely for manual testing.

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

> ⚠️ The keybind in `hypr/modules/programs.lua` calls `wallpaper_launcher.sh` directly, not `wallpaper_rofi.sh`. If you point the keybind at the wrong script, only the type selector opens and nothing happens after you choose.

> Every Rofi theme in this rice imports `rofi/config.rasi` first — shared `matching: "fuzzy"`, `sorting-method: "fzf"`, `terminal`, and the launcher's mode-switcher config live there once, instead of duplicated across all six `.rasi` files.

---

### Rofi — Quick Actions

Beyond the launcher and the wallpaper picker, `rofi/scripts/` has a handful of small, single-purpose tools — each one a plain dmenu script over a CLI tool that was already a dependency, no new GUI toolkits pulled in.

| Script | Keybind / trigger | What it does |
|---|---|---|
| `power.sh` | `SUPER + SHIFT + ESCAPE` | Lock / suspend / logout / reboot / shutdown from a 5-line list — reuses `wlogout/scripts/confirm-then.sh` for the destructive ones, so the confirmation dialog and the command whitelist are shared, not duplicated |
| `mpris.sh` | Waybar `custom/playerctl` right-click | Pick which MPRIS player to control when more than one is running, then Play/Pause/Next/Previous/Stop on that one specifically |
| `audio.sh` | Waybar `pulseaudio` left-click | Lists sinks/sources parsed from `wpctl status`, sets the chosen one as default |
| `wifi.sh` | Waybar `network` left-click | Lists nearby networks via `nmcli`, connects, and prompts for a password with `rofi -password` only if the network actually needs one |
| `bluetooth.sh` | Waybar `bluetooth` left-click | Toggle adapter power, connect/disconnect already-paired devices via `bluetoothctl` |
| `theme.sh` | `SUPER + ALT + W` | Pick one of matugen's 6 color schemes, or the static "Kitasan Glass" baseline — independent of the dynamic on/off toggle (`SUPER + SHIFT + W`) |
| `systemd.sh` | `SUPER + F3` | Lists `systemd --user` units (failed ones first), then start/stop/restart or open `journalctl -f` for the one you pick |
| `mode.sh` | via `kitasan mode` / `kitasan menu` | Rofi frontend for the desktop modes described in [kitasan — Unified CLI](#kitasan-unified-cli) |
| `dashboard.sh` | `SUPER + F5` | Pending updates, failed services, CPU/GPU temperature, disk usage, current MPRIS track, and time since the last dotfiles backup — each with a quick action attached (e.g. selecting "failed services" opens `systemd.sh`) |

All nine reuse `rofi/clipboard.rasi` as their theme (a plain single-column list, no icon assumptions baked in) rather than each shipping its own `.rasi`.

---

### Cava — Audio Visualizer

The `cava/` folder includes three components:

- **`config`** — configures cava with pipewire method, noncurses output at 60fps in mono mode (averaged).
- **`themes/`** — three color palettes: `agua` (blues), `solarized_dark`, and `tricolor`. To activate a theme, copy its contents into the `[color]` block of `cava/config`.
- **`shaders/`** — six GLSL shaders for cava's visual mode: `bar_spectrum.frag`, `eye_of_phi.frag`, `northern_lights.frag`, `spectrogram.frag`, `winamp_line_style_spectrum.frag`, and `pass_through.vert`. To use them, enable the `ngl` method in the `[output]` section of `cava/config` and point `shader` to the path of the `.frag` you want.

> Shaders require cava to be compiled with OpenGL support (`ngl`). Check your package before enabling them.

---

### External Additions — Dynamic Theming

I'm fairly purist about this: I change wallpapers often (based on mood or time of day), but I don't always want my color palette to follow. So dynamic theming is a real, fully wired feature — it's just **off by default**. A fresh clone boots with the static "Kitasan Glass" palette until you turn it on.

**Toggle:** `SUPER + SHIFT + W` runs `rofi/scripts/matugen_toggle.sh`. It flips a sentinel file (`~/.config/matugen/enabled`) and:
- **Turning on** generates colors right away from whatever wallpaper is currently active (or asks you to pick one, if it can't detect it) and notifies you via `notify-send`.
- **Turning off** restores the exact static values — bit for bit, no visual drift from the pre-toggle look.

**Which scheme:** the toggle above is binary (on/off); `SUPER + ALT + W` (`rofi/scripts/theme.sh`) is the other dimension — pick *which* of matugen's 6 Material You schemes to use (`tonal-spot`, `vibrant`, `expressive`, `fidelity`, `content`, `neutral`) while dynamic theming is on. The chosen scheme is stored in `~/.config/matugen/scheme` and read by `matugen_reload.sh` on every subsequent regeneration, so it survives wallpaper changes until you pick a different one.

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
| GTK3 | `gtk-3.0/gtk-colors.css` | none possible — GTK only reads `gtk.css` at app launch; already-open apps keep their old colors |
| GTK4 | `gtk-4.0/gtk-colors.css` | same as GTK3. `gtk-4.0/gtk.css` imports `theme-base.css` (a symlink to the actual installed theme — GTK4 has no `GTK_THEME` env var, so this file *is* the theme) and then this generated file on top, so only the color roles below are overridden, nothing else about the theme changes |
| Qt5 / Qt6 | `qt5ct/colors/kitasan-glass.conf` / `qt6ct/colors/kitasan-glass.conf` | none possible — same per-launch limitation as GTK |

Every generated file has a `*.static.*` counterpart (e.g. `rofi/colors.static.rasi`) that's the source of truth when dynamic theming is off, and what `matugen_toggle.sh` restores when you turn it back off. Semantic colors (errors, critical states) follow the wallpaper too, kept consistent across every surface on purpose.

**GTK/Qt are deliberately partial.** Colorful-Dark-GTK (the shipped GTK theme) defines close to 90 color variables for very specific states (insensitive/backdrop/hover/unfocused/titlebar, mostly with a `_breeze` suffix). Re-tinting all of them blind wasn't worth the risk of a broken-looking widget somewhere; only the roles that define the palette's *identity* — background, foreground, selection, borders, and the semantic colors — are overridden, both under their base name and their `_breeze` variant. The Qt palette follows the same philosophy: it's a minimal diff over the stock `darker.conf` scheme (still shipped by `qt5ct`/`qt6ct`), touching only `WindowText`/`Text`/`Base`/`Window`/`Highlight`/`HighlightedText`/`AlternateBase` and leaving the other ~14 QPalette roles exactly as they were.

If you want to adapt this to your own palette instead of matugen's Material You output, edit the templates in `matugen/templates/` and their matching `*.static.*` baseline — everything downstream (hooks, toggle, sentinel) stays the same.

---

### Fish Functions

**Aliases** — defined in `fish/conf.d/tools.fish`:

<details open>
<summary><b>CLI replacements</b> — modern tools mapped to familiar names</summary>
<br>

| Alias | Replaces | Notes |
|---|---|---|
| `cat` | `bat` | Plain style, no paging |
| `less` | `bat` | With paging |
| `ls` / `ll` / `la` | `eza` | Icons + directory-first |
| `move` / `copy` / `copyr` | `mv` / `cp` / `cp -r` | Interactive + verbose |
| `remove` / `remover` | `rm` / `rm -r` | Interactive + verbose |

</details>

<details open>
<summary><b>System maintenance</b></summary>
<br>

| Alias | Does |
|---|---|
| `mirrors` | Refreshes mirrorlist via reflector (fastest 20 HTTPS mirrors) |
| `fixkeys` | Reinstalls archlinux-keyring |
| `failed` / `userfailed` | Lists failed systemd services |
| `jerrors` | Shows boot errors from journalctl (priority 3) |
| `disks` | `lsblk -f` — disk layout with filesystems |
| `temps` | Live sensor watch every 2s |

</details>

<details>
<summary><b>Config shortcuts</b> — open a config folder directly in VSCodium</summary>
<br>

```fish
ecfish      ecwaybar    echypr      ecswaync
eckitty     echyprlock  ecrofi      ecwlogout
eccava      ecfastfetch ecstarship
```

</details>

**Functions** — beyond aliases and external tool integrations, Fish includes custom functions invocable as commands:

| Function | What it does |
|---|---|
| `kitasan` | Unified CLI wrapping most of the functions below plus theme/mode/dashboard — see [kitasan — Unified CLI](#kitasan-unified-cli). Has full Fish completions (`fish/completions/kitasan.fish`) |
| `sysupdate` | Updates pacman and AUR (yay) in one pass, with animated output. Same thing that runs when you click the `custom/updates` module in Waybar, or `kitasan update` |
| `quickcache` | Quick cleanup of known app caches (browser, Spotify, Electron, etc.) — browser detection is automatic, only cleans what's actually installed, with confirmation before deleting. Also `kitasan clean` |
| `checktrash` / `cleantrash` | The first only reports what can be cleaned (orphan packages, caches, trash); the second actually cleans it, with confirmation. `cleantrash` is also `kitasan clean --deep` |
| `checkerrors` | Diagnoses failed services, journalctl errors (including Hyprland/portals), and recent coredumps. Read-only, changes nothing |
| `healthcheck` | Quick overview of the entire system in one screen: kernel, memory/zram, pending updates, orphan packages, `.pacnew`/`.pacsave` files, failed services, boot errors, disk, network, and temperatures. Unlike `checkerrors`, it does not show full logs — it only counts and flags what needs attention. Also `kitasan health` |
| `keybinds` | Opens an interactive viewer for `KEYBINDS.txt` directly in the terminal, with vim-style navigation (`h/j/k/l`), search (`:` + space), and section pagination. While open, it automatically floats and centers the terminal window |
| `checkkeybinds` | No longer a drift-checker — `KEYBINDS.txt` can't drift from `keybinds.lua` anymore because it's *generated* from it (`hypr/scripts/generate-keybinds-doc.sh`, reading the `-- comment` above each `hl.bind()` as its description). `checkkeybinds` is now a thin wrapper: bare, it runs `--check` and tells you if a regen is needed; `checkkeybinds --write` regenerates `KEYBINDS.txt` for real |
| `fastfetch` *(the function, not the binary)* | Picks a preset from `fastfetch/config*.jsonc` using a weighted shuffle bag (rarer presets show up less often); the bag reshuffles once exhausted, so a repeat across that boundary is possible |

> `KEYBINDS.txt` is generated, not hand-maintained — edit the comment above the relevant `hl.bind()` in `keybinds.lua` and run `checkkeybinds --write` (or `kitasan doctor` to just check first). Manual edits to `KEYBINDS.txt` itself get silently overwritten on the next regen.

---

## Things You Must Change

At minimum, review before using:

| File | What to change |
|---|---|
| `hypr/hyprlock.conf` | Change `$hyprlockDir` to your real path (`/home/your-username/.config/hyprlock`) |
| `hypr/scripts/apply-wallpaper.sh` | Change `DEFAULT_WALLPAPER` to a wallpaper you actually have. This is the only place the default lives; `hypr/modules/autostart.lua` just calls this script to restore the last wallpaper you picked (or this default, on a fresh clone) |
| `hypr/modules/environment.lua` & `hypr/modules/autostart.lua` | Both define the same cursor theme; if you change it, update it in both files to avoid them going out of sync |
| `hypr/modules/input.lua` | Mouse and keyboard are configured with real device names (`Logitech G203 LIGHTSYNC Gaming Mouse`, `Shinetek Technology USB Gaming Keyboard`); change them to yours, or remove the `hl.device` blocks if you don't need per-device sensitivity |
| `hypr/modules/programs.lua` | Change `kitty`, `nautilus`, `zen-browser`, the launcher, or `windowswitcher` command if you use other apps or a different Rofi theme path |
| `rofi/scripts/window-switcher.sh` | The `MINIMIZED_WS` variable defaults to `special:minimized`; change it if you use a different special workspace name |
| `hypr/modules/keybinds.lua` | Change `obs`, screenshot paths, and commands you don't use |
| `fish/conf.d/tools.fish` | The `ec*` aliases (`ecswaync`, `echypr`, etc.) open the corresponding folder in `codium` (VSCodium); change the editor if you use another one |
| `hypr/modules/monitors.lua` | Fixes output, resolution, position and scale for this machine (`HDMI-A-1`, `1920x1080@200Hz`). This is the one you're most likely to need to change before Hyprland even starts — set it to your own monitor, or switch to `output = ""`, `mode = "preferred"`, `position = "auto"`, `scale = "auto"` for automatic detection |
| `waybar/config.jsonc` | Change `hwmon-path-abs`/`input-filename` to the correct sensor for your machine |
| `rofi/scripts/dashboard.sh` | Same `hwmon-path-abs` sensor path as Waybar, hardcoded separately — the CPU temperature row won't work until you fix both |
| `qt5ct/qt5ct.conf` & `qt6ct/qt6ct.conf` | `color_scheme_path` is a hardcoded absolute path (`/home/kitasa-elburakku/.config/...`) — change it to your own `$HOME`, or Qt apps will silently fail to find the color scheme |
| `hypr/scripts/dotbackup-remind.sh` & `systemd/user/dotbackup-remind.timer` | Assumes you maintain your own fork checked out at `~/Projects/dotfiles` and want a weekly nudge if it diverges from `~/.config`. If that's not your workflow, just don't `enable` the timer — nothing else depends on it |
| `hyprlock/layouts/layout.conf` | Points to `hyprlock/wallpapers/current.png`, which always mirrors whatever wallpaper you last picked (see `apply-wallpaper.sh` above); `2.png` is only the static fallback used to bootstrap `current.png` on a fresh clone. Nothing to change here unless you want a different fallback image |
| `fastfetch/config*.jsonc` | Change logos, images and presets if you don't want to use the included assets |

To find all personal paths at once:

```bash
rg "/home/|your-username|kitasa-elburakku|wallpaper|hwmon|Future-black|Colloid" .
```

---

## Scripts and Commands Used in This Rice

| Category | Commands |
|---|---|
| Hyprland/Wayland | `hyprctl`, `hyprlock`, `hypridle`, `waybar`, `swaync`, `swaync-client`, `wlogout`, `awww`, `matugen` |
| Audio/media | `wpctl`, `pavucontrol`, `playerctl`, `cava` |
| Screenshots/clipboard | `hyprshot`, `grim`, `slurp`, `swappy`, `wl-copy`, `wl-paste`, `cliphist`, `hyprpicker` |
| System | `systemctl` (--user, extensively — see [systemd — Session & Services](#systemd-session-services)), `loginctl`, `pacman`, `yay`, `checkupdates`, `paccache`, `journalctl`, `lm_sensors`, `powerprofilesctl` |
| Network/Bluetooth/GUI | `nmcli`, `bluetoothctl`, `nm-connection-editor`, `blueman-manager`, `nwg-look` |
| Terminal/shell | `kitty`, `fish`, `starship`, `fastfetch`, `fzf`, `fd`, `bat`, `eza`, `zoxide`, `ripgrep` |
| Utilities | `curl`, `jq`, `imagemagick`/`magick`, `ffmpeg`, `ffmpegthumbnailer`, `libnotify`/`notify-send`, `udiskie`, `reflector` |

---

## Notes for Beginners

- Don't blindly copy everything. Start with one folder, test it, then move on to the next.
- If a command fails, run it manually in the terminal to see the actual error.
- Paths with `/home/your-username/...` are examples. Replace them with your actual username or use `$HOME` when the program supports it.
- Icons depend on Nerd Fonts. If you see squares or strange symbols, install and select a Nerd Font in your terminal.
- Waybar may break the temperature module if your hardware sensor is different from mine.
- Fish functions run real tasks like updating packages and cleaning caches. Read them before using them.
- `hyprlock/scripts/` has 3 files, all MPRIS-related via `playerctl` — no network calls: `player.sh` (source/title/artist/progress bar, one shared decision of which player is "active" for all three) and its matugen-generated color pair (`music-colors.sh` / `music-colors.static.sh`).
- Some settings are tailored specifically to my hardware, my programs, and my workflow.

---

## Command Reference

<details>
<summary><b>📖 Click to expand — for people coming from Windows or just starting out with Linux</b> (skip if you already know these)</summary>

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

> ⚠️ The AUR contains community-maintained packages. Always inspect the `PKGBUILD` before installing software you don't trust.

```bash
yay -S package
```

### `sudo usermod -aG input $USER`

```bash
sudo usermod -aG input $USER
```

Adds your current user to the `input` group.

The Infinite Desktop scripts need direct access to Linux input devices (mouse and keyboard). Adding your user to the `input` group grants the required permissions.
Breaking it down:

- `sudo` — runs the command with administrator privileges.
- `usermod` — modifies an existing user account.
- `-a` — appends the change without removing the user from other groups.
- `-G input` — adds the user to the `input` group.
- `$USER` — expands to the name of the currently logged-in user.

> ⚠️ You must log out and log back in (or reboot) before the new group membership takes effect.s

Installs packages from the AUR (Arch User Repository). Works similar to pacman but accesses community-maintained software.

### Why is there no automatic installer?

Copying files manually lets you understand where each configuration lives, which program uses each file, detect errors more easily, and modify specific parts without depending on automatic scripts.

Manual installation requires more work, but teaches you much more about how the system actually works.

</details>

---

## External Credits

- Hyprland, Waybar, Rofi, Kitty, Fish, Starship, Fastfetch, Hyprlock, Hypridle, Wlogout, and SwayNC belong to their respective projects.
- The Rofi wallpaper selector (`rofi/scripts/wallpaper_launcher.sh` + `wallpaper_rofi.sh` + `wallpaper_grid.sh`) is original work: a two-level picker built as native Rofi script mode, chaining two independent Rofi instances with state passed via `${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next`. Replaces the previous Quickshell-based version.
- [matugen](https://github.com/InioX/matugen) is the dynamic theming engine behind the optional wallpaper-driven color pipeline — see [External Additions](#external-additions-dynamic-theming).
- Some presets in `fastfetch/config*.jsonc` are adapted from the official Fastfetch project examples.
- Minecraft is property of Mojang/Microsoft. The aesthetic used here is fan-made/personal.
- SDDM Minecraft, Minegrub, cursors, wallpapers, icons, logos, and character images are external assets unless otherwise noted.
- Nerd Fonts and JetBrains Mono Nerd Font belong to their respective authors.
- Credits to **sarodscommits**, who made the Infinite Desktop: [hyprland-infinitie-desktop-v2](https://github.com/sarodscommits/hyprland-infinitie-desktop-v2)

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