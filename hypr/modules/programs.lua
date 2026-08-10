-- __________
-- \______   \_______  ____   ________________    _____   ______
--  |     ___/\_  __ \/  _ \ / ___\_  __ \__  \  /     \ /  ___/
--  |    |     |  | \(  <_> ) /_/  >  | \// __ \|  Y Y  \\___ \
--  |____|     |__|   \____/\___  /|__|  (____  /__|_|  /____  >
--                         /_____/            \/      \/     \/

-- Set programs that you use
Programs = {
    -- Apps 
    terminal       = "kitty",
    fileManager    = "nautilus",
    menu           = "pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/launcher.sh",
    browser        = "zen-browser",
    lockscreen     = "hyprlock",
    record         = "obs",
    --music        = "spotify" --Placeholder,

    -- Rofi 
    wallpaper      = 'pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/scripts/wallpaper_launcher.sh',
    clipboard      = 'pgrep -x rofi >/dev/null && pkill -x rofi || cliphist list | rofi -dmenu -display-columns 2 -p "Clipboard" -theme $HOME/.config/rofi/clipboard.rasi | cliphist decode | wl-copy',
    windowswitcher ='pgrep -x rofi >/dev/null && pkill -x rofi || rofi -show winswitcher -modi winswitcher:~/.config/rofi/scripts/window-switcher.sh -theme ~/.config/rofi/window-switcher.rasi', 
    themePicker    = 'pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/scripts/theme.sh',
    services       = 'pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/scripts/systemd.sh',
    powermenu      = 'pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/scripts/power.sh',
    dashboard      = 'pgrep -x rofi >/dev/null && pkill -x rofi || rofi -show dashboard -modi dashboard:$HOME/.config/rofi/scripts/dashboard.sh -theme $HOME/.config/rofi/clipboard.rasi',
    themeToggle    = "bash $HOME/.config/rofi/scripts/matugen_toggle.sh",
    sessionMenu    = "bash $HOME/.config/wlogout/scripts/launch_wlogout.sh",
    kitasanMenu    = "fish -c 'kitasan menu'"
}

-- Comandos privados
local ok, private = pcall(require, "modules.private")
if ok and type(private) == "table" and type(private.programs) == "table" then
    for key, value in pairs(private.programs) do
        Programs[key] = value
    end
end