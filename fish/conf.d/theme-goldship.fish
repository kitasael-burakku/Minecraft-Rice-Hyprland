# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan · Glass Universal · Fish shell theme
# Paleta: Kitasan Glass · Universal Dark

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          e8e8e8          # foreground base
set -g fish_color_command         f0f0f0          # blanco brillante — comandos
set -g fish_color_builtin         c8b898          # arena cálida — echo, set, read…
set -g fish_color_keyword         d47a6e          # rojo apagado claro — for, if, while…
set -g fish_color_end             7a7a7a          # stone gray — ; y newline
set -g fish_color_error           b85c50          # rojo apagado — errores

# ── Syntax: argumentos & operadores ───────────────────────────
set -g fish_color_param           d8d8d8          # gris claro — argumentos
set -g fish_color_option          8098a8          # azul gris claro — --flags
set -g fish_color_operator        b0d0d8          # cyan claro — = + - * | &
set -g fish_color_redirection     607888          # azul gris oscuro — > >> |
set -g fish_color_escape          e8e8e8          # foreground — \n \t \"
set -g fish_color_quote           d8c098          # arena clara — "strings"

# ── Syntax: estructura ────────────────────────────────────────
set -g fish_color_comment         7a6e64          # gris cálido oscuro — # comentarios
set -g fish_color_bracket         b0d0d8          # cyan claro — () [] {}

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      e8e8e8 --underline
set -g fish_color_cwd             d8d8d8          # gris claro — directorio actual
set -g fish_color_cwd_root        d47a6e          # rojo apagado claro — root

# ── Autosuggestions & historial ───────────────────────────────
set -g fish_color_autosuggestion  5a5a5a          # color8 — ghost text
set -g fish_color_history_current e8e8e8 --bold
set -g fish_color_cancel          b85c50          # rojo apagado — Ctrl-C

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    e8e8e8 --background=1e2e38
set -g fish_color_selection       e8e8e8 --background=2e3238
set -g fish_color_match           c8b898          # arena cálida — brackets coincidentes

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            e8e8e8
set -g fish_color_host            8098a8          # azul gris claro — hostname
set -g fish_color_host_remote     d8c098          # arena clara — SSH

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          b85c50          # rojo apagado — exit code

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              5a5a5a
set -g fish_pager_color_prefix                e8e8e8
set -g fish_pager_color_completion            d8d8d8
set -g fish_pager_color_description           8098a8          # azul gris claro
set -g fish_pager_color_secondary             7a7a7a

set -g fish_pager_color_selected_background   --background=2e3238
set -g fish_pager_color_selected_prefix       e8e8e8
set -g fish_pager_color_selected_completion   e8e8e8
set -g fish_pager_color_selected_description  c8b898          # arena cálida