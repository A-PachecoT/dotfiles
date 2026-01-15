#!/bin/bash

# Dotfiles Installation Script
# Manages configuration files using GNU Stow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we're in the dotfiles directory
if [[ ! -f "install.sh" ]]; then
    error "Please run this script from the dotfiles directory"
    exit 1
fi

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    error "GNU Stow is not installed. Install it with: brew install stow"
    exit 1
fi

# Available packages
PACKAGES=("aerospace" "sketchybar" "git" "zsh" "skhd" "zellij" "ghostty" "tmux" "nvim")

# Function to backup existing configs
backup_configs() {
    info "Creating backup of existing configurations..."
    mkdir -p backup
    
    for package in "${PACKAGES[@]}"; do
        case $package in
            "aerospace")
                [[ -f ~/.aerospace.toml ]] && cp ~/.aerospace.toml backup/ && info "Backed up .aerospace.toml"
                ;;
            "sketchybar")
                [[ -d ~/.config/sketchybar ]] && cp -r ~/.config/sketchybar backup/ && info "Backed up sketchybar config"
                ;;
            "git")
                [[ -f ~/.gitconfig ]] && cp ~/.gitconfig backup/ && info "Backed up .gitconfig"
                ;;
            "zsh")
                [[ -f ~/.zshrc ]] && cp ~/.zshrc backup/ && info "Backed up .zshrc"
                ;;
            "skhd")
                [[ -f ~/.skhdrc ]] && cp ~/.skhdrc backup/ && info "Backed up .skhdrc"
                ;;
            "zellij")
                [[ -d ~/.config/zellij ]] && cp -r ~/.config/zellij backup/ && info "Backed up zellij config"
                ;;
            "ghostty")
                [[ -d ~/.config/ghostty ]] && cp -r ~/.config/ghostty backup/ && info "Backed up ghostty config"
                ;;
            "tmux")
                [[ -f ~/.tmux.conf ]] && cp ~/.tmux.conf backup/ && info "Backed up .tmux.conf"
                ;;
            "nvim")
                [[ -d ~/.config/nvim ]] && cp -r ~/.config/nvim backup/ && info "Backed up nvim config"
                ;;
        esac
    done
    success "Backup completed"
}

# Function to stow a package
stow_package() {
    local package=$1
    info "Stowing $package..."
    
    if stow --no-folding "$package" 2>/dev/null; then
        success "Successfully stowed $package"
    else
        warning "Conflict detected for $package, trying to resolve..."
        
        # Handle common conflicts
        case $package in
            "git")
                [[ -f ~/.gitconfig ]] && mv ~/.gitconfig ~/.gitconfig.bak
                ;;
            "zsh")
                [[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.bak
                ;;
            "skhd")
                [[ -f ~/.skhdrc ]] && mv ~/.skhdrc ~/.skhdrc.bak
                ;;
            "tmux")
                [[ -f ~/.tmux.conf ]] && mv ~/.tmux.conf ~/.tmux.conf.bak
                ;;
        esac
        
        if stow --no-folding "$package"; then
            success "Successfully stowed $package after resolving conflicts"
        else
            error "Failed to stow $package"
            return 1
        fi
    fi
}

# Function to unstow packages
unstow_packages() {
    info "Unstowing all packages..."
    for package in "${PACKAGES[@]}"; do
        if [[ -d "$package" ]]; then
            stow -D "$package" && info "Unstowed $package"
        fi
    done
    success "All packages unstowed"
}

# Function to restow (useful for updates)
restow_packages() {
    info "Restowing all packages..."
    for package in "${PACKAGES[@]}"; do
        if [[ -d "$package" ]]; then
            stow -R "$package" && info "Restowed $package"
        fi
    done
    success "All packages restowed"
}

# Function to setup Jupyter environment
setup_jupyter() {
    info "Setting up global Jupyter environment..."

    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        warning "uv is not installed. Install it with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi

    # Create global Jupyter environment
    JUPYTER_ENV="$HOME/.jupyter-env"

    if [[ -d "$JUPYTER_ENV" ]]; then
        info "Jupyter environment already exists at $JUPYTER_ENV"
        read -p "Recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$JUPYTER_ENV"
        else
            info "Skipping Jupyter setup"
            return 0
        fi
    fi

    info "Creating virtual environment at $JUPYTER_ENV..."
    cd "$HOME" && uv venv "$JUPYTER_ENV"

    info "Installing Jupyter and common data science packages..."
    uv pip install --python "$JUPYTER_ENV/bin/python" \
        ipykernel jupyter jupyterlab \
        pandas numpy matplotlib seaborn scikit-learn

    info "Registering Jupyter kernel..."
    "$JUPYTER_ENV/bin/python" -m ipykernel install --user --name=jupyter-global --display-name="Python (Global Jupyter)"

    success "Jupyter environment setup completed!"
    info "The kernel 'jupyter-global' is now available in VS Code and Jupyter"
    info "To activate: source ~/.jupyter-env/bin/activate"
    info "To install more packages: uv pip install --python ~/.jupyter-env/bin/python <package>"
}

# Function to setup Claude Code hooks
setup_claude_hooks() {
    info "Setting up Claude Code hooks..."

    DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
    CLAUDE_DIR="$HOME/.claude"
    SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    TEMPLATE_FILE="$DOTFILES_DIR/claude/settings.template.json"

    # Check if template exists
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        error "Template file not found: $TEMPLATE_FILE"
        return 1
    fi

    # Create .claude directory if needed
    mkdir -p "$CLAUDE_DIR"

    # Generate hooks config with actual paths
    HOOKS_CONFIG=$(cat "$TEMPLATE_FILE" | sed "s|__DOTFILES__|$DOTFILES_DIR|g")

    if [[ -f "$SETTINGS_FILE" ]]; then
        # Merge hooks into existing settings
        info "Merging hooks into existing settings.json..."

        # Check if jq is available
        if command -v jq &> /dev/null; then
            # Use jq to merge (preserves existing settings)
            EXISTING=$(cat "$SETTINGS_FILE")
            NEW_HOOKS=$(echo "$HOOKS_CONFIG" | jq '.hooks')

            echo "$EXISTING" | jq --argjson hooks "$NEW_HOOKS" '.hooks = $hooks' > "$SETTINGS_FILE.tmp"
            mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            success "Hooks merged into settings.json"
        else
            warning "jq not installed, creating backup and replacing hooks section"
            cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

            # Simple replacement - extract non-hooks settings and add our hooks
            # This is a fallback, jq is preferred
            python3 << EOF
import json

with open("$SETTINGS_FILE", "r") as f:
    existing = json.load(f)

hooks = json.loads('''$HOOKS_CONFIG''')["hooks"]
existing["hooks"] = hooks

with open("$SETTINGS_FILE", "w") as f:
    json.dump(existing, f, indent=2)
EOF
            success "Hooks updated in settings.json (backup at settings.json.backup)"
        fi
    else
        # Create new settings file with hooks
        info "Creating new settings.json with hooks..."
        echo "$HOOKS_CONFIG" | jq '.' > "$SETTINGS_FILE" 2>/dev/null || echo "$HOOKS_CONFIG" > "$SETTINGS_FILE"
        success "Created settings.json with hooks"
    fi

    # Create queue directory
    mkdir -p "$HOME/.claude-pending"

    info "Claude Code hooks configured:"
    info "  - PreToolUse: Block dangerous bash commands"
    info "  - Stop: Voice notification on task completion"
    info "  - Notification: Voice notification on questions"
    info ""
    info "Restart Claude Code to apply hooks"
}

# Main installation function
install_dotfiles() {
    info "Starting dotfiles installation..."

    # Create backup
    backup_configs

    # Stow each package
    for package in "${PACKAGES[@]}"; do
        if [[ -d "$package" ]]; then
            stow_package "$package"
        else
            warning "Package directory '$package' not found, skipping..."
        fi
    done

    # Setup Jupyter environment
    echo ""
    read -p "Do you want to setup the global Jupyter environment? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        setup_jupyter
    else
        info "Skipping Jupyter setup"
    fi

    # Setup Claude Code hooks
    echo ""
    read -p "Do you want to setup Claude Code hooks? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        setup_claude_hooks
    else
        info "Skipping Claude hooks setup"
    fi

    success "Dotfiles installation completed!"
    info "Your configurations are now symlinked to ~/dotfiles/"
}

# Show usage
usage() {
    echo "Usage: $0 [install|unstow|restow|backup|jupyter|claude]"
    echo ""
    echo "Commands:"
    echo "  install  - Install dotfiles using stow (default)"
    echo "  unstow   - Remove all symlinks"
    echo "  restow   - Reinstall all symlinks (useful after updates)"
    echo "  backup   - Backup existing configurations only"
    echo "  jupyter  - Setup global Jupyter environment with uv"
    echo "  claude   - Setup Claude Code hooks (notifications, safety)"
    echo ""
    echo "Available packages: ${PACKAGES[*]}"
}

# Main script logic
case "${1:-install}" in
    "install")
        install_dotfiles
        ;;
    "unstow")
        unstow_packages
        ;;
    "restow")
        restow_packages
        ;;
    "backup")
        backup_configs
        ;;
    "jupyter")
        setup_jupyter
        ;;
    "claude")
        setup_claude_hooks
        ;;
    "help"|"-h"|"--help")
        usage
        ;;
    *)
        error "Unknown command: $1"
        usage
        exit 1
        ;;
esac