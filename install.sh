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
PACKAGES=("aerospace" "sketchybar" "git" "zsh")

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
    
    success "Dotfiles installation completed!"
    info "Your configurations are now symlinked to ~/dotfiles/"
}

# Show usage
usage() {
    echo "Usage: $0 [install|unstow|restow|backup]"
    echo ""
    echo "Commands:"
    echo "  install  - Install dotfiles using stow (default)"
    echo "  unstow   - Remove all symlinks"
    echo "  restow   - Reinstall all symlinks (useful after updates)"
    echo "  backup   - Backup existing configurations only"
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
    "help"|"-h"|"--help")
        usage
        ;;
    *)
        error "Unknown command: $1"
        usage
        exit 1
        ;;
esac