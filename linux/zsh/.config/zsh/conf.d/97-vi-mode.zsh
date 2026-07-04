#!/usr/bin/env zsh
#  Vi mode for the command line (Esc -> NORMAL)
#
#  Loaded from conf.d (not user.zsh) on purpose, same rationale as
#  99-tmux-workflow.zsh: HyDE's user-config loader can shadow user.zsh, but
#  conf.d/*.zsh is always sourced. Numbered 97 so it loads before plugins that
#  might rebind keys.
[[ -f "$HOME/dotfiles/shared/zsh/vi-mode.zsh" ]] && source "$HOME/dotfiles/shared/zsh/vi-mode.zsh"
