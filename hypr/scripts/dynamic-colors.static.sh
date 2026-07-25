#!/usr/bin/env bash
# Restaura el borde de Hyprland a la identidad estática Kitasan Glass (teal
# fijo, sin seguir el wallpaper) — usado por matugen_toggle.sh al apagar el
# theming dinámico. Ya no es blanco puro: desde que los bordes pasaron a ser
# dinámicos en todas las apps, "apagado" significa "vuelve al teal de marca",
# no "vuelve a blanco" (blanco puro ya no es la identidad de reposo de nada).
hyprctl eval 'hl.config({
  general = {
    col = {
      active_border   = "rgba(7ab8b8cc)",
      inactive_border = "rgba(7ab8b80f)",
    },
  },
})' >/dev/null 2>&1 || true
