# Architecture

How the pieces fit together: the Lua config system, the systemd session lifecycle, Waybar's cursor zones, the Rofi tooling, and how changes get backed up to this repo in the first place.

The two external Hyprland plugins this rice loads get their own page — see [PLUGINS.md](PLUGINS.md).

---

## Hyprland in Lua

The main configuration is at `hypr/hyprland.lua`, which loads modules in a deliberate, non-alphabetical order:

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

-- Plugins
require("plugins.hyprglass")
require("plugins.dym-cursor")
```

`environment` loads first because later modules depend on the globals it exports. `programs` loads before `keybinds`, which reads the global `Programs` table. `autostart` is the last of the modules.

The two `require("plugins.…")` lines after them configure external Hyprland plugins, not the compositor itself — they load last, and each file guards on its plugin's config namespace actually existing so a missing or unbuilt plugin can't take the rest of the config down with it. Full detail in [PLUGINS.md](PLUGINS.md).

> ⚠️ This is **not the classic `hyprland.conf` format**. It's Hyprland's native Lua config API (`hl.*`) — keybinds use `hl.bind()`, dispatches use `hl.dsp.*`. You need a Hyprland build with Lua config support for this to load at all; official API stubs live at `/usr/share/hypr/stubs/hl.meta.lua`, and `hypr/.vscode/settings.json` (deliberately published, unlike the rest of `.vscode/`) wires the Lua LSP against them.

**Globals as the cross-module contract:**

| Global | Set in | Read by |
|---|---|---|
| `CursorTheme`, `GTKTheme` | `environment.lua` | `autostart.lua` (`hyprctl setcursor`), `hypr/scripts/apply-static-colors.sh` (GTK4 theme symlink, parsed straight out of `environment.lua`) |
| `HostnamePretty` | `environment.lua` | exported as `$HOSTNAME_PRETTY` via `hl.env()`; read by Starship's `[env_var.HOSTNAME_PRETTY]` — replaces a per-prompt `hostnamectl --pretty` D-Bus call |
| `Programs` | `programs.lua` | `keybinds.lua`, and `rofi/scripts/web_launcher.sh` indirectly (`hl.env("BROWSER", Programs.browser)`) |

> `$USER_PRETTY` is the counterpart of `$HOSTNAME_PRETTY` (used by Starship and by five Fastfetch presets), but it is **not** set anywhere in this repo — it's a Fish universal variable living in the gitignored `fish/fish_variables`. Set it yourself with `set -Ux USER_PRETTY "..."`; if it's unset, both Starship and Fastfetch fall back to `$USER` on their own.

**Key files:**

| File | Purpose |
|---|---|
| `hypr/modules/programs.lua` | Terminal, file manager, browser, and launcher commands — the global `Programs` table |
| `hypr/modules/keybinds.lua` | All keyboard shortcuts; references `Programs.*` and `home` |
| `hypr/modules/autostart.lua` | Deliberately thin — runs `hyprpm reload -n` (loads the plugin `.so` files, see [PLUGINS.md](PLUGINS.md)), pushes the Wayland env into the D-Bus activation environment, starts `hyprland-session.service` (see [Session lifecycle](#session-lifecycle) below), sets the cursor theme, runs `link-steam-icons.sh`, and runs any private autostart commands. Declares the `hyprland.shutdown` teardown handler |
| `hypr/modules/monitors.lua` | Output, resolution, position, scale — hardcoded per machine, see [INSTALLATION.md](INSTALLATION.md#9-fix-personal-paths) |
| `hypr/modules/input.lua` | Keyboard layout and per-device config |
| `hypr/modules/environment.lua` | Wayland/Qt/Electron/AMD env vars, plus `CursorTheme`/`GTKTheme` |
| `hypr/modules/decoration.lua` | Gaps, rounding, blur, shadows; hardcoded border colors here are the cold-start fallback before any theming has run — kept equal to `hypr/scripts/dynamic-colors.static.sh`'s values on purpose |
| `hypr/modules/layout.lua` | dwindle/master/scrolling tuning; `scrolling` is the active default |
| `hypr/modules/animations.lua` | Named bezier curves and springs — "流水 · Ryūsui Motion" |
| `hypr/modules/windowrules.lua` | Per-app float/blur/alpha/animation rules, layer rules, workspace rules |
| `hypr/modules/misc.lua` | Miscellaneous settings, including disabling Hyprland's random wallpaper/logo |
| `hypr/modules/private.lua` *(optional, gitignored)* | Personal programs/autostart/keybinds — see `private.example.lua` for the template. Loaded via `pcall(require, "modules.private")` everywhere it's used, so its absence is harmless |

Four more things live under `hypr/` without being Lua modules:

| Path | Purpose |
|---|---|
| `hypr/hypridle.conf` / `hypr/hypridle-focus.conf` | Idle/lock timeouts. The first is what `hypridle.service` runs (5 min lock / 10 min DPMS off); the second is the longer-timeout variant (30 min / 60 min) that `desktop-mode.sh` launches as a raw process in `focus` mode |
| `hypr/infinite_desktop/` | The Python side of Infinite Desktop — `infinite_desktop_core.py` (the daemon, run by `infinite-desktop.service`), `hypr_ipc.py` (the shared Hyprland-0.55+ `hyprctl dispatch 'hl.dsp.*'` compatibility layer both it and the keybind scripts import), and the five one-shot scripts bound in `keybinds.lua` |
| `hypr/scripts/` | Maintenance and orchestration — see [Scripts that write other files](#scripts-that-write-other-files) below |
| `hypr/plugins/` | Configuration for the two external Hyprland plugins — `hyprglass.lua` and `dym-cursor.lua`. Not modules, and not loaded with them: `hyprland.lua` requires these last, each behind a guard. The plugins themselves are third-party software installed with `hyprpm`, not code in this repo — see [PLUGINS.md](PLUGINS.md) |

**Hot-reloading:** `hyprctl reload` is unreliable for anything the Lua layer parsed. The only mechanism that reliably re-applies Lua-driven config at runtime is `hyprctl eval '<lua expression>'` — this is how the dynamic color pipeline pushes new border colors into a running session without a full relogin (see [THEMING.md](THEMING.md)). Only two lifecycle events exist: `"hyprland.start"` and `"hyprland.shutdown"` — there is no `"hyprland.exit"`.

---

## Session lifecycle

Every daemon in this rice is a real `systemd --user` unit, not a loose background process. Hyprland's Lua layer only has to trigger **one** thing; systemd owns the rest.

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
├──▶ awww.service                ├──▶ polkit-agent.service
├──▶ wallpaper.service (oneshot — restores the last wallpaper, kicks matugen)
└──▶ kb-layout-notify.service

+ timers.target → updates-check.timer, thumbs-refresh.timer,
                  healthcheck-notify.timer, dotbackup-remind.timer

hl.on("hyprland.shutdown") → systemctl --user stop graphical-session.target
      → every unit above (PartOf=graphical-session.target) stops in cascade
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

It has **no `[Install]` section** on purpose — it's not meant to be `enable`d, only started directly by Hyprland at `hyprland.start`. `graphical-session.target` refuses to be started manually (`RefuseManualStart=yes`, a systemd default); it can only be pulled up by something that `Wants=` it, which is exactly what this service does.

Every daemon unit declares `PartOf=graphical-session.target` — a **lifecycle** relation (stop the target, everything with `PartOf=` stops too), not a start trigger. The actual start trigger is each unit's own `[Install] WantedBy=graphical-session.target`, which only takes effect once `systemctl --user enable` has been run on it. Copying unit files into `~/.config/systemd/user/` is not enough by itself — `is-enabled` says `disabled` until you do.

**Why a `.service` for a compositor daemon at all?** Restart-on-crash (`Restart=on-failure`), a real `journalctl --user -u <unit>` log instead of output vanishing, and one predictable teardown path — instead of "reload Waybar" meaning a manual `pkill` and relaunch.

**Timers** (also need `enable --now`):

| Timer | Runs | Why |
|---|---|---|
| `updates-check.timer` | Every 30 min | Refreshes the pacman+AUR update count in the background, instead of Waybar's own polling triggering the (slow) check itself |
| `thumbs-refresh.timer` | Daily | Pre-generates wallpaper thumbnails so the picker never has to generate them on open |
| `healthcheck-notify.timer` | Daily | Silent unless it finds something — orphan packages, failed services, low disk space |
| `dotbackup-remind.timer` | Weekly | Only meaningful if you maintain your own fork the way this repo's author does — see [`dotbackup`](#dotbackup--repo-sync) below |

**No dedicated `hyprland-session.target`.** This was considered and deliberately not built: `hyprland-session.service` bootstrapping the native `graphical-session.target` is the standard pattern non-DE-integrated Wayland compositors use, it already comes with `Requires=basic.target` (sockets, D-Bus, etc.) for free, and every `xdg-desktop-portal-*`/`gvfs-*` unit the desktop portals need is already `PartOf=` the same target. A second target would add a layer without solving anything the native one doesn't already handle.

---

## Runtime — apps talking to each other

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
                     │  SUPER + W        SUPER + SHIFT + /        SUPER + F4 / F5
                     ▼                          ▼                          ▼
          wallpaper_launcher.sh        web_launcher.sh          kitasan menu / dashboard
                     │                 (category → page          (Rofi frontend for health,
        ┌────────────┴─────┐             → $BROWSER)              clean, update, theme,
        ▼                  ▼                                       mode, and service mgmt)
 apply-wallpaper.sh   matugen_reload.sh                     (only runs if the
 (mpvpaper / awww)          │                                  matugen sentinel is ON)
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
   cursor-zone.py           ──  Python, owned by Waybar itself (custom/zone),
                                 talks to Hyprland's control socket directly
                                 and rewrites waybar/zone.css — see below
```

Every generated color file has a `*.static.*` counterpart that's the source of truth when dynamic theming is off — see [THEMING.md](THEMING.md) for the full surface-by-surface breakdown.

---

## Waybar — three islands and the cursor zones

The bar is split into three CSS boxes that map 1:1 onto `modules-left` / `modules-center` / `modules-right` in `waybar/config.jsonc`, and the split is by *purpose*, not by taste:

| Island | Contents | Behaviour |
|---|---|---|
| left | `custom/playerctl`, `custom/playerlabel`, `pulseaudio/slider`, `custom/zone` | hidden at rest |
| center | `hyprland/window`, `hyprland/workspaces`, `clock`, `pulseaudio`, `privacy`, `custom/notification`, `idle_inhibitor`, `tray`, `custom/updates` | **always visible** |
| right | `cpu`, `memory`, `temperature`, `custom/gpu`, `disk`, `power-profiles-daemon`, `custom/bluetooth`, `network`, `custom/power` | hidden at rest |

The rule behind the split is "control vs. state": anything you *use* may hide in a side island; anything you need to *notice* (notifications, updates, privacy indicators, tray) stays in the permanent centre.

**How the reveal works.** `waybar/scripts/cursor-zone.py` is launched by Waybar itself as the `exec` of `custom/zone` — a module that prints nothing and exists purely so Waybar owns the watcher's lifecycle (it starts and dies with the bar; nothing in Hyprland or systemd starts it). The script:

1. Talks straight to Hyprland's **control** socket (`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock`) instead of forking `hyprctl` — it polls `j/cursorpos` about 8×/s, which as `hyprctl` would be ~480 processes a minute.
2. Divides the top 60 px band of each monitor into thirds, in *layout* coordinates (it divides by `scale` and swaps width/height on a 90°/270° `transform`, and re-reads monitor geometry every 30 s so hotplugging a screen doesn't misplace the zones).
3. Writes `waybar/zone.css` — and only when the content actually changes, in place (no temp+rename, which would pull the file out from under Waybar's watcher).

`config.jsonc` sets `reload_style_on_change: true`, and Waybar watches `style.css` **and every file it `@import`s** — so rewriting `zone.css` restyles the bar without restarting or rebuilding it.

**Where each half of the animation lives:** the resting (hidden) state and the *exit* choreography are fixed in `waybar/style.css` (section "ZONAS"); the *entry* choreography is what `cursor-zone.py` generates. Entry rules are prefixed `window#waybar` so they win on specificity regardless of `@import` order. The cascade uses numeric `:nth-child()` on the left and `:nth-last-child()` on the right, so it always runs "from the edge the cursor came in through, inwards" — and moving a module between islands in `config.jsonc` needs no CSS change.

> `waybar/zone.css` **is** versioned even though it's generated, unlike the matugen color files: `style.css` `@import`s it unconditionally, so a fresh clone needs the file to exist. It's committed in its resting ("no zone") state.
>
> To turn the whole thing off: delete the "ZONAS" section of `style.css`, the `@import "zone.css"` line, and the `custom/zone` module from `config.jsonc`. Nothing else depends on it.

**Other Waybar-specific machinery**, all following the same "don't poll something expensive from the bar" rule:

| Script | Module | Why it exists |
|---|---|---|
| `updates.sh` | `custom/updates` (`interval: once`, `signal: 8`) | The real pacman+AUR check runs from `updates-check.timer`, never from the bar's render cycle; the module just reads the cache and is poked with `pkill -RTMIN+8 waybar`. Also serves `--list` (right click) and `--plain` |
| `gpu.sh` | `custom/gpu` | amdgpu usage/temp/power/VRAM from sysfs with zero subprocesses; finds the card by `gpu_busy_percent` rather than hardcoding `card1` |
| `bluetooth.sh` | `custom/bluetooth` (`signal: 9`) | Replaces the native `bluetooth` module, which didn't redraw on state changes and offered no way to force a refresh. `--toggle` powers the adapter (right click) |
| `notifications.sh` | `custom/notification` | Long-lived `swaync-client -swb` subscription, wrapped to add a count, a real tooltip, and a class array so "DND" and "unread" can stack |
| `playerctl-watch.sh` + `playerctl-read.sh` | `custom/playerctl`, `custom/playerlabel` | One `playerctl -F` process (a systemd unit) writes an atomic JSON cache; both modules `tail -F` it instead of each spawning their own watcher |

`waybar/scripts/launch.sh` and `swaync/scripts/launch.sh` are **legacy**: both were superseded by `waybar.service` / `swaync.service`, nothing in the rice calls them any more (`SUPER + SHIFT + R` is a `systemctl --user restart`), and they're kept only as manual debugging fallbacks outside systemd.

---

## Rofi wallpaper picker

A two-level picker built entirely as native Rofi script mode, tied to `SUPER + W`:

```text
SUPER + W
      ↓
wallpaper_launcher.sh               ← entry point (called from keybind)
      ↓
rofi (wallpaper-type-select.rasi)   ← level 0: choose type
  │   Kill video wallpaper   (only shown while mpvpaper is running)
  │   Video
  │   Imagen
      ↓ (selection written to ${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next)
rofi (wallpaper-picker.rasi)        ← level 1: thumbnail grid
  │   [thumb] [thumb] [thumb] ...
      ↓
applies wallpaper + matugen_reload
```

- `rofi/scripts/wallpaper_launcher.sh` — entry point. Runs the type selector, waits for it to close, reads the chosen directory from the runtime-dir state file, then opens the grid picker with the correct theme. Sequential, blocking Rofi instances — that's what makes the two-level flow reliable.
- `rofi/scripts/wallpaper_rofi.sh` — script-mode modi for the type selector. It also offers **"Kill video wallpaper"**, but only while `mpvpaper` is actually running: that entry kills the video layer and leaves whatever static image `awww` is holding underneath untouched. Before handing off to level 1 it re-triggers thumbnail generation, but only if something under either wallpaper directory is newer than the `.last-scan` marker.
- `rofi/scripts/wallpaper_grid.sh` — script-mode modi for the thumbnail grid; applies the wallpaper and calls `matugen_reload.sh` on selection. Display names normalise `_` and `-` to spaces, so two files that would collide get disambiguated with their raw filename in parentheses.
- `rofi/scripts/generate-thumbs.sh` — generates thumbnails in the background (ImageMagick `convert` for images, `ffmpegthumbnailer` for video) into `~/.cache/rofi-wallpapers/thumbs`; never blocks the menu. It's incremental (mtime-compared, so a replaced wallpaper with the same name does get a new thumb), holds a `flock` so an impatient reopen can't start a second full scan on top of the first, and prunes thumbnails whose source wallpaper is gone. Also runs daily from `thumbs-refresh.timer`.

Applying a wallpaper always goes through **`hypr/scripts/apply-wallpaper.sh`**, the single shared entry point called by both the picker and `wallpaper.service`'s restore-on-start. It also:
- persists the chosen path to `~/.config/hypr/.current-wallpaper` (gitignored), so the next session restores it instead of the hardcoded default;
- regenerates `hyprlock/wallpapers/current.png` from that same wallpaper, so the lock screen background always matches — independent of whether dynamic theming is on.

> ⚠️ The keybind must call `wallpaper_launcher.sh`, not `wallpaper_rofi.sh` directly — pointing it at the wrong script opens only the type selector and nothing happens after you choose.

---

## Rofi web hub

A two-level static launcher for frequently-used web pages, tied to `SUPER + SHIFT + /`:

```text
SUPER + SHIFT + /
      ↓
web_launcher.sh                ← entry point (called from keybind)
      ↓
rofi (web-hub.rasi)            ← level 0: category
  │   Linux · Development · AI · Comunications · Documentation
  │   · Rice · General · Search        (whatever websites.conf declares)
      ↓ (chosen category printed on stdout)
rofi (web-hub.rasi)            ← level 1: page
  │   Arch Wiki · CachyOS Wiki · Arch Packages · ...
      ↓ (chosen URL printed on stdout)
$BROWSER opens the URL
```

- `rofi/scripts/web_launcher.sh` — entry point. Toggles an already-open picker closed (same rule as `wallpaper_launcher.sh`), validates rofi/data-file/browser are all available, then runs the category and page pickers as two blocking, sequential `rofi -dmenu` calls. Each level just prints its pick on stdout — no `${XDG_RUNTIME_DIR:-/tmp}` handoff file is needed here, unlike the wallpaper picker, because neither level needs rofi script mode (no thumbnails to render). Pressing ESC at either level means empty output, which the launcher treats as "stop, open nothing" — no orphaned rofi process, no browser launch.
- `rofi/scripts/web_category.sh` — lists the `[Category]` headers from `websites.conf`.
- `rofi/scripts/web_picker.sh <category>` — lists that category's pages and resolves the pick back to its URL.
- `rofi/scripts/web_common.sh` — shared, non-executable parser for `websites.conf`, sourced by all three scripts above so the file format is handled in exactly one place.

**Data** lives in `rofi/websites.conf` — plain `[Category]` sections, one `Name | URL` per line, `#` comments allowed. Adding a page is one line; adding a category is one new `[Header]`. No script changes needed either way, and the format is documented in the file's own header comment.

**Browser resolution** — `rofi/scripts/web_launcher.sh` never hardcodes a browser. It resolves one, in order: `$BROWSER` (exported from `hypr/modules/programs.lua` via `hl.env("BROWSER", Programs.browser)`, so `Programs.browser` stays the single source of truth); failing that, `browser = "..."` parsed straight out of `programs.lua` (covers running the script before a Hyprland reload, or outside Hyprland entirely); failing that, `xdg-open`. The chosen browser launches detached (`nohup ... & disown`), matching the repo's background-launch idiom used elsewhere in `rofi/scripts/`.

> ⚠️ The keybind must call `web_launcher.sh`, not `web_category.sh` or `web_picker.sh` directly — those two are only meant to be invoked by the launcher, and calling them standalone skips the rofi/browser validation and the toggle-close behavior.

---

## `kitasan` — unified CLI

Before this existed, `healthcheck`, `quickcache`, `cleantrash`, and `sysupdate` were four separate Fish functions to remember by name. `kitasan` (`fish/functions/kitasan.fish`) wraps all of them plus theming/mode/dashboard tooling, with Fish completions (`fish/completions/kitasan.fish`) for every subcommand:

```text
kitasan health           → healthcheck
kitasan clean            → quickcache (fast, no sudo)
kitasan clean --deep     → cleantrash (orphans + pacman cache, needs sudo)
kitasan update           → sysupdate
kitasan theme [scheme]   → visual profile picker — Rofi if no argument, direct if you pass one
kitasan wall             → wallpaper picker over fzf, for when you don't want Rofi
kitasan mode [profile]   → normal / focus / gaming / cinema — see below
kitasan doctor           → template parity + keybinds drift + failed services + orphans, read-only
kitasan dashboard        → same panel as SUPER + F5, launched from a terminal
kitasan diskbackup       → second-disk mirror — see below; hidden if not installed
kitasan menu             → all of the above, picked from Rofi (same as SUPER + F4)
```

**Desktop modes** (`kitasan mode`) bundle DND, blur/animations, idle timeout, and power profile into one live-applied state, each via the mechanism that actually supports it — `hyprctl eval` for blur/animations (same one used for dynamic border colors), `swaync-client -dn/-df` for DND, and `systemctl --user stop/start hypridle.service` (or a raw `hypridle -c` process with longer timeouts) for idle behavior:

| Mode | DND | Blur/anim. | Idle | Waybar | Power profile |
|---|---|---|---|---|---|
| `normal` | off | on | `hypridle.service` (5 / 10 min) | shown | `balanced` |
| `focus` | on | on | service stopped, raw `hypridle -c hypridle-focus.conf` (30 / 60 min) | shown | `balanced` |
| `gaming` | on | **off** | stopped entirely | shown | `performance` |
| `cinema` | on | on | stopped entirely | **hidden** | `balanced` |

The active mode is persisted to `~/.cache/kitasan-desktop-mode`, which is what `desktop-mode.sh status` reads and what `rofi/scripts/mode.sh` marks as `(Current)`. The power profile step is skipped silently if `powerprofilesctl` isn't installed.

Modes don't persist across a relogin on purpose — `hyprland.start` re-runs the Lua modules fresh and restarts `hypridle.service`/`waybar.service`, so you never boot back into `gaming` by accident.

---

## Rofi quick actions

Beyond the launcher and wallpaper picker, `rofi/scripts/` has a handful of small, single-purpose tools — each a plain dmenu script over a CLI tool that was already a dependency, no new GUI toolkit pulled in. All of them reuse `rofi/clipboard.rasi` as their theme rather than each shipping its own; the one exception is `power.sh`, which uses `rofi/power-menu.rasi` (a theme laid out for exactly five rows).

| Script | Keybind / trigger | What it does |
|---|---|---|
| `power.sh` | `ALT + ESCAPE` | Lock / suspend / logout / reboot / shutdown — reuses `wlogout/scripts/confirm-then.sh` for the destructive ones and `suspend.sh` for the lock-before-suspend poll. Five entries, not six: Hibernate stays in the full Wlogout menu |
| `mpris.sh` | Waybar `custom/playerctl` right-click | Pick which MPRIS player to control, then Play/Pause/Next/Previous/Stop — the `XF86Audio*` keybinds call bare `playerctl`, which can't target a specific player |
| `audio.sh` | Waybar `pulseaudio` left-click | Lists sinks/sources by parsing `wpctl status`, sets the chosen one as default |
| `wifi.sh` | `SUPER + F6`, Waybar `network` left-click | Lists networks via `nmcli`, connects, prompts for a password only when nmcli says one is required |
| `bluetooth.sh` | `SUPER + F7`, Waybar `custom/bluetooth` left-click | Toggle adapter power, connect/disconnect paired devices, or start an active scan to pair something new — all via `bluetoothctl` |
| `theme.sh` | `SUPER + ALT + W` | Pick one of matugen's 9 color schemes, or the static baseline |
| `systemd.sh` | `SUPER + F3` | Lists `systemd --user` units (failed first), start/stop/restart, or `journalctl -f` in a new terminal |
| `mode.sh` | via `kitasan mode` / `kitasan menu` | Rofi frontend for the desktop modes above; marks the current one |
| `dashboard.sh` | `SUPER + F5`, `kitasan dashboard` | Pending updates, failed services, CPU/GPU temps, disk usage, current MPRIS track, last dotfiles backup. It recomputes nothing: it reads the same caches `updates.sh` and `playerctl-watch.sh` already write, and calls `gpu.sh` for the GPU row |
| `window-switcher.sh` | `ALT + TAB` | Window list with minimize/restore — picking the focused window parks it on `special:minimized`, picking a parked one brings it back. Row identity travels in `$ROFI_INFO`, not in the visible label |

Most of these close an already-open Rofi instead of stacking a second window (`pgrep -x rofi && pkill -x rofi`) — the same toggle rule the keybind commands in `programs.lua` apply.

---

## Cava — audio visualizer

`cava/` has three parts: `config` (pipewire method, noncurses output, 60fps mono), `themes/` (three swappable palettes — `agua`, `solarized_dark`, `tricolor`, applied by copying one into the `[color]` block of `config`), and `shaders/` (six GLSL shaders for cava's visual mode, requiring cava built with OpenGL support — `ngl` method). Cava has no autostart or systemd unit and isn't wired into Waybar, Kitty, or Hyprland — it's launched manually (`cava`) whenever wanted.

---

## Scripts that write other files

Nothing in this rice is generated at build time — but several things *are* written at runtime, and knowing which file has an owner is the difference between editing the source and editing something that gets clobbered on the next wallpaper change.

| Writer | Writes | When |
|---|---|---|
| `matugen` (driven by `rofi/scripts/matugen_reload.sh`) | the 14 per-app color files listed in [THEMING.md](THEMING.md) | on every wallpaper apply, while the sentinel is on |
| `hypr/scripts/apply-static-colors.sh` | those same 14 files, from their `*.static.*` counterparts; plus a bootstrap `hyprlock/wallpapers/current.png` | fresh-clone bootstrap, and every time dynamic theming is switched off |
| `hypr/scripts/apply-wallpaper.sh` | `hypr/.current-wallpaper`, `hyprlock/wallpapers/current.png` | every wallpaper apply, from any entry point |
| `waybar/scripts/cursor-zone.py` | `waybar/zone.css` | whenever the cursor crosses into a different third of the top band |
| `rofi/scripts/generate-thumbs.sh` | `~/.cache/rofi-wallpapers/thumbs/` | picker open (if stale) and daily via timer |
| `rofi/scripts/theme.sh`, `kitasan theme` | `~/.config/matugen/scheme`, `~/.config/matugen/enabled` | when you pick a visual profile. Both are local state and both are gitignored — see [THEMING.md](THEMING.md#two-tracks-static-baseline-vs-matugen) |
| `rofi/scripts/matugen_toggle.sh` | `matugen/enabled` | `SUPER + SHIFT + W` |
| `hypr/scripts/desktop-mode.sh` | `~/.cache/kitasan-desktop-mode` | every mode switch |
| `hypr/scripts/generate-keybinds-doc.sh --write` (via `checkkeybinds --write`) | `~/Documents/KEYBINDS.txt` | manually, after editing `keybinds.lua` |
| `waybar/scripts/updates.sh --force`, `playerctl-watch.sh` | caches under `$XDG_RUNTIME_DIR` | timer / MPRIS events |

Three read-only checkers exist alongside them, all surfaced through `kitasan doctor`. None writes anything, and none blocks anything — they report and exit with the number of problems found.

| Checker | What it compares |
|---|---|
| `check-template-parity.sh` | Every matugen template against its `*.static.*` mirror: both must declare the same set of identifiers (11 pairs). Looks *inside* the color files |
| `check-config-drift.sh` | The wiring *between* files — see below |
| `generate-keybinds-doc.sh --check` | `KEYBINDS.txt` against `keybinds.lua` |

**Why `check-config-drift.sh` exists.** `dotbackup` syncs `~/.config` **into** the repo, so config changes arrive as `dotfiles: backup <date>` commits with no stated intent, and nothing compares the pieces against each other. A half-finished migration can therefore sit broken for days — which is exactly what happened to the GTK layer in August 2026. It runs five checks:

1. Every `@import` in `gtk-3.0/gtk.css` / `gtk-4.0/gtk.css` resolves, and neither file has been replaced by an `nwg-look` symlink.
2. `CursorTheme` and `GTKTheme` from `environment.lua` name directories that actually exist (both lookups are case-sensitive and fail silently).
3. The five places that hardcode the icon theme agree — the two `settings.ini` files plus `qt5ct.conf`, `qt6ct.conf` and `rofi/window-switcher.rasi`.
4. Every file matugen generates has something that loads it. A generated file with no reader is how the GTK pipeline went inert.
5. No broken symlinks anywhere in the config dirs this repo owns.

Its own failure modes were verified against a fixture tree rather than assumed — `KITASAN_CONFIG_DIR` overrides the base path for exactly that purpose. Two limitations are documented in the script header: check 4 matches by basename, so the three surfaces that each generate a `colors.css` mask one another, and checks 2 and 3 read the real `/usr/share` and `~/.icons` regardless of that override.

---

## Unused / legacy pieces still in the tree

Kept deliberately rather than deleted, but nothing calls them — worth knowing before you go looking for what starts them:

| File | Status |
|---|---|
| `waybar/scripts/launch.sh`, `swaync/scripts/launch.sh` | Superseded by `waybar.service` / `swaync.service`. Manual debugging fallbacks only |
| `rofi/scripts/wallpaper_rofi.sh`, `web_category.sh`, `web_picker.sh` | Not orphaned, but not entry points either — only their launchers should ever call them |

> `hypr/scripts/kb-layout-notify.py` used to be listed here as having no caller. It has one now: `systemd/user/kb-layout-notify.service` (`WantedBy=graphical-session.target`, `Restart=always`) runs it as a session daemon, so it needs `enable --now` like every other unit — see [INSTALLATION.md § 6](INSTALLATION.md#6-enable-the-systemd-units). One thing in it is still stale: its docstring says three keyboards are declared in `input.lua` and that a single `Alt+Shift` therefore fires three identical `activelayout` events. `input.lua` currently declares **one** keyboard and one mouse, so the dedup-by-layout-name logic is now belt-and-braces rather than load-bearing.

---

## Fish functions

Custom functions in `fish/functions/`, beyond aliases and external-tool integrations:

| Function | What it does |
|---|---|
| `kitasan` | Unified CLI — see above |
| `sysupdate` | Updates pacman and AUR in one pass (`yay`, falling back to `paru`) |
| `quickcache` / `cleantrash` | Cache/orphan cleanup — fast no-sudo pass vs. deep sudo pass |
| `checktrash` | Read-only counterpart of `cleantrash`: reports orphans, cache, journal and trash sizes without deleting anything |
| `checkerrors` | Diagnoses failed services, journalctl errors, recent coredumps — read-only |
| `healthcheck` | One-screen system overview: kernel, memory/zram, updates, orphans, `.pacnew`/`.pacsave`, failed services, boot errors, disk, network, temperatures |
| `keybinds` | Interactive `KEYBINDS.txt` viewer, vim-style navigation, floats and centers the terminal while open. Reads `~/Documents/KEYBINDS.txt`, falling back to `~/Projects/dotfiles/KEYBINDS.txt` |
| `checkkeybinds` | `KEYBINDS.txt` is generated from `keybinds.lua`, not hand-maintained — bare, checks if a regen is needed; `--write` regenerates it for real |
| `ec` | "Edit config" — opens a config directory in the editor by name (`ec hypr`, `ec waybar`, …), with completions. The old `echypr`/`ecwaybar`/… aliases still exist as wrappers in `conf.d/tools.fish`; the name list has to be kept in sync in both places, on purpose |
| `fastfetch` *(the function in `config.fish`, not the binary)* | Weighted shuffle-bag picker across the eleven presets in `fastfetch/*.jsonc`, with the bag state in `fastfetch/.fastfetch_bag` |

Three files in `fish/conf.d/` are loaded on every shell: `fzf.fish` (fzf integration and shared `FZF_*_OPTS`), `tools.fish` (aliases, all behind a `status is-interactive` guard so scripts don't inherit them), and `report-ui.fish` — the shared `_rui_*` box-drawing helpers that `healthcheck`, `checkerrors`, `checktrash`, `cleantrash`, `quickcache`, `sysupdate` and `kitasan doctor` all render with. Those helpers use **ANSI color names, never hex**, so the reports follow Kitty's palette — which matugen already regenerates with the wallpaper — instead of freezing their own. `theme-goldship.fish` is the fourth file there and is generated (gitignored).

> `KEYBINDS.txt` is generated — edit the comment above the relevant `hl.bind()` in `keybinds.lua` and run `checkkeybinds --write`. Manual edits to `KEYBINDS.txt` itself get silently overwritten on the next regen.

---

## `dotbackup` — repo sync

This repo is not deployed by an installer — it's the *destination* of a one-way sync. `~/.local/bin/dotbackup` (a standalone fish script, not part of this repo, not distributed with it) does the actual work: security checks (correct branch, correct remote, no pending merge/rebase) → local snapshot → sync an explicit directory/file allowlist from `~/.config` into this repo → redaction of private references → `gitleaks` (blocking) → `shellcheck` (informational) → commit and push, each with its own confirmation prompt.

**The direction matters:** changes flow `~/.config` → this repo, never the reverse. Editing a file in this repo directly does nothing to the live system until it's cloned or copied over by hand; conversely, editing the live `~/.config` does nothing to this repo until `dotbackup` runs. `hypr/scripts/dotbackup-remind.sh` (read-only, safe to enable) just diffs the two and notifies if they've drifted — it never syncs anything itself.

**What the allowlist covers.** `dotbackup` syncs whole directories for `cava fastfetch fish hypr hyprlock kitty matugen rofi swaync waybar wlogout`, plus an explicit file list (the two Starship configs and every `systemd/user/` unit). `gtk-3.0/`, `gtk-4.0/`, `qt5ct/` and `qt6ct/` are **not** directory entries — only specific files from them reach the repo. `dotbackup-remind.sh` deliberately keeps a second copy of those two lists (parsing the fish source would be more fragile than maintaining two short lists), and it excludes the one line `dotbackup` redacts from `waybar/config.jsonc` on both sides so a freshly-synced tree doesn't report permanent drift.

If you fork this repo, note that `dotbackup` itself isn't part of what you get — you'd need your own equivalent, or just `cp -r` your configs over by hand when you want to update the repo.

---

## `diskbackup` — second-disk mirror

Same non-distribution as `dotbackup`: `~/.local/bin/diskbackup` (also a standalone fish script) is not part of this repo. It mirrors things `dotbackup` deliberately leaves out — personal git repos with their own remote (this author's music daemon, a game project, its AUR PKGBUILD), a handful of manually-installed GTK/icon themes, and the files that are gitignored on purpose (`hypr/modules/private.lua` and similar — see the theming/private-config notes above) — onto a second local disk. It's defense in depth, not a replacement for GitHub: same one-way-sync philosophy as `dotbackup`, just pointed at `/mnt/storage` instead of a git remote. `diskbackup --check` does the same comparison without writing anything, which `kitasan doctor` uses to report whether the mirror is stale.

`kitasan diskbackup` is wired in as a convenience, but every call site checks `test -x ~/.local/bin/diskbackup` first and degrades gracefully if it's missing — same reasoning as the `pcall` guard around `private.lua`: this repo (and `kitasan.fish` specifically) is meant to still work for anyone who clones it, even though this one script isn't part of what they get. If you fork this repo, `kitasan diskbackup` will just tell you it's not installed rather than erroring.
