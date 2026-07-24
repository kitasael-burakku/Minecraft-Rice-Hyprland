-- __________
-- \______   \_______  ____   ________________    _____   ______
--  |     ___/\_  __ \/  _ \ / ___\_  __ \__  \  /     \ /  ___/
--  |    |     |  | \(  <_> ) /_/  >  | \// __ \|  Y Y  \\___ \
--  |____|     |__|   \____/\___  /|__|  (____  /__|_|  /____  >
--                         /_____/            \/      \/     \/

-- Set programs that you use
Programs = {
    terminal       = "kitty",
    fileManager    = "nautilus",
    menu           = "pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/launcher.sh",
    browser        = "zen-browser",
    wallpaper      = 'pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/scripts/wallpaper_launcher.sh',
    clipboard      = 'pgrep -x rofi >/dev/null && pkill -x rofi || cliphist list | rofi -dmenu -display-columns 2 -p "Clipboard" -theme $HOME/.config/rofi/clipboard.rasi | cliphist decode | wl-copy',
    windowswitcher ='pgrep -x rofi >/dev/null && pkill -x rofi || rofi -show winswitcher -modi winswitcher:~/.config/rofi/scripts/window-switcher.sh -theme ~/.config/rofi/window-switcher.rasi',
    lockscreen     = "hyprlock"
}