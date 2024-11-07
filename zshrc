# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias c='clear'

alias venv='source venv/bin/activate'
alias gate='python3 gateway.py'
alias cdya='cd /mnt/d/yavendio/clients_backends'

alias cdco='cd /mnt/d/code'
alias cddo='cd /mnt/c/Users/Andre/Downloads'
alias cdh='cd /home/andre'

alias cu='cursor .'
alias ex='explorer.exe .'

alias cduni='cd /mnt/c/Users/AndreP/OneDrive\ -\ UNIVERSIDAD\ NACIONAL\ DE\ INGENIERIA/UNI-HUB/UNI\ 2024-2/'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Key bindings configuration for zsh in WSL

# Navigation
bindkey "^[[H" beginning-of-line       # Home
bindkey "^[[F" end-of-line             # End
bindkey "^[[1;5C" forward-word         # Ctrl + Right arrow
bindkey "^[[1;5D" backward-word        # Ctrl + Left arrow

# Editing
bindkey "^[[3~" delete-char            # Delete
bindkey "^H" backward-delete-char      # Backspace
bindkey "^[[3;5~" delete-word          # Ctrl + Delete (delete next word)
bindkey "^W" backward-kill-word        # Ctrl + W (delete previous word)

# History
bindkey "^[[A" history-beginning-search-backward  # Up arrow
bindkey "^[[B" history-beginning-search-forward   # Down arrow

# Other useful shortcuts
bindkey "^U" kill-whole-line           # Ctrl + U (delete entire line)
bindkey "^L" clear-screen              # Ctrl + L (clear screen)
bindkey "^A" beginning-of-line         # Ctrl + A (move to beginning of line)
bindkey "^E" end-of-line               # Ctrl + E (move to end of line)
bindkey "^K" kill-line                 # Ctrl + K (delete from cursor to end of line)
bindkey "^R" history-incremental-search-backward  # Ctrl + R (incremental history search)

# Custom widget to delete selected text
delete-selected-text() {
    if ((REGION_ACTIVE)) then
        zle kill-region
    else
        zle delete-char
    fi
}
zle -N delete-selected-text

# Text selection nal support
bindkey "^[[1;2D" backward-char        # Shift + Left arrow
bindkey "^[[1;2C" forward-char         # Shift + Right arrow
bindkey "^[[1;2A" up-line-or-history   # Shift + Up arrow
bindkey "^[[1;2B" down-line-or-history # Shift + Down arrow
bindkey "^[[1;2H" beginning-of-line    # Shift + Home
bindkey "^[[1;2F" end-of-line          # Shift + End

# Word selection
bindkey "^[[1;6D" backward-word        # Ctrl + Shift + Left arrow
bindkey "^[[1;6C" forward-word         # Ctrl + Shift + Right arrow

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# export PATH="/opt/miniconda3/bin:$PATH"  # commented out by conda initialize
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$HOME/.local/bin:$PATH"
