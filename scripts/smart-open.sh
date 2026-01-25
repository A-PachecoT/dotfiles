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
#   - n(~/.claude/plans/file.md) → ~/.claude/plans/file.md (wrapped paths)
#   - Write(/path/to/file)       → /path/to/file (tool output format)
#   - (path/in/parens)           → path/in/parens (bare parens)
#
# The regex strips :line and :line:col suffixes
# =============================================================================

# Extract path from wrapper patterns: name(path) or (path)
# Handles: n(path), Write(path), Read(path), (path)
if [[ "$input" =~ ^[a-zA-Z_]*\((.+)\)$ ]]; then
    input="${BASH_REMATCH[1]}"
fi

# Expand ~ to $HOME (not auto-expanded in variables)
input="${input/#\~/$HOME}"

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
# Purpose: Fuzzy-find fallback when exact path not found (hop recovery)
# Uses fd + fzf to search for files matching the basename
# =============================================================================
if [[ -z "$resolved_path" ]]; then
    # Extract basename for fuzzy search
    search_term=$(basename "$filepath" 2>/dev/null || echo "$filepath")

    # Try fuzzy find with fd, searching from home directory
    if command -v fd &>/dev/null && command -v fzf &>/dev/null; then
        candidates=$(fd -t f -H --max-depth 8 "$search_term" "$HOME" 2>/dev/null | head -50)

        if [[ -n "$candidates" ]]; then
            # Show fzf popup in tmux for selection
            selected=$(echo "$candidates" | fzf-tmux -p 80%,60% \
                --prompt="hop: " \
                --header="Path not found: $filepath" \
                --query="$search_term" \
                --preview='head -50 {}' \
                --preview-window=right:40%:wrap)

            if [[ -n "$selected" ]]; then
                resolved_path="$selected"
            else
                # User cancelled fzf
                exit 0
            fi
        else
            tmux display-message "hop: No matches for '$search_term'"
            exit 0
        fi
    else
        tmux display-message "hop: File not found: $filepath (install fd + fzf for fuzzy fallback)"
        exit 0
    fi
fi

# Normalize to absolute path (resolve symlinks, .., etc.)
resolved_path=$(cd "$(dirname "$resolved_path")" 2>/dev/null && pwd)/$(basename "$resolved_path")

# Final existence check after normalization
if [[ ! -e "$resolved_path" ]]; then
    tmux display-message "File not found after resolution: $resolved_path"
    exit 0
fi

# =============================================================================
# FILE NAVIGATION (2-tier system)
# Purpose: Open the file in the most appropriate application
#
# Tier 1: Yazi IPC via `ya emit reveal`
#         - Most reliable, handles special chars, spaces, quotes
#         - Requires $YAZI_ID (set when using yazi shell integration)
#         - The `y` alias/function in zshrc enables this
#
# Tier 2: Editor fallback ($EDITOR)
#         - When yazi IPC unavailable
#         - Supports +line syntax for jumping to error line
#
# NOTE: Keystroke simulation (`:cd`, `/search`) doesn't work in yazi because
# `:` opens SHELL mode (external commands), not internal command mode.
# =============================================================================

dir=$(dirname "$resolved_path")
file=$(basename "$resolved_path")

# -----------------------------------------------------------------------------
# Tier 1: Try IPC first (most reliable)
# ya emit reveal navigates to parent dir AND highlights the file atomically
# This handles special characters, spaces, quotes, etc. safely
#
# Socket naming: Each yazi instance uses "yazi-$TMUX_PANE" as socket name
# We find the yazi pane first, then use its pane ID to construct the socket name
# -----------------------------------------------------------------------------

# Find yazi pane in the SAME window as the triggering pane
# TMUX_PANE tells us which pane tmux-fingers was triggered from
# Without -t, list-panes can return wrong window in some contexts
target_window=$(tmux display-message -t "${TMUX_PANE:-}" -p '#{session_name}:#{window_index}' 2>/dev/null || true)

if [[ -n "$target_window" ]]; then
    yazi_pane=$(tmux list-panes -t "$target_window" -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -iE '\byazi\b' | head -1 | awk '{print $1}' || true)
else
    # Fallback: search current window (original behavior)
    yazi_pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -iE '\byazi\b' | head -1 | awk '{print $1}' || true)
fi

if [[ -n "$yazi_pane" ]]; then
    # Use pane ID as YAZI_ID (must be a number, matches --client-id in y() function)
    # Strip the % prefix from tmux pane ID (e.g., %144 → 144)
    client_id="${yazi_pane#%}"

    # If target is a hidden file (starts with .), ensure hidden files are visible
    if [[ "$file" == .* ]]; then
        YAZI_ID="$client_id" ya emit hidden show 2>/dev/null || true
    fi

    if YAZI_ID="$client_id" ya emit reveal "$resolved_path" 2>/dev/null; then
        # Focus the yazi pane so user sees the result
        tmux select-pane -t "$yazi_pane"
        exit 0
    fi
fi

# -----------------------------------------------------------------------------
# Tier 2: Editor fallback (yazi IPC failed)
#
# WHY NO KEYSTROKE FALLBACK:
# Yazi's `:` opens SHELL mode (external commands), not internal commands.
# There's no `:cd /path` like vim - `cd` in a subshell doesn't change yazi's dir.
# The only reliable way to control yazi externally is via IPC (`ya emit`),
# which requires $YAZI_ID (set when using yazi's shell integration).
#
# If you want smart-open to navigate yazi, use the `y` shell wrapper
# which enables IPC via $YAZI_ID.
# -----------------------------------------------------------------------------

# Open file in $EDITOR via new tmux split
# Don't use send-keys (sends to wrong pane) - create a proper split instead
if [[ -n "${EDITOR:-}" ]]; then
    if [[ -n "$line_number" ]]; then
        # Open editor in a new vertical split, then close when done
        tmux split-window -h "$EDITOR +$line_number '$resolved_path'"
    else
        tmux split-window -h "$EDITOR '$resolved_path'"
    fi
    exit 0
fi

# Last resort: Copy path and notify (user can paste wherever they want)
tmux display-message "Path copied: $resolved_path (no yazi IPC, no \$EDITOR)"
