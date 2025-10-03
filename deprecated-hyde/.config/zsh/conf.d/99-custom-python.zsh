#!/usr/bin/env zsh

#==============================================================================
# CUSTOM PYTHON & DEVELOPMENT CONFIGURATION
# 
# This file is part of the dotfiles Python environment setup.
# It provides a comprehensive Python development environment with:
# - System Python for AUR builds and system tools
# - uv-based base environment with common data science libraries
# - Jupyter integration with proper kernels
# - Global development tools
#
# See PYTHON_SETUP.md for complete documentation
#==============================================================================

# Export environment variables for Python compatibility
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
export TF_CPP_MIN_LOG_LEVEL=1

# Task Master aliases (development productivity)
alias tm='task-master'
alias taskmaster='task-master'
alias warp='warp-terminal'

#==============================================================================
# PYTHON ENVIRONMENT MANAGEMENT
#==============================================================================

# Primary Python environments
alias pybase="source ~/.venvs/base/bin/activate"  # Base env with common data science packages
alias pysys="deactivate 2>/dev/null && which python"   # Use system Python for AUR builds
alias pyconda="source /opt/miniconda3/etc/profile.d/conda.sh && conda activate base"  # Conda when needed

# Jupyter shortcuts - launches with base environment pre-loaded
alias jlab="source ~/.venvs/base/bin/activate && jupyter lab"  # JupyterLab
alias jnb="source ~/.venvs/base/bin/activate && jupyter notebook"  # Jupyter Notebook

#==============================================================================
# ENHANCED HISTORY CONFIGURATION
#==============================================================================

# Store history in XDG-compliant location
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

# History behavior options
setopt APPEND_HISTORY             # Write to history file immediately
setopt HIST_EXPIRE_DUPS_FIRST     # Expire duplicate entries first when trimming
setopt HIST_FIND_NO_DUPS          # Do not display previously found duplicates
setopt HIST_IGNORE_ALL_DUPS       # Delete old recorded entry if new entry is duplicate
setopt HIST_IGNORE_DUPS           # Don't record an entry that was just recorded again
# Note: HIST_IGNORE_SPACE disabled in Warp as it conflicts with bootstrap
if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
  setopt HIST_IGNORE_SPACE        # Don't record entries starting with space
fi
setopt HIST_NO_STORE              # Don't store history commands themselves
setopt HIST_REDUCE_BLANKS         # Remove superfluous blanks before recording
setopt HIST_SAVE_NO_DUPS          # Don't save duplicate entries to history file
setopt INC_APPEND_HISTORY         # Write to history file immediately, not on exit
setopt SHARE_HISTORY              # Share history between all zsh sessions
SHELL_SESSION_HISTORY=0           # Disable per-terminal-session history

#==============================================================================
# NODE.JS ENVIRONMENT (keeping existing configuration)
#==============================================================================

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load nvm bash completion

#==============================================================================
# BUN ENVIRONMENT (keeping existing configuration)
#==============================================================================

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/home/andre/.bun/_bun" ] && source "/home/andre/.bun/_bun"

#==============================================================================
# UV INTEGRATION & DEFAULT ENVIRONMENT
#==============================================================================

# Add UV to PATH if not already present
export PATH="$HOME/.local/bin:$PATH"

# Add cargo bin to PATH for Rust tools like code2prompt
export PATH="$HOME/.cargo/bin:$PATH"

# UV shortcuts for quick package installation
alias uvx='uv tool run'  # Run tools without installing
alias uvi='uv pip install'  # Install packages in current env
alias uvs='uv pip sync'  # Sync packages from requirements
alias uvr='uv run'  # Run commands in UV environment

# Function to use UV globally for pip commands
function pip() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Handle special cases
        if [[ "$1" == "--version" ]] || [[ "$1" == "-V" ]]; then
            echo "pip (via uv) - using $(uv --version)"
            return 0
        fi
        uv pip "$@"
    else
        echo "No virtual environment active. Use 'pybase' or create one with 'uv venv'"
        return 1
    fi
}

# Auto-activate base environment on shell startup for UV default behavior
# This ensures UV commands work immediately
if [[ -z "$VIRTUAL_ENV" ]] && [[ -d ~/.venvs/base ]]; then
    source ~/.venvs/base/bin/activate >/dev/null 2>&1
fi

#==============================================================================
# DEVELOPMENT ENVIRONMENT VALIDATION
#==============================================================================

# Optional: Function to validate Python environment setup
function validate_python_env() {
    echo "🐍 Python Environment Status:"
    echo "  System Python: $(which python) ($(python --version 2>/dev/null || echo 'Not found'))"
    echo "  uv available: $(which uv >/dev/null && echo '✅' || echo '❌')"
    echo "  Base env: $([ -d ~/.venvs/base ] && echo '✅' || echo '❌')"
    echo "  Active env: ${VIRTUAL_ENV:-None}"
    echo "  Global tools:"
    echo "    - ruff: $(which ruff >/dev/null && echo '✅' || echo '❌')"
    echo "    - black: $(which black >/dev/null && echo '✅' || echo '❌')"
    echo "    - ipython: $(which ipython >/dev/null && echo '✅' || echo '❌')"
    echo "  Jupyter kernels: $(jupyter kernelspec list 2>/dev/null | grep -c 'base' || echo '0') base kernel(s)"
}

# Uncomment to run validation on shell startup (useful for debugging)
# validate_python_env
