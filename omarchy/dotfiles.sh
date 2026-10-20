#!/usr/bin/env bash
# Sync the Omarchy setup between $HOME and this repo.
#   dotfiles.sh export    copy live files into the repo + refresh package lists
#   dotfiles.sh diff      show what differs between the repo and $HOME
#   dotfiles.sh install   copy repo files into $HOME (backs up what it replaces)
#   dotfiles.sh packages  install the saved pacman/AUR packages
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
manifest="$here/manifest.txt"
services=(omarchy-keep-awake-on-ac.service omarchy-captive-portal.service voxtype.service cua-driver.service)

entries() {
  grep -vE '^\s*(#|$)' "$manifest" | while read -r home_path repo_path; do
    printf '%s\t%s\n' "$home_path" "${repo_path:-omarchy/home/$home_path}"
  done
}

sync_path() { # src dst
  mkdir -p "$(dirname "$2")"
  if [[ $1 == */ ]]; then
    rsync -a --delete --exclude '*.bak*' "$1" "$2"
  else
    cp -a "$1" "$2"
  fi
}

export_packages() {
  local base
  base=$(cat /usr/share/omarchy/install/omarchy-{base,other}.packages | grep -vE '^\s*(#|$)' | sort -u)
  comm -23 <(pacman -Qqen | sort) <(echo "$base") >"$here/packages/pacman.txt"
  # Foreign packages split into AUR ones and local builds (e.g. the dock driver).
  : >"$here/packages/aur.txt"
  : >"$here/packages/local-builds.txt"
  pacman -Qqm | sort | while read -r pkg; do
    if yay -Si --aur "$pkg" >/dev/null 2>&1; then
      echo "$pkg" >>"$here/packages/aur.txt"
    else
      echo "$pkg" >>"$here/packages/local-builds.txt"
    fi
  done
}

export_style() {
  local bg
  bg=$(readlink -f "$HOME/.local/state/omarchy/current/background")
  {
    echo "THEME=$(omarchy theme current)"
    echo "FONT=\"$(omarchy font current)\""
    echo "BACKGROUND=\"${bg#"$HOME"/}\""
  } >"$here/style.env"
}

cmd_export() {
  mkdir -p "$here/packages"
  export_style
  entries | while IFS=$'\t' read -r home_path repo_path; do
    if [[ -e $HOME/$home_path ]]; then
      sync_path "$HOME/$home_path" "$repo/$repo_path"
    else
      echo "skip (missing): ~/$home_path" >&2
    fi
  done
  export_packages
  echo "Exported to $repo. Review with: git -C $repo status"
}

cmd_diff() {
  entries | while IFS=$'\t' read -r home_path repo_path; do
    diff -ru --exclude='*.bak*' "$repo/$repo_path" "$HOME/$home_path" || true
  done
}

cmd_install() {
  local backup="$HOME/.config-backups/development_setup-$(date +%Y%m%d-%H%M%S)"
  entries | while IFS=$'\t' read -r home_path repo_path; do
    [[ -e $repo/$repo_path ]] || continue
    if [[ -e $HOME/$home_path ]]; then
      mkdir -p "$(dirname "$backup/$home_path")"
      cp -a "$HOME/$home_path" "$backup/$home_path"
    fi
    sync_path "$repo/$repo_path" "$HOME/$home_path"
  done
  echo "Previous files backed up to $backup"

  systemctl --user daemon-reload
  for unit in "${services[@]}"; do
    systemctl --user enable "$unit" || echo "could not enable $unit (is its package installed?)" >&2
  done
  # shellcheck source=/dev/null
  source "$here/style.env"
  omarchy theme set "$THEME"
  omarchy font set "$FONT"
  [[ -f $HOME/$BACKGROUND ]] && omarchy theme bg set "$HOME/$BACKGROUND"

  hyprctl reload >/dev/null 2>&1 && hyprctl configerrors || true
  omarchy-restart-xcompose >/dev/null 2>&1 || true
}

cmd_packages() {
  sudo pacman -S --needed - <"$here/packages/pacman.txt"
  if [[ -s $here/packages/aur.txt ]]; then
    yay -S --needed - <"$here/packages/aur.txt"
  fi
  command -v mise >/dev/null && mise install
}

case "${1:-}" in
  export) cmd_export ;;
  diff) cmd_diff ;;
  install) cmd_install ;;
  packages) cmd_packages ;;
  *) sed -n '2,6p' "$0"; exit 1 ;;
esac
