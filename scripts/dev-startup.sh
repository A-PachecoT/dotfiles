#!/bin/bash
# Launch Ghostty windows with specific tmux sessions
# Move each to correct workspace immediately after creation

launch_session() {
    local session=$1
    local workspace=$2
    open -na Ghostty --args --command="tmux new -A -s $session"
    sleep 0.3
    aerospace move-node-to-workspace $workspace
}

sleep 0.5
launch_session cofoundy 2
launch_session bilio 3
launch_session personal 4
launch_session notes 9
