# Architecture

How the pieces fit together: the Lua config system, the systemd session lifecycle, the Rofi wallpaper picker, and how changes get backed up to this repo in the first place.

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
```

`environment` loads first because later modules depend on the globals it exports. `programs` loads before `keybinds`, which reads the global `Programs` table. `autostart` loads last.

> ⚠️ This is **not the classic `hyprland.conf` format**. It's Hyprland's native Lua config API (`hl.*`) — keybinds use `hl.bind()`, dispatches use `hl.dsp.*`. You need a Hyprland build with Lua config support for this to load at all; official API stubs live at `/usr/share/hypr/stubs/hl.meta.lua`, and `hypr/.vscode/settings.json` (deliberately published, unlike the rest of `.vscode/`) wires the Lua LSP against them.

**Globals as the cross-module contract:**

| Global | Set in | Read by |
|---|---|---|
| `CursorTheme`, `GTKTheme` | `environment.lua` | `autostart.lua` (`hyprctl setcursor`), `hypr/scripts/apply-static-colors.sh` (GTK4 theme symlink) |
| `Programs` | `programs.lua` | `keybinds.lua`, throughout |

**Key files:**

| File | Purpose |
|---|---|
| `hypr/modules/programs.lua` | Terminal, file manager, browser, and launcher commands — the global `Programs` table |
| `hypr/modules/keybinds.lua` | All keyboard shortcuts; references `Programs.*` and `home` |
| `hypr/modules/autostart.lua` | Deliberately thin — starts `hyprland-session.service` (see [Session lifecycle](#session-lifecycle) below), sets the cursor theme, runs `link-steam-icons.sh`, and runs any private autostart commands. Declares the `hyprland.shutdown` teardown handler |
| `hypr/modules/monitors.lua` | Output, resolution, position, scale — hardcoded per machine, see [INSTALLATION.md](INSTALLATION.md#9-fix-personal-paths) |
| `hypr/modules/input.lua` | Keyboard layout and per-device config |
| `hypr/modules/environment.lua` | Wayland/Qt/Electron/AMD env vars, plus `CursorTheme`/`GTKTheme` |
| `hypr/modules/decoration.lua` | Gaps, rounding, blur, shadows; hardcoded border colors here are the cold-start fallback before any theming has run — kept equal to `hypr/scripts/dynamic-colors.static.sh`'s values on purpose |
| `hypr/modules/layout.lua` | dwindle/master/scrolling tuning; `scrolling` is the active default |
| `hypr/modules/animations.lua` | Named bezier curves and springs — "流水 · Ryūsui Motion" |
| `hypr/modules/windowrules.lua` | Per-app float/blur/alpha/animation rules, layer rules, workspace rules |
| `hypr/modules/misc.lua` | Miscellaneous settings, including disabling Hyprland's random wallpaper/logo |
| `hypr/modules/private.lua` *(optional, gitignored)* | Personal programs/autostart/keybinds — see `private.example.lua` for the template. Loaded via `pcall(require, "modules.private")` everywhere it's used, so its absence is harmless |

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
├──▶ awww.service                └──▶ polkit-agent.service
└──▶ wallpaper.service (oneshot — restores the last wallpaper, kicks matugen)

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

Every generated color file has a `*.static.*` counterpart that's the source of truth when dynamic theming is off — see [THEMING.md](THEMING.md) for the full surface-by-surface breakdown.

---

## Rofi wallpaper picker

A two-level picker built entirely as native Rofi script mode, tied to `SUPER + W`:

```text
SUPER + W
      ↓
wallpaper_launcher.sh               ← entry point (called from keybind)
      ↓
rofi (wallpaper-type-select.rasi)   ← level 0: choose type
  │   Video
  │   Image
      ↓ (selection written to ${XDG_RUNTIME_DIR:-/tmp}/rofi-wallpaper-next)
rofi (wallpaper-picker.rasi)        ← level 1: thumbnail grid
  │   [thumb] [thumb] [thumb] ...
      ↓
applies wallpaper + matugen_reload
```

- `rofi/scripts/wallpaper_launcher.sh` — entry point. Runs the type selector, waits for it to close, reads the chosen directory from the runtime-dir state file, then opens the grid picker with the correct theme. Sequential, blocking Rofi instances — that's what makes the two-level flow reliable.
- `rofi/scripts/wallpaper_rofi.sh` — script-mode modi for the type selector.
- `rofi/scripts/wallpaper_grid.sh` — script-mode modi for the thumbnail grid; applies the wallpaper and calls `matugen_reload.sh` on selection.
- `rofi/scripts/generate-thumbs.sh` — generates thumbnails in the background; never blocks the menu.

Applying a wallpaper always goes through **`hypr/scripts/apply-wallpaper.sh`**, the single shared entry point called by both the picker and `wallpaper.service`'s restore-on-start. It also:
- persists the chosen path to `~/.config/hypr/.current-wallpaper` (gitignored), so the next session restores it instead of the hardcoded default;
- regenerates `hyprlock/wallpapers/current.png` from that same wallpaper, so the lock screen background always matches — independent of whether dynamic theming is on.

> ⚠️ The keybind must call `wallpaper_launcher.sh`, not `wallpaper_rofi.sh` directly — pointing it at the wrong script opens only the type selector and nothing happens after you choose.

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
kitasan menu             → all of the above, picked from Rofi (same as SUPER + F4)
```

**Desktop modes** (`kitasan mode`) bundle DND, blur/animations, idle timeout, and power profile into one live-applied state, each via the mechanism that actually supports it — `hyprctl eval` for blur/animations (same one used for dynamic border colors), `swaync-client -dn/-df` for DND, and `systemctl --user stop/start hypridle.service` (or a raw `hypridle -c` process with longer timeouts) for idle behavior:

| Mode | Effect |
|---|---|
| `normal` | Everything as installed |
| `focus` | DND on, idle timeout stretched to 30 min (lock) / 60 min (DPMS off) |
| `gaming` | Blur and animations off, DND on, power profile set to `performance` |
| `cinema` | Waybar hidden, DND on, Hypridle stopped entirely |

Modes don't persist across a relogin on purpose — `hyprland.start` re-runs the Lua modules fresh and restarts `hypridle.service`/`waybar.service`, so you never boot back into `gaming` by accident.

---

## Rofi quick actions

Beyond the launcher and wallpaper picker, `rofi/scripts/` has a handful of small, single-purpose tools — each a plain dmenu script over a CLI tool that was already a dependency, no new GUI toolkit pulled in. All of them reuse `rofi/clipboard.rasi` as their theme rather than each shipping its own.

| Script | Keybind / trigger | What it does |
|---|---|---|
| `power.sh` | `ALT + ESCAPE` | Lock / suspend / logout / reboot / shutdown — reuses `wlogout/scripts/confirm-then.sh` for the destructive ones |
| `mpris.sh` | Waybar `custom/playerctl` right-click | Pick which MPRIS player to control, then Play/Pause/Next/Previous/Stop |
| `audio.sh` | Waybar `pulseaudio` left-click | Lists sinks/sources via `wpctl status`, sets the chosen one as default |
| `wifi.sh` | Waybar `network` left-click | Lists networks via `nmcli`, connects, prompts for password only if needed |
| `bluetooth.sh` | Waybar `bluetooth` left-click | Toggle adapter power, connect/disconnect paired devices via `bluetoothctl` |
| `theme.sh` | `SUPER + ALT + W` | Pick one of matugen's 6 color schemes, or the static baseline |
| `systemd.sh` | `SUPER + F3` | Lists `systemd --user` units (failed first), start/stop/restart, or `journalctl -f` |
| `mode.sh` | via `kitasan mode` / `kitasan menu` | Rofi frontend for the desktop modes above |
| `dashboard.sh` | `SUPER + F5` | Pending updates, failed services, CPU/GPU temps, disk usage, current MPRIS track, last dotfiles backup — each row has a quick action attached |

---

## Cava — audio visualizer

`cava/` has three parts: `config` (pipewire method, noncurses output, 60fps mono), `themes/` (three swappable palettes — `agua`, `solarized_dark`, `tricolor`, applied by copying one into the `[color]` block of `config`), and `shaders/` (six GLSL shaders for cava's visual mode, requiring cava built with OpenGL support — `ngl` method). Cava has no autostart or systemd unit and isn't wired into Waybar, Kitty, or Hyprland — it's launched manually (`cava`) whenever wanted.

---

## Fish functions

Custom functions in `fish/functions/`, beyond aliases and external-tool integrations:

| Function | What it does |
|---|---|
| `kitasan` | Unified CLI — see above |
| `sysupdate` | Updates pacman and AUR (yay) in one pass |
| `quickcache` / `cleantrash` | Cache/orphan cleanup — fast no-sudo pass vs. deep sudo pass |
| `checkerrors` | Diagnoses failed services, journalctl errors, recent coredumps — read-only |
| `healthcheck` | One-screen system overview: kernel, memory/zram, updates, orphans, `.pacnew`/`.pacsave`, failed services, boot errors, disk, network, temperatures |
| `keybinds` | Interactive `KEYBINDS.txt` viewer, vim-style navigation, floats and centers the terminal while open |
| `checkkeybinds` | `KEYBINDS.txt` is generated from `keybinds.lua`, not hand-maintained — bare, checks if a regen is needed; `--write` regenerates it for real |
| `fastfetch` *(the function, not the binary)* | Weighted shuffle-bag preset picker across `fastfetch/config*.jsonc` |

> `KEYBINDS.txt` is generated — edit the comment above the relevant `hl.bind()` in `keybinds.lua` and run `checkkeybinds --write`. Manual edits to `KEYBINDS.txt` itself get silently overwritten on the next regen.

---

## `dotbackup` — repo sync

This repo is not deployed by an installer — it's the *destination* of a one-way sync. `~/.local/bin/dotbackup` (a standalone fish script, not part of this repo, not distributed with it) does the actual work: security checks (correct branch, correct remote, no pending merge/rebase) → local snapshot → sync an explicit directory/file allowlist from `~/.config` into this repo → redaction of private references → `gitleaks` (blocking) → `shellcheck` (informational) → commit and push, each with its own confirmation prompt.

**The direction matters:** changes flow `~/.config` → this repo, never the reverse. Editing a file in this repo directly does nothing to the live system until it's cloned or copied over by hand; conversely, editing the live `~/.config` does nothing to this repo until `dotbackup` runs. `hypr/scripts/dotbackup-remind.sh` (read-only, safe to enable) just diffs the two and notifies if they've drifted — it never syncs anything itself.

If you fork this repo, note that `dotbackup` itself isn't part of what you get — you'd need your own equivalent, or just `cp -r` your configs over by hand when you want to update the repo.
