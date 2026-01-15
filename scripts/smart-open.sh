#!/usr/bin/env bash
# =============================================================================
# SMART-OPEN.SH - Intelligent file/URL opener for tmux-fingers
# =============================================================================
# Purpose: Handle Cmd+F selections from tmux-fingers, routing to appropriate
#          destination (browser for URLs, yazi for files, editor as fallback)
#
# Flow: Input → Clipboard → Type Detection → Resolution → Navigation
#
# Called by: tmux-fingers via @fingers-main-action config
# Input: Selected text via stdin (URL, file path, or arbitrary text)
# Output: Opens URL in browser, navigates yazi to file, or opens in editor
# =============================================================================

set -euo pipefail

# =============================================================================
# INPUT HANDLING
# Purpose: Capture input and always copy to clipboard (user expectation)
# =============================================================================
input=$(cat)

# Always copy to clipboard first - even if navigation fails, user has the text
echo -n "$input" | pbcopy

# Empty input = nothing to do
[[ -z "$input" ]] && exit 0

# =============================================================================
# URL HANDLING
# Purpose: Detect URLs and open in default browser
# Pattern: Starts with http:// or https://
# =============================================================================
if [[ "$input" =~ ^https?:// ]]; then
    open "$input"
    exit 0
fi

# =============================================================================
# FILE PATH EXTRACTION
# Purpose: Extract clean file path from various formats
#
# Supported formats:
#   - file.ts:42:10  → file.ts (with line and column from errors)
#   - file.ts:42     → file.ts (with line number)
#   - ./src/file.ts  → relative path
#   - /abs/path.ts   → absolute path
#   - Makefile       → files without extension
#   - .gitignore     → dotfiles
#
# The regex strips :line and :line:col suffixes
# =============================================================================
filepath=$(echo "$input" | sed -E 's/:[0-9]+(:[0-9]+)?$//')

# Also extract line number if present (for editor fallback with +line)
line_number=$(echo "$input" | grep -oE ':[0-9]+' | head -1 | tr -d ':' || true)

# =============================================================================
# FILE RESOLUTION (VSCode-style)
# Purpose: Find the actual file on disk, handling relative paths correctly
#
# Resolution priority:
#   1. Absolute path that exists → use it directly
#   2. Relative to tmux pane's current directory → most common case
#   3. Walk up to project root (.git/package.json) → for deep relative paths
#   4. Not found → show error feedback
#
# CRITICAL BUG FIX: We use tmux's pane_current_path, NOT $(pwd)!
# $(pwd) returns the script's directory, not where the user is working.
# =============================================================================

# Get the ACTUAL working directory of the tmux pane that triggered this
# This is the key fix - the pane where the error/output appeared
pane_cwd=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || echo "$HOME")

resolved_path=""

# Strategy 1: Absolute path - check if it exists directly
if [[ "$filepath" = /* ]] && [[ -e "$filepath" ]]; then
    resolved_path="$filepath"

# Strategy 2: Relative to pane's current directory (most common case)
# Handles: ./file.ts, src/file.ts, ../other/file.ts
elif [[ -e "$pane_cwd/$filepath" ]]; then
    resolved_path="$pane_cwd/$filepath"

# Strategy 3: Walk up directory tree looking for the file
# Use case: Error shows "src/components/Button.tsx" but you're in src/components/
# We walk up until we find .git or package.json (project root markers)
else
    check_dir="$pane_cwd"
    while [[ "$check_dir" != "/" ]]; do
        if [[ -e "$check_dir/$filepath" ]]; then
            resolved_path="$check_dir/$filepath"
            break
        fi
        # Stop at project root to avoid searching entire filesystem
        if [[ -d "$check_dir/.git" ]] || [[ -f "$check_dir/package.json" ]] || [[ -f "$check_dir/Cargo.toml" ]]; then
            break
        fi
        check_dir=$(dirname "$check_dir")
    done
fi

# =============================================================================
# FILE NOT FOUND HANDLING
# Purpose: Provide clear feedback when file cannot be located
# Uses tmux's display-message for non-intrusive notification
# =============================================================================
if [[ -z "$resolved_path" ]]; then
    tmux display-message "File not found: $filepath (searched from $pane_cwd)"
    exit 0
fi

# Normalize to absolute path (resolve symlinks, .., etc.)
resolved_path=$(cd "$(dirname "$resolved_path")" 2>/dev/null && pwd)/$(basename "$resolved_path")

# Final existence check after normalization
if [[ ! -e "$resolved_path" ]]; then
    tmux display-message "File not found after resolution: $resolved_path"
    exit 0
fi

# =============================================================================
# YAZI NAVIGATION (3-tier fallback system)
# Purpose: Navigate to the file in the most reliable way possible
#
# Tier 1: IPC via `ya emit reveal` - Most reliable, handles special chars
# Tier 2: Keystroke simulation - When IPC unavailable (no $YAZI_ID)
# Tier 3: Editor fallback - When no yazi pane exists
#
# The bug fix: Always send Escape first to ensure yazi is in normal mode,
# not stuck in command mode (:) or search mode (/)
# =============================================================================

dir=$(dirname "$resolved_path")
file=$(basename "$resolved_path")

# -----------------------------------------------------------------------------
# Tier 1: Try IPC first (most reliable)
# ya emit reveal navigates to parent dir AND highlights the file atomically
# This handles special characters, spaces, quotes, etc. safely
# -----------------------------------------------------------------------------
if ya emit reveal "$resolved_path" 2>/dev/null; then
    # Find and focus the yazi pane so user sees the result
    yazi_pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -iE '\byazi\b' | head -1 | awk '{print $1}' || true)
    if [[ -n "$yazi_pane" ]]; then
        tmux select-pane -t "$yazi_pane"
    fi
    exit 0
fi

# -----------------------------------------------------------------------------
# Tier 2: Keystroke simulation fallback
# Used when ya emit fails (no $YAZI_ID, yazi not running with IPC)
# -----------------------------------------------------------------------------
yazi_pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -iE '\byazi\b' | head -1 | awk '{print $1}' || true)

if [[ -n "$yazi_pane" ]]; then
    # BUG FIX: Send Escape first to ensure we're in normal mode
    # This fixes the issue where yazi gets stuck in command/search mode
    tmux send-keys -t "$yazi_pane" Escape

    # Small delay to let yazi process the Escape
    sleep 0.05

    # Navigate to directory using command mode
    # Single quotes inside the command to handle paths with spaces
    tmux send-keys -t "$yazi_pane" ":cd '${dir}'" Enter

    # Small delay to let cd complete
    sleep 0.05

    # Search for the file
    # Escape special regex characters in filename to avoid search errors
    # Characters that need escaping in regex: . [ ] \ * ^ $ ( ) + ? { } |
    escaped_file=$(printf '%s' "$file" | sed 's/[.[\*^$()+?{|]/\\&/g')

    # Use anchored search (^...$) to match exact filename
    tmux send-keys -t "$yazi_pane" "/^${escaped_file}\$" Enter

    # Exit search mode and return to normal mode
    tmux send-keys -t "$yazi_pane" Escape

    # Focus the yazi pane so user sees the result
    tmux select-pane -t "$yazi_pane"
    exit 0
fi

# -----------------------------------------------------------------------------
# Tier 3: Editor fallback
# No yazi pane found - open file in $EDITOR with line number support
# -----------------------------------------------------------------------------
if [[ -n "${EDITOR:-}" ]]; then
    # Get the pane where we should open the editor (current pane)
    if [[ -n "$line_number" ]]; then
        # Most editors support +line syntax (vim, nvim, code, etc.)
        tmux send-keys "$EDITOR +$line_number '$resolved_path'" Enter
    else
        tmux send-keys "$EDITOR '$resolved_path'" Enter
    fi
    exit 0
fi

# -----------------------------------------------------------------------------
# Last resort: Just show the path
# No yazi, no editor - at least tell the user where the file is
# -----------------------------------------------------------------------------
tmux display-message "Found: $resolved_path (no yazi or editor to open it)"
