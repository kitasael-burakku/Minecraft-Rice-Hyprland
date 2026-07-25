# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Glass Universal · Fish shell theme (dinámico)
# Generado por matugen — no editar a mano.
# Estático de referencia: ~/.config/fish/theme-goldship.static.fish
#
# Limitación real: fish solo lee conf.d/ al ARRANCAR una shell — no hay
# señal de reload en caliente como en kitty/waybar. Las terminales ya
# abiertas se quedan con los colores viejos hasta que abrís una nueva.

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          f0dfd7
set -g fish_color_command         ffb688
set -g fish_color_builtin         caca93
set -g fish_color_keyword         e5bfa8
set -g fish_color_end             9f8d83
set -g fish_color_error           ffb4ab

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           d7c3b8
set -g fish_color_option          9f8d83
set -g fish_color_operator        ffdbc7
set -g fish_color_redirection     52443c
set -g fish_color_escape          f0dfd7
set -g fish_color_quote           e6e6ad

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         9f8d83
set -g fish_color_bracket         ffdbc7

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      f0dfd7 --underline
set -g fish_color_cwd             d7c3b8
set -g fish_color_cwd_root        e5bfa8

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  52443c
set -g fish_color_history_current f0dfd7 --bold
set -g fish_color_cancel          ffb4ab

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    f0dfd7 --background=312823
set -g fish_color_selection       f0dfd7 --background=261e19
set -g fish_color_match           caca93

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            f0dfd7
set -g fish_color_host            9f8d83
set -g fish_color_host_remote     e6e6ad

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          ffb4ab

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              52443c
set -g fish_pager_color_prefix                f0dfd7
set -g fish_pager_color_completion            d7c3b8
set -g fish_pager_color_description           9f8d83
set -g fish_pager_color_secondary             52443c

set -g fish_pager_color_selected_background   --background=261e19
set -g fish_pager_color_selected_prefix       f0dfd7
set -g fish_pager_color_selected_completion   f0dfd7
set -g fish_pager_color_selected_description  caca93
