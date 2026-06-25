#!/usr/bin/env fish
# ============================================================================
#  dotbackup.fish — backup interactivo de dotfiles a GitHub
# ----------------------------------------------------------------------------
#  Uso: dotbackup
#
#  Flujo:
#    1) Copia configs de ~/.config/* y archivos sueltos a ~/Projects/dotfiles
#    2) Muestra diff de lo que cambió
#    3) Pregunta si quieres editar el README antes de hacer commit
#    4) Pide confirmación antes de hacer commit + push
#    5) Muestra changelog de lo subido
# ============================================================================

set REPO "$HOME/Projects/dotfiles"
set CONFIG "$HOME/.config"

# Colores
set C_RESET  (set_color normal)
set C_BOLD   (set_color --bold white)
set C_DIM    (set_color brblack)
set C_GREEN  (set_color green)
set C_RED    (set_color red)
set C_YELLOW (set_color yellow)
set C_CYAN   (set_color cyan)
set C_BLUE   (set_color blue)

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo $C_BOLD"  󰊤  dotbackup — Kitasan Dotfiles"$C_RESET
echo $C_DIM"  ~/Projects/dotfiles → github.com/kitasael-burakku"$C_RESET
echo ""

# ── Verificar que el repo existe ──────────────────────────────────────────────
if not test -d "$REPO/.git"
    echo $C_RED"  ✘ No se encontró el repo en $REPO"$C_RESET
    exit 1
end

# ── Directorios de config a respaldar ────────────────────────────────────────
# Formato: "origen → destino_dentro_del_repo"
# Si origen = destino, solo pon el nombre una vez
set -l config_dirs \
    "cava" \
    "fastfetch" \
    "fish" \
    "hypr" \
    "hyprlock" \
    "kitty" \
    "rofi" \
    "swaync" \
    "waybar" \
    "wlogout"

# Scripts sueltos en ~/.config/scripts
set -l scripts_dir "scripts"

# Archivos sueltos en ~/.config (no son carpetas)
set -l config_files \
    "starship.toml" \
    "CLAUDE.md"

# Archivos sueltos en ~/Documents
set -l documents_files \
    "KEYBINDS.txt"

# LICENSE y README viven en el repo directamente — no se copian

# Docs
set -l docs_dir "docs"

# ── Paso 1: Copiar archivos ───────────────────────────────────────────────────
echo $C_CYAN"  󰋊  Copiando archivos..."$C_RESET
echo ""

# Configs de ~/.config/
for dir in $config_dirs
    set src "$CONFIG/$dir"
    set dst "$REPO/$dir"
    if test -d "$src"
        mkdir -p "$dst"
        cp -r "$src/." "$dst/"
        echo $C_DIM"    ✓ .config/$dir"$C_RESET
    else
        echo $C_DIM"    - .config/$dir (no existe, saltando)"$C_RESET
    end
end

# Scripts
if test -d "$CONFIG/$scripts_dir"
    mkdir -p "$REPO/$scripts_dir"
    cp -r "$CONFIG/$scripts_dir/." "$REPO/$scripts_dir/"
    echo $C_DIM"    ✓ .config/scripts"$C_RESET
end

# Docs
if test -d "$HOME/$docs_dir"
    mkdir -p "$REPO/$docs_dir"
    cp -r "$HOME/$docs_dir/." "$REPO/$docs_dir/"
    echo $C_DIM"    ✓ ~/docs"$C_RESET
end

# Archivos sueltos desde ~/.config
for file in $config_files
    set src "$CONFIG/$file"
    if test -f "$src"
        cp "$src" "$REPO/$file"
        echo $C_DIM"    ✓ .config/$file"$C_RESET
    end
end

# Archivos sueltos desde ~/Documents
for file in $documents_files
    set src "$HOME/Documents/$file"
    if test -f "$src"
        cp "$src" "$REPO/$file"
        echo $C_DIM"    ✓ ~/Documents/$file"$C_RESET
    end
end

echo ""

# ── Paso 2: Verificar si hay cambios ─────────────────────────────────────────
cd "$REPO"

if test -z "$(git status --porcelain)"
    echo $C_GREEN"  ✓ No hay cambios respecto al último backup."$C_RESET
    echo ""
    exit 0
end

# ── Paso 3: Mostrar diff ──────────────────────────────────────────────────────
echo $C_BOLD"  󰋚  Cambios detectados:"$C_RESET
echo ""

# Archivos nuevos
set new_files (git ls-files --others --exclude-standard)
if test -n "$new_files"
    echo $C_GREEN"  Archivos nuevos:"$C_RESET
    for f in $new_files
        echo $C_GREEN"    + $f"$C_RESET
    end
    echo ""
end

# Archivos modificados
set modified_files (git diff --name-only)
set staged_files (git diff --cached --name-only)
set all_modified (string join \n $modified_files $staged_files | sort -u | string collect)

if test -n "$all_modified"
    echo $C_YELLOW"  Archivos modificados:"$C_RESET
    for f in (echo $all_modified | tr ' ' '\n')
        echo $C_YELLOW"    ~ $f"$C_RESET
    end
    echo ""
end

# Archivos eliminados
set deleted_files (git ls-files --deleted)
if test -n "$deleted_files"
    echo $C_RED"  Archivos eliminados:"$C_RESET
    for f in $deleted_files
        echo $C_RED"    - $f"$C_RESET
    end
    echo ""
end

# Diff detallado opcional
echo $C_DIM"  ¿Ver diff detallado? [s/N] "$C_RESET
read -l show_diff
if string match -qi "s" "$show_diff"
    echo ""
    git diff --color HEAD
    echo ""
end

# ── Paso 4: Opción de editar README ──────────────────────────────────────────
echo $C_BLUE"  󰂺  ¿Quieres editar el README antes del commit? [s/N] "$C_RESET
read -l edit_readme
if string match -qi "s" "$edit_readme"
    set editor (command -v nvim || command -v vim || command -v nano)
    if test -n "$editor"
        $editor "$REPO/README.md"
        echo ""
        echo $C_DIM"  README actualizado."$C_RESET
        echo ""
    else
        echo $C_RED"  ✘ No se encontró editor (nvim/vim/nano)"$C_RESET
    end
end

# ── Paso 5: Mensaje de commit ─────────────────────────────────────────────────
set default_msg "dotfiles: backup "(date "+%Y-%m-%d %H:%M")
echo $C_BOLD"  󰊢  Mensaje de commit:"$C_RESET
echo $C_DIM"  (Enter para usar: $default_msg)"$C_RESET
echo $C_DIM"  > "$C_RESET
read -l commit_msg
if test -z "$commit_msg"
    set commit_msg "$default_msg"
end
echo ""

# ── Paso 6: Confirmación final ────────────────────────────────────────────────
echo $C_BOLD"  ¿Confirmar commit y push a main? [s/N] "$C_RESET
read -l confirm
if not string match -qi "s" "$confirm"
    echo ""
    echo $C_DIM"  Backup cancelado. Los archivos ya fueron copiados al repo local."$C_RESET
    echo ""
    exit 0
end

# ── Paso 7: Commit + Push ─────────────────────────────────────────────────────
echo ""
echo $C_CYAN"  󰊤  Haciendo commit..."$C_RESET

git add -A
git commit -m "$commit_msg"

if test $status -ne 0
    echo $C_RED"  ✘ Error en el commit"$C_RESET
    exit 1
end

echo ""
echo $C_CYAN"  󰊤  Pushing a main..."$C_RESET
git push origin main

if test $status -ne 0
    echo $C_RED"  ✘ Error en el push. ¿Tienes conexión y permisos?"$C_RESET
    exit 1
end

# ── Paso 8: Changelog ────────────────────────────────────────────────────────
echo ""
echo $C_GREEN$C_BOLD"  ✓ Push exitoso"$C_RESET
echo ""
echo $C_BOLD"  󰋚  Changelog del commit:"$C_RESET
echo ""
for line in (git show --stat HEAD | tail -n +2)
    echo "    $C_DIM$line$C_RESET"
end
echo ""
echo $C_DIM"  "(git log --oneline -1)"$C_RESET"
echo ""