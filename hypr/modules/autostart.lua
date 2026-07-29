--    _____          __                  __                 __   
--   /  _  \  __ ___/  |_  ____  _______/  |______ ________/  |_ 
--  /  /_\  \|  |  \   __\/  _ \/  ___/\   __\__  \\_  __ \   __\
-- /    |    \  |  /|  | (  <_> )___ \  |  |  / __ \|  | \/|  |  
-- \____|__  /____/ |__|  \____/____  > |__| (____  /__|   |__|  
--         \/                       \/            \/             

local home = os.getenv("HOME") or "/home/user"

local wait_hyprland   = home .. "/.config/hypr/scripts/wait-for-hyprland.sh"
local apply_wallpaper = home .. "/.config/hypr/scripts/apply-wallpaper.sh"
local wallpaper_state = home .. "/.config/hypr/.current-wallpaper"
local matugen_reload  = home .. "/.config/rofi/scripts/matugen_reload.sh"

hl.on("hyprland.start", function()

    -- Fondo de pantalla: restaura el último wallpaper elegido (persistido en
    -- .current-wallpaper por apply-wallpaper.sh) o cae al default interno del
    -- script si nunca se eligió ninguno / ya no existe. apply-wallpaper.sh es
    -- la fuente única de los flags de mpvpaper/awww — compartida con
    -- rofi/scripts/wallpaper_grid.sh, no hay una segunda copia que mantener
    -- sincronizada a mano.

    -- Encadenado en un solo job de fondo para garantizar el orden:
    -- matugen_reload.sh (no-op si el theming dinámico está apagado) necesita
    -- leer el estado que apply-wallpaper.sh acaba de escribir.
    hl.exec_cmd("awww-daemon &")
    hl.exec_cmd(wait_hyprland .. " && ( " .. apply_wallpaper .. " && wall=\"$(cat '" .. wallpaper_state .. "' 2>/dev/null)\" && " .. matugen_reload .. " \"$wall\" ) &")

    -- Entorno (encadenado para garantizar el orden: el target de systemd
    -- depende de que el entorno D-Bus ya esté actualizado)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user start hyprland-session.service")

    -- UI y Daemons
    hl.exec_cmd("hyprctl setcursor " .. CursorTheme .. " 24")
    hl.exec_cmd(home .. "/.config/waybar/scripts/launch.sh &")
    hl.exec_cmd(wait_hyprland .. " && hypridle &")
    hl.exec_cmd("test -x /usr/lib/polkit-kde-authentication-agent-1 && /usr/lib/polkit-kde-authentication-agent-1 &")

    -- Clipboard
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")

    -- Udiskie
    hl.exec_cmd("udiskie --tray &")

    -- Comandos privados (ver hypr/modules/private.example.lua) — no
    -- versionados. pcall(): la ausencia de private.lua no debe tumbar el
    -- resto del arranque.
    local ok, private = pcall(require, "modules.private")
    if ok and type(private) == "table" and type(private.autostart) == "table" then
        for _, cmd in ipairs(private.autostart) do
            hl.exec_cmd(cmd)
        end
    end
end)

-- Teardown: hyprland-session.service (BindsTo=) y cualquier servicio privado
-- con PartOf= ya están declarados para reaccionar a que
-- graphical-session.target pare — sin esto, nada los paraba nunca y
-- sobrevivían a la sesión.
hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop graphical-session.target")
end)