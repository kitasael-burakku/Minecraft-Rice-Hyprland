# ~/.config/fish/conf.d/theme-goldship.fish
# Kitasan-Ship Refined · Fish shell theme
# Palette: deep slate bg · crimson accent · muted steel secondary · warm amber highlight

# ── Syntax: core ──────────────────────────────────────────────
set -g fish_color_normal          e6e6e6          # default text
set -g fish_color_command         e6e6e6          # command names
set -g fish_color_builtin         e7be73          # echo, set, read, …
set -g fish_color_keyword         ff4f5e          # for, if, while, function, …
set -g fish_color_end             c7c7c7          # ; and newline terminators
set -g fish_color_error           ff6b77          # syntax errors

# ── Syntax: arguments & operators ─────────────────────────────
set -g fish_color_param           b8c5cc          # positional arguments
set -g fish_color_option          8aa2af          # --flags and -options
set -g fish_color_operator        e7be73          # = + - * | & …
set -g fish_color_redirection     8aa2af          # > >> | &
set -g fish_color_escape          f7f7f7          # \n \t \" …
set -g fish_color_quote           caa46a          # "strings" and 'strings'

# ── Syntax: structure ─────────────────────────────────────────
set -g fish_color_comment         6f6f6f          # # inline comments
set -g fish_color_bracket         e7be73          # () [] {}

# ── Paths ─────────────────────────────────────────────────────
set -g fish_color_valid_path      d8d8d8 --underline
set -g fish_color_cwd             ff4f5e          # current dir in prompt
set -g fish_color_cwd_root        ff6b77          # current dir when root

# ── Autosuggestions & history ─────────────────────────────────
set -g fish_color_autosuggestion  4a4a4a          # ghost text (press → to accept)
set -g fish_color_history_current ff4f5e --bold   # selected history entry
set -g fish_color_cancel          ff6b77          # Ctrl-C indicator

# ── Search & selection ────────────────────────────────────────
set -g fish_color_search_match    ffffff --background=384850
set -g fish_color_selection       ffffff --background=2a2a2a
set -g fish_color_match           ff4f5e          # matching parentheses / brackets

# ── Prompt: user & host ───────────────────────────────────────
set -g fish_color_user            e6e6e6
set -g fish_color_host            8aa2af          # local hostname
set -g fish_color_host_remote     e7be73          # SSH hostname

# ── Prompt: status ────────────────────────────────────────────
set -g fish_color_status          ff6b77          # non-zero exit code

# ── Completions pager ─────────────────────────────────────────
set -g fish_pager_color_progress              6f6f6f
set -g fish_pager_color_prefix                ff4f5e  # matched prefix highlight
set -g fish_pager_color_completion            e6e6e6
set -g fish_pager_color_description           8aa2af
set -g fish_pager_color_secondary             909090  # alternate row tint

set -g fish_pager_color_selected_background   --background=24282c
set -g fish_pager_color_selected_prefix       ff4f5e
set -g fish_pager_color_selected_completion   ffffff
set -g fish_pager_color_selected_description  e7be73