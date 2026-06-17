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
| Rofi | Launcher, selector de clipboard, selector de wallpapers (imagen y video) y power menu decorativo |
| matugen | Theming dinámico opcional — el script de reload está listo para usarlo pero no viene conectado a Hypr/Waybar en este rice, ver [Adiciones externas](#adiciones-externas) |
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

- Configuración de Hyprland separada en módulos Lua dentro de `hypr/modules/`, incluyendo un sistema de animaciones con curvas y springs con nombre propio (`animations.lua`).
- Autostart para wallpaper animado con `mpvpaper`, Waybar, SwayNC, Hypridle, Polkit, clipboard, udiskie y fondo animado de terminal con Cava.
- Selector de wallpapers propio en modo script de Rofi (imagen y video), atajo `SUPER + SHIFT + W` — con generación automática de thumbnails y soporte opcional (desactivado por defecto) de theming dinámico vía matugen, ver [Rofi — Selector de wallpapers](#rofi--selector-de-wallpapers).
- Waybar con módulos para disco, audio, reloj, workspaces, tray, updates (con acceso directo a `sysupdate`), red, temperatura, CPU, memoria y un botón de power conectado a un mini-menú en Rofi.
- Rofi como launcher de aplicaciones, selector de historial de clipboard y power menu decorativo (la fuente distinta en ese menú es a propósito, para que resalte; la sesión real se maneja con Wlogout).
- Kitty con Fish como shell, tema de colores propio ("Kitasan-Ship Refined", compartido también con Fish) y soporte para imágenes de Fastfetch vía el protocolo gráfico de Kitty.
- Fish con Starship, rotación aleatoria entre 6 presets de Fastfetch, aliases modernos, y funciones propias de mantenimiento, diagnóstico y un visor interactivo de atajos — ver [Funciones de Fish](#funciones-de-fish).
- Hyprlock con layout minimalista (reloj, fecha, usuario, contraseña) y varios scripts adicionales en el repo que no están conectados al layout actual (batería, MPRIS, clima, ubicación — disponibles si quieres armar tu propia versión más cargada de info).
- SwayNC con centro de notificaciones, controles rápidos y tema `goldship`.
- Wlogout con acciones de bloqueo, salida, suspensión, apagado, hibernación y reinicio — es el menú de sesión real del sistema.
- Layout de Hyprland intercambiable en caliente (dwindle / master / scrolling) y workspace especial tipo scratchpad.
- Atajos para screenshots, color picker, control multimedia, floating con resize automático, Waybar reload y herramientas de sistema.

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
├── rofi/               # Launcher, clipboard, selector de wallpapers y power menu
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
  jq curl imagemagick libnotify ffmpeg \
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
  glava \
  swww \
  matugen \
  awww
```

`awww` queda como fallback opcional dentro de `wallpaper_rofi.sh` si no tienes `swww`; no es obligatorio si ya tienes `swww` instalado.

**Marcadas como por verificar:**

- `hyprland-lua`: este rice usa `hypr/hyprland.lua` con llamadas `hl.*`, no `hyprland.conf` clásico. Verifica el paquete o método correcto para tu versión de Hyprland.
- `hyprshutdown`: aparece como fallback opcional en un keybind.
- `glava`: usado opcionalmente en scripts de Hyprlock si Spotify está reproduciendo.
- `Future-black-cursors`, `Colloid-cursors`, SDDM Minecraft, Minegrub: instala o reemplaza según tu sistema.
- `obs`, `brave`, `vscodium`: aplicaciones personales atadas a keybinds, no son requisitos del entorno base.
- `swww`: requerido por el selector de wallpapers en Rofi (`rofi/scripts/wallpaper_rofi.sh`) para aplicar imágenes. Revisa el nombre exacto del paquete en AUR para tu sistema. `matugen` solo lo necesitas si armas el theme selector descrito en [Adiciones externas](#adiciones-externas).

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
  ~/.config/rofi \
  ~/.config/fastfetch \
  ~/.config/hyprlock \
  ~/.config/swaync \
  ~/.config/wlogout \
  ~/.config/scripts \
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
chmod +x ~/.config/rofi/scripts/*.sh
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
- `hypr/modules/decoration.lua` — gaps, bordes, redondeo, opacidad, sombra y blur.
- `hypr/modules/layout.lua` — configuración de los tres layouts disponibles (dwindle, master, scrolling) y cuál es el default.
- `hypr/modules/animations.lua` — sistema de curvas y springs con nombre propio para ventanas, fades, layers, workspaces y zoom.
- `hypr/modules/windowrules.lua` — reglas de ventana y de capa (blur/alpha/animación para SwayNC, Rofi, Wlogout, Waybar).
- `hypr/modules/misc.lua` — ajustes varios, incluye desactivar el wallpaper/logo aleatorio de Hyprland.

---

## Rofi — Selector de wallpapers

`rofi/scripts/wallpaper_rofi.sh` es un selector de wallpapers con soporte para imagen y video, construido como un modo-script nativo de Rofi (sin depender de un proyecto externo). Está atado al atajo `SUPER + SHIFT + W` (definido en `hypr/modules/keybinds.lua`) y se invoca así:

```bash
rofi -show wallpapers -modi "wallpapers:~/.config/rofi/scripts/wallpaper_rofi.sh"
```

Reemplaza al selector anterior basado en Quickshell, que se quitó del repo por completo.

Cómo funciona:

- Lee los wallpapers desde `WALLPAPER_DIR` (por defecto `~/Videos/wallpapersvideo`, la misma carpeta que usa el wallpaper animado de `autostart.lua`). Si guardas tus wallpapers en otro lugar, exporta esa variable antes de lanzar Rofi en vez de mover archivos.
- Cada vez que abres el menú, dispara en segundo plano `generate-thumbs.sh`, que genera (o regenera si el archivo cambió) un thumbnail `.jpg` por wallpaper en `~/.cache/rofi-wallpapers/thumbs` usando ImageMagick para imágenes y un frame de ffmpeg para videos. No bloquea la apertura del menú: si un thumbnail nuevo todavía no está listo, esa entrada aparece sin ícono pero sigue siendo seleccionable.
- Al elegir un wallpaper, los formatos de video (`mp4`, `mkv`, `mov`, `webm`) se aplican relanzando `mpvpaper`; los formatos de imagen (`jpg`, `jpeg`, `png`, `webp`, `gif`) se aplican con `swww` (o `awww` como fallback si no tienes `swww`).
- Después de aplicar el wallpaper, llama a `matugen_reload.sh`, que puede correr `matugen` y avisarle a Hypr, Waybar, Kitty, SwayNC y SwayOSD que recarguen. **Viene desactivado por defecto** porque este rice no cambia de colores — ver [Adiciones externas](#adiciones-externas) si quieres conectarlo de verdad.

No hay un archivo de configuración personal que copiar (a diferencia del `Settings.qml` del picker anterior): basta con tener tus wallpapers en `WALLPAPER_DIR` y dar permisos de ejecución a los scripts (`chmod +x ~/.config/rofi/scripts/*.sh`).

---

## Adiciones externas

Soy bastante purista con esto: cambio de wallpaper seguido (según el ánimo o la hora del día), pero no cambio de paleta de color cada vez que lo hago. Por eso `rofi/scripts/matugen_reload.sh` viene con todas sus variables `ENABLE_*` (`ENABLE_DYNAMIC_COLORS`, `ENABLE_MATUGEN`, `ENABLE_HYPR_RELOAD`, `ENABLE_WAYBAR_RELOAD`, `ENABLE_KITTY_RELOAD`, `ENABLE_CAVA_RELOAD`, `ENABLE_SWAYNC_RELOAD`, `ENABLE_SWAYOSD_RELOAD`) apagadas por defecto.

El script ya sabe cuándo correr `matugen` y a qué procesos avisarles después de aplicar un wallpaper, pero la parte de "aplicar esos colores" no está conectada en este repo: `hypr/modules/decoration.lua` tiene los colores escritos directo en el código, `waybar/style.css` no importa ningún archivo de colores externo, y `kitty.conf` usa mi tema estático propio. No la armé de punta a punta, así que no la documento como si funcionara.

Si quieres un theme selector real con esto, tendrías que:

1. Tener tus propios templates de matugen apuntando a las rutas de `HYPR_COLORS_PATH` / `WAYBAR_COLORS_PATH` (o exportar esas variables a donde sí escriban).
2. Hacer que `decoration.lua`, `waybar/style.css` y `kitty.conf` lean esos archivos generados en vez de los valores fijos que tienen ahora.
3. Prender solo las variables `ENABLE_*` que correspondan a lo que conectes.

Si lo terminas armando, este es un buen lugar para anotar cómo te quedó.

---

## Funciones de Fish

Además de los alias y la integración con herramientas externas, Fish trae funciones propias invocables como comandos:

- `sysupdate` — actualiza pacman y AUR (yay) en una sola pasada, con salida animada. Es lo mismo que corre el módulo `custom/updates` de Waybar al hacer click.
- `quickcache` — limpieza rápida de cachés de apps conocidas (Brave, Spotify, Electron, etc.), con confirmación antes de borrar.
- `checktrash` / `cleantrash` — el primero solo reporta qué se puede limpiar (paquetes huérfanos, cachés, papelera); el segundo lo limpia de verdad, con confirmación.
- `checkerrors` — diagnóstico de servicios fallidos, errores de journalctl (incluyendo Hyprland/portales) y coredumps recientes. Solo lectura, no cambia nada.
- `healthcheck` — el chequeo más completo: sistema, memoria/zram, actualizaciones pendientes, paquetes huérfanos, archivos `.pacnew`/`.pacsave`, servicios fallidos, red y temperaturas.
- `keybinds` — abre un visor interactivo de `KEYBINDS.txt` directo en la terminal, con navegación tipo vim (`h/j/k/l`), búsqueda (`:` + espacio) y paginación por sección. Mientras está abierto, flota y centra automáticamente la ventana de la terminal.
- `fastfetch` (la función, no el binario) — elige al azar uno de los presets en `fastfetch/config*.jsonc`, evitando repetir el mismo dos veces seguidas.

> ⚠️ `keybinds` depende de que `KEYBINDS.txt` mantenga un formato exacto: encabezado de sección en MAYÚSCULAS, una línea de solo guiones debajo, y entradas `TECLA␣␣␣␣Descripción` con al menos dos espacios entre columnas. Si editas ese archivo a mano, respeta el formato o el visor deja de reconocer las secciones.

---

## Cosas que debes cambiar

Revisa como mínimo antes de usar:

- `hypr/hyprlock.conf` — cambia `$hyprlockDir` por tu ruta real (`/home/tu-usuario/.config/hyprlock`).
- `hypr/modules/autostart.lua` — cambia la ruta del wallpaper animado `~/Videos/wallpapersvideo/minecraft.mp4`.
- `hypr/modules/environment.lua` y `hypr/modules/autostart.lua` — ambos definen el mismo tema de cursor; si lo cambias, actualízalo en los dos archivos para que no queden desincronizados.
- `hypr/modules/input.lua` — cambia nombres de mouse/teclado si no tienes esos dispositivos.
- `hypr/modules/programs.lua` — cambia `kitty`, `thunar` o el launcher si usas otras apps.
- `hypr/modules/keybinds.lua` — cambia `brave`, `obs`, `vscodium`, rutas de screenshots y comandos que no uses.
- `waybar/config.jsonc` — cambia `hwmon-path = /sys/class/hwmon/hwmon3/temp1_input` por el sensor correcto de tu máquina. El módulo `hyprland/window` muestra el texto fijo `"CachyOs"` a propósito (decisión estética); cámbialo a `{title}` si prefieres ver el título real de la ventana enfocada.
- `hyprlock/layouts/layout.conf` — cambia `~/.config/hyprlock/wallpapers/1.png` si usas otro wallpaper.
- `wlogout/style.css` — las seis rutas de iconos (`lock.png`, `logout.png`, `hibernate.png`, `shutdown.png`, `reboot.png`, `suspend.png`) están escritas como ruta absoluta a mi usuario; cámbialas por la tuya.
- `fastfetch/config*.jsonc` — cambia logos, imágenes y presets si no quieres usar los assets incluidos.
- `swaync/config.json` — cambia botones como `blueman-manager`, `nwg-look` o `nm-connection-editor` si no los usas.

Para encontrar todas las rutas personales de golpe:

```bash
rg "/home/|tu-usuario|kitasa-elburakku|wallpaper|hwmon|Future-black|Colloid" .
```

---

## Scripts y comandos utilizados en el rice

- **Hyprland/Wayland:** `hyprctl`, `hyprlock`, `hypridle`, `waybar`, `swaync`, `swaync-client`, `wlogout`, `swww`, `awww`, `matugen`
- **Audio/media:** `wpctl`, `pavucontrol`, `playerctl`, `cava`, `glava`
- **Screenshots/clipboard:** `hyprshot`, `grim`, `slurp`, `swappy`, `wl-copy`, `wl-paste`, `cliphist`, `hyprpicker`
- **Sistema:** `systemctl`, `loginctl`, `pacman`, `yay`, `checkupdates`, `paccache`, `journalctl`, `lm_sensors`
- **Red/GUI:** `nm-connection-editor`, `blueman-manager`, `nwg-look`
- **Terminal/shell:** `kitty`, `fish`, `starship`, `fastfetch`, `fzf`, `bat`, `eza`, `zoxide`, `ripgrep`
- **Utilidades:** `curl`, `jq`, `imagemagick`/`magick`, `ffmpeg`, `libnotify`/`notify-send`, `udiskie`, `reflector`

---

## Notas para principiantes

- No copies todo a ciegas. Empieza por una carpeta, prueba, y luego sigue con otra.
- Si un comando falla, ejecútalo manualmente en la terminal para ver el error real.
- Las rutas con `/home/tu-usuario/...` son ejemplos. Cámbialas por tu usuario real o usa `$HOME` cuando el programa lo soporte.
- Los iconos dependen de Nerd Fonts. Si ves cuadros o símbolos raros, instala y selecciona una Nerd Font en tu terminal.
- Waybar puede romper el módulo de temperatura si tu sensor de hardware no es el mismo que el mío.
- Las funciones de Fish ejecutan tareas reales como actualizar paquetes y limpiar caché. Léelas antes de usarlas.
- Los scripts de Hyprlock usan MPRIS, `playerctl`, `curl`, `jq`, `imagemagick` y servicios externos como `wttr.in` o `ipinfo.io`.
- La carpeta `hyprlock/` trae scripts de batería, MPRIS/Spotify, clima, ubicación y cronómetro que **no están conectados** al `layout.conf` activo — quedaron disponibles por si quieres armar tu propio layout más cargado de información; el lock screen actual es deliberadamente minimalista.
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
- El selector de wallpapers en Rofi (`rofi/scripts/wallpaper_rofi.sh`) es trabajo propio, construido como modo-script nativo de Rofi tras dejar atrás la versión anterior basada en Quickshell.
- [matugen](https://github.com/InioX/matugen) es la herramienta de theming dinámico que el script de reload del selector de wallpapers está preparado para usar, pero no viene conectada en este rice — ver [Adiciones externas](#adiciones-externas).
- Algunos presets de `fastfetch/config*.jsonc` están adaptados de los ejemplos oficiales del propio proyecto Fastfetch.
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