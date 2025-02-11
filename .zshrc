#==============================================================================
# INSTANT PROMPT (Must be at the start)
#==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#==============================================================================
# SOURCE MODULES
#==============================================================================
# Define the config directory
ZSH_CONFIG_DIR="${HOME}/.zsh"

# Source all module files
source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# Load modules in specific order
source_if_exists "$ZSH_CONFIG_DIR/exports.zsh"    # Load exports first
source_if_exists "$ZSH_CONFIG_DIR/plugins.zsh"    # Then plugins
source_if_exists "$ZSH_CONFIG_DIR/functions.zsh"  # Functions
source_if_exists "$ZSH_CONFIG_DIR/aliases.zsh"    # Aliases
source_if_exists "$ZSH_CONFIG_DIR/bindings.zsh"   # Key bindings
source_if_exists "$ZSH_CONFIG_DIR/completion.zsh" # Completion settings
source_if_exists "$ZSH_CONFIG_DIR/history.zsh"    # History configuration

# Load WSL-specific configuration if in WSL
if uname -r | grep -q "WSL"; then
    source_if_exists "$ZSH_CONFIG_DIR/wsl.zsh"
fi

# Load Powerlevel10k theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
