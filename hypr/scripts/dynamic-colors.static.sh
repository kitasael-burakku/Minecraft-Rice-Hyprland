#!/usr/bin/env bash
# Restaura el borde de Hyprland a los valores originales (blanco puro, sin
# degradado) — usado por matugen_toggle.sh al apagar el theming dinámico.
hyprctl eval 'hl.config({
  general = {
    col = {
      active_border   = "rgba(ffffff33)",
      inactive_border = "rgba(ffffff0a)",
    },
  },
})' >/dev/null 2>&1 || true
