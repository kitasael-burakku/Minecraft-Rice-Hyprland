-- Plantilla de hypr/modules/private.lua — ese archivo NO se versiona
-- (gitignored). Copiá este a private.lua y completá con tus propios
-- comandos privados.

-- programs.lua, autostart.lua y keybinds.lua lo requieren con pcall(), así
-- que si private.lua no existe, el resto de la config sigue funcionando
-- exactamente igual — solo faltan estos extras opcionales. Reemplaza el
-- viejo mecanismo de redactar por regex el nombre de un proyecto privado
-- directamente en programs.lua/autostart.lua (que llegó a borrar un
-- comentario a media frase) por un archivo que simplemente nunca se publica.

return {
    -- Se fusiona en la tabla pública Programs (hypr/modules/programs.lua).
    programs = {
        -- music = "mi-reproductor-privado",
    },

    -- Comandos ejecutados en "hyprland.start", después de los públicos
    -- (hypr/modules/autostart.lua).
    autostart = {
        -- "systemctl --user start mi-servicio-privado.service",
    },

    -- Se llama al final de hypr/modules/keybinds.lua, después de todos los
    -- binds públicos. Recibe mainMod (el modificador principal, "SUPER")
    -- para no tener que hardcodearlo de nuevo acá.
    binds = function(mainMod)
        -- hl.bind(mainMod .. "+ M", hl.dsp.exec_cmd(Programs.music))
    end,
}
