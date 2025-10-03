#!/bin/bash
#==============================================================================
# DOTFILES INSTALLER
# 
# This script installs and synchronizes dotfiles configurations
# Priority: Arch Linux > Ubuntu > macOS > Windows/WSL
# 
# Usage: ./install.sh [options]
# Options:
#   --force     Skip confirmation prompts
#   --backup    Backup existing configs before installing
#   --minimal   Install only essential configs
#==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    read -p "$1 (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

#==============================================================================
# PLATFORM DETECTION
#==============================================================================

detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v pacman &> /dev/null; then
            echo "arch"
        elif command -v apt-get &> /dev/null; then
            if uname -r | grep -q "WSL"; then
                echo "wsl"
            else
                echo "ubuntu"
            fi
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

detect_desktop_environment() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
            echo "hyde"
        elif [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
            echo "gnome"
        elif [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]]; then
            echo "kde"
        else
            echo "unknown"
        fi
    else
        echo "none"
    fi
}

#==============================================================================
# BACKUP FUNCTIONS
#==============================================================================

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up $file to $backup"
        cp "$file" "$backup"
    fi
}

backup_configs() {
    log_info "Creating backups of existing configurations..."
    
    # List of files to backup
    local files=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.gitconfig"
        "$HOME/.config/zsh/.zshrc"
    )
    
    for file in "${files[@]}"; do
        backup_file "$file"
    done
    
    log_success "Backups created"
}

#==============================================================================
# INSTALLATION FUNCTIONS
#==============================================================================

install_common_configs() {
    log_info "Installing common configurations..."
    
    # Git configuration
    if [[ -f "$SCRIPT_DIR/.gitconfig" ]]; then
        log_info "Installing git configuration..."
        ln -sf "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
    fi
    
    # Common shell configurations
    if [[ -d "$SCRIPT_DIR/.config/zsh/conf.d" ]]; then
        log_info "Installing shell configurations..."
        mkdir -p "$HOME/.config/zsh/conf.d"
        
        # Link common configurations
        for conf in "$SCRIPT_DIR/.config/zsh/conf.d"/*.zsh; do
            if [[ -f "$conf" ]]; then
                ln -sf "$conf" "$HOME/.config/zsh/conf.d/$(basename "$conf")"
            fi
        done
    fi
    
    log_success "Common configurations installed"
}

install_platform_specific() {
    local platform="$1"
    log_info "Installing $platform-specific configurations..."
    
    case "$platform" in
        arch)
            install_arch_configs
            ;;
        ubuntu)
            install_ubuntu_configs
            ;;
        wsl)
            install_wsl_configs
            ;;
        macos)
            install_macos_configs
            ;;
        *)
            log_warning "No platform-specific configurations for $platform"
            ;;
    esac
}

install_arch_configs() {
    log_info "Installing Arch Linux configurations..."
    
    # Check for HyDE
    if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
        log_info "HyDE detected, integrating with existing setup..."
        # Don't override HyDE's core configs, just add our customizations
        
        # Link our custom Python config
        ln -sf "$SCRIPT_DIR/.config/zsh/conf.d/99-custom-python.zsh" \
               "$HOME/.config/zsh/conf.d/99-custom-python.zsh"
    fi
    
    # Install packages if requested
    if confirm "Install Arch Linux packages?"; then
        install_arch_packages
    fi
    
    log_success "Arch Linux configurations installed"
}

install_ubuntu_configs() {
    log_info "Installing Ubuntu configurations..."
    # Ubuntu-specific setup
    log_success "Ubuntu configurations installed"
}

install_wsl_configs() {
    log_info "Installing WSL configurations..."
    
    # Link WSL-specific configs
    if [[ -f "$SCRIPT_DIR/.zsh/wsl.zsh" ]]; then
        mkdir -p "$HOME/.zsh"
        ln -sf "$SCRIPT_DIR/.zsh/wsl.zsh" "$HOME/.zsh/wsl.zsh"
    fi
    
    log_success "WSL configurations installed"
}

install_macos_configs() {
    log_info "Installing macOS configurations..."
    # macOS-specific setup
    log_success "macOS configurations installed"
}

#==============================================================================
# PACKAGE INSTALLATION
#==============================================================================

install_arch_packages() {
    log_info "Installing Arch Linux packages..."
    
    # Detect AUR helper
    local aur_helper=""
    if command -v yay &> /dev/null; then
        aur_helper="yay"
    elif command -v paru &> /dev/null; then
        aur_helper="paru"
    else
        log_warning "No AUR helper found, skipping AUR packages"
    fi
    
    # Install packages from list
    if [[ -f "$SCRIPT_DIR/platform/linux/arch/packages.txt" ]]; then
        log_info "Installing official packages..."
        sudo pacman -S --needed $(cat "$SCRIPT_DIR/platform/linux/arch/packages.txt" | grep -v '^#' | tr '\n' ' ')
    fi
    
    # Install AUR packages if helper available
    if [[ -n "$aur_helper" ]] && [[ -f "$SCRIPT_DIR/platform/linux/arch/aur.txt" ]]; then
        log_info "Installing AUR packages..."
        $aur_helper -S --needed $(cat "$SCRIPT_DIR/platform/linux/arch/aur.txt" | grep -v '^#' | tr '\n' ' ')
    fi
}

#==============================================================================
# SHELL CONFIGURATION
#==============================================================================

setup_shell() {
    log_info "Setting up shell configuration..."
    
    # Check current shell
    local current_shell=$(basename "$SHELL")
    
    if [[ "$current_shell" != "zsh" ]]; then
        if confirm "Switch to Zsh as default shell?"; then
            if command -v zsh &> /dev/null; then
                log_info "Changing default shell to Zsh..."
                chsh -s $(which zsh)
                log_success "Default shell changed to Zsh (restart terminal to apply)"
            else
                log_error "Zsh not installed. Please install it first."
            fi
        fi
    fi
    
    # Install shell configurations
    if [[ ! -f "$HOME/.zshrc" ]] || confirm "Replace existing .zshrc?"; then
        backup_file "$HOME/.zshrc"
        ln -sf "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    fi
}

#==============================================================================
# MAIN INSTALLATION FLOW
#==============================================================================

main() {
    # Parse arguments
    FORCE=false
    BACKUP=false
    MINIMAL=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE=true
                shift
                ;;
            --backup)
                BACKUP=true
                shift
                ;;
            --minimal)
                MINIMAL=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Header
    echo -e "${BLUE}==================================${NC}"
    echo -e "${BLUE}    DOTFILES INSTALLER${NC}"
    echo -e "${BLUE}==================================${NC}"
    echo
    
    # Detect platform
    PLATFORM=$(detect_platform)
    DESKTOP_ENV=$(detect_desktop_environment)
    
    log_info "Detected platform: $PLATFORM"
    log_info "Detected desktop environment: $DESKTOP_ENV"
    echo
    
    # Backup if requested
    if [[ "$BACKUP" == "true" ]] || confirm "Backup existing configurations?"; then
        backup_configs
    fi
    
    # Install configurations
    install_common_configs
    install_platform_specific "$PLATFORM"
    
    # Setup shell
    if [[ "$MINIMAL" != "true" ]]; then
        setup_shell
    fi
    
    # Success message
    echo
    log_success "Dotfiles installation complete!"
    echo
    echo "Next steps:"
    echo "1. Restart your terminal for shell changes to take effect"
    echo "2. Run 'validate_python_env' to check Python setup"
    echo "3. Review the documentation in docs/ for more information"
    echo
    echo "To sync future changes, run: ./sync.sh"
}

# Run main function
main "$@"