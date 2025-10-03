#!/bin/bash

# Cross-Platform Dotfiles Installation Script
# Manages configuration files using GNU Stow
# Supports: macOS (Darwin), Linux (Arch, etc.)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
platform() { echo -e "${CYAN}[PLATFORM]${NC} $1"; }

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)

# Platform-specific package lists
MACOS_PACKAGES=("aerospace" "sketchybar" "hammerspoon" "git" "zsh")
LINUX_PACKAGES=("hyprland" "zsh-linux" "kitty" "waybar" "dunst" "git")
SHARED_PACKAGES=("git")

# Get packages for current platform
get_packages() {
    case $PLATFORM in
        "macos")
            echo "${MACOS_PACKAGES[@]}"
            ;;
        "linux")
            echo "${LINUX_PACKAGES[@]}"
            ;;
        *)
            error "Unsupported platform: $OSTYPE"
            exit 1
            ;;
    esac
}

PACKAGES=($(get_packages))

# Check if we're in the dotfiles directory
if [[ ! -f "install.sh" ]]; then
    error "Please run this script from the dotfiles directory"
    exit 1
fi

# Check if stow is installed
check_stow() {
    if ! command -v stow &> /dev/null; then
        error "GNU Stow is not installed."
        case $PLATFORM in
            "macos")
                info "Install it with: brew install stow"
                ;;
            "linux")
                info "Install it with: sudo pacman -S stow (Arch) or sudo apt install stow (Ubuntu)"
                ;;
        esac
        exit 1
    fi
}

# Display platform info
show_platform_info() {
    platform "Detected platform: $PLATFORM ($OSTYPE)"
    info "Packages for this platform: ${PACKAGES[*]}"
    echo ""
}

# Function to backup existing configs
backup_configs() {
    info "Creating backup of existing configurations..."
    local backup_dir="backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    case $PLATFORM in
        "macos")
            [[ -f ~/.aerospace.toml ]] && cp ~/.aerospace.toml "$backup_dir/" && info "✓ Backed up .aerospace.toml"
            [[ -d ~/.config/sketchybar ]] && cp -r ~/.config/sketchybar "$backup_dir/" && info "✓ Backed up sketchybar/"
            [[ -f ~/.gitconfig ]] && cp ~/.gitconfig "$backup_dir/" && info "✓ Backed up .gitconfig"
            [[ -f ~/.zshrc ]] && cp ~/.zshrc "$backup_dir/" && info "✓ Backed up .zshrc"
            ;;
        "linux")
            [[ -f ~/.config/hypr/userprefs.conf ]] && mkdir -p "$backup_dir/hypr" && cp ~/.config/hypr/{userprefs.conf,monitors.conf,pyprland.toml} "$backup_dir/hypr/" 2>/dev/null && info "✓ Backed up hyprland configs"
            [[ -d ~/.config/hypr/scripts ]] && cp -r ~/.config/hypr/scripts "$backup_dir/hypr/" && info "✓ Backed up hyprland scripts"
            [[ -f ~/.config/zsh/user.zsh ]] && mkdir -p "$backup_dir/zsh" && cp ~/.config/zsh/{user.zsh,.p10k.zsh} "$backup_dir/zsh/" 2>/dev/null && info "✓ Backed up zsh configs"
            [[ -f ~/.config/zsh/conf.d/98-zoxide.zsh ]] && mkdir -p "$backup_dir/zsh/conf.d" && cp ~/.config/zsh/conf.d/98-zoxide.zsh "$backup_dir/zsh/conf.d/" && info "✓ Backed up zoxide config"
            [[ -f ~/.config/kitty/kitty.conf ]] && mkdir -p "$backup_dir/kitty" && cp ~/.config/kitty/kitty.conf "$backup_dir/kitty/" && info "✓ Backed up kitty.conf"
            [[ -f ~/.config/waybar/config.jsonc ]] && mkdir -p "$backup_dir/waybar" && cp ~/.config/waybar/{config.jsonc,style.css,user-style.css} "$backup_dir/waybar/" 2>/dev/null && info "✓ Backed up waybar configs"
            [[ -f ~/.config/dunst/dunst.conf ]] && mkdir -p "$backup_dir/dunst" && cp ~/.config/dunst/dunst.conf "$backup_dir/dunst/" && info "✓ Backed up dunst.conf"
            [[ -f ~/.gitconfig ]] && cp ~/.gitconfig "$backup_dir/" && info "✓ Backed up .gitconfig"
            ;;
    esac

    success "Backup completed: $backup_dir"
}

# Function to stow a package
stow_package() {
    local package=$1
    local dry_run=${2:-false}

    if [[ ! -d "$package" ]]; then
        warning "Package '$package' not found, skipping..."
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        info "DRY-RUN: Would stow $package..."
        stow --no --verbose "$package" 2>&1 | grep -E "LINK|would" || true
        return 0
    fi

    info "Stowing $package..."

    if stow --no-folding "$package" 2>/dev/null; then
        success "✓ Successfully stowed $package"
    else
        warning "Conflict detected for $package, trying to resolve..."

        # Move conflicting files with .bak extension
        case $package in
            "git")
                [[ -f ~/.gitconfig ]] && mv ~/.gitconfig ~/.gitconfig.bak
                ;;
            "zsh")
                [[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.bak
                ;;
            "hyprland")
                [[ -f ~/.config/hypr/userprefs.conf ]] && mv ~/.config/hypr/userprefs.conf ~/.config/hypr/userprefs.conf.bak
                [[ -f ~/.config/hypr/monitors.conf ]] && mv ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak
                [[ -f ~/.config/hypr/pyprland.toml ]] && mv ~/.config/hypr/pyprland.toml ~/.config/hypr/pyprland.toml.bak
                [[ -d ~/.config/hypr/scripts ]] && mv ~/.config/hypr/scripts ~/.config/hypr/scripts.bak
                ;;
            "zsh-linux")
                [[ -f ~/.config/zsh/user.zsh ]] && mv ~/.config/zsh/user.zsh ~/.config/zsh/user.zsh.bak
                [[ -f ~/.config/zsh/.p10k.zsh ]] && mv ~/.config/zsh/.p10k.zsh ~/.config/zsh/.p10k.zsh.bak
                [[ -f ~/.config/zsh/conf.d/98-zoxide.zsh ]] && mv ~/.config/zsh/conf.d/98-zoxide.zsh ~/.config/zsh/conf.d/98-zoxide.zsh.bak
                ;;
            "kitty")
                [[ -f ~/.config/kitty/kitty.conf ]] && mv ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.bak
                ;;
            "waybar")
                [[ -f ~/.config/waybar/config.jsonc ]] && mv ~/.config/waybar/config.jsonc ~/.config/waybar/config.jsonc.bak
                [[ -f ~/.config/waybar/style.css ]] && mv ~/.config/waybar/style.css ~/.config/waybar/style.css.bak
                [[ -f ~/.config/waybar/user-style.css ]] && mv ~/.config/waybar/user-style.css ~/.config/waybar/user-style.css.bak
                ;;
            "dunst")
                [[ -f ~/.config/dunst/dunst.conf ]] && mv ~/.config/dunst/dunst.conf ~/.config/dunst/dunst.conf.bak
                ;;
        esac

        if stow --no-folding "$package"; then
            success "✓ Successfully stowed $package after resolving conflicts"
        else
            error "✗ Failed to stow $package"
            return 1
        fi
    fi
}

# Function to unstow packages
unstow_packages() {
    info "Unstowing all packages for $PLATFORM..."
    for package in "${PACKAGES[@]}"; do
        if [[ -d "$package" ]]; then
            stow -D "$package" && info "✓ Unstowed $package"
        fi
    done
    success "All packages unstowed"
}

# Function to restow (useful for updates)
restow_packages() {
    info "Restowing all packages for $PLATFORM..."
    for package in "${PACKAGES[@]}"; do
        if [[ -d "$package" ]]; then
            stow -R "$package" && info "✓ Restowed $package"
        fi
    done
    success "All packages restowed"
}

# Dry-run mode
dry_run() {
    show_platform_info
    warning "DRY-RUN MODE: Showing what would be installed (no changes will be made)"
    echo ""

    for package in "${PACKAGES[@]}"; do
        stow_package "$package" true
        echo ""
    done

    info "To actually install, run: ./install.sh install"
}

# Main installation function
install_dotfiles() {
    local specific_packages=("$@")

    show_platform_info
    check_stow

    # If specific packages provided, validate them
    if [[ ${#specific_packages[@]} -gt 0 ]]; then
        info "Installing specific packages: ${specific_packages[*]}"

        # Validate packages exist and are for current platform
        for pkg in "${specific_packages[@]}"; do
            if [[ ! -d "$pkg" ]]; then
                error "Package '$pkg' does not exist"
                exit 1
            fi

            # Check if package is valid for platform
            local valid=false
            for platform_pkg in "${PACKAGES[@]}"; do
                if [[ "$pkg" == "$platform_pkg" ]]; then
                    valid=true
                    break
                fi
            done

            if [[ "$valid" == "false" ]]; then
                warning "Package '$pkg' is not for platform '$PLATFORM'"
                warning "Valid packages: ${PACKAGES[*]}"
                exit 1
            fi
        done

        PACKAGES=("${specific_packages[@]}")
    else
        info "Installing all packages for $PLATFORM..."
    fi

    echo ""

    # Create backup
    backup_configs
    echo ""

    # Stow each package
    for package in "${PACKAGES[@]}"; do
        stow_package "$package"
    done

    echo ""
    success "Dotfiles installation completed!"
    info "Your configurations are now symlinked to ~/dotfiles/"

    # Platform-specific post-install messages
    show_reload_instructions "${PACKAGES[@]}"
}

# Show reload instructions based on installed packages
show_reload_instructions() {
    local installed_packages=("$@")

    echo ""
    info "Reload instructions:"

    for pkg in "${installed_packages[@]}"; do
        case $pkg in
            "hyprland")
                echo "  - Hyprland: hyprctl reload"
                ;;
            "zsh-linux"|"zsh")
                echo "  - Zsh: exec zsh"
                ;;
            "waybar")
                echo "  - Waybar: pkill waybar && waybar &"
                ;;
            "dunst")
                echo "  - Dunst: killall dunst && dunst &"
                ;;
            "kitty")
                echo "  - Kitty: Ctrl+Shift+F5 (in Kitty terminal)"
                ;;
            "aerospace")
                echo "  - AeroSpace: aerospace reload-config"
                ;;
            "sketchybar")
                echo "  - SketchyBar: sketchybar --reload"
                ;;
        esac
    done
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [PACKAGES...]

Cross-platform dotfiles installation using GNU Stow

Commands:
  install [PKG...]  - Install dotfiles using stow (default)
                      If packages specified, only install those
  unstow            - Remove all symlinks
  restow            - Reinstall all symlinks (useful after updates)
  backup            - Backup existing configurations only
  dry-run           - Show what would be installed without making changes
  help              - Show this help message

Platform: $PLATFORM
Available packages: ${PACKAGES[*]}

Examples:
  $0                        # Install all packages for current platform
  $0 install                # Same as above
  $0 install hyprland       # Install only hyprland package
  $0 install zsh-linux kitty # Install only zsh-linux and kitty
  $0 dry-run                # Preview what will be installed
  $0 unstow                 # Remove all symlinks
  $0 backup                 # Only create backup, no installation

EOF
}

# Main script logic
case "${1:-install}" in
    "install")
        shift  # Remove 'install' from args
        install_dotfiles "$@"  # Pass remaining args as packages
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
    "dry-run"|"--dry-run"|"-n")
        dry_run
        ;;
    "help"|"-h"|"--help")
        usage
        ;;
    *)
        # If no command given, check if it looks like a package name
        if [[ -d "$1" ]]; then
            info "No command specified, assuming 'install $@'"
            install_dotfiles "$@"
        else
            error "Unknown command: $1"
            usage
            exit 1
        fi
        ;;
esac
