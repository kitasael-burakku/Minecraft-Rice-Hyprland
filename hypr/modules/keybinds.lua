--  ____  __.            __________.__            .___      
-- |    |/ _|____ ___.__.\______   \__| ____    __| _/______
-- |      <_/ __ <   |  | |    |  _/  |/    \  / __ |/  ___/
-- |    |  \  ___/\___  | |    |   \  |   |  \/ /_/ |\___ \ 
-- |____|__ \___  > ____| |______  /__|___|  /\____ /____  >
--         \/   \/\/             \/        \/      \/    \/ ---------

local mainMod = "SUPER"
local home = os.getenv("HOME") or "/home/kitasa-elburakku"

-- Defensivo: si programs.lua no cargó (orden de require roto, error de
-- sintaxis, etc.) esto evita que TODO este archivo tumbe con un error de
-- "index a nil value" al primer uso de la tabla Programs — en cambio,
-- solo ese bind puntual queda con un comando vacío en vez de matar el
-- registro entero de atajos.
Programs = Programs or {}

local function notify_missing(app)
    return "notify-send 'Missing command' '" .. app .. " is not installed or not in PATH'"
end

------------------------------
----        APPS          ----
------------------------------

-- Terminal
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(Programs.terminal))

-- File Manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(Programs.fileManager))

-- Browser
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(Programs.browser))

-- App Launcher
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(Programs.menu))

-- Notification Center
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("swaync-client -t"))

-- Wallpaper picker
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(Programs.wallpaper))

-- Toggle theming dinámico (matugen)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(home .. "/.config/rofi/scripts/matugen_toggle.sh"))

-- Music

-- OBS Studio
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obs"))

-----------------------------
----      WINDOWS         ----
-----------------------------

-- Close focused window
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())

-- Toggle floating mode
hl.bind("+ CTRL + ALT + V", function()
    local win = hl.get_active_window()
    local monitor = hl.get_active_monitor()

    if not win or not monitor then
        return
    end

    if not win.floating then
        local width = monitor.width * 0.48
        local height = monitor.height * 0.6

        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ x = width, y = height }))
        hl.dispatch(hl.dsp.window.center())
    else
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    end
end)

-- Window shitcher
hl.bind("ALT + TAB", hl.dsp.exec_cmd(Programs.windowswitcher))

-- Fullscreen mode 1
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))

-- Fullscreen mode 0
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 0 }))

-----------------------------
----       SYSTEM         ----
-----------------------------

-- Keybind Viewer
hl.bind(mainMod .. "+ F1", hl.dsp.exec_cmd("kitty --title keybinds -e fish -c keybinds"))

-- Update System
hl.bind(mainMod .. "+ F2", hl.dsp.exec_cmd("kitty --title sysupdate -e fish -c sysupdate"))

-- Exit Hyprland
hl.bind(mainMod .. " + delete", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Session menu (Wlogout)
hl.bind(mainMod .. "+ ESCAPE", hl.dsp.exec_cmd(home .. "/.config/wlogout/scripts/launch_wlogout.sh"))

-- Lock screen
hl.bind(mainMod .. " + ALT + H", hl.dsp.exec_cmd(Programs.lockscreen))

-- System monitor (btop)
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd(Programs.terminal .. " --title btop -e btop"))
hl.bind("SHIFT + ESCAPE", hl.dsp.exec_cmd(Programs.terminal .. " --title bottom -e btm"))

-- Reload Waybar & SwayNc
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/launch.sh"))

-----------------------------
----   CLIPBOARD / COLOR  ----
-----------------------------

-- Clipboard history
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(Programs.clipboard))

-- Color picker
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))

-----------------------------
----     SCREENSHOTS      ----
-----------------------------

-- Full monitor
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots"))

-- Region screenshot with Swappy
hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))

-- Active window screenshot
hl.bind(mainMod .. " + F10", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/Screenshots"))

-----------------------------
----        FOCUS         ----
-----------------------------

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-----------------------------
----    MOVE WINDOWS      ----
-----------------------------

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down"  }))

-----------------------------
----      WORKSPACES      ----
-----------------------------

for i = 1, 10 do
    local key = i % 10
    -- Switch to workspace
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    -- Move window to workspace
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

------------------------------
----      SCRATCHPAD      ----
------------------------------

-- Toggle scratchpad
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))

-- Move window to scratchpad
hl.bind(mainMod .. " + SHIFT + S", function()
    local win = hl.get_active_window()
    if not win then return end

    if win.workspace.special then
        -- está en special, regresarla al workspace activo
        hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
    else
        -- está en workspace normal, mandarla al special
        hl.dispatch(hl.dsp.window.move({ workspace = "special:magic" }))
    end
end)

-----------------------------
----        MEDIA         ----
-----------------------------

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true, repeating = true })

-- Media playback
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

-----------------------------
----        MOUSE         ----
-----------------------------

-- Move / resize windows
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspace scrolling
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-----------------------------
----   LAYOUT SWITCHER    ----
-----------------------------

-- Dwindle layout
hl.bind(mainMod .. "+ SHIFT + D", hl.dsp.exec_cmd([[hyprctl eval 'hl.config({ general = { layout = "dwindle" } })']]))

-- Master layout
hl.bind(mainMod .. "+ SHIFT + M", hl.dsp.exec_cmd([[hyprctl eval 'hl.config({ general = { layout = "master" } })']]))

-- Scrolling layout
hl.bind(mainMod .. "+ SHIFT + O", hl.dsp.exec_cmd([[hyprctl eval 'hl.config({ general = { layout = "scrolling" } })']]))
