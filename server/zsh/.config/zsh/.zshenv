# Server profile env (every zsh, interactive or not): PATH only.
# The conf.d/ modules are interactive-only here and load from .zshrc.
typeset -U path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)
export EDITOR=nvim VISUAL=nvim
