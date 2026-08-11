# Completion for `kitasan` — subcommands with description, plus specific
# completion for the ones that take an argument (theme <scheme>, mode <profile>).
# The subcommand list and the valid-schemes list have to match
# fish/functions/kitasan.fish (switch "$sub" / "set -l valid" in
# __kitasan_theme) — not derived automatically, same approach already used by
# fish/conf.d/tools.fish for the `ec` aliases vs __ec_targets.

set -l subcommands health clean update theme wall mode doctor dashboard menu

complete -c kitasan -f

# ── Subcommands (only if none has been chosen yet) ────────────────────
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a health -d "System health check"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a clean -d "Quick cache cleanup"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a update -d "Full update (pacman + AUR)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a theme -d "Visual profile (matugen scheme)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a wall -d "Terminal wallpaper picker (fzf)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a mode -d "Desktop mode (normal/focus/gaming/cinema)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a doctor -d "Parity + keybinds + services + orphans"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a dashboard -d "System overview (rofi)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a menu -d "All of the above, chosen from rofi"

# ── kitasan clean --deep ────────────────────────────────────────────────
complete -c kitasan -n "__fish_seen_subcommand_from clean" -l deep -d "Orphans + pacman cache (sudo)"

# ── kitasan theme <scheme> — same 9 validated by __kitasan_theme ─────────
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a tonal-spot  -d "matugen default"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a vibrant     -d "Saturated colors"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a expressive -d "Contrasting accents"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a fidelity   -d "Faithful to the image's colors"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a content   -d "Balanced over the content"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a neutral    -d "Low contrast, muted"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a rainbow    -d "Multicolor"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a monochrome -d "Grayscale"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a fruit-salad -d "Multicolor, softer than rainbow"

# ── kitasan mode <profile> ──────────────────────────────────────────────
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a normal -d "Everything as usual"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a focus  -d "DND on, later lock"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a gaming -d "No blur/animations, performance profile"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a cinema -d "Bar hidden, no auto-lock"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a status -d "Show current mode"
