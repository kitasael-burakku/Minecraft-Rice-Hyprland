--    _____          __                  __                 __   
--   /  _  \  __ ___/  |_  ____  _______/  |______ ________/  |_ 
--  /  /_\  \|  |  \   __\/  _ \/  ___/\   __\__  \\_  __ \   __\
-- /    |    \  |  /|  | (  <_> )___ \  |  |  / __ \|  | \/|  |  
-- \____|__  /____/ |__|  \____/____  > |__| (____  /__|   |__|  
--         \/                       \/            \/             

local home = os.getenv("HOME") or "/home/kitasa-elburakku"

local wait_hyprland = home .. "/.config/hypr/scripts/wait-for-hyprland.sh"
local default_wallpaper = home .. "/Videos/Wallpapers/behind-the-market.mp4"

hl.on("hyprland.start", function()

    -- Fondo de pantalla
    hl.exec_cmd("awww-daemon &")
    hl.exec_cmd(wait_hyprland .. " && mpvpaper -o '--loop-file=inf --no-audio' '*' " .. default_wallpaper .. " &")

    -- Colores dinámicos (matugen) a partir del wallpaper de arranque —
    -- no-op si el theming dinámico está apagado (matugen_reload.sh chequea
    -- el sentinel solo). Sin esto, el wallpaper por defecto nunca dispara
    -- una generación porque no pasa por el picker de rofi.
    hl.exec_cmd(wait_hyprland .. " && " .. home .. "/.config/rofi/scripts/matugen_reload.sh '" .. default_wallpaper .. "' &")

    -- Entorno (encadenado para garantizar el orden: el target de systemd
    -- depende de que el entorno D-Bus ya esté actualizado)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user start hyprland-session.service")

    -- UI y Daemons
    hl.exec_cmd("hyprctl setcursor Future-black-cursors 24")
    hl.exec_cmd(home .. "/.config/waybar/scripts/launch.sh &")
    hl.exec_cmd(wait_hyprland .. " && hypridle &")
    hl.exec_cmd("test -x /usr/lib/polkit-kde-authentication-agent-1 && /usr/lib/polkit-kde-authentication-agent-1 &")

    -- Clipboard
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")

    -- Udiskie
    hl.exec_cmd("udiskie --tray &")

end)