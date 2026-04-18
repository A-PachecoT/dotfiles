#!/bin/bash
# Quick Look with auto-focus
qlmanage -p "$1" &>/dev/null &
PID=$!
sleep 0.05
osascript -e 'tell application "System Events" to set frontmost of process "qlmanage" to true' 2>/dev/null
wait $PID
