#!/usr/bin/env zsh
#  Zoxide Configuration
# Smart directory navigation tool

# Initialize zoxide if available
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
    # Remove debug message after testing
    # echo "✓ Zoxide loaded successfully"
fi