#!/bin/bash
# Open file path in yazi (for tmux-open integration)
# Handles formats: path/to/file.ts:42:10, path/to/file.ts:42, path/to/file.ts

input="$1"

# Extract just the file path (remove line:col suffix)
filepath=$(echo "$input" | sed 's/:.*$//')

# Expand to absolute path if relative
if [[ ! "$filepath" = /* ]]; then
    # Try to find the file from common project roots
    if [[ -f "$filepath" ]]; then
        filepath="$(pwd)/$filepath"
    elif [[ -f "$HOME/$filepath" ]]; then
        filepath="$HOME/$filepath"
    fi
fi

# Check if file exists
if [[ ! -f "$filepath" ]]; then
    echo "File not found: $filepath"
    exit 1
fi

# Get the directory
dir=$(dirname "$filepath")
file=$(basename "$filepath")

# Send reveal command to yazi via its socket
# This requires yazi to be running with IPC enabled
if command -v ya &> /dev/null; then
    ya emit reveal "$filepath" 2>/dev/null && exit 0
fi

# Fallback: if ya command didn't work, try to focus yazi pane and cd
# Find the yazi pane in current window
yazi_pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' | grep -i yazi | head -1 | awk '{print $1}')

if [[ -n "$yazi_pane" ]]; then
    # Send keys to yazi to navigate to the file
    # In yazi: 'g' + path goes to path, or we can use the search
    tmux select-pane -t "$yazi_pane"
    # Type the path to search/navigate
    tmux send-keys -t "$yazi_pane" ":" "cd $dir" Enter
    tmux send-keys -t "$yazi_pane" "/$file" Enter
else
    # No yazi found, just open in default editor
    ${EDITOR:-nvim} "$filepath"
fi
