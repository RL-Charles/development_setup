# development_setup

Dotfiles for restoring the same editor, multiplexer, shell, and colours on a
new machine (WSL today, Omarchy next).

The look lives in config, not in compiled plugin caches or login tokens.

Current split (kept as-is, not unified):

| Surface | Theme |
| --- | --- |
| herdr + Neovim | Tokyo Night (moon) |
| Windows Terminal + Starship + Ghostty | Catppuccin Mocha |
| VS Code | Dark+ |
| Cursor | Default Dark Modern (auto light/dark) |

## Layout

| Path | Goes on a new machine |
| --- | --- |
| `herdr_config.toml` | `~/.config/herdr/config.toml` |
| `nvim/` | `~/.config/nvim/` |
| `starship.toml` | `~/.config/starship.toml` |
| `zsh/.zshrc` | `~/.zshrc` |
| `git/.gitconfig` | `~/.gitconfig` (review the `gh` helper path) |
| `vscode/settings.json` | VS Code User `settings.json` (Linux / Omarchy) |
| `vscode/keybindings.json` | VS Code User `keybindings.json` |
| `vscode/extensions.txt` | `code --install-extension` each line |
| `vscode/windows/settings.json` | Windows VS Code only (Git Bash / Nushell paths) |
| `cursor/settings.json` | Cursor User `settings.json` (Linux / Omarchy) |
| `cursor/windows/settings.json` | Windows Cursor only |
| `windows-terminal/settings.json` | Windows Terminal `LocalState/settings.json` |
| `ghostty/config` | `~/.config/ghostty/config` (Omarchy host terminal) |

Do not copy herdr logs, sockets, or `session.json`. Those are local runtime files.
Do not copy Cursor/VS Code `auth.json`, `globalStorage`, or chat history.

## What this repo does not store

- GitHub / Railway / Cursor login tokens — run `gh auth login`, `railway login`, sign into Cursor
- TradiePro `.env.local` / `apps/api/.env` — copy privately or import into Bitwarden with `scripts/bw-import-tradiepro.sh`; never commit
- `~/.ssh` private keys (this WSL user had none; GitHub used `gh`)
- zsh history, nvim plugin caches, `node_modules`

## Restore Neovim

Needs Neovim 0.11+, git, a C compiler (`build-essential` on Debian, `base-devel` on Arch), `unzip`, `ripgrep`, and `fd` (`fd-find` on Ubuntu, symlink `fd` → `fdfind`).

```bash
git clone https://github.com/RL-Charles/development_setup.git
rm -rf ~/.config/nvim
cp -a development_setup/nvim ~/.config/nvim
nvim
```

First launch installs plugins from `nvim/lazy-lock.json` (including `tokyonight.nvim`). Theme is set in `nvim/lua/plugins/colorscheme.lua`.

## Restore herdr

```bash
mkdir -p ~/.config/herdr
cp development_setup/herdr_config.toml ~/.config/herdr/config.toml
herdr server reload-config
```

herdr 0.8.2 on the source machine. Prefix is `ctrl+space`. Theme is tokyo-night. `host_cursor = "native"` lets Neovim switch block vs bar.

## Restore shell (zsh + Starship)

Login shell is **zsh**. Prompt is **Starship** with Catppuccin Mocha.

```bash
# Arch / Omarchy
sudo pacman -S zsh starship
chsh -s /usr/bin/zsh

mkdir -p ~/.zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
cp development_setup/zsh/.zshrc ~/.zshrc
cp development_setup/starship.toml ~/.config/starship.toml
```

Optional afterwards: nvm, `gh`, Railway CLI, OpenCode. The zshrc sources those only if they exist.

## Import TradiePro env files into a Bitwarden collection

Linux CLI is `~/.local/bin/bw`. You log in once; the agent does the import.

```bash
~/development/development_setup/scripts/bw-agent-login.sh
```

That writes `~/.config/bitwarden-agent/session` (mode 600). Reply in Cursor `logged in`. Do not paste the session or env values into chat.

The importer creates one Secure Note per env file with hidden custom fields. stdout is names only. After import: `rm -f ~/.config/bitwarden-agent/session && bw lock`.

If you created a **folder** in the personal vault instead of an org collection, the agent will use `--folder` instead.

## Restore git identity

```bash
cp development_setup/git/.gitconfig ~/.gitconfig
gh auth login
```

## Restore VS Code

Linux / Omarchy:

```bash
mkdir -p ~/.config/Code/User
cp development_setup/vscode/settings.json ~/.config/Code/User/settings.json
cp development_setup/vscode/keybindings.json ~/.config/Code/User/keybindings.json
xargs -a development_setup/vscode/extensions.txt -I{} code --install-extension {}
```

On Windows, use `vscode/windows/settings.json` instead (Git Bash default profile, Nushell path, home-lab SSH host).

## Restore Cursor

Linux / Omarchy:

```bash
mkdir -p ~/.config/Cursor/User
cp development_setup/cursor/settings.json ~/.config/Cursor/User/settings.json
```

On Windows, use `cursor/windows/settings.json`. Do not copy `~/.cursor/cli-config.json` — it contains account tokens; set model/approval prefs in the app.

## Restore host terminal

**Windows:** replace Windows Terminal settings with `windows-terminal/settings.json` (default profile is WSL Ubuntu, Catppuccin Mocha, Cascadia Mono 12).

**Omarchy / Linux:** Ghostty is the usual host terminal.

```bash
mkdir -p ~/.config/ghostty
cp development_setup/ghostty/config ~/.config/ghostty/config
```

Install Cascadia Mono if you want the same typeface as Windows Terminal.

## Neovim navigation (QWERTY)

| Action | Keys |
| --- | --- |
| Find files | `Ctrl-p` / `<Space><Space>` / `<Space>ff` |
| Grep | `<Space>sg` |
| File tree | `<Space>e` |
| Harpoon add | `<Space>a` or `<Space>H` |
| Harpoon menu | `<Space>h` |
| Harpoon jump | `<Space>1`–`9` (or `Alt-1`–`4`) |
| Next / prev buffer | `Shift-l` / `Shift-h` |
