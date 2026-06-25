# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Neutral Stone · Fish shell theme
# Paleta: negros, blancos, grises cálidos, 3 acentos funcionales

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          e2e2e2          # blanco neutro — texto base
set -g fish_color_command         e8e8e8          # gris muy claro — nombres de comandos
set -g fish_color_builtin         e0c898          # arena clara — echo, set, read…
set -g fish_color_keyword         c05a48          # terracota — for, if, while…
set -g fish_color_end             909090          # stone gray — ; y newline
set -g fish_color_error           d06858          # terracota claro — errores de sintaxis

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           cccccc          # gris claro — argumentos posicionales
set -g fish_color_option          88aabf          # azul grisáceo — --flags y -options
set -g fish_color_operator        dce4e8          # frost — = + - * | & …
set -g fish_color_redirection     628090          # azul oscuro — > >> | &
set -g fish_color_escape          e2e2e2          # blanco — \n \t \" …
set -g fish_color_quote           c8b090          # arena — "strings" 'strings'

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         8a7d6e          # gris cálido — # comentarios
set -g fish_color_bracket         dce4e8          # frost — () [] {}

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      e2e2e2 --underline
set -g fish_color_cwd             cccccc          # gris claro — directorio actual
set -g fish_color_cwd_root        c05a48          # terracota — directorio root

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  686868          # gris oscuro — ghost text
set -g fish_color_history_current e8e8e8 --bold   # casi blanco — historial seleccionado
set -g fish_color_cancel          d06858          # terracota — Ctrl-C

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    e2e2e2 --background=2a3a44
set -g fish_color_selection       e2e2e2 --background=1e2024
set -g fish_color_match           e0c898          # arena — brackets coincidentes

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            e2e2e2          # blanco neutro
set -g fish_color_host            88aabf          # azul grisáceo — hostname local
set -g fish_color_host_remote     c8b090          # arena — hostname SSH

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          d06858          # terracota — exit code no-cero

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              686868
set -g fish_pager_color_prefix                e8e8e8   # casi blanco — prefijo coincidente
set -g fish_pager_color_completion            e2e2e2
set -g fish_pager_color_description           88aabf   # azul grisáceo
set -g fish_pager_color_secondary             909090   # stone — fila alternada

set -g fish_pager_color_selected_background   --background=1e2024
set -g fish_pager_color_selected_prefix       e8e8e8
set -g fish_pager_color_selected_completion   e2e2e2
set -g fish_pager_color_selected_description  e0c898   # arena