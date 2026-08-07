# Completado de `kitasan` — subcomandos con descripción, más completado
# específico para los que aceptan argumento (theme <esquema>, mode <perfil>).
# La lista de subcomandos y la de esquemas válidos tienen que coincidir con
# fish/functions/kitasan.fish (switch "$sub" / "set -l valid" en
# __kitasan_theme) — no derivadas automáticamente, mismo criterio que ya usa
# fish/conf.d/tools.fish para los alias de `ec` frente a __ec_targets.

set -l subcommands health clean update theme wall mode doctor dashboard menu

complete -c kitasan -f

# ── Subcomandos (sólo si todavía no se eligió ninguno) ────────────────────
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a health -d "Chequeo de salud del sistema"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a clean -d "Limpieza rápida de cache"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a update -d "Update completo (pacman + AUR)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a theme -d "Perfil visual (esquema de matugen)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a wall -d "Selector de wallpaper por terminal (fzf)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a mode -d "Modo de escritorio (normal/focus/gaming/cinema)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a doctor -d "Paridad + keybinds + servicios + huérfanos"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a dashboard -d "Panorama del sistema (rofi)"
complete -c kitasan -n "not __fish_seen_subcommand_from $subcommands" -a menu -d "Todo lo de arriba, elegido desde rofi"

# ── kitasan clean --deep ────────────────────────────────────────────────
complete -c kitasan -n "__fish_seen_subcommand_from clean" -l deep -d "Huérfanos + cache de pacman (sudo)"

# ── kitasan theme <esquema> — mismos 9 que valida __kitasan_theme ─────────
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a tonal-spot  -d "Default de matugen"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a vibrant     -d "Colores saturados"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a expressive -d "Acentos contrastantes"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a fidelity   -d "Fiel a los colores de la imagen"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a content   -d "Balanceado sobre el contenido"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a neutral    -d "Bajo contraste, apagado"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a rainbow    -d "Multicolor"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a monochrome -d "Escala de grises"
complete -c kitasan -n "__fish_seen_subcommand_from theme" -a fruit-salad -d "Multicolor, más suave que rainbow"

# ── kitasan mode <perfil> ──────────────────────────────────────────────
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a normal -d "Todo como siempre"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a focus  -d "DND on, bloqueo más tardío"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a gaming -d "Sin blur/animaciones, perfil performance"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a cinema -d "Barra oculta, sin bloqueo automático"
complete -c kitasan -n "__fish_seen_subcommand_from mode" -a status -d "Mostrar el modo actual"
