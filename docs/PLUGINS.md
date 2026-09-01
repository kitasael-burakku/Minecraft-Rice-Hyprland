# Plugins

Two Hyprland compositor plugins are part of this rice's look. **Neither is code from this repository** — both are third-party projects with their own authors, licenses and issue trackers. What this repo contributes is the *configuration* for them: one Lua file each under `hypr/plugins/`.

| Plugin | Upstream | Author / maintainer | License | Configured in |
|---|---|---|---|---|
| **hyprglass** | [hyprnux/hyprglass](https://github.com/hyprnux/hyprglass) | the **hyprnux** organization; the `LICENSE` file is copyright **Jeremy Trufier** (2025) | BSD 3-Clause | `hypr/plugins/hyprglass.lua` |
| **hypr-dynamic-cursors** | [VirtCode/hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors) | **VirtCode** | MIT | `hypr/plugins/dym-cursor.lua` |

> Everything in `hypr/plugins/` is *my* configuration of *their* software. If a plugin misbehaves, crashes Hyprland, or fails to build, that belongs upstream — not in this repo's issues. If you reuse this rice, keep the attribution above.

Neither plugin is required. The session comes up fine without both of them; you lose the glass material and the cursor motion, nothing else. See [Turning a plugin off](#turning-a-plugin-off) below.

---

## How plugins are wired into this rice

```text
hypr/hyprland.lua
   ├─ require("modules.*")        ← 11 modules, the compositor config proper
   └─ require("plugins.hyprglass")     ← plugin config, loaded LAST
      require("plugins.dym-cursor")
```

Three conventions make this work, and they matter more than the individual option values:

**1. Plugins load last.** `hyprland.lua` `require`s the two plugin files after every module, `modules.autostart` included. That ordering is deliberate — see point 3.

**2. Every plugin file opens with a guard.** A plugin's config namespace only exists when its `.so` is actually loaded. Reading `hl.plugin.hyprglass.*` when it isn't gives `attempt to index a nil value`, which aborts the whole Lua config — not just the plugin's own section. So each file starts with an early return:

```lua
if not (hl.plugin and hl.plugin.hyprglass) then
    return
end
```

This is the difference between "no glass this boot" and "no keybinds, no window rules, no monitors this boot". It is not optional. Upstream documents the same pattern for both plugins.

**3. `autostart.lua` runs `hyprpm reload -n` on `hyprland.start`.** hyprpm loads the compiled `.so` files, and loading them makes Hyprland re-parse its config — which is the pass where the guards above finally succeed and the plugin settings actually apply. The call is deliberately **not** run under `sudo`: only `hyprpm add`/`update`/`remove` write to `/var/cache/hyprpm/` (root-owned) and need privileges. `reload` only reads the `.so` files (mode `755`) and talks to `hyprctl`, so it works unprivileged — putting `sudo` there would hang the session start on a password prompt nothing can answer.

**Where the `.so` files live:** `/var/cache/hyprpm/$USER/`, written by hyprpm as root. They are not in this repo and can't be — they're binaries built against the exact Hyprland ABI on your machine.

---

## hyprglass

### What it is

A Hyprland plugin that renders translucent windows as a thick convex glass slab: frosted Gaussian blur, edge refraction, chromatic aberration, a Fresnel edge glow and a specular highlight. Upstream describes it as inspired by Liquid Glass design.

### What it adds to this rice

The whole "Kitasan Glass" name stops being just a palette. Windows that were previously flat translucent rectangles with Hyprland's blur behind them now have a bezel, refract what's behind their edges, and pick up a highlight along the top — the material this rice's colors were always designed for.

It replaces Hyprland's own blur on the windows it touches (see the `manage_window_blur` note below), so this is a substitution, not an extra layer stacked on top.

### Installation

Upstream's recommended route, and the one this rice assumes:

```bash
hyprpm add https://github.com/hyprnux/hyprglass
hyprpm enable hyprglass
```

Upstream also documents two alternatives: a pre-built `hyprglass.so` from the [releases page](https://github.com/hyprnux/hyprglass/releases/latest) (each release targets a specific Hyprland API version — check the release notes match yours), and a manual `make` followed by `hyprctl plugin load $(pwd)/hyprglass.so`. Both are described in the upstream README; this rice doesn't use either.

### Requirements

- A Hyprland build with plugin support, and a plugin binary built against **that exact** Hyprland ABI. `hyprpm` handles this by building from source on your machine.
- **Hyprland shadows must be present in the render pipeline.** The plugin auto-enables them at load time if they're off. Their visual values (range, color) can be zero — only the decoration's presence matters.
- Upstream notes that some Hyprland/hyprutils version combinations fail to build. Specifically documented: Hyprland **0.55.4** headers with hyprutils newer than **0.13.1** break every Hyprland plugin identically (a smart-pointer `operator bool` became explicit after 0.55.4 shipped). That is not a hyprglass bug — see upstream's Troubleshooting section for the workarounds.

### How this rice configures it

`hypr/plugins/hyprglass.lua`, after the guard:

- **Defines one user preset, `liquid`** — via `hg.preset("liquid", { ... })`, with separate `dark` and `light` tables. It's a user preset, not one of upstream's four built-ins (`high_contrast`, `subtle`, `clear`, `glass`); those stay available and untouched.
- **Sets the globals** — `enabled = 1`, `default_theme = "dark"`, `default_preset = "liquid"`, `manage_window_blur = 1`.
- **Leaves layer-surface glass off** (`layers.enabled = 0`). Upstream ships this disabled by default and warns that it hooks `renderLayer`, a private Hyprland internal that can break on compositor updates. Waybar and SwayNC therefore keep their own CSS look rather than becoming glass.
- **Tags two classes of window out of the effect**, using upstream's `hyprglass_disabled` tag:

  | Rule | Match | Why |
  |---|---|---|
  | `hyprglass-off-video` | `class = "^(mpv)$"` | The glass re-samples the background every frame. Over moving video that's sustained GPU cost for an effect that visibly lags behind the picture |
  | `hyprglass-off-fullscreen` | `fullscreen = true` | Nothing behind a fullscreen window to refract. `decoration.lua` already sets `fullscreen_opacity = 1`, so these windows are opaque anyway — the rule makes it explicit and skips the work |

**The tags upstream understands** (all four are usable in `hl.window_rule`, and on the fly via `hyprctl dispatch tagwindow +<tag>`):

| Tag | Effect |
|---|---|
| `hyprglass_disabled` | Force the effect off on this window — wins over `hyprglass_enabled` |
| `hyprglass_enabled` | Force it on, even with the global `enabled` off (whitelist mode) |
| `hyprglass_preset_<name>` | Use a different preset for this window only |
| `hyprglass_theme_light` / `hyprglass_theme_dark` | Override `default_theme` for this window only |

### Things worth knowing before you tune it

- **`manage_window_blur` is on for a reason.** Glass replaces Hyprland's blur on glassed windows, and the plugin sets the `noblur` property on them to make that stick. Without it, Hyprland's `blur:new_optimizations` cache — captured *before* plugin decorations render — hides the glass on windows that aren't moving. That's the "the effect only shows while I'm dragging the window" symptom.
- **The plugin only acts on windows that are actually translucent.** Opaque windows fall out on their own; you don't need a rule for them.
- The two window rules above are the ones this rice wants, not a complete list of what's worth excluding. Anything that redraws constantly is a candidate.

---

## hypr-dynamic-cursors

### What it is

A Hyprland plugin that simulates the cursor as a physical object being dragged across the screen — it can tilt, rotate toward the direction of travel, or stretch with speed. It also implements **shake to find** (magnify the cursor when it's shaken), the way KDE Plasma and macOS do.

Upstream is candid that the project started as a joke and makes no guarantee of future updates; shake-to-find is described there as the one genuinely useful feature, added as an afterthought.

### What it adds to this rice

Motion on the one element that's on screen constantly. `tilt` is subtle enough to read as physics rather than as an effect, and shake-to-find earns its place on a 1920×1080 screen full of translucent windows where a small cursor is genuinely easy to lose.

### Installation

```bash
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors
hyprpm enable dynamic-cursors
```

Note the two names differ: the **repository** is `hypr-dynamic-cursors`, the **plugin** hyprpm enables is `dynamic-cursors`, and this repo's config file is `dym-cursor.lua`. All three refer to the same thing.

Upstream also documents distro packages that manage the plugin better than hyprpm can — **nixpkgs** / a flake for NixOS, and `hyprland-plugin/dynamic-cursors` from the Hyproverlay portage overlay for Gentoo. Neither applies on Arch/CachyOS, which is what this rice targets.

### Requirements

- Hyprland **v0.41.2 or newer**. Upstream's `main` branch generally targets Hyprland's `main` (`-git`).
- **`x86_64` only.** The plugin leans on Hyprland's function-hook API, which only exists on x86_64. It will load on other architectures and simply do nothing useful.
- **Nvidia GPUs get software cursors.** Hyprland draws hardware-cursor buffers on the CPU on Nvidia because of driver limitations, and this plugin would redraw that buffer every frame while the cursor moves. So on Nvidia the plugin forces software cursors — correct behavior, at a small performance cost. This rice runs an AMD RX 7600, so it isn't in that path.
- **Performance**, per upstream: software cursors, no additional cost; hardware cursors, roughly what an animated cursor shape costs whenever the pointer is moving. During shake magnification the compositor temporarily switches to software cursors on every system.

### How this rice configures it

`hypr/plugins/dym-cursor.lua` is upstream's fully-commented default configuration block, kept verbatim (comments included) so the available options stay readable at the point of use, with a guard added on top and these deviations from upstream defaults:

| Option | Upstream default | Here | Effect |
|---|---|---|---|
| `threshold` | `2` | `1` | Reshapes on a smaller angle change — smoother, slightly more expensive for hardware cursors |
| `tilt.limit` | `5000` | `300` | Full tilt is reached at 300 px/s instead of 5000, so normal pointer speed actually tilts |
| `tilt.activation` | `negative_quadratic` | `linear` | Tilt tracks speed proportionally instead of ramping aggressively |
| `tilt.window` | `100` | `120` | Slightly longer speed-averaging window — smoother slow movement, marginally more lag |
| `stretch.limit` | `3000` | `300` | Only matters if you switch `mode` to `stretch` |
| `stretch.activation` | `quadratic` | `linear` | Same — inactive under `mode = "tilt"` |

`mode = "tilt"` (upstream's default) is what's active. `shake` is enabled with upstream's defaults throughout, as is the whole `hyprcursor` block.

**Modes you can switch to** by changing `mode`: `tilt`, `rotate`, `stretch`, or `none` (disables the motion but keeps shake-to-find).

### The hyprcursor caveat

The `hyprcursor` block in the config only does something if **all** of these hold, per upstream:

- `plugin.dynamic_cursors.hyprcursor.enabled` is true (it is, by default)
- `cursor.enable_hyprcursor` is true (Hyprland default)
- you are using a hyprcursor theme, and that theme is **SVG-based**

This rice's `CursorTheme` is `Vimix-white-cursors` (from the `vimix-cursors` package), a classic XCursor theme — **not** a hyprcursor theme. No hyprcursor theme is installed on the reference machine. So the high-resolution magnified shapes that block describes do not currently apply here; magnified cursors fall back to `nearest = 1` pixelated upscaling of the existing bitmap. The block is kept at upstream defaults so that installing an SVG hyprcursor theme later is the only change needed.

### Features present upstream but not used here

Documented so you know they exist, not because anything in this repo wires them:

- **Shape rules** (`hl.plugin.dynamic_cursors.shape_rule { ... }`) — override the mode per cursor shape. Server-side shapes only; most XWayland apps won't honor them.
- **IPC events** (`shake.ipc`) — emits `shakestart` / `shakeupdate` / `shakeend` on Hyprland's event socket. Off by default and noisy; upstream warns it spams the socket during a shake.
- **A magnify dispatcher** — `hl.plugin.dynamic_cursors.dsp_magnify({ duration = 2000, size = 4.0 })`, bindable like any Hyprland dispatcher, to trigger the magnification from a keybind instead of by shaking.

---

## Maintenance

**After every Hyprland update, plugins must be rebuilt.** A plugin compiled against the old ABI will refuse to load, and hyprpm reports the mismatch:

```bash
hyprpm update        # rebuilds every added plugin against the running Hyprland
```

`hyprpm update` writes into `/var/cache/hyprpm/`, so it prompts for `sudo`. This is the one plugin operation that is *not* automated by this rice — `autostart.lua` only runs `hyprpm reload -n`, which loads what's already built.

The guards in `hypr/plugins/*.lua` are what make the in-between state survivable: between a Hyprland update and the next `hyprpm update`, the plugins simply don't load and the rest of the config comes up untouched.

Useful commands:

```bash
hyprpm list          # which repos are added, which plugins are enabled
hyprpm reload -n     # reload the built .so files (-n notifies on success)
hyprpm disable <plugin>   # keep it built, stop loading it
hyprpm remove <url>       # drop the repo and its build cache entirely
```

## Turning a plugin off

Three levels, least to most permanent:

1. **Keep it loaded, stop the effect** — set `enabled = 0` (hyprglass) or `enabled = false` (dynamic-cursors) in its file under `hypr/plugins/`.
2. **Stop loading the config** — comment out the matching `require("plugins.…")` line at the bottom of `hypr/hyprland.lua`. The `.so` still loads; nothing configures it, so it runs on its own defaults.
3. **Stop loading the plugin** — `hyprpm disable hyprglass` / `hyprpm disable dynamic-cursors`, then relogin or `hyprpm reload`. The guards make the config files no-ops, so they can stay where they are.

To be rid of a plugin entirely, `hyprpm remove <repo-url>` and delete its file from `hypr/plugins/` along with its `require` line.

---

## See also

- [ARCHITECTURE.md § Hyprland in Lua](ARCHITECTURE.md#hyprland-in-lua) — the module system these plugin files load into, and why `hyprctl reload` doesn't re-apply Lua-driven config
- [INSTALLATION.md § 11. Hyprland plugins](INSTALLATION.md#11-hyprland-plugins-optional) — where plugin installation sits in the install order
- The upstream READMEs are the authority on every option listed here. This page documents *what this rice does with them*, and is not a substitute for either project's own documentation.
