--    _____         .__                __  .__                      
--   /  _  \   ____ |__| _____ _____ _/  |_|__| ____   ____   ______
--  /  /_\  \ /    \|  |/     \\__  \\   __\  |/  _ \ /    \ /  ___/
-- /    |    \   |  \  |  Y Y  \/ __ \|  | |  (  <_> )   |  \\___ \ 
-- \____|__  /___|  /__|__|_|  (____  /__| |__|\____/|___|  /____  >
--         \/     \/         \/     \/                    \/     \/ 

-- ─────────────────────────────────────────────────────────────────────────────
-- Velvet Motion Animations
-- ─────────────────────────────────────────────────────────────────────────────

-- Curves
hl.curve("silkOut",       { type = "bezier", points = { {0.16, 1.00}, {0.30, 1.00} } })
hl.curve("softIn",        { type = "bezier", points = { {0.38, 0.00}, {0.20, 1.00} } })
hl.curve("cinemaFade",    { type = "bezier", points = { {0.22, 0.00}, {0.36, 1.00} } })
hl.curve("glass",         { type = "bezier", points = { {0.25, 0.10}, {0.25, 1.00} } })
hl.curve("swiftSlide",    { type = "bezier", points = { {0.05, 0.90}, {0.18, 1.00} } })
hl.curve("calm",          { type = "bezier", points = { {0.40, 0.00}, {0.60, 1.00} } })

-- Springs
hl.curve("velvetWindow",  { type = "spring", mass = 1, stiffness = 95,  dampening = 20 })
hl.curve("softPop",       { type = "spring", mass = 1, stiffness = 115, dampening = 17 })
hl.curve("cleanDrag",     { type = "spring", mass = 1, stiffness = 160, dampening = 30 })
hl.curve("workspaceFlow", { type = "spring", mass = 1, stiffness = 130, dampening = 24 })

-- Global
hl.animation({ leaf = "global",        enabled = true, speed = 7.0,  bezier = "silkOut" })
hl.animation({ leaf = "border",        enabled = true, speed = 7.5,  bezier = "glass"   })

-- Windows
hl.animation({ leaf = "windows",       enabled = true, speed = 5.0,  spring = "velvetWindow" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.4,  spring = "softPop",      style = "popin 88%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3.6,  bezier = "cinemaFade",   style = "popin 96%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 7.2,  spring = "cleanDrag"     })

-- Fades
hl.animation({ leaf = "fade",          enabled = true, speed = 2.0,  bezier = "cinemaFade" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.6,  bezier = "softIn"     })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.3,  bezier = "calm"       })

-- Layers
hl.animation({ leaf = "layers",        enabled = true, speed = 4.0,  bezier = "silkOut" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3.6,  bezier = "glass",      style = "slide top" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 3.0,  bezier = "cinemaFade", style = "slide top" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.4,  bezier = "softIn" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.1,  bezier = "calm"   })

-- Workspaces
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5.6,  spring = "workspaceFlow", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5.0,  bezier = "swiftSlide",    style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 6.0,  bezier = "silkOut",       style = "slide" })

-- Zoom
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 6.0,  bezier = "glass" })