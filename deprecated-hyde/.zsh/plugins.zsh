#==============================================================================
# ZINIT CONFIGURATION
#==============================================================================

# Initialize Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# Theme (load immediately as it's needed for prompt)
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Completion and suggestions (can be loaded after prompt)
zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zsh-users/zsh-completions

# Syntax highlighting (load last for best compatibility)
zinit ice wait'0' lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# History search
zinit ice wait lucid
zinit light zsh-users/zsh-history-substring-search

# Additional tools - only load if they exist
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

# Load zoxide if available
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
fi