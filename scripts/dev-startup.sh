#!/bin/bash
# Launch Ghostty windows with tmux sessions and route each to its AeroSpace
# workspace on Mac boot.
#
# Fixed trio (cofoundy -> WS2, notes -> WS9) always get their pinned slots.
# Bitwarden is launched + routed separately (see .aerospace.toml's
# after-startup-command and on-window-detected rule for workspace 8).
# Every other tmux session -- local (discovered from the last
# tmux-resurrect snapshot) and remote (discovered on the Arch box over
# SSH) -- is placed dynamically via the sticky workspace map.
#
# See docs/superpowers/specs/2026-07-04-dynamic-tmux-session-restore-design.md
#
# Bash 3.2 compatible on purpose (macOS's /bin/bash, which is what runs
# here when AeroSpace execs this via exec-and-forget): no associative
# arrays, no mapfile/readarray. No `set -e`/`set -u`: one failing
# session/window must never abort the rest of the loop.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.local/state/dotfiles/dev-startup.log"
mkdir -p "$(dirname "$LOG_FILE")"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

log() {
	echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >>"$LOG_FILE"
	[ "$DRY_RUN" -eq 1 ] && echo "$*"
}

launch_local_session() {
	local session="$1" workspace="$2"
	if [ "$DRY_RUN" -eq 1 ]; then
		log "dry-run: local session '$session' -> tmux new -A -s $session -> workspace $workspace"
		return
	fi
	open -na Ghostty --args --command="tmux new -A -s $session"
	sleep 0.3
	aerospace move-node-to-workspace "$workspace"
}

launch_remote_session() {
	local session="$1" workspace="$2"
	if [ "$DRY_RUN" -eq 1 ]; then
		log "dry-run: remote session '$session' -> etc $session (via zsh -ic) -> workspace $workspace"
		return
	fi
	open -na Ghostty --args --command="/bin/zsh -ic 'etc $session'"
	sleep 0.3
	aerospace move-node-to-workspace "$workspace"
}

# --- Fixed trio ---
sleep 0.5
launch_local_session cofoundy 2
launch_local_session notes 9

# --- Discover variable sessions ---
local_sessions=()
while IFS= read -r line; do
	[ -n "$line" ] && local_sessions[${#local_sessions[@]}]="$line"
done < <("$SCRIPT_DIR/resurrect-session-names.sh")

remote_sessions=()
while IFS= read -r line; do
	[ -n "$line" ] && remote_sessions[${#remote_sessions[@]}]="$line"
done < <("$SCRIPT_DIR/arch-session-names.sh")

if [ "${#local_sessions[@]}" -eq 0 ] && [ "${#remote_sessions[@]}" -eq 0 ]; then
	log "no variable sessions discovered this boot (fresh resurrect snapshot, or Arch unreachable, or genuinely none running)"
fi

# --- Resolve workspaces via the sticky map ---
variable_input="$(mktemp)"
for s in "${local_sessions[@]:-}"; do
	[ -n "$s" ] && echo "local $s" >>"$variable_input"
done
for s in "${remote_sessions[@]:-}"; do
	[ -n "$s" ] && echo "remote $s" >>"$variable_input"
done

assignments="$("$SCRIPT_DIR/workspace-sticky-map.sh" <"$variable_input")"
rm -f "$variable_input"

# --- Log any workspace shared by more than one session (pool exhaustion) ---
shared_ws="$(echo "$assignments" | awk '{print $3}' | sort | uniq -d)"
if [ -n "$shared_ws" ]; then
	for ws in $shared_ws; do
		sharing="$(echo "$assignments" | awk -v w="$ws" '$3==w{print $1":"$2}' | tr '\n' ' ')"
		log "workspace $ws is shared by multiple sessions (pool exhausted): $sharing"
	done
fi

# --- Launch each variable session ---
echo "$assignments" | while read -r type name workspace; do
	[ -z "$name" ] && continue
	case "$type" in
	local) launch_local_session "$name" "$workspace" ;;
	remote) launch_remote_session "$name" "$workspace" ;;
	esac
done
