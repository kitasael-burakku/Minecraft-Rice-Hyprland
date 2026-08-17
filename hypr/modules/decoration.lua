-- ________                                    __  .__               
-- \______ \   ____   ____  ________________ _/  |_|__| ____   ____  
--  |    |  \_/ __ \_/ ___\/  _ \_  __ \__  \\   __\  |/  _ \ /    \ 
--  |    `   \  ___/\  \__(  <_> )  | \// __ \|  | |  (  <_> )   |  \
-- /_______  /\___  >\___  >____/|__|  (____  /__| |__|\____/|___|  /
--         \/     \/     \/                 \/                    \/ 

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 10,
        gaps_out = 30,

        border_size = 2,

        -- Teal Kitasan Glass, no blanco — misma identidad de reposo que
        -- hypr/scripts/dynamic-colors.static.sh (fuente de verdad), para que
        -- un arranque en frío y un "apagar el toggle" luzcan igual.
        col = {
            active_border = "rgba(7ab8b8cc)",
            inactive_border = "rgba(7ab8b80f)",
        },

        resize_on_border         = true,
        extend_border_grab_area  = 18,
        hover_icon_on_border     = true,

        allow_tearing = false,
    },

    decoration = {
        rounding       = 20,
        rounding_power = 2.5,

        active_opacity   = 0.9,
        inactive_opacity = 0.8,
        fullscreen_opacity = 1,

        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            sharp = false,
            color = "rgba(0,0,0,0.55)",
            offset = { 0, 5 },
            scale = 1.0,
        },

        blur = {
            enabled  = true,
            size     = 5,
            passes   = 2,

            ignore_opacity    = true,
            new_optimizations = true,

            xray = false,

            special = true,

            vibrancy =0.18,
            vibrancy_darkness = 0.0,
            input_methods             = true,
            input_methods_ignorealpha = 0.20,
        },
    },

    animations = {
        enabled = true,
    },

    -- SIN render.direct_scanout. Se probó en 1 (2026-08-17) y se revirtió:
    -- la opción tomaba efecto —"USER" desapareció de directScanoutBlockedBy—
    -- pero en pantalla completa real directScanoutTo se quedó en "0", o sea
    -- que el scanout nunca llegó a activarse. Activar una opción que no hace
    -- nada es deuda: queda ahí sugiriendo que el camino rápido está en uso
    -- cuando no lo está.
    --
    -- Sospecha no confirmada: el monitor va con bitdepth = 10 (formato de
    -- salida XRGB2101010, ver modules/monitors.lua) y las apps presentan
    -- buffers de 8 bits; si el plano no acepta el buffer sin conversión, el
    -- scanout directo es imposible por construcción. Para descartarlo habría
    -- que quitar bitdepth = 10 y repetir la prueba en fullscreen.
})