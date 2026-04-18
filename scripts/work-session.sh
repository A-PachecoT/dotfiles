#!/bin/bash

# Work session script - keeps system awake for 9 hours then sleeps
# Usage: ./work-session.sh

HOURS=${1:-9}
SECONDS=$((HOURS * 3600))

echo "🔒 Starting $HOURS-hour work session..."
echo "   • Locking screen now"
echo "   • System will stay awake for $HOURS hours"
echo "   • Press Ctrl+C to cancel early"

# Lock screen immediately
osascript -e 'tell application "System Events" to keystroke "q" using {command down, control down}'

# Keep system awake for specified hours
caffeinate -i -t $SECONDS &
CAFFEINATE_PID=$!

echo "✅ Work session active (PID: $CAFFEINATE_PID)"
echo "   System will auto-sleep at $(date -v+${HOURS}H '+%H:%M')"

# Trigger SketchyBar to show the moon icon
sketchybar --trigger work_session_started

# Wait for caffeinate to finish or be interrupted
wait $CAFFEINATE_PID 2>/dev/null

# Hide the moon icon when session ends
sketchybar --trigger work_session_ended

echo "💤 Work session ended - system can now sleep normally"