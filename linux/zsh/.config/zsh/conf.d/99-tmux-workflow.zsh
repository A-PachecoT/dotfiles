#!/usr/bin/env zsh
#  tmux + yazi dev workflow (cl, y, tm, tw, ts, tp, th)
#
#  Loaded from conf.d (not user.zsh) on purpose: HyDE's user-config loader is an
#  if/elif chain that prefers $HOME/.user.zsh over $ZDOTDIR/user.zsh, so a stale
#  ~/.user.zsh can shadow the stowed user.zsh. conf.d/*.zsh is always sourced.
[[ -f "$HOME/dotfiles/shared/zsh/tmux-workflow.zsh" ]] && source "$HOME/dotfiles/shared/zsh/tmux-workflow.zsh"
