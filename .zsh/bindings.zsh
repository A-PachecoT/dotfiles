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

# Set vi mode
bindkey -v
export KEYTIMEOUT=1 