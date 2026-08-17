-- ________                                    __  .__               
-- \______ \   ____   ____  ________________ _/  |_|__| ____   ____  
--  |    |  \_/ __ \_/ ___\/  _ \_  __ \__  \\   __\  |/  _ \ /    \ 
--  |    `   \  ___/\  \__(  <_> )  | \// __ \|  | |  (  <_> )   |  \
-- /_______  /\___  >\___  >____/|__|  (____  /__| |__|\____/|___|  /
--         \/     \/     \/                 \/                    \/ 

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 10,
        gaps_out = 30,

        border_size = 2,

        -- Teal Kitasan Glass, no blanco — misma identidad de reposo que
        -- hypr/scripts/dynamic-colors.static.sh (fuente de verdad), para que
        -- un arranque en frío y un "apagar el toggle" luzcan igual.
        col = {
            active_border = "rgba(7ab8b8cc)",
            inactive_border = "rgba(7ab8b80f)",
        },

        resize_on_border         = true,
        extend_border_grab_area  = 18,
        hover_icon_on_border     = true,

        allow_tearing = false,
    },

    decoration = {
        rounding       = 20,
        rounding_power = 2.5,

        active_opacity   = 0.9,
        inactive_opacity = 0.8,
        fullscreen_opacity = 1,

        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            sharp = false,
            color = "rgba(0,0,0,0.55)",
            offset = { 0, 5 },
            scale = 1.0,
        },

        blur = {
            enabled  = true,
            size     = 5,
            passes   = 2,

            ignore_opacity    = true,
            new_optimizations = true,

            xray = false,

            special = true,

            vibrancy =0.18,
            vibrancy_darkness = 0.0,
            input_methods             = true,
            input_methods_ignorealpha = 0.20,
        },
    },

    animations = {
        enabled = true,
    },

    -- Scanout directo: manda una ventana a pantalla completa al plano de la
    -- GPU sin pasar por el compositor — una copia menos por frame y hasta un
    -- frame menos de latencia (5 ms a 200 Hz). Estaba en 0 (el default de
    -- Hyprland), y `hyprctl monitors -j` lo confirmaba con
    -- "directScanoutBlockedBy": ["USER", ...].
    --
    -- Modo 1 (sólo para ventanas que lo piden) y NO 2 (forzado): el 2 es donde
    -- aparecen los artefactos al entrar/salir de fullscreen que hicieron que
    -- Hyprland lo dejara apagado por defecto.
    --
    -- A verificar en uso real: el monitor está en bitdepth = 10
    -- (XRGB2101010) y las apps presentan buffers de 8 bits. Si el plano no
    -- acepta esa conversión, el scanout directo no se activa nunca y esto no
    -- hace nada — se comprueba con `hyprctl monitors -j | grep directScanout`
    -- estando en fullscreen: si directScanoutTo sigue en "0", revertir.
    render = {
        direct_scanout = 1,
    },
})