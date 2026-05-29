--  __      __.__            .___                    
-- /  \    /  \__| ____    __| _/______  _  ________ 
-- \   \/\/   /  |/    \  / __ |/  _ \ \/ \/ /  ___/ 
--  \        /|  |   |  \/ /_/ (  <_> )     /\___ \  
--   \__/\  / |__|___|  /\____ |\____/ \/\_//____  > 
--        \/          \/      \/                 \/  
--                              .___                
--            _____    ____    __| _/                
--            \__  \  /    \  / __ |                 
--             / __ \|   |  \/ /_/ |                 
--            (____  /___|  /\____ |                 
--                 \/     \/      \/                 
-- .____                                             
-- |    |   _____  ___.__. ___________  ______       
-- |    |   \__  \<   |  |/ __ \_  __ \/  ___/       
-- |    |___ / __ \\___  \  ___/|  | \/\___ \        
-- |_______ (____  / ____|\___  >__|  /____  >       
--         \/    \/\/         \/           \/        

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from all apps
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = {
        class = "hyprland-run",
    },

    move  = "20 monitor_h-120",
    float = true,
})

-- Cava
hl.window_rule({
    name  = "cava-float",
    match = {
        class = "^(cava-float)$",
    },
    
    float = true,
    opacity = 0.90,
})

--------------------
---- LAYER RULES ----
--------------------

-- Notification Center
hl.layer_rule({
    name  = "swaync-control-blur",
    match = {
        namespace = "swaync-control-center",
    },

    blur = true,
})

hl.layer_rule({
    name  = "swaync-control-alpha",
    match = {
        namespace = "swaync-control-center",
    },

    ignore_alpha = 0.5,
})

hl.layer_rule({
    name  = "swaync-control-animation",
    match = {
        namespace = "swaync-control-center",
    },

    animation = "slide",
})

-- Notification Window
hl.layer_rule({
    name  = "swaync-window-blur",
    match = {
        namespace = "swaync-notification-window",
    },

    blur = true,
})

hl.layer_rule({
    name  = "swaync-window-alpha",
    match = {
        namespace = "swaync-notification-window",
    },

    ignore_alpha = 0.5,
})

hl.layer_rule({
    name  = "swaync-window-animation",
    match = {
        namespace = "swaync-notification-window",
    },

    animation = "slide",
})

-- Logout dialog
hl.layer_rule({
    name  = "logout-blur",
    match = {
        namespace = "logout_dialog",
    },

    blur = true,
})

hl.layer_rule({
    name  = "logout-animation",
    match = {
        namespace = "logout_dialog",
    },

    animation = "slide 60%",
})

-- Rofi
hl.layer_rule({
    name  = "rofi-blur",
    match = {
        namespace = "rofi",
    },

    blur = true,
})

hl.layer_rule({
    name  = "rofi-alpha",
    match = {
        namespace = "rofi",
    },

    ignore_alpha = 1,
})

hl.layer_rule({
    name  = "rofi-animation",
    match = {
        namespace = "rofi",
    },

    animation = "popin",
})

-- Waybar
hl.layer_rule({
    name  = "waybar-blur",
    match = {
        namespace = "waybar",
    },

    blur = true,
})

hl.layer_rule({
    name  = "waybar-alpha",
    match = {
        namespace = "waybar",
    },

    ignore_alpha = 0.5,
})

--------------------------
---- WORKSPACE RULES ----
--------------------------

-- Smart gaps / no gaps when only

--hl.workspace_rule({
--    workspace = "w[tv1]",
--    gaps_out  = 20,
--    gaps_in   = 10,
--})

--hl.workspace_rule({
--    workspace = "f[1]",
--    gaps_out  = 20,
--    gaps_in   = 10,
--})

--hl.window_rule({
--    name  = "no-gaps-wtv1",
--    match = {
--        float     = false,
--        workspace = "w[tv1]",
--    },

--    border_size   = 1,
--    rounding      = 18,
--    rounding_power = 4,
--})

--hl.window_rule({
--    name  = "no-gaps-f1",
--   match = {
--        float     = false,
--        workspace = "f[1]",
--    },

--    border_size = 1,
--    rounding    = 18,
--    rounding_power = 4,
--})