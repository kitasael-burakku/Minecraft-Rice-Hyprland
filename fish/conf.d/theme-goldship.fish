# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Neutral Stone · Fish shell theme
# Paleta: negros, blancos, grises cálidos, 3 acentos funcionales

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          e2e2e2          # blanco neutro — texto base
set -g fish_color_command         d0d0d0          # gris claro — nombres de comandos
set -g fish_color_builtin         c0a880          # arena — echo, set, read…
set -g fish_color_keyword         964840          # terracota — for, if, while…
set -g fish_color_end             787878          # stone gray — ; y newline
set -g fish_color_error           a85a48          # terracota claro — errores de sintaxis

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           b0b0b0          # gris medio — argumentos posicionales
set -g fish_color_option          6a8898          # azul grisáceo — --flags y -options
set -g fish_color_operator        c0c8cc          # frost — = + - * | & …
set -g fish_color_redirection     4a6070          # azul oscuro — > >> | &
set -g fish_color_escape          e2e2e2          # blanco — \n \t \" …
set -g fish_color_quote           a89070          # arena — "strings" 'strings'

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         686058          # gris cálido — # comentarios
set -g fish_color_bracket         c0c8cc          # frost — () [] {}

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      e2e2e2 --underline
set -g fish_color_cwd             b0b0b0          # gris medio — directorio actual
set -g fish_color_cwd_root        964840          # terracota — directorio root

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  484848          # gris oscuro — ghost text
set -g fish_color_history_current d0d0d0 --bold   # gris claro — historial seleccionado
set -g fish_color_cancel          a85a48          # terracota — Ctrl-C

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    e2e2e2 --background=2a3a44
set -g fish_color_selection       e2e2e2 --background=1e2024
set -g fish_color_match           c0a880          # arena — brackets coincidentes

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            e2e2e2          # blanco neutro
set -g fish_color_host            6a8898          # azul grisáceo — hostname local
set -g fish_color_host_remote     a89070          # arena — hostname SSH

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          a85a48          # terracota — exit code no-cero

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              484848
set -g fish_pager_color_prefix                d0d0d0   # gris claro — prefijo coincidente
set -g fish_pager_color_completion            e2e2e2
set -g fish_pager_color_description           6a8898   # azul grisáceo
set -g fish_pager_color_secondary             787878   # stone — fila alternada

set -g fish_pager_color_selected_background   --background=1e2024
set -g fish_pager_color_selected_prefix       d0d0d0
set -g fish_pager_color_selected_completion   e2e2e2
set -g fish_pager_color_selected_description  c0a880   # arena