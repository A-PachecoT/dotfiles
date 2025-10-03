#!/usr/bin/env bash

# clipsync.sh - Synchronize clipboard between Wayland and X11 applications
# Enhanced version with safety mechanisms and error handling
set -euo pipefail

# Configuration
MODE="watch"
NOTIFY="yes"
MAX_CLIPBOARD_SIZE=1048576  # 1MB limit
LOG_FILE="/tmp/clipsync.log"
HEARTBEAT_INTERVAL=30
MAX_SYNC_ATTEMPTS=3

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        watch)
            MODE="watch"
            ;;
        once)
            MODE="once"
            ;;
        without-notifications)
            NOTIFY="no"
            ;;
    esac
done

# Function to show notification if enabled
notify() {
    if [ "$NOTIFY" = "yes" ]; then
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "ClipSync" "$1" "$2" -t 2000 2>/dev/null || true
        fi
    fi
}

# Validate clipboard content size and safety
validate_clipboard_content() {
    local content="$1"
    local size=${#content}
    
    if [ $size -gt $MAX_CLIPBOARD_SIZE ]; then
        log "WARNING: Clipboard content too large ($size bytes), skipping sync"
        return 1
    fi
    
    # Check for potential binary content
    if printf '%s' "$content" | LC_ALL=C grep -q '[[:cntrl:]]' 2>/dev/null; then
        # Allow common control chars like newlines and tabs
        if printf '%s' "$content" | LC_ALL=C grep -q $'[^\t\n\r\x20-\x7E]' 2>/dev/null; then
            log "WARNING: Potential binary content detected, skipping sync"
            return 1
        fi
    fi
    
    return 0
}

# Function to sync from Wayland to X11 clipboard with safety checks
sync_to_x11() {
    local content
    local attempts=0
    
    while [ $attempts -lt $MAX_SYNC_ATTEMPTS ]; do
        if content=$(timeout 5 wl-paste -n 2>/dev/null); then
            if [ -n "$content" ] && validate_clipboard_content "$content"; then
                if echo -n "$content" | timeout 5 xclip -selection clipboard 2>/dev/null; then
                    log "Synced to X11 (${#content} bytes)"
                    notify "Clipboard Sync" "Wayland → X11"
                    return 0
                else
                    log "WARNING: Failed to write to X11 clipboard (attempt $((attempts + 1)))"
                fi
            fi
        else
            log "WARNING: Failed to read from Wayland clipboard (attempt $((attempts + 1)))"
        fi
        
        attempts=$((attempts + 1))
        [ $attempts -lt $MAX_SYNC_ATTEMPTS ] && sleep 1
    done
    
    log "ERROR: Failed to sync to X11 after $MAX_SYNC_ATTEMPTS attempts"
    return 1
}

# Function to sync from X11 to Wayland clipboard with safety checks
sync_to_wayland() {
    local content
    local attempts=0
    
    while [ $attempts -lt $MAX_SYNC_ATTEMPTS ]; do
        if content=$(timeout 5 xclip -selection clipboard -o 2>/dev/null); then
            if [ -n "$content" ] && validate_clipboard_content "$content"; then
                if echo -n "$content" | timeout 5 wl-copy 2>/dev/null; then
                    log "Synced to Wayland (${#content} bytes)"
                    notify "Clipboard Sync" "X11 → Wayland"
                    return 0
                else
                    log "WARNING: Failed to write to Wayland clipboard (attempt $((attempts + 1)))"
                fi
            fi
        else
            log "WARNING: Failed to read from X11 clipboard (attempt $((attempts + 1)))"
        fi
        
        attempts=$((attempts + 1))
        [ $attempts -lt $MAX_SYNC_ATTEMPTS ] && sleep 1
    done
    
    log "ERROR: Failed to sync to Wayland after $MAX_SYNC_ATTEMPTS attempts"
    return 1
}

# Check for required tools
if ! command -v wl-paste >/dev/null 2>&1 || ! command -v wl-copy >/dev/null 2>&1; then
    notify "ClipSync Error" "wl-clipboard is not installed"
    echo "Error: wl-clipboard is not installed"
    exit 1
fi

if ! command -v xclip >/dev/null 2>&1; then
    notify "ClipSync Error" "xclip is not installed"
    echo "Error: xclip is not installed"
    exit 1
fi

# Main functionality
case "$MODE" in
    once)
        # Perform one-time sync in both directions
        sync_to_x11
        sync_to_wayland
        ;;
    watch)
        notify "ClipSync" "Starting clipboard sync service"
        
        log "Starting clipboard sync watchers"
        
        # Enhanced Wayland to X11 sync with safety
        {
            last_content=""
            heartbeat_counter=0
            
            while true; do
                if content=$(timeout 5 wl-paste -n 2>/dev/null); then
                    if [ "$content" != "$last_content" ] && [ -n "$content" ]; then
                        if validate_clipboard_content "$content"; then
                            if echo -n "$content" | timeout 5 xclip -selection clipboard 2>/dev/null; then
                                log "Wayland→X11 sync: ${#content} bytes"
                                last_content="$content"
                            else
                                log "WARNING: Failed X11 clipboard write"
                            fi
                        fi
                    fi
                fi
                
                # Heartbeat logging
                heartbeat_counter=$((heartbeat_counter + 1))
                if [ $((heartbeat_counter % HEARTBEAT_INTERVAL)) -eq 0 ]; then
                    log "Wayland watcher heartbeat (${heartbeat_counter}s)"
                fi
                
                sleep 1
            done
        } &
        WAYLAND_PID=$!
        
        # Enhanced X11 to Wayland sync with safety
        {
            last_content=""
            heartbeat_counter=0
            
            while true; do
                if content=$(timeout 5 xclip -selection clipboard -o 2>/dev/null); then
                    if [ "$content" != "$last_content" ] && [ -n "$content" ]; then
                        if validate_clipboard_content "$content"; then
                            if echo -n "$content" | timeout 5 wl-copy 2>/dev/null; then
                                log "X11→Wayland sync: ${#content} bytes"
                                last_content="$content"
                            else
                                log "WARNING: Failed Wayland clipboard write"
                            fi
                        fi
                    fi
                fi
                
                # Heartbeat logging
                heartbeat_counter=$((heartbeat_counter + 1))
                if [ $((heartbeat_counter % HEARTBEAT_INTERVAL)) -eq 0 ]; then
                    log "X11 watcher heartbeat (${heartbeat_counter}s)"
                fi
                
                sleep 1
            done
        } &
        X11_PID=$!
        
        # Setup signal handlers for clean shutdown
        trap 'log "Shutting down clipboard sync"; kill $WAYLAND_PID $X11_PID 2>/dev/null || true; exit 0' TERM INT
        
        log "Clipboard sync watchers started (PIDs: $WAYLAND_PID, $X11_PID)"
        
        # Wait for termination
        wait $WAYLAND_PID $X11_PID
        ;;
esac

exit 0 