--  ____  __.            __________.__            .___      
-- |    |/ _|____ ___.__.\______   \__| ____    __| _/______
-- |      <_/ __ <   |  | |    |  _/  |/    \  / __ |/  ___/
-- |    |  \  ___/\___  | |    |   \  |   |  \/ /_/ |\___ \ 
-- |____|__ \___  > ____| |______  /__|___|  /\____ /____  >
--         \/   \/\/             \/        \/      \/    \/ ---------

local mainMod = "SUPER"
local home = os.getenv("HOME") or "/home/kitasa-elburakku"

local function notify_missing(app)
    return "notify-send 'Missing command' '" .. app .. " is not installed or not in PATH'"
end

-----------------------------
---- MAIN APPLICATIONS ------
-----------------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(Programs.terminal)) -- Terminal
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(Programs.fileManager)) -- File Manager
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave")) -- Browser
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(Programs.menu)) -- App Launcher
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("swaync-client -t")) -- Notification Center

-- Wallpaper picker 
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(
    'rofi -show wallpapers -modi "wallpapers:' .. home .. '/.config/rofi/scripts/wallpaper_rofi.sh" -theme ' .. home .. '/.config/rofi/wallpaper-picker.rasi'
))

-- Gaming / Recording
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obs")) -- OBS Studio

---------------------------
---- DEVELOPMENT MODE ----
---------------------------

-- Open Hyprland configuration
hl.bind(mainMod .. " + CTRL + H", hl.dsp.exec_cmd("vscodium ~/.config/hypr"))

-----------------------------
---- WINDOW MANAGEMENT ----
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
        local width = monitor.width * 0.5
        local height = monitor.height * 0.6

        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ x = width, y = height }))
        hl.dispatch(hl.dsp.window.center())
    else
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    end
end)

-- Fullscreen modes
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 0 }))

----------------------------
---- SESSION / SYSTEM ----
----------------------------

-- Exit Hyprland
hl.bind(mainMod .. " + delete", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Session menu
hl.bind(mainMod .. "+ ESCAPE", hl.dsp.exec_cmd(home .. "/.config/wlogout/scripts/launch_wlogout.sh"))

-- Lock screen
hl.bind(mainMod .. " + ALT + H", hl.dsp.exec_cmd("hyprlock"))

-- System monitor
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd(Programs.terminal .. " -e btop"))

-- Cava
hl.bind(mainMod .. "+ SHIFT + X", hl.dsp.exec_cmd("pgrep -x cava >/dev/null && pkill -x cava || kitty --class cava-float cava"))

-- Reload Waybar
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/launch_waybar.sh"))

--------------------------------
---- CLIPBOARD COLOR PICKER ----
--------------------------------

hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd('cliphist list | rofi -dmenu -display-columns 2 -p "Clipboard" -theme ' .. home .. '/.config/rofi/style-4.rasi | cliphist decode | wl-copy'))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))

---------------------
---- SCREENSHOTS ----
---------------------

-- Full monitor
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots"))

-- Region selection
hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))

-- Active window
hl.bind(mainMod .. " + F10", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/Screenshots"))

--------------------------
---- WINDOW FOCUSING ----
--------------------------

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-------------------------
---- WINDOW MOVEMENT ----
-------------------------

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

--------------------
---- WORKSPACES ----
--------------------

for i = 1, 10 do
    local key = i % 10
    -- Switch workspace
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    -- Move window to workspace
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

------------------------------
---- SPECIAL WORKSPACE ----
------------------------------

-- Toggle scratchpad workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))

-- Move focused window to scratchpad
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

--------------------------
---- MEDIA CONTROLS ----
--------------------------

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })

-- Media playback
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

---------------------
---- MOUSE BINDS ----
---------------------

-- Move / resize windows
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Workspace scrolling
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-----------------------
--- Layout switcher ---
-----------------------
hl.bind(mainMod .. "+ SHIFT + D", hl.dsp.exec_cmd([[hyprctl eval 'hl.config({ general = { layout = "dwindle" } })']]))
hl.bind(mainMod .. "+ SHIFT + M", hl.dsp.exec_cmd([[hyprctl eval 'hl.config({ general = { layout = "master" } })']]))
hl.bind(mainMod .. "+ SHIFT + O", hl.dsp.exec_cmd([[hyprctl eval 'hl.config({ general = { layout = "scrolling" } })']]))
