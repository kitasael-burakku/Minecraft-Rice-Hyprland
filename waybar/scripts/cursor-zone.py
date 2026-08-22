#!/usr/bin/env python3
"""Divide la franja superior de cada monitor en tres zonas y escribe zone.css.

Por qué un archivo CSS y no una clase en un módulo: en Waybar cada módulo es un
Gtk::EventBox sin nombre que envuelve un Gtk::Label con el nombre (#cpu, etc.),
así que la clase que un custom module puede publicar queda dos niveles dentro
del árbol y CSS no puede subir desde ahí para tocar a los demás módulos. Los
selectores de hermanos (~ y +) sí existen en GTK3 —verificado— pero no sirven
aquí por esa anidación. Reescribir zone.css y dejar que Waybar lo recargue
(reload_style_on_change, que también vigila los @import) es el único camino
limpio que no reconstruye la barra entera.

Por qué Python y no bash como el resto de scripts: `hyprctl cursorpos` cuesta
~2.9ms de fork+exec y esto sondea ~8 veces por segundo. Serían ~480 procesos
por minuto, justo lo que los comentarios de config.jsonc evitan a propósito en
custom/bluetooth y custom/updates. Hablando directo al socket de Hyprland desde
un proceso residente el sondeo no cuesta ningún spawn.

Lo lanza Waybar como exec de custom/zone, así que muere con Waybar; no hay nada
que arrancar en Hyprland ni en systemd.

ANIMACIÓN
---------
Este script no solo enciende y apaga: escribe la coreografía de ENTRADA. La de
salida vive fija en style.css. La cascada se apoya en dos cosas comprobadas
contra este GTK (3.24):

  · :nth-child(n) y :nth-last-child(n) NUMÉRICOS funcionan, y transition-delay
    se puede fijar por posición. Por eso no hace falta saber cuántos módulos
    tiene cada isla: la izquierda cuenta desde el principio y la derecha desde
    el final, así que mover módulos entre listas de config.jsonc no obliga a
    tocar nada aquí.
  · Recargar el CSS entero NO corta las transiciones en curso ni reinicia los
    @keyframes que ya estaban corriendo (medido: un pulso infinito sigue su
    curva a través de la recarga). Por eso se puede reescribir este archivo al
    cruzar cada tercio sin que parpadeen los pulsos de crítico/urgente.

La dirección es "desde el borde por el que entra el cursor hacia dentro": la
isla izquierda aparece de izquierda a derecha y la derecha de derecha a
izquierda. La cápsula entra sin retraso y se apaga la última.
"""

import json
import os
import socket
import sys
import time

POLL_SECONDS = 0.12   # latencia máxima entre mover el cursor y ver el cambio
TOP_BAND_PX = 60      # alto de la franja sensible desde el borde superior del monitor
                      # (la barra ocupa y=5..48; 60 deja llegar al borde y a las esquinas)
SIDE_FRACTION = 1 / 3 # ancho de cada zona lateral; el resto es centro (= ninguna)
GEOMETRY_REFRESH_S = 30  # relee monitores cada tanto: enchufar/quitar una pantalla o
                         # cambiar resolución movería las zonas sin avisar

# --- Coreografía de entrada (la de salida está en style.css) ---
ENTER_MS = 260
ENTER_CURVE = "cubic-bezier(0.16, 1, 0.3, 1)"   # expo-out: entra rápido y frena
ENTER_STEP_MS = 32                              # retraso que suma cada módulo
STAGGER_SLOTS = 10                              # posiciones cubiertas por isla

ZONE_CSS = os.path.expanduser("~/.config/waybar/zone.css")

HEADER = ("/* Generado por scripts/cursor-zone.py — no editar a mano.\n"
          "   Se reescribe solo cuando el cursor cambia de zona. */\n")


def side_css(side, counter):
    """CSS de la isla visible, con la cascada de entrada.

    `counter` es "nth-child" o "nth-last-child": decide si la cascada avanza
    desde el borde de la pantalla hacia el centro o al revés.

    Los selectores llevan window#waybar delante a propósito: zone.css se importa
    antes que las reglas base de style.css (los @import van al principio), así
    que necesita más especificidad para ganar, no orden. Por lo mismo cada
    retraso va en su propia regla con :nth-*: el atajo "transition" pone el
    delay a 0, y una regla aparte más específica lo vuelve a poner.
    """
    lines = [
        "window#waybar .modules-%s {" % side,
        "    background-color: alpha(@bg, 0.588);",
        "    border-bottom-color: alpha(@accent, 0.666);",
        "    transition: background-color %dms %s," % (ENTER_MS, ENTER_CURVE),
        "                border-bottom-color %dms %s;" % (ENTER_MS, ENTER_CURVE),
        "    transition-delay: 0ms;",   # la cápsula entra la primera
        "}",
        "window#waybar .modules-%s > * {" % side,
        "    opacity: 1;",
        "    transition: opacity %dms %s;" % (ENTER_MS, ENTER_CURVE),
        "}",
    ]
    for slot in range(1, STAGGER_SLOTS + 1):
        lines.append(
            "window#waybar .modules-%s > *:%s(%d) { transition-delay: %dms; }"
            % (side, counter, slot, (slot - 1) * ENTER_STEP_MS)
        )
    return "\n".join(lines) + "\n"


RULES = {
    # Cursor pegado al borde izquierdo: la cascada avanza hacia el centro.
    "left": side_css("left", "nth-child"),
    # Cursor pegado al borde derecho: se cuenta desde el final para que el
    # primero en encenderse sea el módulo del borde (custom/power).
    "right": side_css("right", "nth-last-child"),
    # El centro es permanente y no se oculta nunca, así que su zona no enciende
    # nada: estar en el tercio central solo significa "ninguno de los laterales".
    "center": "",
    "none": "",
}


def hypr(command):
    """Una petición al socket de control de Hyprland. Sin fork, sin hyprctl."""
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        raise RuntimeError("HYPRLAND_INSTANCE_SIGNATURE no está en el entorno")
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/run/user/%d" % os.getuid())
    path = os.path.join(runtime, "hypr", sig, ".socket.sock")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.settimeout(2)
        sock.connect(path)
        sock.sendall(command.encode())
        chunks = []
        while True:
            chunk = sock.recv(8192)
            if not chunk:
                break
            chunks.append(chunk)
    return b"".join(chunks)


def monitors():
    """Geometría en coordenadas de LAYOUT, que es en las que va `cursorpos`.

    hyprctl da width/height en píxeles físicos, así que en un monitor con
    scale != 1 hay que dividir o las zonas caen donde no toca. transform impar
    (90/270 grados) intercambia ancho y alto.
    """
    out = []
    for mon in json.loads(hypr("j/monitors")):
        scale = mon.get("scale") or 1
        width = mon["width"] / scale
        height = mon["height"] / scale
        if mon.get("transform", 0) % 2:
            width, height = height, width
        out.append((mon["x"], mon["y"], width, height))
    return out


def zone_for(x, y, mons):
    """Zona de la franja superior del monitor bajo el cursor, o 'none'."""
    for mx, my, mw, mh in mons:
        if mx <= x < mx + mw and my <= y < my + mh:
            if y - my >= TOP_BAND_PX:
                return "none"
            rel = (x - mx) / mw
            if rel < SIDE_FRACTION:
                return "left"
            if rel >= 1 - SIDE_FRACTION:
                return "right"
            return "center"
    return "none"


_last_written = None


def write_zone(zone):
    """Escribe zone.css si el contenido cambia de verdad.

    Escritura in situ (no temp+rename) para no cambiar el inodo: el vigilante
    de Waybar tiene el @import en su lista de watch y un rename le quitaría el
    archivo de debajo, igual que el "has been replaced" que ya se ve con
    playerctl-watch.sh en el journal.

    El corto por contenido importa: "center" y "none" generan lo mismo, así que
    salir de la franja por el tercio central no debe costar una recarga de CSS
    (Waybar reparsea style.css y todos sus @import en cada escritura).
    """
    global _last_written
    content = HEADER + RULES[zone]
    if content == _last_written:
        return
    with open(ZONE_CSS, "w", encoding="utf-8") as handle:
        handle.write(content)
    _last_written = content


def main():
    mons = []
    # Waybar puede arrancar antes de que el socket de Hyprland conteste. Si esto
    # revienta, el módulo custom/zone muere y no se respawnea: las zonas se
    # quedan apagadas hasta reiniciar la barra. Así que se insiste.
    while not mons:
        try:
            mons = monitors()
        except Exception:
            time.sleep(1)

    write_zone("none")
    current = "none"
    last_geometry = time.monotonic()

    while True:
        try:
            pos = json.loads(hypr("j/cursorpos"))
            zone = zone_for(pos["x"], pos["y"], mons)
            if time.monotonic() - last_geometry > GEOMETRY_REFRESH_S:
                mons = monitors() or mons
                last_geometry = time.monotonic()
        except Exception:
            # Hyprland reiniciando, socket cambiando, etc.: no morir ni ensuciar
            # el journal; reintentar y refrescar la geometría.
            time.sleep(1)
            try:
                mons = monitors() or mons
                last_geometry = time.monotonic()
            except Exception:
                pass
            continue

        if zone != current:
            write_zone(zone)
            current = zone

        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
