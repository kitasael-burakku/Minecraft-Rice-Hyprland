#!/usr/bin/env bash
# Restores the Hyprland border to the static Kitasan Glass identity (fixed
# teal, not following the wallpaper) — used by matugen_toggle.sh when
# turning dynamic theming off. It's no longer pure white: since borders
# became dynamic across all apps, "off" means "back to the brand teal",
# not "back to white" (pure white is no longer anything's resting identity).
hyprctl eval 'hl.config({
  general = {
    col = {
      active_border   = "rgba(7ab8b8cc)",
      inactive_border = "rgba(7ab8b80f)",
    },
  },
})' >/dev/null 2>&1 || true
