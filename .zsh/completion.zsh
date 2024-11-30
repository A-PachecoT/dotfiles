#==============================================================================
# COMPLETION CONFIGURATION
#==============================================================================
# Load custom completions
autoload -Uz compinit
compinit

# Enable correction
setopt correct

# Disable paste highlighting
zle_highlight+=(paste:none) 