# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Neutral Stone · Fish shell theme · VIBRANT EDITION
# Paleta: negros, blancos puros, grises claros, 3 acentos vibrantes

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          ffffff          # blanco puro — texto base
set -g fish_color_command         f5f5f5          # blanco brillante — nombres de comandos
set -g fish_color_builtin         ffdfa9          # arena brillante — echo, set, read…
set -g fish_color_keyword         e06d5a          # terracota encendido — for, if, while…
set -g fish_color_end             b0b0b0          # stone gray claro — ; y newline
set -g fish_color_error           f88472          # terracota brillante — errores de sintaxis

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           e0e0e0          # gris muy claro — argumentos posicionales
set -g fish_color_option          a6cde6          # azul cielo grisáceo — --flags y -options
set -g fish_color_operator        f0f5f8          # frost intenso — = + - * | & …
set -g fish_color_redirection     8bb3c9          # azul claro pastel — > >> | &
set -g fish_color_escape          ffffff          # blanco puro — \n \t \" …
set -g fish_color_quote           ebd3b4          # arena clara — "strings" 'strings'

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         bdae9e          # gris cálido claro — # comentarios
set -g fish_color_bracket         f0f5f8          # frost intenso — () [] {}

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      ffffff --underline
set -g fish_color_cwd             e0e0e0          # gris muy claro — directorio actual
set -g fish_color_cwd_root        e06d5a          # terracota encendido — directorio root

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  8a8a8a          # gris medio (más legible) — ghost text
set -g fish_color_history_current ffffff --bold   # blanco puro — historial seleccionado
set -g fish_color_cancel          f88472          # terracota brillante — Ctrl-C

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    ffffff --background=3a5060
set -g fish_color_selection       ffffff --background=2e3238
set -g fish_color_match           ffdfa9          # arena brillante — brackets coincidentes

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            ffffff          # blanco puro
set -g fish_color_host            a6cde6          # azul cielo grisáceo — hostname local
set -g fish_color_host_remote     ebd3b4          # arena clara — hostname SSH

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          f88472          # terracota brillante — exit code no-cero

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              8a8a8a
set -g fish_pager_color_prefix                ffffff   # blanco puro — prefijo coincidente
set -g fish_pager_color_completion            e0e0e0
set -g fish_pager_color_description           a6cde6   # azul cielo grisáceo
set -g fish_pager_color_secondary             b0b0b0   # stone claro — fila alternada

set -g fish_pager_color_selected_background   --background=2e3238
set -g fish_pager_color_selected_prefix       ffffff
set -g fish_pager_color_selected_completion   ffffff
set -g fish_pager_color_selected_description  ffdfa9   # arena brillante