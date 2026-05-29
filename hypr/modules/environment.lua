-- ___________           .__                                            __   
-- \_   _____/ _______  _|__|______  ____   ____   _____   ____   _____/  |_ 
--  |    __)_ /    \  \/ /  \_  __ \/  _ \ /    \ /     \_/ __ \ /    \   __\
--  |        \   |  \   /|  ||  | \(  <_> )   |  \  Y Y  \  ___/|   |  \  |  
-- /_______  /___|  /\_/ |__||__|   \____/|___|  /__|_|  /\___  >___|  /__|  
--         \/     \/                           \/      \/     \/     \/      

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Cursor settings
hl.env("XCURSOR_THEME", "Colloid-cursors")
hl.env("XCURSOR_SIZE", "20")

-- Toolkit Backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG Desktop Portal
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt Variables
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- AMD Specific
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("LIBVDPAU_DRIVER", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")

-- Graphics & Rendering
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GSK_RENDERER", "ngl")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")