# Allow HyDE's Oh My Zsh loading for better stability
# unset DEFER_OMZ_LOAD

# Configure instant prompt behavior BEFORE loading it
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

#==============================================================================
# INSTANT PROMPT (Must be at the start)
#==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Suppress instant prompt warning for pokego
# Use 'quiet' to keep instant prompt but suppress warnings, or 'off' to disable it completely
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

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

# Allow HyDE to manage plugins for better integration
# plugins=()

# Ensure vim mode is active after all plugins load
bindkey -v
export KEYTIMEOUT=1

# Execute pokego only for interactive shells and after all initialization
# Skip in VS Code, non-interactive shells, or if explicitly disabled
if [[ $- == *i* ]] && [[ -z "${POKEGO_SKIP}" ]] && [[ "${TERM_PROGRAM}" != "vscode" ]] && [[ "${VSCODE_INJECTION}" != "1" ]]; then
    # Use a simple deferred execution for pokego
    autoload -Uz add-zsh-hook
    _pokego_delayed() {
        pokego --random 1 --no-title
        add-zsh-hook -d precmd _pokego_delayed
    }
    add-zsh-hook precmd _pokego_delayed
fi
