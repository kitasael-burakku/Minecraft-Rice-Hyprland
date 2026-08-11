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
        gaps_out = 20,

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
        rounding       = 15,
        rounding_power = 2.4,

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
            size     = 10,
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
})