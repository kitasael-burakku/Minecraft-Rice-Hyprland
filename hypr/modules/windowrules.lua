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

--------------------
---- WINDOW RULES ----
--------------------

-- Ignore maximize requests from all apps
hl.window_rule({
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
    
    float   = true,
    opacity = 0.90,
})

--------------------
---- MEDIA APPS ----
--------------------

-- MPV: float centrado con tamaño razonable
hl.window_rule({
    name  = "mpv-float",
    match = {
        class = "^(mpv)$",
    },

    float  = true,
    center = true,
    size   = "960 540",
})

-- MPV: animación popin para que se sienta menos abrupto
hl.window_rule({
    name  = "mpv-anim",
    match = {
        class = "^(mpv)$",
    },

    animation = "popin 80%",
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
    ignore_alpha = 0.4,
    animation = "slide right",
})

-- Notification Window
hl.layer_rule({
    name  = "swaync-window-blur",
    match = {
        namespace = "swaync-notification-window",
    },

    blur = true,
    ignore_alpha = 0.4,
})

-- Rofi
hl.layer_rule({
    name  = "rofi",
    match = {
        namespace = "rofi",
    },

    blur = true,
    ignore_alpha = 0.9,
    animation = "slide 20%"
})

-- Wlogout 
hl.layer_rule({
    name  = "wlogout",
    match = {
        namespace = "logout_dialog",
    },

    blur = true,
    ignore_alpha=0.5,
})

--------------------------
---- WORKSPACE RULES ----
--------------------------

-- Smart gaps / no gaps when only one tiled window
hl.workspace_rule({
    workspace = "w[tv1]",
    gaps_out  = 30,
    gaps_in   = 15,
})

hl.workspace_rule({
    workspace = "f[1]",
    gaps_out  = 30,
    gaps_in   = 15,
})

hl.window_rule({
    name  = "no-gaps-wtv1",
    match = {
        float     = false,
        workspace = "w[tv1]",
    },

    border_size    = 1,
    rounding       = 18,
    rounding_power = 4,
})

hl.window_rule({
    name  = "no-gaps-f1",
    match = {
        float     = false,
        workspace = "f[1]",
    },

    border_size    = 1,
    rounding       = 18,
    rounding_power = 4,
})

-- Special workspace (scratchpad)
hl.workspace_rule({
    workspace = "special:magic",
    gaps_out  = 10,
    gaps_in   = 20,
    border_size = 0,
})

------------
--- APPS ---
------------
hl.window_rule({
    name  = "spotify-float",
    match = {
        class = "^(Spotify|spotify)$",
    },
    float  = true,
    center = true,
    size   = "1100 700",
})
