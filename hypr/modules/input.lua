-- .___                      __   
-- |   | ____ ______  __ ___/  |_ 
-- |   |/    \\____ \|  |  \   __\
-- |   |   |  \  |_> >  |  /|  |  
-- |___|___|  /   __/|____/ |__|  
--          \/|__|                

hl.config({
    input = {
        kb_layout  = "us,es",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification
    },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more

-- Mouse --
hl.device({
    name        = "Logitech G203 LIGHTSYNC Gaming Mouse",
    sensitivity = -0.5,
    accel_profile = "flat"
})

-- Teclado --
hl.device ({
  name = "Shinetek Technology USB Gaming Keyboard",
    kb_layout  = "us,es",
    kb_options = "grp:alt_shift_toggle",
})