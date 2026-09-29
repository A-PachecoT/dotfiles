# Server profile .zshrc — the minimal stand-in for HyDE's loader on a headless box.
# Plugins come from apt (server/bootstrap-ubuntu.sh); the prompt is powerlevel10k
# cloned to ~/.local/share/powerlevel10k; user layer = linux/zsh (conf.d + .p10k.zsh).
# user.zsh is NOT sourced: it is HyDE-specific (OMZ plugins, do_render, desktop art).

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE AUTO_CD INTERACTIVE_COMMENTS

autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Ubuntu names these binaries differently
(( $+commands[fdfind] && ! $+commands[fd] )) && alias fd=fdfind
(( $+commands[batcat] && ! $+commands[bat] )) && alias bat=batcat
(( $+commands[eza] )) && alias ls='eza --group-directories-first' ll='eza -lha --group-directories-first'

# User modules (linux/zsh/.config/zsh/conf.d: zoxide, vi-mode, tmux workflow, mesh, …)
for file in "$ZDOTDIR"/conf.d/*.zsh(N); do
  [[ -r "$file" ]] && source "$file"
done

[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

P10K_THEME="$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"
if [[ -r "$P10K_THEME" ]]; then
  source "$P10K_THEME"
  [[ -r "$ZDOTDIR/.p10k.zsh" ]] && source "$ZDOTDIR/.p10k.zsh"
fi

# Must be last
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
