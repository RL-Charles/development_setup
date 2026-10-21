#!/usr/bin/env bash
# Sync the WSL + Windows setup between this machine and the repo.
#   dotfiles.sh export    copy live files into the repo
#   dotfiles.sh diff      show what differs between the repo and the machine
#   dotfiles.sh install   copy repo files onto the machine (backs up what it replaces)
#   dotfiles.sh packages  install the mise toolchain and Omarchy's bash defaults
#   dotfiles.sh windows   install Windows apps, login items and settings (after install)
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
manifest="$here/manifest.txt"
win_home=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")

# Prints: <absolute machine path> TAB <path in repo> TAB <label>
entries() {
  grep -vE '^\s*(#|$)' "$manifest" | while read -r path repo_path; do
    if [[ $path == win:* ]]; then
      path=${path#win:}
      printf '%s\t%s\t%s\n' "$win_home/$path" "${repo_path:-wsl/windows/$path}" "win:$path"
    else
      printf '%s\t%s\t%s\n' "$HOME/$path" "${repo_path:-wsl/home/$path}" "~/$path"
    fi
  done
}

sync_path() { # src dst
  mkdir -p "$(dirname "$2")"
  if [[ $1 == */ ]]; then
    rsync -a --delete --exclude '*.bak*' "$1" "$2"
  else
    cp "$1" "$2"
  fi
}

cmd_export() {
  entries | while IFS=$'\t' read -r path repo_path label; do
    if [[ -e $path ]]; then
      sync_path "$path" "$repo/$repo_path"
    else
      echo "skip (missing): $label" >&2
    fi
  done
  echo "Exported to $repo. Review with: git -C $repo status"
}

cmd_diff() {
  entries | while IFS=$'\t' read -r path repo_path _; do
    diff -ru --exclude='*.bak*' "$repo/$repo_path" "$path" || true
  done
}

cmd_install() {
  local backup="$HOME/.config-backups/development_setup-$(date +%Y%m%d-%H%M%S)"
  entries | while IFS=$'\t' read -r path repo_path label; do
    [[ -e $repo/$repo_path ]] || continue
    if [[ -e $path ]]; then
      mkdir -p "$(dirname "$backup/${label#\~/}")"
      cp -a "$path" "$backup/${label#\~/}"
    fi
    sync_path "$repo/$repo_path" "$path"
  done
  echo "Previous files backed up to $backup"
}

cmd_packages() {
  command -v mise >/dev/null || curl -fsSL https://mise.run | sh
  ~/.local/bin/mise install -y
  if [[ -d ~/.local/share/omarchy/.git ]]; then
    git -C ~/.local/share/omarchy pull --ff-only
  else
    git clone --depth 1 https://github.com/basecamp/omarchy ~/.local/share/omarchy
  fi
  if [[ ! -d ~/.local/share/blesh/.git ]]; then
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh ~/.local/share/blesh
  fi
  make -C ~/.local/share/blesh
}

cmd_windows() {
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$here/windows.ps1")"
}

case "${1:-}" in
  export) cmd_export ;;
  diff) cmd_diff ;;
  install) cmd_install ;;
  packages) cmd_packages ;;
  windows) cmd_windows ;;
  *) sed -n '2,7p' "$0"; exit 1 ;;
esac
