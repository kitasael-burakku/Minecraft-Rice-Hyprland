# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Glass Universal · Fish shell theme (dinámico)
# Generado por matugen — no editar a mano.
# Estático de referencia: ~/.config/fish/theme-goldship.static.fish
#
# Limitación real: fish solo lee conf.d/ al ARRANCAR una shell — no hay
# señal de reload en caliente como en kitty/waybar. Las terminales ya
# abiertas se quedan con los colores viejos hasta que abrís una nueva.

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          {{colors.on_surface.default.hex_stripped}}
set -g fish_color_command         {{colors.primary.default.hex_stripped}}
set -g fish_color_builtin         {{colors.tertiary.default.hex_stripped}}
set -g fish_color_keyword         {{colors.secondary.default.hex_stripped}}
set -g fish_color_end             {{colors.outline.default.hex_stripped}}
set -g fish_color_error           {{colors.error.default.hex_stripped}}

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           {{colors.on_surface_variant.default.hex_stripped}}
set -g fish_color_option          {{colors.outline.default.hex_stripped}}
set -g fish_color_operator        {{colors.on_secondary_container.default.hex_stripped}}
set -g fish_color_redirection     {{colors.outline_variant.default.hex_stripped}}
set -g fish_color_escape          {{colors.on_surface.default.hex_stripped}}
set -g fish_color_quote           {{colors.on_tertiary_container.default.hex_stripped}}

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         {{colors.outline.default.hex_stripped}}
set -g fish_color_bracket         {{colors.on_secondary_container.default.hex_stripped}}

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      {{colors.on_surface.default.hex_stripped}} --underline
set -g fish_color_cwd             {{colors.on_surface_variant.default.hex_stripped}}
set -g fish_color_cwd_root        {{colors.secondary.default.hex_stripped}}

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  {{colors.outline_variant.default.hex_stripped}}
set -g fish_color_history_current {{colors.on_surface.default.hex_stripped}} --bold
set -g fish_color_cancel          {{colors.error.default.hex_stripped}}

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    {{colors.on_surface.default.hex_stripped}} --background={{colors.surface_container_high.default.hex_stripped}}
set -g fish_color_selection       {{colors.on_surface.default.hex_stripped}} --background={{colors.surface_container.default.hex_stripped}}
set -g fish_color_match           {{colors.tertiary.default.hex_stripped}}

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            {{colors.on_surface.default.hex_stripped}}
set -g fish_color_host            {{colors.outline.default.hex_stripped}}
set -g fish_color_host_remote     {{colors.on_tertiary_container.default.hex_stripped}}

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          {{colors.error.default.hex_stripped}}

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              {{colors.outline_variant.default.hex_stripped}}
set -g fish_pager_color_prefix                {{colors.on_surface.default.hex_stripped}}
set -g fish_pager_color_completion            {{colors.on_surface_variant.default.hex_stripped}}
set -g fish_pager_color_description           {{colors.outline.default.hex_stripped}}
set -g fish_pager_color_secondary             {{colors.outline_variant.default.hex_stripped}}

set -g fish_pager_color_selected_background   --background={{colors.surface_container.default.hex_stripped}}
set -g fish_pager_color_selected_prefix       {{colors.on_surface.default.hex_stripped}}
set -g fish_pager_color_selected_completion   {{colors.on_surface.default.hex_stripped}}
set -g fish_pager_color_selected_description  {{colors.tertiary.default.hex_stripped}}
