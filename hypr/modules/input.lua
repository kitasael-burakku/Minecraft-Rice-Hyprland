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
        
        repeat_rate = 50,
        repeat_delay = 250
    },
})

-- Config por dispositivo
-- Ver https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
--
-- OJO CON EL NOMBRE: tiene que ser el SLUG que imprime `hyprctl devices`
-- (minúsculas, cada tanda de caracteres no alfanuméricos colapsada a un
-- guión), no el nombre bonito del dispositivo. Un bloque cuyo nombre no
-- empareja NO da error: se ignora en silencio, y para colmo
-- `hyprctl eval` responde "ok" igual, porque valida la llamada y no que
-- el nombre case con algo. Estos dos bloques estuvieron sin aplicarse
-- justamente por eso hasta 2026-09-01.
--
-- Para ver los nombres válidos:  hyprctl devices

-- Mouse --
hl.device({
    name          = "logitech-g203-lightsync-gaming-mouse",
    -- 0 = sin modificar. El valor original acá era -0.5, pero nunca llegó
    -- a aplicarse (nombre mal escrito), así que al arreglar el nombre se
    -- deja en neutro a propósito para no cambiar el tacto de golpe.
    sensitivity   = 0,
    accel_profile = "flat"
})

-- Teclado --
-- Repite kb_layout/kb_options del hl.config global de arriba. Es
-- redundante, y es la razón por la que el teclado sí funcionaba mientras
-- este bloque estaba muerto: lo que lo hacía andar era el global.
hl.device({
    name       = "shinetek-technology-usb-gaming-keyboard",
    kb_layout  = "us,es",
    kb_options = "grp:alt_shift_toggle",
})