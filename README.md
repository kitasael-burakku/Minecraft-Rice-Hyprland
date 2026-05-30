# Minecraft-Rice-Hyprland

Minecraft-Rice-Hyprland es mi configuración personal para Hyprland inspirada en Minecraft, CachyOS y Arch Linux.

Este proyecto **NO es un instalador automático**, **NO es una configuración universal** y **NO garantiza compatibilidad con todos los sistemas**.

Su objetivo principal es servir como material de aprendizaje para usuarios que quieran entender cómo está construido un entorno Hyprland real utilizando:

- Hyprland modular en Lua
- Waybar
- Rofi
- Kitty
- Fish
- Fastfetch
- Hyprlock
- SwayNC
- Scripts personalizados

La idea de este repositorio no es copiar todo y esperar que funcione.

La idea es:

```text
Leer
↓
Entender
↓
Adaptar
↓
Aprender
↓
Construir tu propia configuración
```

Muchas configuraciones modernas utilizan instaladores automáticos que ocultan gran parte del funcionamiento interno del sistema.

Este repositorio toma la dirección opuesta.

Aquí encontrarás rutas reales, scripts reales, configuraciones reales y decisiones tomadas para un sistema de uso diario. Algunas cosas funcionarán inmediatamente, otras requerirán modificaciones, y precisamente ahí es donde ocurre el aprendizaje.

Si buscas una instalación de un clic probablemente este repositorio no sea para ti.

Si te interesa aprender cómo está construido un rice de Hyprland y entender qué hace cada archivo antes de ejecutarlo, entonces probablemente sí.

## Hardware utilizado

CPU: AMD Ryzen 7 8700F
GPU: AMD Radeon RX 7600 8GB
RAM: 16GB DDR5
Monitor: 1920x1080 @ 200Hz
OS: CachyOS

Esta configuración fue desarrollada y probada principalmente en este hardware.

## ¿A quién está dirigido?

Este repositorio puede ser útil si:

- Quieres aprender cómo se organiza un rice real.
- Te interesa Hyprland y Wayland.
- Quieres entender cómo funcionan los dotfiles.
- Te gusta modificar configuraciones y adaptarlas a tu sistema.
- Prefieres comprender lo que instalas antes de ejecutarlo.

Probablemente NO sea para ti si:

- Buscas una instalación completamente automática.
- No quieres editar archivos de configuración.
- No quieres modificar rutas, sensores o programas.
- Esperas compatibilidad garantizada.
- Quieres una configuración lista para usar sin realizar cambios.

## Screenshots

### Desktop

![Desktop](docs/screenshots/3.png)

### Waybar

![Rofi-Swaync](docs/screenshots/2.png)

### Terminal-BG

![Terminal-bg](docs/screenshots/1.png)

### Hyprlock 

![Hyprlock](docs/screenshots/4.png)

## Features

- Configuracion de Hyprland separada en modulos Lua dentro de `hypr/modules/`.
- Autostart para wallpaper animado con `mpvpaper`, Waybar, SwayNC, Hypridle, Polkit, clipboard y udiskie.
- Waybar con modulos para disco, audio, reloj, workspaces, tray, updates, red, temperatura, CPU y memoria.
- Rofi como launcher de aplicaciones y como selector para historial de clipboard.
- Kitty con Fish como shell, colores personalizados y soporte para imagenes de Fastfetch.
- Fish con Starship, Fastfetch aleatorio, aliases modernos, funciones de actualizacion y limpieza.
- Hyprlock con layout visual, wallpaper, reloj, fecha, usuario, estado de bateria y scripts MPRIS.
- SwayNC con centro de notificaciones, controles rapidos y tema `goldship`.
- Wlogout con acciones de bloqueo, salida, suspension, apagado, hibernacion y reinicio.
- Atajos para screenshots, color picker, control multimedia, scratchpad, Waybar reload y herramientas de sistema.

### Extras

Este rice utiliza terminal-bg, una herramienta creada por DaarcyDev
que permite utilizar contenido animado dentro de la terminal.

- YouTube: https://www.youtube.com/@DaarcyDev
- GitHub: https://github.com/DaarcyDev/terminal-bg

## Estructura del repo

```text
.
├── fastfetch/
├── fish/
├── hypr/
├── hyprlock/
├── kitty/
├── rofi/
├── scripts/
├── swaync/
├── waybar/
└── wlogout/
```

## Dependencias

Los nombres pueden variar segun repositorios habilitados, CachyOS, AUR o cambios de paquetes. Revisa cada paquete antes de instalarlo.

### Base recomendada para Arch/CachyOS

```bash
sudo pacman -Syu
sudo pacman -S \
  hyprland waybar kitty fish starship fastfetch rofi-wayland \
  hyprlock hypridle swaync wlogout \
  pipewire wireplumber pavucontrol playerctl \
  networkmanager network-manager-applet \
  bluez bluez-utils blueman \
  wl-clipboard cliphist grim slurp swappy \
  thunar btop udiskie polkit-kde-agent \
  jq curl imagemagick libnotify \
  pacman-contrib reflector fzf bat eza zoxide ripgrep \
  lm_sensors ttf-jetbrains-mono-nerd
```

### Dependencias AUR o por verificar

```bash
yay -S \
  mpvpaper \
  hyprshot \
  hyprpicker \
  nwg-look \
  brave-bin \
  vscodium-bin \
  cava \
  glava \
```

Marcadas como **por verificar**:

- `hyprland-lua`: este rice usa `hypr/hyprland.lua` y llamadas `hl.*`, no un `hyprland.conf` clasico. Verifica cual es el paquete/plugin/metodo correcto para tu version de Hyprland.
- `hyprshutdown`: aparece como fallback opcional en un keybind.
- `glava`: usado opcionalmente por scripts de Hyprlock si Spotify esta reproduciendo.
- `Future-black-cursors`, `Colloid-cursors`, SDDM Minecraft, Minegrub, cursores, wallpapers y assets externos: instala o reemplaza segun tu sistema.
- `obs`, `brave`, `vscodium`: son aplicaciones personales atadas a keybinds, no requisitos del entorno base.

## Antes de empezar

⚠️ Haz una copia de seguridad de tu configuración actual antes de copiar cualquier archivo.

Ejemplo:

```bash
mkdir -p ~/backup-configs

cp -r \
~/.config/hypr \
~/.config/waybar \
~/.config/kitty \
~/.config/fish \
~/backup-configs 2>/dev/null
```

Si algo sale mal podrás restaurar tu configuración anterior fácilmente.

⚠️ Lee los archivos antes de copiarlos.

⚠️ No ejecutes scripts que no entiendas.

⚠️ Revisa las rutas personales, wallpapers, sensores y programas antes de iniciar sesión en Hyprland.

## Explicación de los comandos utilizados

Si eres nuevo en Linux, esta sección explica brevemente algunos de los comandos utilizados durante la instalación.

### git clone

```bash
git clone https://github.com/usuario/repositorio.git
```

Clona (descarga) un repositorio GitHub a tu computadora.

Equivalente a descargar un ZIP, pero conservando el historial de Git.

---

### cd

```bash
cd ~/dotfiles
```

Cambia de directorio.

Permite moverte entre carpetas desde la terminal.

Ejemplo:

```bash
cd ~/.config
```

entra en la carpeta `.config`.

---

### mkdir

```bash
mkdir -p ~/.config
```

Crea directorios.

La opción `-p` crea la carpeta únicamente si no existe y evita errores si ya está creada.

---

### cp

```bash
cp archivo.txt destino/
```

Copia archivos.

Ejemplo:

```bash
cp config.fish ~/.config/fish/
```

copia el archivo a la carpeta de configuración de Fish.

---

### cp -r

```bash
cp -r hypr waybar ~/.config/
```

Copia directorios completos.

La opción `-r` significa **recursivo** y permite copiar carpetas junto con todos sus archivos internos.

Sin `-r`, Linux no copiará directorios.

---

### chmod

```bash
chmod +x script.sh
```

Agrega permisos de ejecución.

Esto permite ejecutar el archivo como programa o script.

Ejemplo:

```bash
chmod +x ~/.config/waybar/scripts/update.sh
```

---

### chsh

```bash
chsh -s /usr/bin/fish
```

Cambia la shell predeterminada del usuario.

Después de cerrar sesión y volver a entrar, Fish se abrirá automáticamente en lugar de Bash.

---

### rg (ripgrep)

```bash
rg "wallpaper" .
```

Busca texto dentro de archivos.

Muy útil para encontrar:

- rutas personales
- nombres de usuario
- sensores de hardware
- wallpapers
- variables

Ejemplo:

```bash
rg "/home/|tu-usuario|wallpaper" .
```

---

### sudo

```bash
sudo pacman -S paquete
```

Ejecuta un comando con permisos de administrador.

Se utiliza para instalar programas o modificar partes del sistema.

Úsalo únicamente cuando entiendas lo que hace el comando.

---

### pacman

```bash
sudo pacman -S paquete
```

Gestor de paquetes de Arch Linux y CachyOS.

Comandos comunes:

```bash
sudo pacman -S paquete
```

Instalar paquete.

```bash
sudo pacman -Rns paquete
```

Eliminar paquete junto con dependencias innecesarias.

```bash
sudo pacman -Syu
```

Actualizar todo el sistema.

---

### yay

```bash
yay -S paquete
```

Instala paquetes desde el AUR (Arch User Repository).

Funciona de forma similar a pacman pero permite acceder a software mantenido por la comunidad.

---

### ¿Por qué no existe un instalador automático?

Este repositorio busca enseñar cómo funciona una configuración real de Linux.

Copiar archivos manualmente permite:

- Entender dónde vive cada configuración.
- Aprender la estructura de `~/.config`.
- Saber qué programa utiliza cada archivo.
- Detectar errores más fácilmente.
- Modificar partes específicas sin depender de scripts automáticos.

La instalación manual requiere un poco más de trabajo, pero también enseña mucho más sobre el sistema.

## Instalacion manual

Este repo no es plug-and-play. Haz backup de tu configuracion actual antes de copiar nada.

```bash
git clone https://github.com/kitasael-burakku/Minecraft-Rice-Hyprland.git ~/dotfiles
cd ~/dotfiles
```

Copia las carpetas que quieras usar:

```bash
mkdir -p ~/.config
cp -r hypr waybar rofi kitty fish fastfetch hyprlock swaync wlogout scripts ~/.config/

mkdir -p ~/Documents
cp ~/dotfiles/KEYBINDS.txt ~/Documents/KEYBINDS.txt
```

Da permisos de ejecucion a los scripts:

```bash
chmod +x ~/.config/waybar/scripts/*.sh
chmod +x ~/.config/rofi/launcher.sh
chmod +x ~/.config/swaync/scripts/*.sh
chmod +x ~/.config/wlogout/scripts/*.sh
chmod +x ~/.config/hyprlock/scripts/*.sh
chmod +x ~/.config/scripts/terminal-bg-cava.sh
```

Si quieres usar Fish como shell:

```bash
chsh -s /usr/bin/fish
```

Antes de iniciar sesion en Hyprland, revisa las rutas, monitores, sensores, wallpaper y programas. Si algo no existe en tu sistema, Hyprland puede iniciar incompleto o algunos atajos no haran nada.

## Hyprland en Lua

La configuracion principal esta en:

```text
hypr/hyprland.lua
```

Ese archivo carga modulos:

```lua
require("modules.animations")
require("modules.autostart")
require("modules.decoration")
require("modules.environment")
require("modules.input")
require("modules.programs")
require("modules.keybinds")
require("modules.layout")
require("modules.misc")
require("modules.monitors")
require("modules.windowrules")
```

Esto no es el formato clasico de `hyprland.conf`. Necesitas tener funcionando el soporte de Lua para Hyprland en tu instalacion. Si tu Hyprland solo lee `hyprland.conf`, esta configuracion no cargara tal cual.

Archivos importantes:

- `hypr/modules/programs.lua`: terminal, file manager y launcher.
- `hypr/modules/keybinds.lua`: atajos de teclado, screenshots, multimedia y sesion.
- `hypr/modules/autostart.lua`: servicios y programas que arrancan con Hyprland.
- `hypr/modules/monitors.lua`: salida, modo, posicion y escala.
- `hypr/modules/input.lua`: layout de teclado y dispositivos especificos.
- `hypr/modules/environment.lua`: variables de entorno Wayland, Qt, Electron y AMD.

## Notas para principiantes

- No copies todo a ciegas. Empieza por una carpeta, prueba, y luego sigue con otra.
- Si un comando falla, ejecutalo manualmente en terminal para ver el error real.
- Las rutas con `/home/tu-usuario/...` son ejemplos. Cambialas por tu usuario o usa `$HOME` cuando el programa lo soporte.
- Los iconos dependen de Nerd Fonts. Si ves cuadros raros, instala y selecciona una Nerd Font.
- Waybar puede romper el modulo de temperatura si tu sensor no es el mismo.
- Las funciones de Fish ejecutan tareas reales como actualizar paquetes y limpiar cache. Leelas antes de usarlas.
- Los scripts de Hyprlock usan MPRIS, `playerctl`, `curl`, `jq`, `imagemagick` y datos externos como `wttr.in` o `ipinfo.io`.
- Algunas configuraciones estan pensadas para mi hardware, mis programas y mi flujo de trabajo.

## Cosas que debes cambiar

Revisa como minimo:

- `hypr/hyprlock.conf`: cambia `$hyprlockDir = home/tu-usuario/.config/hyprlock` por tu ruta real. Probablemente deberia ser algo como `/home/tu-usuario/.config/hyprlock`.
- `hypr/modules/autostart.lua`: cambia el wallpaper animado `~/Videos/wallpapersvideo/minecraft.mp4`.
- `hypr/modules/autostart.lua`: cambia o instala el cursor `Future-black-cursors`.
- `hypr/modules/environment.lua`: revisa `XCURSOR_THEME`, variables AMD y variables Qt segun tu hardware.
- `hypr/modules/input.lua`: cambia nombres de mouse/teclado si no tienes esos dispositivos.
- `hypr/modules/programs.lua`: cambia `kitty`, `thunar` o el launcher si usas otras apps.
- `hypr/modules/keybinds.lua`: cambia `brave`, `obs`, `vscodium`, rutas de screenshots y comandos que no uses.
- `waybar/config.jsonc`: cambia `hwmon-path = /sys/class/hwmon/hwmon3/temp1_input` por el sensor correcto de tu maquina.
- `waybar/config.jsonc`: revisa `pavucontrol`, `nm-connection-editor`, `kitty fish -lc 'sysupdate'` y el script de updates.
- `hyprlock/layouts/layout.conf`: cambia `~/.config/hyprlock/wallpapers/1.png` si usas otro wallpaper.
- `wlogout/style.css`: revisa las rutas `HOME`, `$HOME` y `$HOME.config`; algunas pueden necesitar una ruta absoluta porque CSS no siempre expande variables de shell.
- `fastfetch/config*.jsonc`: cambia logos, imagenes y presets si no quieres usar los assets incluidos.
- `swaync/config.json`: cambia botones como `blueman-manager`, `nwg-look` o `nm-connection-editor` si no los usas.

Para encontrar rutas absolutas o referencias personales:

```bash
rg "/home/|tu-usuario|wallpaper|hwmon|Future-black|Colloid" .
```

## Scripts y comandos detectados

Este rice referencia, entre otros:

- Hyprland/Wayland: `hyprctl`, `hyprlock`, `hypridle`, `waybar`, `swaync`, `swaync-client`, `wlogout`.
- Audio/media: `wpctl`, `pavucontrol`, `playerctl`, `cava`, `glava`.
- Screenshots/clipboard: `hyprshot`, `grim`, `slurp`, `swappy`, `wl-copy`, `wl-paste`, `cliphist`, `hyprpicker`.
- Sistema: `systemctl`, `loginctl`, `pacman`, `yay`, `checkupdates`, `paccache`, `journalctl`, `lm_sensors`.
- Red/GUI: `nm-connection-editor`, `blueman-manager`, `nwg-look`.
- Terminal/shell: `kitty`, `fish`, `starship`, `fastfetch`, `fzf`, `bat`, `eza`, `zoxide`, `ripgrep`.
- Utilidades: `curl`, `jq`, `imagemagick`/`magick`, `libnotify`/`notify-send`, `udiskie`, `reflector`.

## Creditos externos

Este repositorio mezcla configuracion propia con herramientas, temas, assets y referencias de terceros.

- Hyprland, Waybar, Rofi, Kitty, Fish, Starship, Fastfetch, Hyprlock, Hypridle, Wlogout y SwayNC pertenecen a sus respectivos proyectos.
- Minecraft es propiedad de Mojang/Microsoft. La estetica usada aqui es fan-made/personal.
- SDDM Minecraft, Minegrub, cursores, wallpapers, iconos, logos, imagenes y otros assets externos no son mios salvo que se indique explicitamente lo contrario.
- Los logos o imagenes de personajes incluidos en `fastfetch/fastfetchlogo/` y wallpapers deben tratarse como assets externos si no hay una nota clara de autoria propia.
- Nerd Fonts y JetBrains Mono Nerd Font pertenecen a sus respectivos autores/proyectos.

Si reutilizas este rice, conserva los creditos de los proyectos y assets que uses.

## Advertencias importantes

⚠️ Este proyecto está diseñado para ser leído, entendido y adaptado.

⚠️ No es una configuración universal.

⚠️ Algunas rutas contienen referencias personales y deben modificarse antes de utilizarse.

⚠️ Algunas configuraciones dependen de hardware AMD específico.

⚠️ Waybar puede requerir cambios en sensores de temperatura según tu equipo.

⚠️ Algunos scripts ejecutan acciones reales sobre el sistema.

⚠️ Wlogout puede apagar, reiniciar, suspender o hibernar el equipo.

⚠️ Las funciones de Fish pueden actualizar paquetes, limpiar cachés y modificar archivos de usuario.

⚠️ Lee cualquier script antes de ejecutarlo.

⚠️ No copies configuraciones a ciegas.

⚠️ Si algo falla, ejecuta el comando manualmente y revisa el error real en la terminal.

⚠️ Este repositorio es una referencia educativa y una base para crear tu propia configuración, no una receta cerrada.

## Estado del proyecto

Este repo representa mi rice personal en progreso. Puede tener rutas, decisiones y dependencias muy especificas de mi sistema. Usalo como material de aprendizaje y como base para crear tu propia configuracion, no como una receta cerrada.

## Filosofía del proyecto

Mi objetivo con este rice no es construir una configuración perfecta.

Mi objetivo es construir una configuración que yo pueda entender, mantener y modificar sin depender de herramientas externas o capas innecesarias de abstracción.

Prefiero:

- Configuración modular antes que archivos gigantes.
- Instalación manual antes que scripts mágicos.
- Entender antes que copiar.
- Simplicidad antes que complejidad innecesaria.
- Aprender antes que automatizar.

Si este repositorio te ayuda a aprender algo sobre Linux, Hyprland, Waybar, Fish o dotfiles, entonces ya cumplió su propósito.
