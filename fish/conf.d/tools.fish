if status is-interactive; and command -q zoxide
    zoxide init fish | source
end

# El resto de este archivo es puro alias/conveniencia interactiva — sin esta
# guarda, cualquier script fish (incluido "dotbackup" antes de que se le
# forzara "command ls" a propósito) hereda "ls" apuntando a eza, etc.
if status is-interactive
    # ── Modern CLI Replacements ──────────────────────────────
    alias cat="bat --style=plain --paging=never"
    alias less="bat"
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -lah --icons --group-directories-first"
    alias la="eza -a --icons --group-directories-first"
    alias move="mv -iv"
    alias copy="cp -iv"
    alias copyr="cp -riv"
    alias remove="rm -iv"
    alias remover="rm -riv"

    # ── System Maintenance ───────────────────────────────────
    alias mirrors="sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
    alias fixkeys="sudo pacman -Syu archlinux-keyring"

    # ── Logs & Diagnostics ───────────────────────────────────
    alias failed="systemctl --failed"
    alias userfailed="systemctl --user --failed"
    alias jerrors="journalctl -b -p 3 --no-pager"

    # ── Hardware & Monitoring ────────────────────────────────
    alias disks="lsblk -f"
    alias temps="watch -n 2 sensors"

    # ── Software Config ──────────────────────────────────────
    alias ecswaync="codium ~/.config/swaync && pkill kitty"
    alias echypr="codium ~/.config/hypr && pkill kitty"
    alias ecwaybar="codium ~/.config/waybar && pkill kitty"
    alias ecfish="codium ~/.config/fish && pkill kitty"

    alias eckitty="codium ~/.config/kitty && pkill kitty"
    alias echyprlock="codium ~/.config/hyprlock && pkill kitty"
    alias ecrofi="codium ~/.config/rofi && pkill kitty"
    alias ecwlogout="codium ~/.config/wlogout && pkill kitty"

    alias eccava="codium ~/.config/cava && pkill kitty"
    alias ecfastfetch="codium ~/.config/fastfetch && pkill kitty"
    alias ecstarship="codium ~/.config/matugen/templates/starship.toml ~/.config/starship.static.toml && pkill kitty"
end