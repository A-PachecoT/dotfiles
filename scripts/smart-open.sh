#!/bin/bash
# Smart opener for tmux-fingers
# Detects URLs vs file paths and opens accordingly

input=$(cat)

# Copy to clipboard first
echo "$input" | pbcopy

# Detect type and open
if [[ "$input" =~ ^https?:// ]]; then
    # URL → open in browser
    open "$input"
elif [[ "$input" =~ \.[a-zA-Z]+:?[0-9]*$ ]]; then
    # File path (with optional :line) → open in yazi

    # Extract just the file path (remove :line:col)
    filepath=$(echo "$input" | sed 's/:.*$//')

    # Find yazi pane and navigate to file
    yazi_pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -i yazi | head -1 | awk '{print $1}')

    if [[ -n "$yazi_pane" ]]; then
        # Get directory and filename
        if [[ -f "$filepath" ]]; then
            dir=$(dirname "$filepath")
            file=$(basename "$filepath")
        elif [[ -f "$(pwd)/$filepath" ]]; then
            dir=$(dirname "$(pwd)/$filepath")
            file=$(basename "$filepath")
        else
            # File doesn't exist, just try to cd to directory part
            dir=$(dirname "$filepath")
            file=$(basename "$filepath")
        fi

        # Focus yazi pane and navigate
        tmux select-pane -t "$yazi_pane"
        # Use yazi's built-in cd command
        tmux send-keys -t "$yazi_pane" ":" "cd $dir" Enter
        # Search for the file
        tmux send-keys -t "$yazi_pane" "/$file" Enter
    fi
fi
