# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Glass Universal · Fish shell theme (dinámico)
# Generado por matugen — no editar a mano.
# Estático de referencia: ~/.config/fish/theme-goldship.static.fish
#
# Limitación real: fish solo lee conf.d/ al ARRANCAR una shell — no hay
# señal de reload en caliente como en kitty/waybar. Las terminales ya
# abiertas se quedan con los colores viejos hasta que abrís una nueva.

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          e3e3d8
set -g fish_color_command         b7d085
set -g fish_color_builtin         a0d0c8
set -g fish_color_keyword         c2caab
set -g fish_color_end             8f9284
set -g fish_color_error           b85c50

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           c6c8b9
set -g fish_color_option          8f9284
set -g fish_color_operator        dee6c6
set -g fish_color_redirection     45483d
set -g fish_color_escape          e3e3d8
set -g fish_color_quote           bcece4

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         8f9284
set -g fish_color_bracket         dee6c6

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      e3e3d8 --underline
set -g fish_color_cwd             c6c8b9
set -g fish_color_cwd_root        c2caab

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  45483d
set -g fish_color_history_current e3e3d8 --bold
set -g fish_color_cancel          b85c50

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    e3e3d8 --background=292b23
set -g fish_color_selection       e3e3d8 --background=1e2019
set -g fish_color_match           a0d0c8

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            e3e3d8
set -g fish_color_host            8f9284
set -g fish_color_host_remote     bcece4

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          b85c50

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              45483d
set -g fish_pager_color_prefix                e3e3d8
set -g fish_pager_color_completion            c6c8b9
set -g fish_pager_color_description           8f9284
set -g fish_pager_color_secondary             45483d

set -g fish_pager_color_selected_background   --background=1e2019
set -g fish_pager_color_selected_prefix       e3e3d8
set -g fish_pager_color_selected_completion   e3e3d8
set -g fish_pager_color_selected_description  a0d0c8
