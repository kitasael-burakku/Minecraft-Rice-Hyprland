if status is-interactive
# Commands to run in interactive sessions can go here
end

set -g fish_greeting

starship init fish | source

# ------- Fastfetch -------
  function __fastfetch_random
      if not command -q fastfetch
          return
      end

      set -l configs $HOME/.config/fastfetch/config*.jsonc
      set -l count (count $configs)

      if test $count -eq 0
          return
      else if test $count -eq 1
          fastfetch --config "$configs[1]"
          return
      end

      set -l idx_file "$HOME/.config/fastfetch/.last_idx"
      set -l last 0

      if test -f "$idx_file"
          set last (string trim < "$idx_file")
      end

      set -l idx (random 1 $count)
      while test "$idx" = "$last"
          set idx (random 1 $count)
      end

      printf "%s\n" "$idx" > "$idx_file"
      fastfetch --config "$configs[$idx]"
  end

# Only run in real interactive shell
if status is-interactive
    __fastfetch_random
end

bind \cr history-pager

# Created by `pipx` on 2026-05-28 21:20:25
fish_add_path "$HOME/.local/bin"
