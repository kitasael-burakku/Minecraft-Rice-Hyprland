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
--- WINDOW RULES ---
--------------------

-- Ignore maximize requests from all apps
hl.window_rule({ name  = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })

-- Fix some dragging issues with XWayland
hl.window_rule({ name  = "fix-xwayland-drags", match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false, }, no_focus = true, })

-- Hyprland-run windowrule
hl.window_rule({ name  = "move-hyprland-run", match = { class = "hyprland-run", }, move  = "20 monitor_h-120", float = true, })

-------------------
--- LAYER RULES ---
-------------------

-- Notification Center
hl.layer_rule({ name  = "swaync-control-blur", match = { namespace = "swaync-control-center", },blur = true , ignore_alpha = 0.4, animation = "slide right" })

-- Notification Window
hl.layer_rule({ name  = "swaync-window-blur", match = { namespace = "swaync-notification-window", }, blur = true, ignore_alpha = 0.4 })

-- Rofi
hl.layer_rule({ name  = "rofi", match = { namespace = "rofi", },blur = true, ignore_alpha = 0.9, animation = "popin" })

-- Wlogout 
hl.layer_rule({ name  = "wlogout", match = { namespace = "logout_dialog", }, blur = true, ignore_alpha=0.5 })

--------------------------
---- WORKSPACE RULES -----
--------------------------

-- Workspace de una sola ventana tileada (w[tv1]/f[1]): gap interno un poco
-- mayor que el global (15 vs 12 de decoration.lua) y, más abajo, borde más
-- fino + rounding suave solo para esas ventanas — no es "sin gaps", es un
-- tratamiento distinto para el caso de una sola ventana.

hl.workspace_rule({ workspace = "w[tv1]", gaps_out  = 20, gaps_in   = 10, })
hl.workspace_rule({ workspace = "f[1]", gaps_out  = 10, gaps_in   = 20, })
hl.window_rule({ name  = "no-gaps-wtv1", match = { float     = false, workspace = "w[tv1]",}, border_size    = 1, rounding       = 18, rounding_power = 4, })
hl.window_rule({ name  = "no-gaps-f1", match = { float     = false, workspace = "f[1]", }, border_size    = 1, rounding       = 18, rounding_power = 4, })

-- Special workspace (scratchpad)
hl.workspace_rule({ workspace = "special:magic", gaps_out  = 10, gaps_in   = 20, border_size = 0, })