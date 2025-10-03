#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# Function to check if running in WSL
is_wsl() {
    if grep -qi microsoft /proc/version; then
        return 0
    else
        return 1
    fi
}

# Function to backup existing configurations
backup_configs() {
    print_status "Backing up existing configurations..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.dotfiles_backups/$timestamp"
    
    # Create backups directory if it doesn't exist
    mkdir -p "$backup_dir"
    
    local files=(".zshrc" ".gitconfig" ".p10k.zsh")
    
    for file in "${files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$backup_dir/"
            print_success "Backed up $file to $backup_dir"
        fi
    done

    # Create a symlink to latest backup
    local latest_link="$HOME/.dotfiles_backups/latest"
    rm -f "$latest_link" 2>/dev/null
    ln -sf "$backup_dir" "$latest_link"
    print_success "Created link to latest backup at ~/.dotfiles_backups/latest"

    # Add .zsh directory backup
    if [ -d "$HOME/.zsh" ]; then
        cp -r "$HOME/.zsh" "$backup_dir/"
        print_success "Backed up .zsh directory to $backup_dir"
    fi
}

# Function to deploy configurations
deploy_configs() {
    print_status "Deploying configurations..."
    
    # Create .zsh directory if it doesn't exist
    mkdir -p "$HOME/.zsh"
    
    # Deploy .zsh modules
    for file in "$SCRIPT_DIR"/.zsh/*.zsh; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ -L "$HOME/.zsh/$filename" ] && [ "$(readlink -f "$HOME/.zsh/$filename")" = "$(readlink -f "$file")" ]; then
                print_warning "$filename already linked to dotfiles"
            else
                ln -sf "$file" "$HOME/.zsh/$filename"
                print_success "Deployed $filename"
            fi
        fi
    done
    
    # Remove .zshrc.windows from required files
    local required_files=(
        ".gitconfig" 
        ".zshrc" 
        ".p10k.zsh"
        ".zsh/aliases.zsh"
        ".zsh/bindings.zsh"
        ".zsh/completion.zsh"
        ".zsh/exports.zsh"
        ".zsh/functions.zsh"
        ".zsh/history.zsh"
        ".zsh/plugins.zsh"
        ".zsh/wsl.zsh"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$file" ]; then
            print_warning "Missing $file"
        fi
    done
    
    # Handle .gitconfig
    if [ -f "$SCRIPT_DIR/.gitconfig" ]; then
        if [ -L "$HOME/.gitconfig" ] && [ "$(readlink -f "$HOME/.gitconfig")" = "$(readlink -f "$SCRIPT_DIR/.gitconfig")" ]; then
            print_warning ".gitconfig already linked to dotfiles"
        else
            ln -sf "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
            print_success "Deployed .gitconfig"
        fi
    fi
    
    # Handle .p10k.zsh
    if [ -f "$SCRIPT_DIR/.p10k.zsh" ]; then
        if [ -L "$HOME/.p10k.zsh" ] && [ "$(readlink -f "$HOME/.p10k.zsh")" = "$(readlink -f "$SCRIPT_DIR/.p10k.zsh")" ]; then
            print_warning ".p10k.zsh already linked to dotfiles"
        else
            ln -sf "$SCRIPT_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
            print_success "Deployed .p10k.zsh"
        fi
    fi
    
    # Handle .zshrc (simplified, no Windows-specific handling)
    if [ -f "$SCRIPT_DIR/.zshrc" ]; then
        if [ -L "$HOME/.zshrc" ] && [ "$(readlink -f "$HOME/.zshrc")" = "$(readlink -f "$SCRIPT_DIR/.zshrc")" ]; then
            print_warning ".zshrc already linked to dotfiles"
        else
            ln -sf "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
            print_success "Deployed .zshrc symlink"
        fi
    else
        print_error "Missing .zshrc file"
        exit 1
    fi
}

# Function to print usage
print_usage() {
    echo "Usage: $0 [-f|--force] [--save-p10k] [-h|--help]"
    echo "Options:"
    echo "  -f, --force    Force sync without backup"
    echo "  --save-p10k    Save current p10k configuration to dotfiles"
    echo "  -h, --help     Show this help message"
}

# Function to safely copy p10k config
copy_p10k() {
    print_status "Copying p10k configuration..."
    if [ -f "$HOME/.p10k.zsh" ]; then
        cat "$HOME/.p10k.zsh" > "$SCRIPT_DIR/.p10k.zsh"
        print_success "Copied .p10k.zsh to dotfiles"
    else
        print_error "No .p10k.zsh found in home directory"
        exit 1
    fi
}

# Main function
main() {
    local FORCE=false
    local SAVE_P10K=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE=true
                shift
                ;;
            --save-p10k)
                SAVE_P10K=true
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    print_status "Starting dotfiles sync..."
    
    # Check if running from the correct directory
    if [ ! -f "$SCRIPT_DIR/sync.sh" ]; then
        print_error "Please run this script from its directory"
        exit 1
    fi

    # Backup existing configurations unless force flag is used
    if [ "$FORCE" = false ]; then
        backup_configs
    else
        print_warning "Skipping backup due to force flag"
    fi
    
    # Deploy configurations
    deploy_configs
    
    if [ "$SAVE_P10K" = true ]; then
        copy_p10k
        exit 0
    fi

    print_success "Sync completed successfully!"
    print_status "Please restart your shell for changes to take effect."
}

# Run main function
main "$@"