# Configuration for zsh in Linux

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Initialize Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# Load Powerlevel10k theme
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Load plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Basic aliases
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'

# Development aliases
alias venv='source venv/bin/activate'
alias py='python3'
alias pip='pip3'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Key bindings
bindkey "^[[H" beginning-of-line       # Home
bindkey "^[[F" end-of-line             # End
bindkey "^[[1;5C" forward-word         # Ctrl + Right arrow
bindkey "^[[1;5D" backward-word        # Ctrl + Left arrow
bindkey "^[[3~" delete-char            # Delete
bindkey "^H" backward-delete-char      # Backspace
bindkey "^[[3;5~" delete-word          # Ctrl + Delete
bindkey "^W" backward-kill-word        # Ctrl + W
bindkey "^[[A" history-beginning-search-backward  # Up arrow
bindkey "^[[B" history-beginning-search-forward   # Down arrow

# Load custom completions
autoload -Uz compinit
compinit

# Set vi mode
bindkey -v
export KEYTIMEOUT=1

# Enable correction
setopt correct

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh