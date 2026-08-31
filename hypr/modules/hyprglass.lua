-- Hyprglass — vidrio esmerilado sobre las ventanas translúcidas.
--
-- Plugin externo, no forma parte de Hyprland: github.com/hyprnux/hyprglass
-- Se instala con hyprpm, que guarda el .so compilado en
-- /var/cache/hyprpm/$USER/ (de root: por eso pide sudo).
--
-- Apagarlo entero = comentar el require("modules.hyprglass") de hyprland.lua.
-- Estado y diagnóstico = `checkhyprglass` en fish.
--
-- OJO: hyprctl reload NO re-ejecuta los módulos require'd. Para aplicar
-- cambios de este archivo sin reiniciar la sesión:
--   hyprctl eval 'dofile("/home/kitasa-elburakku/.config/hypr/modules/hyprglass.lua")'

-- ── Guarda ───────────────────────────────────────────────────────────────────
-- El plugin puede perfectamente no estar cargado: tras cada update de Hyprland
-- hyprpm necesita un `hyprpm update`, y hasta entonces no carga nada. Sin esta
-- guarda, arrancar en ese estado revienta con "attempt to index a nil value" y
-- se lleva por delante el resto de la config, no solo el vidrio.
if not (hl.plugin and hl.plugin.hyprglass) then
    return
end

local hg = hl.plugin.hyprglass

-- ── Preset "liquid" — el look de iOS 26 ──────────────────────────────────────
-- Preset propio en vez de tocar los globales, para que los cuatro built-in
-- (high_contrast, subtle, clear, glass) sigan intactos y se puedan comparar en
-- caliente:  hyprctl dispatch tagwindow +hyprglass_preset_glass
--
-- El orden de resolución del plugin es:
--   variante de tema del preset -> parte compartida -> preset heredado
--   -> override de tema -> valor global -> default del código
-- Por eso lo específico de dark/light va en sus sub-tablas y el resto en la
-- raíz, que es la parte compartida.
--
-- La idea del Liquid Glass de Apple no es "mucho desenfoque": es un canto
-- grueso que refracta como lente de verdad, con un brillo especular marcado,
-- y el fondo todavía reconocible detrás. Frost moderado, borde protagonista.
hg.preset("liquid", {
    -- Refracción alta: es el rasgo que hace que se lea como cristal y no como
    -- un panel translúcido. El canto arrastra hacia dentro lo que hay más allá
    -- del borde de la ventana. Rango 0.0-1.0.
    refraction_strength = 1,

    -- Bisel con cuerpo. El default 0.06 deja un filo delgado que se pierde;
    -- Apple usa un canto ancho. Máximo admitido 0.15.
    edge_thickness = 0.10,

    -- El glint que recorre el borde superior, y el halo del canto.
    specular_strength = 0.60,
    fresnel_strength  = 0.50,

    -- Frost moderado a propósito: blur_strength son valor × 12 px, así que
    -- esto son ~15.6 px. El default 2.0 (24 px) lechea el fondo y mata la
    -- sensación de vidrio; en iOS todavía distingues lo que hay detrás.
    -- Cuatro pasadas para que la caída sea limpia y no bandee (máx 5).
    blur_strength   = 0.45,
    blur_iterations = 4,

    -- Dispersión espectral en el canto. Presente, pero sin arcoíris: el
    -- default 0.5 se nota demasiado y delata el efecto. Rango 0.0-1.0.
    chromatic_aberration = 0.20,

    -- Domo central sutil. La superficie no es plana, magnifica un pelo por el
    -- centro. Subirlo mucho hace efecto ojo de pez.
    lens_distortion = 0.50,

    glass_opacity = 1.0,

    -- Casi incoloro, que es como es el vidrio de Apple: el color lo aporta lo
    -- que hay detrás, no el material. Los dos últimos dígitos son la alpha =
    -- fuerza del tinte; 0x18 es un susurro frío.
    --
    -- Elegido neutro también por una razón práctica: matugen regenera
    -- hypr/dynamic-colors.sh con cada wallpaper, y este tinte no está en esa
    -- tubería. Neutro nunca queda desincronizado.
    tint_color = 0xf2f4ff18,

    dark = {
        -- Los defaults de dark (brightness 0.82, saturation 0.80,
        -- vibrancy 0.15) apagan bastante. Apple mantiene el material vivo.
        brightness = 0.88,
        contrast   = 0.92,
        saturation = 0.92,
        vibrancy   = 0.28,

        -- Oscurece las zonas claras del fondo para que lo que va encima del
        -- vidrio siga siendo legible. Es de las cosas que más "sistema
        -- operativo de Apple" hacen ver al material. Default dark 0.4.
        adaptive_dim = 0.55,
    },

    light = {
        brightness     = 1.10,
        contrast       = 0.94,
        saturation     = 0.95,
        vibrancy       = 0.22,
        -- El simétrico: en tema claro se aclaran las zonas oscuras.
        adaptive_boost = 0.50,
    },
})

-- ── Ajustes globales ─────────────────────────────────────────────────────────
-- Se escribe en forma anidada en vez de con hg.config(). Las dos funcionan en
-- 0.56.2 (comprobado en vivo con hyprctl eval), pero hg.config() aplana las
-- claves a "plugin.hyprglass.x.y" y el issue #71 del repo reporta builds donde
-- hl.config las descarta sin avisar. La anidada no depende de eso.
hl.config({
    plugin = {
        hyprglass = {
            enabled = 1,

            -- Fijo en dark: el resto del sistema ya lo es
            -- (GTKTheme = "Adwaita-dark" en modules/environment.lua).
            default_theme = "dark",

            -- El preset de arriba. Para comparar con los built-in basta
            -- cambiar esta línea por "glass", "high_contrast", "subtle" o
            -- "clear" y re-aplicar con el dofile del encabezado.
            default_preset = "liquid",

            -- El plugin pone `noblur` en las ventanas a las que aplica vidrio.
            -- No es opcional de facto: sin eso, la caché de blur:new_optimizations
            -- de Hyprland se captura antes de que dibujen las decoraciones del
            -- plugin y el vidrio solo se ve mientras arrastras la ventana.
            -- Efecto secundario: el blur afinado de modules/decoration.lua
            -- (size 10, passes 2, vibrancy 0.18) deja de aplicar en esas
            -- ventanas y manda el blur_strength del preset.
            manage_window_blur = 1,

            layers = {
                -- Apagado — que además ya es el default del plugin.
                --
                -- Dos razones. Una: el vidrio sobre layer surfaces engancha
                -- `renderLayer`, una función interna privada de Hyprland, y el
                -- propio README avisa de que el hook puede romperse en
                -- cualquier update que cambie su firma. Waybar y swaync ya se
                -- caen solos en esta máquina.
                -- Dos: no aporta. modules/windowrules.lua ya les da blur
                -- nativo (blur = true en los layer_rule de waybar, swaync,
                -- rofi y wlogout), que es estable y lleva tiempo funcionando.
                --
                -- Si algún día se enciende: las sombras de los layers cuentan
                -- como contenido visible, así que hace falta mask_threshold
                -- por encima de la alpha de la sombra o se glasea el hueco.
                enabled = 0,
            },
        },
    },
})

-- ── Dónde no quiero vidrio ───────────────────────────────────────────────────
-- El plugin solo actúa sobre ventanas con transparencia, así que lo opaco
-- queda fuera solo. Estas reglas son para lo translúcido que igual no debería
-- llevarlo.
--
-- Los tags que entiende el plugin (src/PluginConfig.hpp):
--   hyprglass_disabled        apaga el vidrio ahí (gana sobre _enabled)
--   hyprglass_enabled         lo fuerza aunque el global esté en 0
--   hyprglass_preset_<nombre> usa otro preset solo ahí
--   hyprglass_theme_<nombre>  usa otro tema solo ahí
-- En caliente: hyprctl dispatch tagwindow +hyprglass_preset_subtle

-- Vídeo: el vidrio re-muestrea el fondo. Sobre imagen en movimiento eso es
-- coste de GPU sostenido, y el issue #59 del repo describe que el re-render se
-- queda corto justo en ese caso, así que además se ve desfasado.
hl.window_rule({
    name  = "hyprglass-off-video",
    match = { class = "^(mpv)$" },
    tag   = "+hyprglass_disabled",
})

-- Fullscreen: a pantalla completa no hay "detrás" que refractar, solo coste.
-- Además decoration.lua ya pone fullscreen_opacity = 1, así que en la práctica
-- estas ventanas ya son opacas; esto lo hace explícito y ahorra el trabajo.
hl.window_rule({
    name  = "hyprglass-off-fullscreen",
    match = { fullscreen = true },
    tag   = "+hyprglass_disabled",
})
