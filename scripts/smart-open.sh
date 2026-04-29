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
# Walk from pane_cwd up to (and including) $HOME without stopping at project
# roots. Portfolio folders like ~/cofoundy/ aren't git repos themselves, so
# stopping at the first .git inside them would miss siblings like ~/cofoundy/legal/.
else
    check_dir="$pane_cwd"
    while :; do
        if [[ -e "$check_dir/$filepath" ]]; then
            resolved_path="$check_dir/$filepath"
            break
        fi
        # Stop once we've checked $HOME — don't walk above the user's directory
        [[ "$check_dir" == "$HOME" ]] && break
        [[ "$check_dir" == "/" ]] && break
        check_dir=$(dirname "$check_dir")
    done
fi

# =============================================================================
# FILE NOT FOUND HANDLING
# Purpose: Fuzzy-find fallback when exact path not found (hop recovery)
# Uses fd + fzf to search for files matching the basename
# =============================================================================
if [[ -z "$resolved_path" ]]; then
    # Extract basename for fd's filename search; seed fzf with full relative
    # path so directory context narrows results when basenames collide.
    search_basename=$(basename "$filepath" 2>/dev/null || echo "$filepath")

    # Try fuzzy find with fd, searching from home directory
    # -HI: include hidden AND gitignored. Legal drafts, private docs, and
    # vendored material are exactly the files users hop to — don't silently
    # skip them just because they're gitignored.
    if command -v fd &>/dev/null && command -v fzf &>/dev/null; then
        candidates=$(fd -t f -HI --max-depth 8 "$search_basename" "$HOME" 2>/dev/null | head -50)

        if [[ -n "$candidates" ]]; then
            # Show fzf popup in tmux for selection
            selected=$(echo "$candidates" | fzf-tmux -p 80%,60% \
                --prompt="hop: " \
                --header="Path not found: $filepath" \
                --query="$filepath" \
                --preview='head -50 {}' \
                --preview-window=right:40%:wrap)

            if [[ -n "$selected" ]]; then
                resolved_path="$selected"
            else
                # User cancelled fzf
                exit 0
            fi
        else
            tmux display-message "hop: No matches for '$search_basename'"
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
# `ya emit-to <id> reveal` navigates to parent dir AND highlights the file
# atomically, handling special chars/spaces/quotes safely.
#
# Client-id discovery: the naive assumption "tmux pane ID == yazi --client-id"
# breaks in practice. y() stamps the client-id at launch, but pane IDs can
# diverge over time (pane respawns, tmux server restarts, long-lived shells).
# Instead of guessing, we walk the process tree:
#   tmux pane → pane_pid → yazi child pid → parse `--client-id N` from ps
# -----------------------------------------------------------------------------

# Find yazi pane in the SAME window as the triggering pane
target_window=$(tmux display-message -t "${TMUX_PANE:-}" -p '#{session_name}:#{window_index}' 2>/dev/null || true)

if [[ -n "$target_window" ]]; then
    yazi_pane=$(tmux list-panes -t "$target_window" -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -iE '\byazi\b' | head -1 | awk '{print $1}' || true)
else
    yazi_pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -iE '\byazi\b' | head -1 | awk '{print $1}' || true)
fi

if [[ -n "$yazi_pane" ]]; then
    # Resolve the real client-id from the running yazi process
    pane_pid=$(tmux display-message -t "$yazi_pane" -p '#{pane_pid}' 2>/dev/null || true)
    client_id=""
    if [[ -n "$pane_pid" ]]; then
        yazi_pid=$(pgrep -P "$pane_pid" yazi 2>/dev/null | head -1 || true)
        if [[ -n "$yazi_pid" ]]; then
            client_id=$(ps -o command= -p "$yazi_pid" 2>/dev/null | grep -oE -- '--client-id [0-9]+' | awk '{print $2}' || true)
        fi
    fi

    # Fallback to pane-id heuristic if discovery failed (yazi launched raw)
    [[ -z "$client_id" ]] && client_id="${yazi_pane#%}"

    # If target is hidden (dotfile or dot-dir), ensure hidden entries are visible
    if [[ "$file" == .* ]]; then
        ya emit-to "$client_id" hidden show 2>/dev/null || true
    fi

    if [[ -d "$resolved_path" ]]; then
        # Directory: cd yazi into it so the user sees the contents directly.
        # No auto-open (yazi's opener for dirs is "enter", which cd already did).
        if ya emit-to "$client_id" cd "$resolved_path" 2>/dev/null; then
            tmux select-pane -t "$yazi_pane"
            exit 0
        fi
    else
        # File: reveal (cd to parent + highlight) + open (triggers yazi's
        # configured opener — nvim for text files, loads inside the yazi pane).
        if ya emit-to "$client_id" reveal "$resolved_path" 2>/dev/null; then
            ya emit-to "$client_id" open 2>/dev/null || true
            tmux select-pane -t "$yazi_pane"
            exit 0
        fi
    fi

    # ya emit-to failed — yazi's DDS registration is flaky when many instances
    # accumulate (upstream yazi issue). Quickest fix: restart the yazi instance
    # so it gets a fresh DDS registration.
    tmux display-message "hop: yazi DDS not responding (id $client_id). Restart yazi: focus pane $yazi_pane, press q, then 'y'"
    exit 1
fi

# No yazi pane visible in this window — don't spawn editors or external openers.
# Hop is explicitly a yazi-navigation tool; if there's nowhere to reveal to, say so.
tmux display-message "hop: no yazi pane in this window"
exit 1
