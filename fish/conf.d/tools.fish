if status is-interactive; and command -q zoxide
    zoxide init fish | source
end

# The rest of this file is pure alias/interactive convenience — without this
# guard, any fish script (including "dotbackup" before it was deliberately
# forced to "command ls") would inherit "ls" pointing to eza, etc.
if status is-interactive
    # ── Modern CLI Replacements ──────────────────────────────
    alias cat="bat --paging=never"
    alias less="bat"
    alias ls="eza --icons --group-directories-first"
    alias lah="eza -lah --icons --group-directories-first"
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
    # All of this now lives in functions/ec.fish (with tab-completion:
    # "ec <TAB>"). The old names are kept as wrappers so muscle memory
    # doesn't break — adding a new config is one line in __ec_targets, not
    # another alias here.
    # NOTE: this list has to match __ec_targets in functions/ec.fish. It's
    # deliberately not derived from there — doing so would force loading
    # ec.fish on EVERY shell start just to read the names, and ec.fish lives
    # in functions/ specifically so it only loads when you actually use it.
    # The price is having to add the name on both sides.
    for __ec_name in swaync hypr waybar fish kitty hyprlock rofi wlogout \
        cava fastfetch matugen starship
        alias ec$__ec_name="ec $__ec_name"
    end
    set -e __ec_name
end