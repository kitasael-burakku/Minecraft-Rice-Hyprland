#!/usr/bin/env bash
# Generado por matugen — no editar a mano.
# Aplica el borde de Hyprland en caliente vía `hyprctl eval` + hl.config()
# (confirmado en vivo: `hyprctl keyword` está rechazado para el parser Lua;
# ni `hyprctl reload` ni `reload full-reset` re-ejecutan módulos `require`ados,
# así que este es el único mecanismo que realmente aplica el cambio al toque).
#
# "Todo dinámico": el borde activo es un degradado entre el acento y el
# secundario del wallpaper (ya no blanco). El inactivo es el acento a alpha
# bajo — sigue siendo sutil, pero ya no es un blanco fijo.
# Estático de referencia: ~/.config/hypr/scripts/dynamic-colors.static.sh

hyprctl eval 'hl.config({
  general = {
    col = {
      active_border   = { colors = {"rgba(a9c7ffcc)", "rgba(bec7dc99)"}, angle = 45 },
      inactive_border = "rgba(a9c7ff0f)",
    },
  },
})' >/dev/null 2>&1 || true
