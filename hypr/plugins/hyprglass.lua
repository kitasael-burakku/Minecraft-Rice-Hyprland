-- Hyprglass — vidrio esmerilado. Plugin externo vía hyprpm.
-- github.com/hyprnux/hyprglass · el .so vive en /var/cache/hyprpm/$USER/
-- Aplicar cambios sin reiniciar (hyprctl reload no re-ejecuta los require'd):
--   hyprctl eval 'dofile("~/.config/hypr/plugins/hyprglass.lua")'

-- Si un update de Hyprland deja el plugin sin cargar, sin esta guarda revienta
-- toda la config, no solo el vidrio.
if not (hl.plugin and hl.plugin.hyprglass) then
    return
end

local hg = hl.plugin.hyprglass

-- ── Preset "liquid" ──────────────────────────────────────────────────────────
hg.preset("liquid", {
    refraction_strength  = 1.5,   -- el canto dobla lo de atrás; es la firma
    edge_thickness       = 0.15,  -- fracción de la dimensión MENOR
    specular_strength    = 0.1,
    fresnel_strength     = 0.1,
    blur_strength        = 0.80,  -- × 12 = px reales
    blur_iterations      = 1,
    chromatic_aberration = 0.85,
    lens_distortion      = 1.4,   -- domo central; escala con la dimensión menor
    glass_opacity        = 0.95,
    tint_color           = 0xf2f4ff18,  -- RRGGBBAA, los 2 últimos = fuerza

    -- Los defaults de dark (brightness 0.82, saturation 0.80, vibrancy 0.15)
    -- apagan de más.
    dark = {
        brightness   = 0.80,
        contrast     = 0.98,
        saturation   = 0.92,
        vibrancy     = 0.28,
        adaptive_dim = 0.10,  -- oscurece lo brillante detrás para que se lea
    },

    light = {
        brightness     = 1.10,
        contrast       = 0.94,
        saturation     = 0.95,
        vibrancy       = 0.22,
        adaptive_boost = 0.50,  -- el simétrico: aclara lo oscuro
    },
})

-- ── Globales ─────────────────────────────────────────────────────────────────
hl.config({
    plugin = {
        hyprglass = {
            enabled        = 1,
            default_theme  = "dark",
            default_preset = "liquid",

            -- Pone `noblur` en las ventanas glaseadas. Sin esto el vidrio solo
            -- se ve al arrastrar (la caché de blur:new_optimizations se captura
            -- antes que las decoraciones del plugin). Efecto secundario: el
            -- blur de decoration.lua deja de aplicar ahí.
            manage_window_blur = 1,

            layers = { enabled = 1 },
        },
    },
})

-- ── Vidrio en layer surfaces ─────────────────────────────────────────────────
-- Engancha `renderLayer`, un interno privado: puede romperse en updates.
-- Solo rofi — waybar, swaync y wlogout se probaron y se descartaron; se quedan
-- con blur nativo en modules/windowrules.lua. Rofi ahí NO lleva blur nativo, o
-- se sumaría al vidrio (el plugin no lo apaga en layers, solo en ventanas).
--
-- ns: match EXACTO. Los de swaync son "swaync-control-center" y
-- "swaync-notification-window", no "swaync". Verificar con `hyprctl layers`.
-- mask: alpha mínima para glasear. Las sombras del layer cuentan como
-- contenido, así que con el default (0.001) se glasea también su hueco.
local glassed_layers = {
    { ns = "rofi", preset = "liquid", mask = 0.05 },
}

-- Vía config de texto y no hg.layer(): esa solo encola, y el commit ocurre en
-- config.reloaded, que antes vacía la cola y repuebla desde estas cadenas.
-- Como reload no re-ejecuta los módulos, hg.layer() no vuelve y el filtro queda
-- vacío — y vacío significa glasear TODOS los layers, wallpaper incluido.
local ns_list, ns_presets, ns_thresholds = {}, {}, {}
for _, layer in ipairs(glassed_layers) do
    table.insert(ns_list,       layer.ns)
    table.insert(ns_presets,    layer.ns .. ":" .. layer.preset)
    table.insert(ns_thresholds, layer.ns .. "=" .. layer.mask)
end

hl.config({
    plugin = {
        hyprglass = {
            layers = {
                namespaces                = table.concat(ns_list, ","),
                namespace_presets         = table.concat(ns_presets, ","),
                namespace_mask_thresholds = table.concat(ns_thresholds, ","),
            },
        },
    },
})

-- ── Dónde no ─────────────────────────────────────────────────────────────────
-- Tags: hyprglass_disabled / _enabled / _preset_<n> / _theme_<n>
-- En caliente: hyprctl dispatch tagwindow +hyprglass_preset_subtle

-- El vidrio re-muestrea el fondo en cada frame: sobre vídeo es coste constante
-- y encima se ve desfasado (issue #59).
hl.window_rule({
    name  = "hyprglass-off-video",
    match = { class = "^(mpv)$" },
    tag   = "+hyprglass_disabled",
})

-- A pantalla completa no hay "detrás" que refractar, solo coste.
hl.window_rule({
    name  = "hyprglass-off-fullscreen",
    match = { fullscreen = true },
    tag   = "+hyprglass_disabled",
})
