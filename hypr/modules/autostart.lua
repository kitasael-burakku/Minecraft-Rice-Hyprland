--    _____          __                  __                 __   
--   /  _  \  __ ___/  |_  ____  _______/  |______ ________/  |_ 
--  /  /_\  \|  |  \   __\/  _ \/  ___/\   __\__  \\_  __ \   __\
-- /    |    \  |  /|  | (  <_> )___ \  |  |  / __ \|  | \/|  |  
-- \____|__  /____/ |__|  \____/____  > |__| (____  /__|   |__|  
--         \/                       \/            \/             

local home = os.getenv("HOME") or "/home/kitasa-elburakku"

hl.on("hyprland.start", function()
   
    -- Fondo de pantalla
    hl.exec_cmd("awww-daemon &")
    hl.exec_cmd("sleep 0.5 && mpvpaper -o '--loop-file=inf --no-audio' '*' " .. home .. "/Videos/wallpapersvideo/minecraft-house.mp4 &")
    
    -- Entorno
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("systemctl --user start hyprland-session.service")
   
    -- UI y Daemons
    hl.exec_cmd("hyprctl setcursor Future-black-cursors 24")
    hl.exec_cmd(home .. "/.config/waybar/scripts/launch.sh &")
    hl.exec_cmd("sleep 2 && hypridle &")
    hl.exec_cmd("test -x /usr/lib/polkit-kde-authentication-agent-1 && /usr/lib/polkit-kde-authentication-agent-1 &")

    -- Clipboard
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")

    -- Udiskie
    hl.exec_cmd("udiskie --tray &")

    -- Terminal 
    hl.exec_cmd(home .. "/.config/scripts/terminal-bg-cava.sh &")
end)