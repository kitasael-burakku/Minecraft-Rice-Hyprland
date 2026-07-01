--    _____         .__                __  .__                      
--   /  _  \   ____ |__| _____ _____ _/  |_|__| ____   ____   ______
--  /  /_\  \ /    \|  |/     \\__  \\   __\  |/  _ \ /    \ /  ___/
-- /    |    \   |  \  |  Y Y  \/ __ \|  | |  (  <_> )   |  \\___ \ 
-- \____|__  /___|  /__|__|_|  (____  /__| |__|\____/|___|  /____  >
--         \/     \/         \/     \/                    \/     \/ 

-- ╔═══════════════════════════════════════════════════════════╗
-- ║                V E L V E T   M O T I O N                  ║
-- ╚═══════════════════════════════════════════════════════════╝

-- ─── Bézier curves ──────────────────────────────────────────
hl.curve("velvetOut",   { type="bezier", points={{0.08,0.96},{0.16,1.00}} })
hl.curve("velvetIn",    { type="bezier", points={{0.32,0.00},{0.14,0.98}} })
hl.curve("silkEase",    { type="bezier", points={{0.16,0.06},{0.20,1.00}} })
hl.curve("breathe",     { type="bezier", points={{0.24,0.00},{0.52,1.00}} })
hl.curve("snapDrift",   { type="bezier", points={{0.04,0.84},{0.14,1.00}} })
hl.curve("snapClose",   { type="bezier", points={{1.0,0.90},{1.0,0.10}} })
hl.curve("ghostFade",   { type="bezier", points={{0.00,0.00},{0.72,1.00}} })

-- ─── Springs ────────────────────────────────────────────────
hl.curve("windowSettle",{ type="spring", mass=1, stiffness=110, dampening=26 })
hl.curve("windowBirth", { type="spring", mass=1, stiffness=130, dampening=20 })
hl.curve("windowGlide", { type="spring", mass=1, stiffness=200, dampening=34 })
hl.curve("floorLift",   { type="spring", mass=1, stiffness=125, dampening=28 })

-- ─── Global ─────────────────────────────────────────────────
hl.animation({ leaf="global",  enabled=true, speed=6.5, bezier="velvetOut" })
hl.animation({ leaf="border",  enabled=true, speed=8.2, bezier="silkEase"  })

-- ─── Windows ────────────────────────────────────────────────
hl.animation({ leaf="windows",     enabled=true, speed=4.2, spring="windowSettle" })
hl.animation({ leaf="windowsIn",   enabled=true, speed=3.8, spring="windowBirth",  style="popin 88%" })
hl.animation({ leaf="windowsOut",  enabled=true, speed=3.0, bezier="snapClose",    style="popin 25%" })
hl.animation({ leaf="windowsMove", enabled=true, speed=6.0, spring="windowGlide"  })

-- ─── Fades ──────────────────────────────────────────────────
hl.animation({ leaf="fade",    enabled=true, speed=1.8, bezier="breathe"   })
hl.animation({ leaf="fadeIn",  enabled=true, speed=1.4, bezier="velvetIn"  })
hl.animation({ leaf="fadeOut", enabled=true, speed=1.0, bezier="ghostFade" })

-- ─── Layers ─────────────────────────────────────────────────
hl.animation({ leaf="layers",        enabled=true, speed=4.4, bezier="velvetOut" })
hl.animation({ leaf="layersIn",      enabled=true, speed=3.6, bezier="silkEase",  style="slide bot" })
hl.animation({ leaf="layersOut",     enabled=true, speed=2.8, bezier="snapClose", style="slide bot" })
hl.animation({ leaf="fadeLayersIn",  enabled=true, speed=1.0, bezier="velvetIn"  })
hl.animation({ leaf="fadeLayersOut", enabled=true, speed=0.8, bezier="ghostFade" })

-- ─── Workspaces ─────────────────────────────────────────────
hl.animation({ leaf="workspaces",    enabled=true, speed=4.4, spring="floorLift", style="slidefadevert 20%" })
hl.animation({ leaf="workspacesIn",  enabled=true, speed=4.0, bezier="snapDrift", style="slidefadevert 20%" })
hl.animation({ leaf="workspacesOut", enabled=true, speed=4.4, bezier="velvetOut", style="slidefadevert 20%" })

-- ─── Zoom ───────────────────────────────────────────────────
hl.animation({ leaf="zoomFactor", enabled=true, speed=6.8, bezier="silkEase" })