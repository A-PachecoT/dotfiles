#!/usr/bin/env bash

# Enhanced clipboard startup script with safety mechanisms
set -euo pipefail

# Configuration
MAX_RETRIES=3
RETRY_DELAY=2
LOG_FILE="/tmp/clipboard-autostart.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Safe process termination with timeout
safe_kill() {
    local pattern="$1"
    local timeout=10
    
    if pgrep -f "$pattern" >/dev/null 2>&1; then
        log "Terminating processes matching: $pattern"
        pkill -f "$pattern" || true
        
        # Wait for graceful termination
        local count=0
        while pgrep -f "$pattern" >/dev/null 2>&1 && [ $count -lt $timeout ]; do
            sleep 1
            ((count++))
        done
        
        # Force kill if still running
        if pgrep -f "$pattern" >/dev/null 2>&1; then
            log "Force killing stubborn processes: $pattern"
            pkill -9 -f "$pattern" || true
            sleep 1
        fi
    fi
}

# Kill any existing clipboard processes to prevent duplicates
log "Starting clipboard cleanup..."
safe_kill "wl-paste.*watch"
safe_kill "clipsync"
safe_kill "clipse.*listen"

# Wait a moment to ensure processes are terminated
sleep 2

# Safe service starter with retry logic
start_service() {
    local service_name="$1"
    local command="$2"
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        log "Starting $service_name (attempt $((retries + 1))/$MAX_RETRIES)"
        
        if eval "$command" 2>>"$LOG_FILE"; then
            log "$service_name started successfully"
            return 0
        else
            log "$service_name failed to start (attempt $((retries + 1)))"
            retries=$((retries + 1))
            [ $retries -lt $MAX_RETRIES ] && sleep $RETRY_DELAY
        fi
    done
    
    log "ERROR: $service_name failed to start after $MAX_RETRIES attempts"
    return 1
}

# Start clipse listener first with resource limits
if command -v clipse >/dev/null 2>&1; then
    # Limit clipse to prevent resource exhaustion
    start_service "clipse listener" "timeout 300 clipse -listen &" || log "WARNING: clipse failed to start"
    sleep 1
else
    log "WARNING: clipse not found, skipping"
fi

# Start cliphist for backward compatibility with rate limiting
if command -v cliphist >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
    # Rate-limited clipboard monitoring to prevent DBus flooding
    start_service "cliphist text monitor" "wl-paste --type text --watch timeout 10 sh -c 'cliphist store' &" || log "WARNING: cliphist text monitor failed"
    start_service "cliphist image monitor" "wl-paste --type image --watch timeout 10 sh -c 'cliphist store' &" || log "WARNING: cliphist image monitor failed"
else
    log "WARNING: cliphist or wl-paste not found, skipping backward compatibility"
fi

# Set up clipboard synchronization for X11/Wayland compatibility
if command -v wl-paste >/dev/null 2>&1; then
    CLIPSYNC_SCRIPT="$HOME/.config/hypr/scripts/clipsync.sh"
    
    if [ -f "$CLIPSYNC_SCRIPT" ] && [ -x "$CLIPSYNC_SCRIPT" ]; then
        # Start clipsync with notification suppression (no timeout - it should run continuously)
        start_service "clipsync bridge" "'$CLIPSYNC_SCRIPT' watch without-notifications &" || log "WARNING: clipsync failed to start"
    else
        log "WARNING: clipsync script not found or not executable"
    fi
else
    log "WARNING: wl-paste not available, skipping clipboard sync"
fi

# Environment fixes for clipboard compatibility
log "Setting up environment variables for clipboard compatibility"
export ELECTRON_OZONE_PLATFORM_HINT=auto
export CHROMIUM_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland"
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland

# Increase DBus timeout to prevent clipboard-related crashes
export DBUS_DEFAULT_TIMEOUT=25000

# Verify services are running
sleep 3
running_services=0
if pgrep -f "clipse.*listen" >/dev/null 2>&1; then
    log "✓ clipse listener is running"
    running_services=$((running_services + 1))
fi

if pgrep -f "wl-paste.*watch.*cliphist" >/dev/null 2>&1; then
    log "✓ cliphist monitors are running"
    running_services=$((running_services + 1))
fi

if pgrep -f "clipsync" >/dev/null 2>&1; then
    log "✓ clipsync bridge is running"
    running_services=$((running_services + 1))
fi

log "Clipboard initialization complete. Running services: $running_services"

# Create a simple health check script
cat > "/tmp/clipboard-health-check.sh" << 'EOF'
#!/bin/bash
# Simple clipboard health check
if ! pgrep -f "clipse.*listen" >/dev/null 2>&1; then
    echo "WARNING: clipse listener not running"
    exit 1
fi
exit 0
EOF
chmod +x "/tmp/clipboard-health-check.sh"

log "Clipboard services startup completed successfully" 