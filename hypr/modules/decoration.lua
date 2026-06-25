-- ________                                    __  .__               
-- \______ \   ____   ____  ________________ _/  |_|__| ____   ____  
--  |    |  \_/ __ \_/ ___\/  _ \_  __ \__  \\   __\  |/  _ \ /    \ 
--  |    `   \  ___/\  \__(  <_> )  | \// __ \|  | |  (  <_> )   |  \
-- /_______  /\___  >\___  >____/|__|  (____  /__| |__|\____/|___|  /
--         \/     \/     \/                 \/                    \/ 

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 15,
        gaps_out = 30,

        border_size = 1,

        col = {
            active_border = {
                colors = {
                    "rgba(c6c6c655)",
                },
            },

            inactive_border = "rgba(00000022)",
        },

        resize_on_border         = true,
        extend_border_grab_area  = 18,
        hover_icon_on_border     = true,

        allow_tearing = false,

        layout = "scrolling",
    },

    decoration = {
        rounding       = 14,
        rounding_power = 4,

        active_opacity   = 0.9,
        inactive_opacity = 0.8,
        fullscreen_opacity = 0.95,

        dim_inactive = true,
        dim_strength = 0.06,

        shadow = {
            enabled      = true,
            range        = 10,
            render_power = 2,
            -- offset por defecto { 0, 0 }, sin desplazamiento
            color        = 0xee121212,
        },

        blur = {
            enabled  = true,
            size     = 5,
            passes   = 2,

            ignore_opacity    = true,
            new_optimizations = true,

            xray = true,

            noise      = 0.010,
            contrast   = 0.9,
            brightness = 1,

            vibrancy          = 0.08,
            vibrancy_darkness = 0.06,

            special = true,

            popups                    = true,
            popups_ignorealpha        = 0.20,
            input_methods             = true,
            input_methods_ignorealpha = 0.20,
        },
    },

    animations = {
        enabled = true,
        -- Curvas y animaciones definidas en animations.lua
    },
})