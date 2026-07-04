#!/bin/bash
# Prints tmux session names currently active on the Arch box, one per line.
# Prints nothing (exit 0) if the host is unreachable, auth fails, or the
# connection attempt exceeds the timeout — never blocks the rest of
# dev-startup.sh waiting on a dead remote.

REMOTE="${ET_REMOTE:-andre@andre-arch}"

ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
	"$REMOTE" "tmux list-sessions -F '#S'" 2>/dev/null
exit 0
