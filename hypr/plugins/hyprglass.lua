-- Hyprglass — vidrio esmerilado sobre las ventanas translúcidas.
--
-- Plugin externo, no forma parte de Hyprland: github.com/hyprnux/hyprglass
-- Se instala con hyprpm, que guarda el .so compilado en
-- /var/cache/hyprpm/$USER/ (de root: por eso pide sudo).
--
-- Apagarlo entero = comentar el require("plugins.hyprglass") de hyprland.lua.
-- Estado y diagnóstico = `checkhyprglass` en fish.

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
hg.preset("liquid", {

    -- Refracción alta: Rango 0.0-1.0.
    refraction_strength = 1,

    -- Bisel con cuerpo. Máximo admitido 0.15.
    edge_thickness = 0.15,

    -- El glint que recorre el borde superior, y el halo del canto.
    specular_strength = 0.1,
    fresnel_strength  = 0.1,

    -- Frost.
    blur_strength   = 0.4,
    blur_iterations = 2,

    -- Dispersión espectral en el canto.
    chromatic_aberration = 0.5,

    -- Domo central sutil. La superficie no es plana, magnifica un pelo por el
    -- centro. Subirlo mucho hace efecto ojo de pez.
    lens_distortion = 1,

    glass_opacity = 1.0,

    tint_color = 0xf2f4ff18,

    dark = {
        -- Los defaults de dark (brightness 0.82, saturation 0.80,
        -- vibrancy 0.15) apagan bastante. Apple mantiene el material vivo.
        brightness = 0.88,
        contrast   = 0.92,
        saturation = 0.92,
        vibrancy   = 0.28,

        adaptive_dim = 0.35,
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
hl.config({
    plugin = {
        hyprglass = {
            enabled = 1,
            default_theme = "dark",
            default_preset = "liquid",
            manage_window_blur = 1,

            layers = {
                -- Apagado —
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
