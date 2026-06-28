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

        border_size = 2,

        col = {
            active_border = "rgba(ffffff33)",
            inactive_border = "rgba(ffffff0a)",
        },

        resize_on_border         = true,
        extend_border_grab_area  = 18,
        hover_icon_on_border     = true,

        allow_tearing = false,

        layout = "scrolling",
    },

    decoration = {
        rounding       = 14,
        rounding_power = 2.5,

        active_opacity   = 0.9,
        inactive_opacity = 0.8,
        fullscreen_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = 0x99000000,
            offset       = "0 4", 
        },

        blur = {
            enabled  = true,
            size     = 7,
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