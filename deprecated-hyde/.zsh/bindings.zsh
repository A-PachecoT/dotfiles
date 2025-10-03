#==============================================================================
# KEY BINDINGS
#==============================================================================
bindkey "^[[H" beginning-of-line       # Home
bindkey "^[[F" end-of-line             # End
bindkey "^[[1;5C" forward-word         # Ctrl + Right arrow
bindkey "^[[1;5D" backward-word        # Ctrl + Left arrow
bindkey "^[[3~" delete-char            # Delete
bindkey "^H" backward-delete-char      # Backspace
bindkey "^[[3;5~" delete-word          # Ctrl + Delete
bindkey "^W" backward-kill-word        # Ctrl + W

#==============================================================================
# VIM MODE & HISTORY SEARCH
#==============================================================================
# Set vi mode
bindkey -v
export KEYTIMEOUT=1

# Enable history search with completion
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Smart history search
bindkey "^P" up-line-or-beginning-search      # Ctrl+P: search history backward
bindkey "^N" down-line-or-beginning-search    # Ctrl+N: search history forward

# Additional Vim-like bindings
bindkey '^R' history-incremental-search-backward  # Ctrl+R: search history
bindkey '^S' history-incremental-search-forward   # Ctrl+S: search history forward
bindkey '^A' beginning-of-line                    # Ctrl+A: start of line
bindkey '^E' end-of-line                         # Ctrl+E: end of line