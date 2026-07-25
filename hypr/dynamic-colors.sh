#!/usr/bin/env bash
# Generado por matugen — no editar a mano.
# Aplica el borde de Hyprland en caliente vía `hyprctl eval` + hl.config()
# (confirmado en vivo: `hyprctl keyword` está rechazado para el parser Lua;
# ni `hyprctl reload` ni `reload full-reset` re-ejecutan módulos `require`ados,
# así que este es el único mecanismo que realmente aplica el cambio al toque).
#
# "Balanceado": el borde activo pasa de blanco puro a un degradado sutil
# blanco→acento (se mantiene la misma opacidad tenue de siempre, 0x33, no un
# blanco opaco). El borde inactivo queda estático (rgba(ffffff0a), casi
# invisible, no vale la pena animarlo).
# Estático de referencia: ~/.config/hypr/scripts/dynamic-colors.static.sh

hyprctl eval 'hl.config({
  general = {
    col = {
      active_border   = { colors = {"rgba(ffffff33)", "rgba(ffb77a66)"}, angle = 45 },
      inactive_border = "rgba(ffffff0a)",
    },
  },
})' >/dev/null 2>&1 || true
