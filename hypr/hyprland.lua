--    _____                .__    .____    .__                                              
--   /  _  \_______   ____ |  |__ |    |   |__| ____  __ _____  ___                         
--  /  /_\  \_  __ \_/ ___\|  |  \|    |   |  |/    \|  |  \  \/  /                         
-- /    |    \  | \/\  \___|   Y  \    |___|  |   |  \  |  />    <                          
-- \____|__  /__|    \___  >___|  /_______ \__|___|  /____//__/\_ \                         
--         \/            \/     \/        \/       \/            \/                         
--                                       ____  ___                                         
--                                       \   \/  /                                         
--                                        \     /                                          
--                                        /     \                                          
--                                       /___/\  \                                         
--                                             \_/                                         
--                                ___ ___                      .__                     .___
--                               /   |   \ ___.__._____________|  | _____    ____    __| _/
--                              /    ~    <   |  |\____ \_  __ \  | \__  \  /    \  / __ | 
--                              \    Y    /\___  ||  |_> >  | \/  |__/ __ \|   |  \/ /_/ | 
--                               \___|_  / / ____||   __/|__|  |____(____  /___|  /\____ | 
--                                     \/  \/     |__|                   \/     \/      \/ 

-- Organizancion de los archivos de Hyprland 
-- Modules: LLeva los modulos de hyprland que son necesarios para su configuracion original 
-- Plugins: Son los plugins del sistema que estan instalados y su configuracion va ahi 

require("modules.environment")

require("modules.monitors")
require("modules.input")

require("modules.animations")
require("modules.decoration")

require("modules.layout")
require("modules.windowrules")

require("modules.programs")
require("modules.keybinds")

require("modules.misc")
require("modules.autostart")

-- Plugins
require("plugins.hyprglass")
require("plugins.dym-cursor")