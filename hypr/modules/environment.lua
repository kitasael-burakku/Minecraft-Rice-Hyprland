-- ___________           .__                                            __   
-- \_   _____/ _______  _|__|______  ____   ____   _____   ____   _____/  |_ 
--  |    __)_ /    \  \/ /  \_  __ \/  _ \ /    \ /     \_/ __ \ /    \   __\
--  |        \   |  \   /|  ||  | \(  <_> )   |  \  Y Y  \  ___/|   |  \  |  
-- /_______  /___|  /\_/ |__||__|   \____/|___|  /__|_|  /\___  >___|  /__|  
--         \/     \/                           \/      \/     \/     \/      

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Variables
CursorTheme = "Future-black-cursors"
GTKTheme = "Win11-Fantasy-Dark"

-- Nombre bonito de la máquina. Vive acá y no en `hostnamectl --pretty`
-- porque el prompt (starship, [env_var.HOSTNAME_PRETTY]) lo lee en CADA
-- render: la variante hostnamectl no lee un archivo, abre D-Bus contra
-- systemd-hostnamed y lo activa si no estaba corriendo — 59 ms medidos por
-- prompt, sobre un dato que no cambia entre logins. Como variable de entorno
-- el mismo dato cuesta 0.
-- Valor personal: cambiar al clonar, igual que monitors.lua e input.lua.
HostnamePretty = "ゴールドシップ"

-- Theme
hl.env("XCURSOR_THEME", CursorTheme)
hl.env("XCURSOR_SIZE", "24")
hl.env("HOSTNAME_PRETTY", HostnamePretty)

-- SIN hl.env("GTK_THEME", GTKTheme): el tema ya está declarado en
-- gtk-3.0/settings.ini (gtk-theme-name), que es el canal normal. GTK_THEME
-- como variable de entorno es un override duro que gana sobre settings.ini
-- para TODA app GTK, así que el mismo dato vivía en dos lugares y uno tapaba
-- al otro. Queda settings.ini como fuente única.
--
-- OJO: la variable Lua GTKTheme de arriba NO se puede borrar —
-- hypr/scripts/apply-static-colors.sh la lee con
-- grep -oP '(?<=^GTKTheme = ")[^"]+' para recrear el symlink
-- gtk-4.0/theme-base.css. Sin ella se rompe el bootstrap de un clon nuevo.

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

-- GSK_RENDERER quitado. Medido con GSK_DEBUG=renderer sobre GTK 4.22.4:
--   con GSK_RENDERER=gl  -> "trying GskGLRenderer" / usa GskGLRenderer
--   sin la variable      -> usa GskVulkanRenderer
-- O sea: no era un no-op, estaba forzando el renderer viejo de OpenGL. En una
-- RX 7600 (RDNA3) con vulkan-radeon instalado, el camino Vulkan es el que GTK
-- elige solo y el que está mejor mantenido río arriba.
--
-- El comentario anterior decía "keep only if GTK apps render correctly", así
-- que en algún momento esto arregló un glitch real — pero fue con una versión
-- de GTK bastante anterior. Si vuelve a aparecer algo raro en apps GTK4
-- (nautilus, portales), restaurar con:  hl.env("GSK_RENDERER", "gl")