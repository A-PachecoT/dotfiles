#!/bin/bash

#==============================================================================
# PYTHON DEVELOPMENT ENVIRONMENT SETUP SCRIPT
#
# This script sets up a comprehensive Python development environment with:
# - System Python tools for AUR package building
# - uv-based base environment with data science libraries
# - Global development tools
# - Jupyter integration
# - IDE configuration
#
# Usage: ./setup_python_env.sh [--force]
# Use --force to recreate existing environments
#==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Force flag
FORCE=false
if [[ "$1" == "--force" ]]; then
    FORCE=true
    echo -e "${YELLOW}🔄 Force mode enabled - will recreate existing environments${NC}"
fi

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

#==============================================================================
# SYSTEM DEPENDENCIES
#==============================================================================

log_info "Installing system Python build tools..."

if check_command "pacman"; then
    # Arch Linux
    sudo pacman -S --needed python-pip python-build python-wheel python-setuptools python-virtualenv
    log_success "System Python tools installed"
elif check_command "apt"; then
    # Debian/Ubuntu
    sudo apt update
    sudo apt install -y python3-pip python3-build python3-wheel python3-setuptools python3-venv
    log_success "System Python tools installed"
else
    log_warning "Unknown package manager - please install Python build tools manually"
fi

#==============================================================================
# UV INSTALLATION
#==============================================================================

log_info "Checking uv installation..."

if ! check_command "uv"; then
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    log_success "uv installed"
else
    log_success "uv already available"
fi

#==============================================================================
# BASE ENVIRONMENT SETUP
#==============================================================================

BASE_ENV="$HOME/.venvs/base"

if [[ -d "$BASE_ENV" ]] && [[ "$FORCE" == "false" ]]; then
    log_warning "Base environment already exists at $BASE_ENV"
    log_info "Use --force to recreate or activate manually with: source $BASE_ENV/bin/activate"
else
    if [[ -d "$BASE_ENV" ]]; then
        log_info "Removing existing base environment..."
        rm -rf "$BASE_ENV"
    fi
    
    log_info "Creating base Python environment..."
    uv venv "$BASE_ENV" --python 3.13
    log_success "Base environment created"
    
    log_info "Installing common data science and development packages..."
    source "$BASE_ENV/bin/activate"
    
    # Core data science stack
    uv pip install \
        numpy \
        pandas \
        matplotlib \
        seaborn \
        scikit-learn \
        requests \
        jupyter \
        ipython \
        black \
        ruff \
        pytest \
        mypy \
        build \
        wheel \
        setuptools
    
    log_success "Base environment packages installed"
fi

#==============================================================================
# GLOBAL TOOLS INSTALLATION
#==============================================================================

log_info "Installing global development tools..."

# Install tools that should be available system-wide
for tool in "black" "ruff" "ipython"; do
    if uv tool list | grep -q "$tool" && [[ "$FORCE" == "false" ]]; then
        log_warning "$tool already installed globally"
    else
        log_info "Installing $tool globally..."
        uv tool install "$tool" ${FORCE:+--force}
        log_success "$tool installed globally"
    fi
done

#==============================================================================
# JUPYTER KERNEL SETUP
#==============================================================================

log_info "Setting up Jupyter kernel for base environment..."

source "$BASE_ENV/bin/activate"
python -m ipykernel install --user --name=base --display-name="Python (Base Environment)" ${FORCE:+--force}
log_success "Jupyter kernel configured"

#==============================================================================
# ZSH CONFIGURATION
#==============================================================================

log_info "Setting up zsh configuration..."

# Create XDG-compliant configuration directory
mkdir -p "$HOME/.config/zsh/conf.d"

# Check if our configuration is already linked/copied
PYTHON_CONFIG="$HOME/.config/zsh/conf.d/99-custom-python.zsh"
DOTFILES_CONFIG="$HOME/dotfiles/.config/zsh/conf.d/99-custom-python.zsh"

if [[ -f "$DOTFILES_CONFIG" ]]; then
    if [[ ! -f "$PYTHON_CONFIG" ]] || [[ "$FORCE" == "true" ]]; then
        ln -sf "$DOTFILES_CONFIG" "$PYTHON_CONFIG"
        log_success "Python zsh configuration linked"
    else
        log_warning "Python zsh configuration already exists"
    fi
else
    log_warning "Dotfiles Python configuration not found at $DOTFILES_CONFIG"
    log_info "Make sure to sync your dotfiles or copy the configuration manually"
fi

#==============================================================================
# IDE CONFIGURATION HINTS
#==============================================================================

log_info "IDE Configuration recommendations:"
echo ""
echo "For Cursor/VS Code, add to ~/.config/Cursor/User/settings.json:"
echo '{'
echo '    "python.defaultInterpreterPath": "'$BASE_ENV'/bin/python",'
echo '    "python.terminal.activateEnvironment": true,'
echo '    "jupyter.kernels.filter": ['
echo '        {'
echo '            "path": "'$BASE_ENV'/bin/python",'
echo '            "type": "pythonEnvironment"'
echo '        }'
echo '    ]'
echo '}'
echo ""

#==============================================================================
# VALIDATION
#==============================================================================

log_info "Validating installation..."

# Test base environment
if source "$BASE_ENV/bin/activate" && python -c "import numpy, pandas, matplotlib, jupyter" 2>/dev/null; then
    log_success "Base environment validation passed"
else
    log_error "Base environment validation failed"
    exit 1
fi

# Test global tools
for tool in "ruff" "black" "ipython"; do
    if check_command "$tool"; then
        log_success "$tool available globally"
    else
        log_warning "$tool not found in PATH"
    fi
done

# Test Jupyter kernel
if jupyter kernelspec list 2>/dev/null | grep -q "base"; then
    log_success "Jupyter kernel configured correctly"
else
    log_warning "Jupyter kernel may not be configured correctly"
fi

#==============================================================================
# COMPLETION
#==============================================================================

echo ""
log_success "🎉 Python development environment setup complete!"
echo ""
echo "Available commands:"
echo "  pybase  - Activate base environment with data science libraries"
echo "  jlab    - Launch JupyterLab"
echo "  jnb     - Launch Jupyter Notebook"
echo "  pysys   - Use system Python"
echo "  pyconda - Use conda when needed"
echo ""
echo "Global tools available:"
echo "  ruff    - Python linter/formatter"
echo "  black   - Code formatter"
echo "  ipython - Enhanced Python REPL"
echo ""
echo "To use the new configuration, restart your terminal or run:"
echo "  source ~/.config/zsh/conf.d/99-custom-python.zsh"
echo ""
log_info "See PYTHON_SETUP.md for complete documentation"
