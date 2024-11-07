#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Error handling
set -e  # Exit on error
trap 'catch $? $LINENO' ERR

# Function to handle errors
catch() {
    print_error "Error $1 occurred on line $2"
    exit 1
}

# Function to print status messages
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Environment checks
IS_REMOTE=false
HAS_SUDO=false
BACKUP_SHELL="/bin/bash"  # Fallback shell

# Function to check internet connectivity
check_internet() {
    print_status "Checking internet connection..."
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection"
        exit 1
    fi
    print_success "Internet connection available"
}

# Function to check if running in WSL
is_wsl() {
    if grep -qi microsoft /proc/version; then
        return 0
    else
        return 1
    fi
}

# Function to check existing installations
check_existing() {
    local package=$1
    if command -v "$package" &> /dev/null; then
        print_warning "$package is already installed"
        return 0
    fi
    return 1
}

# Function to verify download
verify_download() {
    local file=$1
    if [ ! -f "$file" ]; then
        print_error "Failed to download $file"
        return 1
    fi
    return 0
}

# Function to install common dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Update package list
    if ! sudo apt-get update; then
        print_error "Failed to update package list"
        exit 1
    fi

    # List of packages to install
    local packages=(
        zsh
        git
        curl
        fzf
        vim
        python3
        python3-pip
        fonts-powerline
    )

    # Install required packages
    for package in "${packages[@]}"; do
        if ! check_existing "$package"; then
            print_status "Installing $package..."
            if ! sudo apt-get install -y "$package"; then
                print_error "Failed to install $package"
                exit 1
            fi
        fi
    done

    print_success "Dependencies installed"
}

# Function to install Zinit
install_zinit() {
    print_status "Installing Zinit..."
    
    if [ -d "${ZINIT_HOME}" ]; then
        print_warning "Zinit is already installed"
        return
    fi
    
    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    mkdir -p "$(dirname $ZINIT_HOME)"
    if ! git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
        print_error "Failed to install Zinit"
        exit 1
    fi
    
    print_success "Zinit installed"
}

# Function to install Powerlevel10k fonts
install_p10k_fonts() {
    print_status "Installing Powerlevel10k fonts..."
    
    local fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$fonts_dir"
    
    local font_files=(
        "MesloLGS NF Regular.ttf"
        "MesloLGS NF Bold.ttf"
        "MesloLGS NF Italic.ttf"
        "MesloLGS NF Bold Italic.ttf"
    )

    cd "$fonts_dir"
    
    for font in "${font_files[@]}"; do
        if [ ! -f "$font" ]; then
            print_status "Downloading $font..."
            if ! curl -fLo "$font" "https://github.com/romkatv/powerlevel10k-media/raw/master/${font// /%20}"; then
                print_error "Failed to download $font"
                exit 1
            fi
        else
            print_warning "$font already exists"
        fi
    done
    
    fc-cache -f -v
    print_success "Powerlevel10k fonts installed"
}

# Function to setup zoxide
install_zoxide() {
    print_status "Installing zoxide..."
    
    if check_existing "zoxide"; then
        return
    fi
    
    # Add ~/.local/bin to PATH temporarily
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
        print_error "Failed to install zoxide"
        exit 1
    fi
    
    # Add PATH to .zshrc if not already present
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
    
    print_success "Zoxide installed"
}

# Function to backup existing configurations
backup_configs() {
    print_status "Backing up existing configurations..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.dotfiles_backup_$timestamp"
    
    mkdir -p "$backup_dir"
    
    local files=(".zshrc" ".gitconfig" ".p10k.zsh")
    
    for file in "${files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            mv "$HOME/$file" "$backup_dir/"
            print_success "Backed up $file to $backup_dir"
        fi
    done
}

# Function to deploy configurations
deploy_configs() {
    print_status "Deploying configurations..."
    
    local required_files=(".gitconfig" ".zshrc" ".zshrc.windows")
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$file" ]; then
            print_warning "Missing $file"
        fi
    done
    
    # Copy .gitconfig
    if [ -f "$SCRIPT_DIR/.gitconfig" ]; then
        cp "$SCRIPT_DIR/.gitconfig" ~/.gitconfig
        print_success "Deployed .gitconfig"
    fi
    
    # Copy appropriate .zshrc based on environment
    if is_wsl; then
        if [ -f "$SCRIPT_DIR/.zshrc.windows" ]; then
            cp "$SCRIPT_DIR/.zshrc.windows" ~/.zshrc
            print_success "Deployed .zshrc.windows as .zshrc"
        else
            print_error "Missing .zshrc.windows file"
            exit 1
        fi
    else
        if [ -f "$SCRIPT_DIR/.zshrc" ]; then
            cp "$SCRIPT_DIR/.zshrc" ~/.zshrc
            print_success "Deployed .zshrc"
        else
            print_error "Missing .zshrc file"
            exit 1
        fi
    fi
}

# Function to change shell safely
change_shell() {
    print_status "Changing default shell to zsh..."
    
    local zsh_path=$(which zsh)
    
    # Check if zsh is installed and executable
    if [ ! -x "$zsh_path" ]; then
        print_error "zsh is not installed or not executable"
        return 1
    fi
    
    # For remote sessions, test zsh before changing default shell
    if [ "$IS_REMOTE" = true ]; then
        print_status "Testing zsh before changing shell..."
        if ! "$zsh_path" -c 'exit'; then
            print_error "zsh test failed - keeping current shell for safety"
            return 1
        fi
    fi
    
    # Check if zsh is in /etc/shells
    if ! grep -q "$zsh_path" /etc/shells; then
        if [ "$HAS_SUDO" = true ]; then
            print_status "Adding zsh to /etc/shells..."
            echo "$zsh_path" | sudo tee -a /etc/shells
        else
            print_warning "Cannot add zsh to /etc/shells - insufficient permissions"
            return 1
        fi
    fi
    
    # Change shell using chsh, but keep backup shell reference
    if [ "$SHELL" != "$zsh_path" ]; then
        print_status "Backing up current shell settings..."
        echo "export BACKUP_SHELL=$SHELL" >> "$HOME/.zshrc"
        
        if ! chsh -s "$zsh_path"; then
            print_error "Failed to change shell. Current shell preserved."
            return 1
        fi
        
        # Add safety switch back to backup shell
        echo "# Safety switch back to backup shell" >> "$HOME/.zshrc"
        echo "switch_to_backup_shell() {" >> "$HOME/.zshrc"
        echo "    if [ -x \"\$BACKUP_SHELL\" ]; then" >> "$HOME/.zshrc"
        echo "        exec \"\$BACKUP_SHELL\"" >> "$HOME/.zshrc"
        echo "    fi" >> "$HOME/.zshrc"
        echo "}" >> "$HOME/.zshrc"
        
        print_success "Default shell changed to zsh with safety backup"
    else
        print_status "Shell is already zsh"
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    if [ -d "$HOME/.cache/zinit" ]; then
        rm -rf "$HOME/.cache/zinit"
    fi
    if [ -d "$HOME/.local/share/zinit/zinit.old" ]; then
        rm -rf "$HOME/.local/share/zinit/zinit.old"
    fi
    print_success "Cleanup completed"
}

# Clean install flag
CLEAN_INSTALL=false

# Function to print usage
print_usage() {
    echo "Usage: $0 [-c|--clean]"
    echo "  -c, --clean    Clean install (removes existing configurations)"
    exit 1
}

# Function to clean existing installations
clean_existing() {
    print_status "Cleaning existing installations..."
    
    # Remove Zinit
    if [ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/zinit" ]; then
        print_status "Removing existing Zinit installation..."
        rm -rf "${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
    fi
    
    # Remove Zoxide
    if [ -d "$HOME/.local/share/zoxide" ]; then
        print_status "Removing existing Zoxide installation..."
        rm -rf "$HOME/.local/share/zoxide"
    fi
    
    # Remove fonts
    if [ -d "$HOME/.local/share/fonts" ]; then
        print_status "Removing existing fonts..."
        rm -f "$HOME/.local/share/fonts/MesloLGS NF"*
    fi
    
    # Remove configurations
    local configs=(".zshrc" ".gitconfig" ".p10k.zsh")
    for config in "${configs[@]}"; do
        if [ -f "$HOME/$config" ]; then
            print_status "Removing existing $config..."
            rm -f "$HOME/$config"
        fi
    done
    
    print_success "Clean completed"
}

# Function to check environment
check_environment() {
    print_status "Checking environment..."
    
    # Check if running in SSH/remote
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        IS_REMOTE=true
        print_warning "Remote session detected - enabling safety measures"
    fi
    
    # Check sudo access without password
    if sudo -n true 2>/dev/null; then
        HAS_SUDO=true
    else
        print_warning "Limited sudo access - some features may be restricted"
    fi
    
    # Verify backup shell exists
    if [ ! -x "$BACKUP_SHELL" ]; then
        print_error "Backup shell $BACKUP_SHELL not found"
        exit 1
    fi
    # Check if home directory is writable
    if [ ! -w "$HOME" ]; then
        print_error "Home directory is not writable"
        exit 1
    fi
}

# Main installation function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                CLEAN_INSTALL=true
                shift
                ;;
            -h|--help)
                print_usage
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                ;;
        esac
    done

    print_status "Starting setup..."
    
    # Check environment first
    check_environment
    
    # If remote and no sudo, warn user
    if [ "$IS_REMOTE" = true ] && [ "$HAS_SUDO" = false ]; then
        print_warning "Running in remote environment with limited permissions"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Setup cancelled"
            exit 1
        fi
    fi
    
    # Check if running from the correct directory
    if [ ! -f "$SCRIPT_DIR/setup.sh" ]; then
        print_error "Please run this script from its directory"
        exit 1
    fi
    
    # Check internet connectivity
    check_internet
    
    # Clean install if requested
    if [ "$CLEAN_INSTALL" = true ]; then
        clean_existing
    else
        # Backup existing configurations
        backup_configs
    fi
    
    # Install dependencies
    install_dependencies
    
    # Install Zinit
    install_zinit
    
    # Install P10k fonts
    install_p10k_fonts
    
    # Install zoxide
    install_zoxide
    
    # Deploy configurations
    deploy_configs
    
    # Change shell
    change_shell
    
    # Cleanup
    cleanup
    
    print_success "Setup completed successfully!"
    print_status "Please log out and log back in for all changes to take effect."
    print_status "After logging back in, run 'p10k configure' to setup your Powerlevel10k theme."
}

# Run main function
main