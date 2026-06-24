# ~/.config/fish/conf.d/theme-overworld.fish
# Minecraft Overworld · Fish shell theme
# Palette: cave black · grass green · stone gray · golden wheat · water blue

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          e8e8e0          # snow white — default text
set -g fish_color_command         a8d878          # bright grass — command names
set -g fish_color_builtin         f0c030          # glowstone gold — echo, set, read…
set -g fish_color_keyword         cc2b2b          # redstone red — for, if, while…
set -g fish_color_end             9a9a8e          # stone gray — ; and newline
set -g fish_color_error           e8601a          # lava orange — syntax errors

# ── Syntax: arguments & operators ─────────────────────────────
set -g fish_color_param           a8c8d8          # ice blue — positional arguments
set -g fish_color_option          4a9ec0          # water blue — --flags and -options
set -g fish_color_operator        f0c030          # glowstone — = + - * | & …
set -g fish_color_redirection     4a9ec0          # water blue — > >> | &
set -g fish_color_escape          e8e8e0          # snow — \n \t \" …
set -g fish_color_quote           c9a84c          # wheat amber — "strings" 'strings'

# ── Syntax: structure ─────────────────────────────────────────
set -g fish_color_comment         7a7a76          # shadow stone — # comments
set -g fish_color_bracket         f0c030          # glowstone — () [] {}

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      e8e8e0 --underline
set -g fish_color_cwd             4a7c2f          # grass green — current dir
set -g fish_color_cwd_root        cc2b2b          # redstone — current dir when root

# ── Autosuggestions & history ─────────────────────────────────
set -g fish_color_autosuggestion  7a7a76          # shadow stone — ghost text
set -g fish_color_history_current 4a7c2f --bold   # grass green — selected history
set -g fish_color_cancel          e8601a          # lava — Ctrl-C

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    e8e8e0 --background=2a5a82
set -g fish_color_selection       e8e8e0 --background=1a1a18
set -g fish_color_match           f0c030          # glowstone — matching brackets

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            e8e8e0          # snow
set -g fish_color_host            4a9ec0          # water blue — local hostname
set -g fish_color_host_remote     c9a84c          # wheat — SSH hostname

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          e8601a          # lava — non-zero exit code

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              4a4a46
set -g fish_pager_color_prefix                4a7c2f   # grass — matched prefix
set -g fish_pager_color_completion            e8e8e0
set -g fish_pager_color_description           4a9ec0
set -g fish_pager_color_secondary             9a9a8e   # stone — alternate row

set -g fish_pager_color_selected_background   --background=1a1a18
set -g fish_pager_color_selected_prefix       4a7c2f
set -g fish_pager_color_selected_completion   e8e8e0
set -g fish_pager_color_selected_description  f0c030