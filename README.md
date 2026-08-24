# development_setup

Dotfiles for my machines: **herdr** (tokyo-night) and **Neovim** (LazyVim + Tokyo Night moon).

The look lives in config, not in compiled plugin caches. Cloning this repo and copying the files below restores both themes.

## Layout

| Path | Goes on a new machine |
| --- | --- |
| `herdr_config.toml` | `~/.config/herdr/config.toml` |
| `nvim/` | `~/.config/nvim/` |

Do not copy herdr logs, sockets, or `session.json`. Those are local runtime files.

## Restore Neovim

Needs Neovim 0.11+, git, a C compiler (`build-essential`), `unzip`, `ripgrep`, and `fd` (`fd-find` on Ubuntu, symlink `fd` → `fdfind`).

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
