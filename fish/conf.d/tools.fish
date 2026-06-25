zoxide init fish | source

# ── Modern CLI Replacements ─────────────────────────────
alias cat="bat --style=plain --paging=never"
alias less="bat"
alias grep="rg"
alias ls="eza --icons --group-directories-first"
alias ll="eza -lah --icons --group-directories-first"
alias la="eza -a --icons --group-directories-first"
alias move="mv -v"
alias copy="cp -v"
alias copyall="cp -rv"
alias removeall="rm -rf"
alias remove="rm"
alias letters="toilet -f mono12"

# ── Personal Projects ───────────────────────────────────
alias game="cd ~/Projects/ProjectRPS && echo ""You Entered into the dev"""
alias exec_game="RPS.exe"
alias docs="cd ~/Projects/notas && echo ""Welcome to documentation from RPS"""
alias dotfiles="cd ~/Projects/dotfiles && echo ""Welcome to dotfiles on git""" 

# ── System Maintenance ──────────────────────────────────
alias mirrors="sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
alias fixkeys="sudo pacman -Syu archlinux-keyring"

# ── Logs & Diagnostics ──────────────────────────────────
alias failed="systemctl --failed"
alias userfailed="systemctl --user --failed"
alias jerrors="journalctl -b -p 3 --no-pager"

# ── Hardware & Monitoring ───────────────────────────────
alias disks="lsblk -f"
alias temps="watch -n 1 sensors"
 
