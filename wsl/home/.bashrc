# WSL port of omarchy/home/.bashrc.
# Omarchy's bash defaults come from a clone of basecamp/omarchy, so aliases,
# inputrc, mise/starship/zoxide init stay identical to the Omarchy machine.
#   Update them with: git -C ~/.local/share/omarchy pull
export OMARCHY_PATH="$HOME/.local/share/omarchy"

# User tool paths, needed even for non-interactive shells (Omarchy's
# env-bootstrap does this, but it hard-codes /usr/share/omarchy)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.local/share/mise/shims:"*) ;;
  *) PATH="$PATH:$HOME/.local/share/mise/shims" ;;
esac
export PATH

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# Omarchy points these at omarchy-launch-* scripts, which don't exist on WSL
export EDITOR=nvim
export BROWSER=wslview

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Open files and URLs with the Windows default app instead of xdg-open
open() (
  wslview "$@" >/dev/null 2>&1 &
)

# Omarchy sources fzf's key bindings from the Arch package path; mise's fzf
# carries its own (Ctrl-R, Ctrl-T, Alt-C)
if command -v fzf &> /dev/null && [[ ! -f /usr/share/fzf/key-bindings.bash ]]; then
  eval "$(fzf --bash)"
fi

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# Inline history suggestions and programmable completion for interactive Bash.
# Right Arrow accepts the displayed suggestion.
[[ -r "$HOME/.local/share/blesh/out/ble.sh" ]] && source "$HOME/.local/share/blesh/out/ble.sh"
