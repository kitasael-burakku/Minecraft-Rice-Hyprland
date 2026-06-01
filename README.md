# Minecraft-Rice-Hyprland

Mi configuración personal para Hyprland inspirada en Minecraft, corriendo en CachyOS.

Este proyecto **NO es un instalador automático**, **NO es una configuración universal** y **NO garantiza compatibilidad con todos los sistemas**.

---

## Screenshots

### Desktop
![Desktop](docs/screenshots/3.png)

### Rofi + SwayNC
![Rofi-Swaync](docs/screenshots/2.png)

### Terminal con fondo animado
![Terminal-bg](docs/screenshots/1.png)

### Hyprlock
![Hyprlock](docs/screenshots/4.png)

---

## ¿Por dónde empezar?

Este repositorio está pensado para dos tipos de personas:

**Si vienes de Windows o eres nuevo en Linux →**
Lee primero la sección [Explicación de comandos](#explicación-de-los-comandos-utilizados), luego [Antes de empezar](#antes-de-empezar) y después sigue el orden del README.

**Si ya conoces Linux y dotfiles →**
Ve directo a [Estructura del repo](#estructura-del-repo), [Hyprland en Lua](#hyprland-en-lua) y [Cosas que debes cambiar](#cosas-que-debes-cambiar).

---

## Por qué existe este repositorio

Llegué a Linux desde Windows buscando más control sobre mi sistema. Empecé con Arch, cometí muchos errores, aprendí de todos ellos, y eventualmente migré a CachyOS donde construí este rice.

La mayoría de configuraciones modernas usan instaladores automáticos que ocultan cómo funciona todo por dentro. Este repositorio toma la dirección opuesta.

La idea no es copiar todo y esperar que funcione. La idea es:

```text
Leer → Entender → Adaptar → Aprender → Construir tu propia configuración
```

Aquí encontrarás rutas reales, scripts reales y decisiones tomadas para un sistema de uso diario. Algunas cosas funcionarán de inmediato, otras requerirán modificaciones, y precisamente ahí es donde ocurre el aprendizaje.

Si buscas una instalación de un clic, este repositorio probablemente no sea para ti.
Si quieres entender qué hace cada archivo antes de ejecutarlo, entonces probablemente sí.

---

## ¿A quién está dirigido?

Puede ser útil si:

- Vienes de Windows y quieres aprender Linux desde adentro.
- Quieres entender cómo se organiza y construye un rice real.
- Te interesa Hyprland, Wayland y los dotfiles.
- Prefieres comprender lo que instalas antes de ejecutarlo.
- Te gusta modificar configuraciones y adaptarlas a tu sistema.

Probablemente NO sea para ti si:

- Buscas una instalación completamente automática.
- No quieres editar archivos de configuración.
- Esperas compatibilidad garantizada sin realizar cambios.

---

## Hardware utilizado

```
CPU: AMD Ryzen 7 8700F
GPU: AMD Radeon RX 7600 8GB
RAM: 16GB DDR5
Monitor: 1920x1080 @ 200Hz
OS: CachyOS
```

Esta configuración fue desarrollada y probada en este hardware. Algunas partes dependen específicamente de AMD.

---

## Herramientas utilizadas

| Herramienta | Función |
|---|---|
| Hyprland (Lua) | Window manager modular |
| Waybar | Barra de estado |
| Rofi | Launcher y selector de clipboard |
| Kitty | Terminal |
| Fish + Starship | Shell con prompt personalizado |
| Fastfetch | Info del sistema al abrir terminal |
| Hyprlock | Pantalla de bloqueo |
| SwayNC | Centro de notificaciones |
| Wlogout | Menú de sesión |
| mpvpaper | Wallpaper animado |
| cava / glava | Visualizador de audio |
| terminal-bg | Fondo animado dentro de la terminal |
| Qylock | Tema SDDM estilo Minecraft |
| MINEGRUB | Tema GRUB estilo Minecraft |

> Qylock: https://github.com/Darkkal44/qylock
> MINEGRUB: https://github.com/Lxtharia/minegrub-theme
> terminal-bg (DaarcyDev): https://github.com/DaarcyDev/terminal-bg

---

## Features

- Configuración de Hyprland separada en módulos Lua dentro de `hypr/modules/`.
- Autostart para wallpaper animado con `mpvpaper`, Waybar, SwayNC, Hypridle, Polkit, clipboard y udiskie.
- Waybar con módulos para disco, audio, reloj, workspaces, tray, updates, red, temperatura, CPU y memoria.
- Rofi como launcher de aplicaciones y selector para historial de clipboard.
- Kitty con Fish como shell, colores personalizados y soporte para imágenes de Fastfetch.
- Fish con Starship, Fastfetch aleatorio, aliases modernos, funciones de actualización y limpieza.
- Hyprlock con layout visual, wallpaper, reloj, fecha, usuario, estado de batería y scripts MPRIS.
- SwayNC con centro de notificaciones, controles rápidos y tema `goldship`.
- Wlogout con acciones de bloqueo, salida, suspensión, apagado, hibernación y reinicio.
- Atajos para screenshots, color picker, control multimedia, scratchpad, Waybar reload y herramientas de sistema.

---

## Estructura del repo

```text
.
├── docs/screenshots/   # Capturas del rice
├── fastfetch/          # Configs jsonc, logos y presets visuales
├── fish/               # config.fish, funciones y temas de Fish shell
├── hypr/               # Hyprland Lua, módulos, hypridle.conf y hyprlock.conf base
├── hyprlock/           # Layout, colores, wallpaper y scripts de lock screen
├── kitty/              # Configuración de Kitty y colores
├── rofi/               # Launcher y tema Rofi
├── scripts/            # Scripts personales
├── swaync/             # Config, estilos, iconos y tema de notificaciones
├── waybar/             # Config, CSS y scripts de Waybar
└── wlogout/            # Layout, CSS, iconos y scripts de apagado/sesión
```

Cada carpeta va dentro de `~/.config/` en tu sistema, excepto `docs/`.

---

## Dependencias

Los nombres pueden variar según los repositorios habilitados. Revisa cada paquete antes de instalarlo.

### Base recomendada para Arch / CachyOS

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

### AUR o por verificar

```bash
yay -S \
  mpvpaper \
  hyprshot \
  hyprpicker \
  nwg-look \
  brave-bin \
  vscodium-bin \
  cava \
  glava
```

**Marcadas como por verificar:**

- `hyprland-lua`: este rice usa `hypr/hyprland.lua` con llamadas `hl.*`, no `hyprland.conf` clásico. Verifica el paquete o método correcto para tu versión de Hyprland.
- `hyprshutdown`: aparece como fallback opcional en un keybind.
- `glava`: usado opcionalmente en scripts de Hyprlock si Spotify está reproduciendo.
- `Future-black-cursors`, `Colloid-cursors`, SDDM Minecraft, Minegrub: instala o reemplaza según tu sistema.
- `obs`, `brave`, `vscodium`: aplicaciones personales atadas a keybinds, no son requisitos del entorno base.

---

## Antes de empezar

> ⚠️ Haz un backup de tu configuración actual antes de copiar cualquier archivo.

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

> ⚠️ Lee los archivos antes de copiarlos.

> ⚠️ No ejecutes scripts que no entiendas.

> ⚠️ Revisa rutas personales, wallpapers, sensores y programas antes de iniciar sesión en Hyprland.

---

## Instalación manual

Este repo no es plug-and-play.

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

Da permisos de ejecución a los scripts:

```bash
chmod +x ~/.config/waybar/scripts/*.sh
chmod +x ~/.config/rofi/launcher.sh
chmod +x ~/.config/swaync/scripts/*.sh
chmod +x ~/.config/wlogout/scripts/*.sh
chmod +x ~/.config/hyprlock/scripts/*.sh
chmod +x ~/.config/scripts/terminal-bg-cava.sh
```

Si quieres usar Fish como shell por defecto:

```bash
chsh -s /usr/bin/fish
```

Antes de iniciar sesión en Hyprland revisa rutas, monitores, sensores, wallpaper y programas. Si algo no existe en tu sistema, Hyprland puede iniciar incompleto o algunos atajos no harán nada.

---

## Hyprland en Lua

La configuración principal está en:

```text
hypr/hyprland.lua
```

Ese archivo carga módulos:

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

> Esto **no es el formato clásico** de `hyprland.conf`. Necesitas tener funcionando el soporte de Lua para Hyprland en tu instalación. Si tu Hyprland solo lee `hyprland.conf`, esta configuración no cargará tal cual.

Archivos importantes:

- `hypr/modules/programs.lua` — terminal, file manager y launcher.
- `hypr/modules/keybinds.lua` — atajos de teclado, screenshots, multimedia y sesión.
- `hypr/modules/autostart.lua` — servicios y programas que arrancan con Hyprland.
- `hypr/modules/monitors.lua` — salida, modo, posición y escala.
- `hypr/modules/input.lua` — layout de teclado y dispositivos específicos.
- `hypr/modules/environment.lua` — variables de entorno Wayland, Qt, Electron y AMD.

---

## Cosas que debes cambiar

Revisa como mínimo antes de usar:

- `hypr/hyprlock.conf` — cambia `$hyprlockDir` por tu ruta real (`/home/tu-usuario/.config/hyprlock`).
- `hypr/modules/autostart.lua` — cambia la ruta del wallpaper animado `~/Videos/wallpapersvideo/minecraft.mp4`.
- `hypr/modules/autostart.lua` — cambia o instala el cursor `Future-black-cursors`.
- `hypr/modules/environment.lua` — revisa `XCURSOR_THEME`, variables AMD y Qt según tu hardware.
- `hypr/modules/input.lua` — cambia nombres de mouse/teclado si no tienes esos dispositivos.
- `hypr/modules/programs.lua` — cambia `kitty`, `thunar` o el launcher si usas otras apps.
- `hypr/modules/keybinds.lua` — cambia `brave`, `obs`, `vscodium`, rutas de screenshots y comandos que no uses.
- `waybar/config.jsonc` — cambia `hwmon-path = /sys/class/hwmon/hwmon3/temp1_input` por el sensor correcto de tu máquina.
- `hyprlock/layouts/layout.conf` — cambia `~/.config/hyprlock/wallpapers/1.png` si usas otro wallpaper.
- `wlogout/style.css` — revisa rutas con `$HOME`; CSS no siempre expande variables de shell, puede necesitar ruta absoluta.
- `fastfetch/config*.jsonc` — cambia logos, imágenes y presets si no quieres usar los assets incluidos.
- `swaync/config.json` — cambia botones como `blueman-manager`, `nwg-look` o `nm-connection-editor` si no los usas.

Para encontrar todas las rutas personales de golpe:

```bash
rg "/home/|tu-usuario|wallpaper|hwmon|Future-black|Colloid" .
```

---

## Scripts y comandos utilizados en el rice

- **Hyprland/Wayland:** `hyprctl`, `hyprlock`, `hypridle`, `waybar`, `swaync`, `swaync-client`, `wlogout`
- **Audio/media:** `wpctl`, `pavucontrol`, `playerctl`, `cava`, `glava`
- **Screenshots/clipboard:** `hyprshot`, `grim`, `slurp`, `swappy`, `wl-copy`, `wl-paste`, `cliphist`, `hyprpicker`
- **Sistema:** `systemctl`, `loginctl`, `pacman`, `yay`, `checkupdates`, `paccache`, `journalctl`, `lm_sensors`
- **Red/GUI:** `nm-connection-editor`, `blueman-manager`, `nwg-look`
- **Terminal/shell:** `kitty`, `fish`, `starship`, `fastfetch`, `fzf`, `bat`, `eza`, `zoxide`, `ripgrep`
- **Utilidades:** `curl`, `jq`, `imagemagick`/`magick`, `libnotify`/`notify-send`, `udiskie`, `reflector`

---

## Notas para principiantes

- No copies todo a ciegas. Empieza por una carpeta, prueba, y luego sigue con otra.
- Si un comando falla, ejecútalo manualmente en la terminal para ver el error real.
- Las rutas con `/home/tu-usuario/...` son ejemplos. Cámbialas por tu usuario real o usa `$HOME` cuando el programa lo soporte.
- Los iconos dependen de Nerd Fonts. Si ves cuadros o símbolos raros, instala y selecciona una Nerd Font en tu terminal.
- Waybar puede romper el módulo de temperatura si tu sensor de hardware no es el mismo que el mío.
- Las funciones de Fish ejecutan tareas reales como actualizar paquetes y limpiar caché. Léelas antes de usarlas.
- Los scripts de Hyprlock usan MPRIS, `playerctl`, `curl`, `jq`, `imagemagick` y servicios externos como `wttr.in` o `ipinfo.io`.
- Algunas configuraciones están pensadas para mi hardware específico, mis programas y mi flujo de trabajo.

---

## Explicación de los comandos utilizados

> Esta sección es para quienes vienen de Windows o están comenzando en Linux. Si ya los conoces, puedes saltarla.

### git clone

```bash
git clone https://github.com/usuario/repositorio.git
```

Descarga un repositorio de GitHub a tu computadora, conservando el historial de cambios. Es equivalente a descargar un ZIP pero mejor.

---

### cd

```bash
cd ~/dotfiles
```

Cambia de directorio (carpeta) en la terminal. `cd ~/.config` entra a la carpeta de configuración.

---

### mkdir

```bash
mkdir -p ~/.config
```

Crea directorios. La opción `-p` evita errores si la carpeta ya existe.

---

### cp y cp -r

```bash
cp archivo.txt destino/        # copia un archivo
cp -r hypr waybar ~/.config/   # copia carpetas completas (recursivo)
```

Sin `-r`, Linux no copia directorios.

---

### chmod +x

```bash
chmod +x script.sh
```

Agrega permisos de ejecución. Necesario para poder ejecutar scripts `.sh` como programas.

---

### chsh

```bash
chsh -s /usr/bin/fish
```

Cambia la shell predeterminada del usuario. Después de cerrar sesión y volver a entrar, Fish se abrirá automáticamente en lugar de Bash.

---

### rg (ripgrep)

```bash
rg "wallpaper" .
```

Busca texto dentro de archivos. Muy útil para encontrar rutas personales, nombres de usuario, sensores y variables en los configs.

---

### sudo

```bash
sudo pacman -S paquete
```

Ejecuta un comando con permisos de administrador. Úsalo solo cuando entiendas qué hace el comando.

---

### pacman

```bash
sudo pacman -S paquete      # instalar
sudo pacman -Rns paquete    # eliminar con dependencias innecesarias
sudo pacman -Syu            # actualizar todo el sistema
```

Gestor de paquetes de Arch Linux y CachyOS.

---

### yay

```bash
yay -S paquete
```

Instala paquetes desde el AUR (Arch User Repository). Funciona similar a pacman pero accede a software mantenido por la comunidad.

---

### ¿Por qué no hay instalador automático?

Copiar archivos manualmente permite entender dónde vive cada configuración, qué programa usa cada archivo, detectar errores más fácilmente y modificar partes específicas sin depender de scripts automáticos.

La instalación manual requiere más trabajo, pero enseña mucho más sobre cómo funciona el sistema.

---

## Créditos externos

- Hyprland, Waybar, Rofi, Kitty, Fish, Starship, Fastfetch, Hyprlock, Hypridle, Wlogout y SwayNC pertenecen a sus respectivos proyectos.
- terminal-bg fue creado por [DaarcyDev](https://www.youtube.com/@DaarcyDev).
- Minecraft es propiedad de Mojang/Microsoft. La estética usada aquí es fan-made/personal.
- SDDM Minecraft, Minegrub, cursores, wallpapers, iconos, logos e imágenes de personajes son assets externos salvo que se indique lo contrario.
- Nerd Fonts y JetBrains Mono Nerd Font pertenecen a sus respectivos autores.

Si reutilizas este rice, conserva los créditos de los proyectos y assets que uses.

---

## Estado del proyecto

Rice personal en progreso. Puede tener rutas, decisiones y dependencias muy específicas de mi sistema. Úsalo como material de aprendizaje y como base para crear tu propia configuración.

---

## Filosofía del proyecto

Mi objetivo no es construir una configuración perfecta, sino una que yo pueda entender, mantener y modificar sin depender de herramientas externas o capas innecesarias de abstracción.

Prefiero:

- Configuración modular antes que archivos gigantes.
- Instalación manual antes que scripts mágicos.
- Entender antes que copiar.
- Simplicidad antes que complejidad innecesaria.
- Aprender antes que automatizar.

Si este repositorio te ayuda a aprender algo sobre Linux, Hyprland, Waybar, Fish o dotfiles, entonces ya cumplió su propósito.