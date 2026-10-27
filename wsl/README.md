# Windows 11 + WSL2 setup

The work laptop: Windows 11 with WSL2 Ubuntu, set up to look and behave like
Omarchy. This is separate from the Omarchy (Arch) setup in `omarchy/` and the
shared files at the repo root; nothing in here is used on Linux.

## Layout

| Path | What it is |
| --- | --- |
| `manifest.txt` | Every file this machine syncs. `win:` entries are under the Windows profile |
| `dotfiles.sh` | `export` / `diff` / `install` / `packages` / `windows` |
| `windows.ps1` | Windows apps (winget), login items and settings; run by `dotfiles.sh windows` |
| `home/` | WSL `$HOME` files, at their `$HOME` path |
| `windows/` | Windows profile files, at their `%USERPROFILE%` path |
| `vscode-extensions.txt` | VS Code extensions on this machine |

Every manifest entry is a WSL copy under `home/` or `windows/`. The repo-root
files with the same names (nvim, starship, git, Windows Terminal, WezTerm,
herdr, VS Code) belong to the Omarchy/shared setup; changing one doesn't
change the other.

## Fresh machine

```bash
git clone https://github.com/RL-Charles/development_setup.git ~/development_setup
cd ~/development_setup
wsl/dotfiles.sh packages
wsl/dotfiles.sh install
wsl/dotfiles.sh windows
```

## VS Code

VS Code runs on Windows and opens WSL folders through Remote - WSL (`code .`
from a WSL shell). Its user settings and keybindings are Windows files,
`windows/AppData/Roaming/Code/User/`, synced by the manifest. The default
terminal is Ubuntu (WSL) in JetBrainsMono Nerd Font 9 medium, matching
Windows Terminal.

Install VS Code (PowerShell, no admin):

```powershell
winget install --id Microsoft.VisualStudioCode --exact --scope user
```

Then `wsl --shutdown` so WSL picks up `code` on the PATH, and install the
extensions on both sides. Windows (UI side) from PowerShell:

```powershell
wsl bash -c 'cat ~/development_setup/wsl/vscode-extensions.txt' | ForEach-Object { code --install-extension $_ }
```

WSL (language servers, debuggers) from a WSL shell; the Remote extensions only
run on Windows:

```bash
grep -vE '^ms-vscode(-remote)?\.remote' ~/development_setup/wsl/vscode-extensions.txt | xargs -n1 code --install-extension
```
