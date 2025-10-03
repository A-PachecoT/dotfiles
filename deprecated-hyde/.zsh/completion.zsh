#==============================================================================
# COMPLETION CONFIGURATION
#==============================================================================
# Load custom completions
autoload -Uz compinit
compinit

# Disable default zsh correction since we're using thefuck
unsetopt correct
unsetopt correct_all

# Disable paste highlighting
zle_highlight+=(paste:none)

# The Fuck CLI completion and alias
if command -v thefuck >/dev/null 2>&1; then
    eval $(thefuck --alias)
fi 