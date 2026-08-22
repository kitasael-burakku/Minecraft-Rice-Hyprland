#!/usr/bin/env python3
"""Avisa con un popup cuando cambia la distribución de teclado.

Por qué esto y no un módulo en la barra: el dato solo importa en el instante
en que cambia. Un indicador permanente gasta sitio en la barra las 24 horas
para algo que miras dos segundos al día, y `grp:alt_shift_toggle` (que es lo
que hay configurado en hypr/modules/input.lua) se pulsa sin querer con una
facilidad notable — el momento en que te enteras es justo ese.

Escucha el socket de EVENTOS de Hyprland (.socket2.sock), que no es el mismo
que el de control (.socket.sock) que usa waybar/scripts/cursor-zone.py: aquí
Hyprland empuja líneas "evento>>datos" y no hay que sondear nada.

Ojo con el duplicado: hay tres teclados declarados en input.lua y Hyprland
emite un `activelayout` POR DISPOSITIVO, así que un solo Alt+Shift dispara
tres eventos idénticos. Se deduplica por nombre de distribución.
"""

import os
import socket
import subprocess
import sys
import time

# Etiqueta corta para el popup. Lo que manda xkb son nombres largos
# ("English (US)"), y en un aviso de un segundo se lee mejor un código.
SHORT = {
    "English (US)": "US",
    "Spanish": "ES",
    "Spanish (Latin American)": "LATAM",
    "Catalan": "CAT",
    "English (UK)": "UK",
}

TIMEOUT_MS = 1200


def event_socket():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        raise RuntimeError("HYPRLAND_INSTANCE_SIGNATURE no está en el entorno")
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/run/user/%d" % os.getuid())
    path = os.path.join(runtime, "hypr", sig, ".socket2.sock")
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)
    return sock


def short_name(layout):
    if layout in SHORT:
        return SHORT[layout]
    # Cualquier distribución que no esté en la tabla: las tres primeras letras
    # en mayúsculas es mejor que no enseñar nada.
    return layout.split()[0][:3].upper() if layout else "??"


def notify(layout):
    # El hint de sincronía hace que cada aviso SUSTITUYA al anterior en vez de
    # apilarse: cambiar cuatro veces seguidas deja un popup, no cuatro.
    subprocess.run(
        [
            "notify-send",
            "-a", "Keyboard",
            "-i", "input-keyboard",
            "-t", str(TIMEOUT_MS),
            "-h", "string:x-canonical-private-synchronous:kb-layout",
            "-h", "string:synchronous:kb-layout",
            "󰌌  %s" % short_name(layout),
            layout,
        ],
        check=False,
    )


def main():
    last = None
    while True:
        try:
            sock = event_socket()
        except Exception:
            # Hyprland todavía no está, o se está reiniciando.
            time.sleep(2)
            continue

        try:
            with sock, sock.makefile("r", encoding="utf-8", errors="replace") as stream:
                for line in stream:
                    line = line.rstrip("\n")
                    if not line.startswith("activelayout>>"):
                        continue
                    # "activelayout>>NOMBRE DEL TECLADO,Distribución"
                    payload = line.split(">>", 1)[1]
                    _, _, layout = payload.partition(",")
                    layout = layout.strip()
                    if not layout or layout == last:
                        continue
                    last = layout
                    notify(layout)
        except Exception:
            pass

        # El socket se cayó (Hyprland reiniciado): reconectar sin morir, que
        # esto lo supervisa systemd con Restart=always y no queremos gastar
        # los reintentos del StartLimit en algo tan normal.
        time.sleep(2)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
