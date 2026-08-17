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

    -- Scanout directo: manda la ventana en pantalla completa al plano de la
    -- GPU sin pasar por el compositor — una copia menos por frame y hasta un
    -- frame menos de latencia (5 ms a 200 Hz).
    --
    -- Modo 1 (sólo ventanas que lo piden) y NO 2 (forzado): el 2 es donde
    -- aparecen los artefactos al entrar/salir de fullscreen que hicieron que
    -- Hyprland lo dejara apagado por defecto.
    --
    -- VERIFICADO EN VIVO (2026-08-17), con mpv --fs como cliente opaco:
    --
    --   direct_scanout=0 -> directScanoutTo "0",  blockedBy ["USER"]
    --                       currentFormat XRGB2101010
    --   direct_scanout=1 -> directScanoutTo <addr de la ventana>, blockedBy null
    --                       currentFormat "Invalid" (= escanea el buffer
    --                       del cliente, no compone)
    --
    -- Reproducido dos veces. Se había revertido antes creyendo que no hacía
    -- nada, y sospechando que bitdepth = 10 (XRGB2101010, ver
    -- modules/monitors.lua) impedía el scanout de buffers de 8 bits. Falso:
    -- funciona con bitdepth = 10 puesto. Para que se active hacen falta dos
    -- condiciones que sí importan y son fáciles de no cumplir sin darse
    -- cuenta:
    --   1. La ventana tiene que ser "solitary" — fullscreen real, nada
    --      encima. Un juego en borderless-windowed o un vídeo en fullscreen
    --      de navegador no califican.
    --   2. Tiene que ser opaca. Lo es gracias a fullscreen_opacity = 1 de
    --      acá arriba; con active_opacity 0.9 sola, ninguna ventana
    --      calificaría nunca.
    -- Planificación de frames alternativa que Hyprland 0.56 todavía no activa
    -- por defecto. Donde más debería notarse es justo en este setup: 200 Hz
    -- con VRR activo, que es el caso que más castiga un pacing malo.
    --
    -- Activado 2026-08-17. Marcado como experimental río arriba, pero acá ya
    -- tiene veredicto: el movimiento se siente más firme, y el "medio raro"
    -- que había antes desapareció. Es una evaluación subjetiva y no puede ser
    -- otra cosa — esto no cambia CPU ni GPU, cambia CUÁNDO se presenta cada
    -- frame, así que ningún contador lo mide. Se queda.
    --
    -- Si alguna vez aparece un glitch de presentación raro (tearing donde no
    -- debería, stutter al cambiar de refresh), éste es el primer sospechoso:
    -- borrar la línea y volver a probar antes de investigar nada más.
    render = {
        direct_scanout = 1,
        new_render_scheduling = true,
    },
})