-- __________                                                   
-- \______   \_______  ____   ________________    _____   ______
--  |     ___/\_  __ \/  _ \ / ___\_  __ \__  \  /     \ /  ___/
--  |    |     |  | \(  <_> ) /_/  >  | \// __ \|  Y Y  \\___ \ 
--  |____|     |__|   \____/\___  /|__|  (____  /__|_|  /____  >
--                         /_____/            \/      \/     \/ 

-- Set programs that you use
Programs = {
    terminal    = "kitty",
    fileManager = "thunar",
    menu        = "pgrep -x rofi >/dev/null && pkill -x rofi || bash $HOME/.config/rofi/launcher.sh",
    browser     = "zen-browser",
    music       = "spotify-launcher",
    wallpaper   = 'pgrep -x rofi >/dev/null && pkill -x rofi || rofi -show wallpapers -modi "wallpapers:$HOME/.config/rofi/scripts/wallpaper_rofi.sh" -theme $HOME/.config/rofi/wallpaper-picker.rasi',
    clipboard = 'cliphist list | rofi -dmenu -display-columns 2 -p "Clipboard" -theme $HOME/.config/rofi/clipboard.rasi | cliphist decode | wl-copy',
}