--    _____          __                  __                 __
--   /  _  \  __ ___/  |_  ____  _______/  |______ ________/  |_
--  /  /_\  \|  |  \   __\/  _ \/  ___/\   __\__  \\_  __ \   __\
-- /    |    \  |  /|  | (  <_> )___ \  |  |  / __ \|  | \/|  |
-- \____|__  /____/ |__|  \____/____  > |__| (____  /__|   |__|
--         \/                       \/            \/

-- Migrado a systemd (ver ~/.config/systemd/user/*.service): antes este
-- archivo era ~60 líneas de hl.exec_cmd encadenadas a mano con "&&"/"&"
-- dentro de strings Lua para simular orden y backgrounding — sin
-- supervisión (si waybar o hypridle morían, quedaban muertos hasta un
-- SUPER+SHIFT+R o un reinicio) y con logs sueltos por todos lados en
-- $XDG_RUNTIME_DIR.

-- Ahora "systemctl --user start hyprland-session.service" alcanza: ese
-- servicio (BindsTo=/Wants=/After=graphical-session.target) activa el
-- target, y el target trae solo a todo lo que declara
-- WantedBy=graphical-session.target — waybar, playerctl-watch, swaync,
-- hypridle, awww, wallpaper (restaura el último + dispara matugen),
-- cliphist-text/image, udiskie, infinite-desktop, polkit-agent y maly.
-- Cada uno con su propio Restart= y su journal (`journalctl --user -u
-- <servicio>`), y el orden real lo expresan After=/Requires= en vez de
-- concatenación de comandos.

local home = os.getenv("HOME") or "/home/user"

hl.on("hyprland.start", function()
    -- Entorno primero: graphical-session.target (y todo lo que arranca con
    -- él) necesita que el D-Bus activation environment ya tenga
    -- WAYLAND_DISPLAY/XDG_CURRENT_DESKTOP/XDG_SESSION_TYPE actualizados, o
    -- los servicios que dependen de Wayland arrancan con el entorno viejo.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE GTK_THEME GDK_BACKEND QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME GSK_RENDERER && systemctl --user start hyprland-session.service")

    -- Único one-shot que no tiene sentido como servicio propio (no es un
    -- daemon, no hay nada que supervisar).
    hl.exec_cmd("hyprctl setcursor " .. CursorTheme .. " 24")

    -- Symlinkea steam_icon_<appid> -> librarycache/.../logo.png en
    -- ~/.local/share/icons/hicolor (ver hypr/scripts/link-steam-icons.sh).
    -- Otro one-shot sin estado que supervisar: corre, termina, listo.
    hl.exec_cmd(home .. "/.config/hypr/scripts/link-steam-icons.sh")

    -- Comandos privados (ver hypr/modules/private.example.lua) — no
    -- versionados. pcall(): la ausencia de private.lua no debe tumbar el
    -- resto del arranque. Para daemons privados de verdad, preferí un
    -- .service propio con WantedBy=graphical-session.target (ver
    -- maly.service) — esta lista es para lo que de verdad sea un one-shot.
    local ok, private = pcall(require, "modules.private")
    if ok and type(private) == "table" and type(private.autostart) == "table" then
        for _, cmd in ipairs(private.autostart) do
            hl.exec_cmd(cmd)
        end
    end
end)

-- Teardown: todo lo que declara PartOf=graphical-session.target (los 11
-- servicios de arriba + cualquier servicio privado con el mismo PartOf=) se
-- para en cascada con esto — sin esto, nada los paraba nunca y sobrevivían
-- a la sesión.
hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop graphical-session.target")
end)
