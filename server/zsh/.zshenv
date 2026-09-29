# Headless server (server profile): point zsh at the XDG config, same layout the
# Arch desktop gets from HyDE. Stowed from ~/dotfiles/server/zsh.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
[[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
