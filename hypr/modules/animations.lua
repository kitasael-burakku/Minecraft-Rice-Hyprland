--  ██▀███ ▓██   ██▓ █    ██   ██████  █    ██  ██▓
-- ▓██ ▒ ██▒▒██  ██▒ ██  ▓██▒▒██    ▒  ██  ▓██▒▓██▒
-- ▓██ ░▄█ ▒ ▒██ ██░▓██  ▒██░░ ▓██▄   ▓██  ▒██░▒██▒
-- ▒██▀▀█▄   ░ ▐██▓░▓▓█  ░██░  ▒   ██▒▓▓█  ░██░░██░
-- ░██▓ ▒██▒ ░ ██▒▓░▒▒█████▓ ▒██████▒▒▒▒█████▓ ░██░
-- ░ ▒▓ ░▒▓░  ██▒▒▒ ░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░░▒▓▒ ▒ ▒ ░▓
--
-- ║   流 水   ·   R Y Ū S U I   M O T I O N   · v2 (0.56+)
-- ║   agua sobre vidrio · flowing water on glass

-- ─── Bézier curves ──────────────────────────────────────────────────────
hl.curve("ryuOut",     { type="bezier", points={{0.16,1.00},{0.30,1.00}} })
hl.curve("currentIn",  { type="bezier", points={{0.32,0.00},{0.18,1.00}} })
hl.curve("meniscus",   { type="bezier", points={{0.25,0.10},{0.25,1.00}} })
hl.curve("stillWater", { type="bezier", points={{0.37,0.00},{0.63,1.00}} })
hl.curve("undertow",   { type="bezier", points={{0.40,0.00},{0.85,0.55}} })
hl.curve("ripple",     { type="bezier", points={{0.20,1.08},{0.32,1.00}} })
hl.curve("dissolve",   { type="bezier", points={{0.45,0.00},{0.80,0.85}} })

-- ─── Spring-feel beziers ────────────────────────────────────────────────
hl.curve("settleFeel", { type="bezier", points={{0.22,1.04},{0.36,1.00}} })
hl.curve("birthFeel",  { type="bezier", points={{0.18,1.10},{0.30,1.00}} })
hl.curve("glideFeel",  { type="bezier", points={{0.20,0.95},{0.25,1.00}} })
hl.curve("tideFeel",   { type="bezier", points={{0.24,1.05},{0.35,1.00}} })

-- ─── Global ─────────────────────────────────────────────────────────────
hl.animation({ leaf="global",  enabled=true, speed=3.0, bezier="ryuOut"  })
hl.animation({ leaf="border",  enabled=true, speed=5.0, bezier="meniscus"})

-- ─── Windows ──────────────────────────────────────────────────────────────────────────────────────
hl.animation({ leaf="windows",     enabled=true, speed=3.0, bezier="settleFeel"                    })
hl.animation({ leaf="windowsIn",   enabled=true, speed=2.6, bezier="birthFeel",  style="popin 87%" })
hl.animation({ leaf="windowsOut",  enabled=true, speed=1.0, bezier="undertow",   style="popin 70%" })
hl.animation({ leaf="windowsMove", enabled=true, speed=3.8, bezier="glideFeel"                     })

-- ─── Fades ──────────────────────────────────────────────────────────────────
hl.animation({ leaf="fade",     enabled=true, speed=1.3, bezier="stillWater" })
hl.animation({ leaf="fadeIn",   enabled=true, speed=1.1, bezier="ryuOut"     })
hl.animation({ leaf="fadeOut",  enabled=true, speed=0.8, bezier="dissolve"   })

-- ─── Layers ───────────────────────────────────────────────────────────────────────────────────────
hl.animation({ leaf="layers",        enabled=true, speed=2.8, bezier="ryuOut"                      })
hl.animation({ leaf="layersIn",      enabled=true, speed=2.2, bezier="ripple",   style="slide bot" })
hl.animation({ leaf="layersOut",     enabled=true, speed=1.8, bezier="undertow", style="slide bot" })

-- ─── Workspaces ───────────────────────────────────────────────────────────────────────────────────────────
hl.animation({ leaf="workspaces",    enabled=true, speed=2.8, bezier="tideFeel", style="slidefadevert" })

-- ─── Zoom ───────────────────────────────────────────────────────────────────
hl.animation({ leaf="zoomFactor", enabled=true, speed=4.0, bezier="meniscus" })