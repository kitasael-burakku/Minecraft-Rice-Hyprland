# Documentation Index

This folder holds the deep-dive docs for [Minecraft-Rice-Hyprland](../README.md). The top-level `README.md` is a short landing page; everything below is where the actual how-to and why-to live.

| Doc | Read this if you want to... |
|---|---|
| [INSTALLATION.md](INSTALLATION.md) | Get this rice running on your own machine, step by step, in the order things actually need to happen |
| [THEMING.md](THEMING.md) | Understand or change the color pipeline (static vs. matugen), GTK/Qt theming, and where to get the icon/cursor/GTK themes this rice uses |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Understand how the pieces fit together — the Lua config system, the systemd session lifecycle, the Rofi wallpaper picker, and the `dotbackup` deploy pipeline |

Two more references live outside this folder, on purpose:

- **[`../KEYBINDS.txt`](../KEYBINDS.txt)** — the full keybind list. It stays at the repo root because it's *generated* (`hypr/scripts/generate-keybinds-doc.sh`, from `hypr/modules/keybinds.lua`) and deployed to `~/Documents/KEYBINDS.txt`, where the `keybinds` Fish function reads it directly. Moving it here would break that path. It's written in Spanish — that's a separate, known gap, not an oversight.
- **[`../README.md`](../README.md)** — highlights, screenshots, feature list, hardware/compatibility, credits, and the project philosophy.

If something here goes stale relative to the actual config, the config is the source of truth — these docs describe it, they don't drive it.
