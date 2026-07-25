# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Glass Universal · Fish shell theme (dinámico)
# Generado por matugen — no editar a mano.
# Estático de referencia: ~/.config/fish/theme-goldship.static.fish
#
# Limitación real: fish solo lee conf.d/ al ARRANCAR una shell — no hay
# señal de reload en caliente como en kitty/waybar. Las terminales ya
# abiertas se quedan con los colores viejos hasta que abrís una nueva.

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          efe0d6
set -g fish_color_command         ffb77d
set -g fish_color_builtin         c5cb96
set -g fish_color_keyword         e3c0a6
set -g fish_color_end             9e8e82
set -g fish_color_error           b85c50

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           d6c3b6
set -g fish_color_option          9e8e82
set -g fish_color_operator        ffdcc3
set -g fish_color_redirection     51443b
set -g fish_color_escape          efe0d6
set -g fish_color_quote           e1e7b0

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         9e8e82
set -g fish_color_bracket         ffdcc3

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      efe0d6 --underline
set -g fish_color_cwd             d6c3b6
set -g fish_color_cwd_root        e3c0a6

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  51443b
set -g fish_color_history_current efe0d6 --bold
set -g fish_color_cancel          b85c50

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    efe0d6 --background=312822
set -g fish_color_selection       efe0d6 --background=261e18
set -g fish_color_match           c5cb96

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            efe0d6
set -g fish_color_host            9e8e82
set -g fish_color_host_remote     e1e7b0

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          b85c50

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              51443b
set -g fish_pager_color_prefix                efe0d6
set -g fish_pager_color_completion            d6c3b6
set -g fish_pager_color_description           9e8e82
set -g fish_pager_color_secondary             51443b

set -g fish_pager_color_selected_background   --background=261e18
set -g fish_pager_color_selected_prefix       efe0d6
set -g fish_pager_color_selected_completion   efe0d6
set -g fish_pager_color_selected_description  c5cb96
