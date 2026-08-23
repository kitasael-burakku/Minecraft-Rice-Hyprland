-- ___________           .__                                            __   
-- \_   _____/ _______  _|__|______  ____   ____   _____   ____   _____/  |_ 
--  |    __)_ /    \  \/ /  \_  __ \/  _ \ /    \ /     \_/ __ \ /    \   __\
--  |        \   |  \   /|  ||  | \(  <_> )   |  \  Y Y  \  ___/|   |  \  |  
-- /_______  /___|  /\_/ |__||__|   \____/|___|  /__|_|  /\___  >___|  /__|  
--         \/     \/                           \/      \/     \/     \/      

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Variables
CursorTheme = "Nordic_Cursors_Scalable"
GTKTheme = "Win11-Fantasy-Dark"

-- Nombre bonito de la máquina. Vive acá y no en `hostnamectl --pretty`
-- Valor personal: cambiar al clonar, igual que monitors.lua e input.lua.
HostnamePretty = "ゴールドシップ"

-- Theme
hl.env("XCURSOR_THEME", CursorTheme)
hl.env("XCURSOR_SIZE", "24")
hl.env("HOSTNAME_PRETTY", HostnamePretty)

-- Toolkit Backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- XDG Desktop Portal / Session
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt Variables
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Electron / Chromium
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- AMD / Mesa video acceleration
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")

-- Firefox / Java / GTK rendering
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")