# Machine setup

Work laptop: Windows 11 + WSL2 Ubuntu (distro name `Ubuntu`, systemd on). I came from Omarchy (Arch + Hyprland) and want this machine to look and behave like it.

## Dotfiles

- Repo: `~/development_setup` (github.com/RL-Charles/development_setup). Every config change I want kept goes through it.
- WSL + Windows files are listed in `wsl/manifest.txt` and synced by `wsl/dotfiles.sh` (`export` / `diff` / `install` / `packages`). `win:` entries live under the Windows profile (`/mnt/c/Users/charl`).
- After changing a live config, run `wsl/dotfiles.sh export` and show me `git diff`; don't commit or push without asking.
- `omarchy/` is the Omarchy machine's setup; leave it alone unless I ask.

## Shell and tools

- Bash, with Omarchy's default bash rc sourced from a clone at `~/.local/share/omarchy` (`OMARCHY_PATH`). Personal additions go in `~/.bashrc`, never in the clone.
- CLI tools come from mise (`~/.config/mise/config.toml`), not apt, so they install without sudo. Claude Code is the native install, not mise.
- `sudo` needs my password: give me the exact command to run with `! ` instead of trying it.

## Look

- Windows Terminal + Starship: Catppuccin Mocha, CaskaydiaMono Nerd Font 12 semibold.
- Neovim (LazyVim) + herdr: Tokyo Night (moon). This split is intentional.
- GlazeWM (`win:.glzr/glazewm/config.yaml`) carries Omarchy's Hyprland keybindings on the Win key.
