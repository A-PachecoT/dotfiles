#!/usr/bin/env bash

# clipse-cliphist-bridge.sh - Bridge between cliphist and clipse
# This script syncs clipboard history from cliphist to clipse

# Configuration
CLIPSE_DIR="$HOME/.config/clipse"
CLIPSE_HISTORY="$CLIPSE_DIR/clipboard_history.json"
TEMP_FILE="/tmp/cliphist_to_clipse.json"
MAX_ENTRIES=50  # Reasonable number of entries to sync
DEBUG=false  # Set to true for debugging

# Debug function
debug() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $1" >&2
    fi
}

# Check if cliphist has any entries
if ! command -v cliphist >/dev/null 2>&1; then
    echo "cliphist not found, skipping bridge"
    exit 0
fi

# Get cliphist entries
CLIPHIST_ENTRIES=$(cliphist list | head -$MAX_ENTRIES)
if [ -z "$CLIPHIST_ENTRIES" ]; then
    echo "No cliphist entries found, keeping existing clipse history"
    exit 0
fi

# Ensure clipse directory exists
mkdir -p "$CLIPSE_DIR"

# Create a backup of the current clipse history
if [ -f "$CLIPSE_HISTORY" ]; then
    cp "$CLIPSE_HISTORY" "${CLIPSE_HISTORY}.bak"
    debug "Created backup of clipse history"
fi

# Initialize a new JSON array
echo '[' > "$TEMP_FILE"

# Convert cliphist entries to clipse format
FIRST_ENTRY=true
while IFS=$'\t' read -r id content; do
    if [ -n "$content" ]; then
        # Add comma separator for all entries except the first
        if [ "$FIRST_ENTRY" = false ]; then
            echo ',' >> "$TEMP_FILE"
        fi
        FIRST_ENTRY=false
        
        # Escape JSON special characters
        ESCAPED_CONTENT=$(echo "$content" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')
        
        # Add entry to JSON
        cat >> "$TEMP_FILE" << EOF
    {
        "content": "$ESCAPED_CONTENT",
        "timestamp": "$(date +"%Y-%m-%dT%H:%M:%S.%3NZ")",
        "pinned": false,
        "type": "text"
    }
EOF
    fi
done <<< "$CLIPHIST_ENTRIES"

# Close the JSON array
echo '' >> "$TEMP_FILE"
echo ']' >> "$TEMP_FILE"

# Check if the JSON is valid
if command -v jq >/dev/null 2>&1; then
    if ! jq . "$TEMP_FILE" > /dev/null 2>&1; then
        echo "Error: Generated JSON is not valid, keeping original"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    debug "JSON validation successful"
fi

# Replace the clipse history with our new file
mv "$TEMP_FILE" "$CLIPSE_HISTORY"

echo "Synced $(echo "$CLIPHIST_ENTRIES" | wc -l) entries from cliphist to clipse"

exit 0 