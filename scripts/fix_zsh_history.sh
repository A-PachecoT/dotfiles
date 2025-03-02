#!/bin/bash

# Fix corrupted Zsh history file
# Usage: ./fix_zsh_history.sh

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print status function
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Main function
fix_history() {
    HISTORY_FILE="${HOME}/.zsh_history"
    BACKUP_FILE="${HISTORY_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    
    print_status "Fixing corrupted Zsh history file..."
    
    # Check if history file exists
    if [ -f "$HISTORY_FILE" ]; then
        # Create backup
        print_status "Creating backup of current history file at $BACKUP_FILE"
        cp -f "$HISTORY_FILE" "$BACKUP_FILE"
        
        # Remove corrupted file
        print_status "Removing corrupted history file"
        rm -f "$HISTORY_FILE"
    else
        print_warning "No history file found at $HISTORY_FILE"
    fi
    
    # Create new empty history file
    print_status "Creating new empty history file"
    touch "$HISTORY_FILE"
    
    # Set correct permissions
    chmod 600 "$HISTORY_FILE"
    
    # Try to recover history from backup
    if [ -f "$BACKUP_FILE" ]; then
        print_status "Attempting to recover history from backup..."
        if fc -R "$BACKUP_FILE" 2>/dev/null; then
            print_success "Successfully recovered some history entries"
        else
            print_warning "Could not recover history from backup"
        fi
    fi
    
    print_success "Zsh history file has been fixed!"
    print_status "You may need to restart your shell for changes to take effect."
}

# Run the function
fix_history 