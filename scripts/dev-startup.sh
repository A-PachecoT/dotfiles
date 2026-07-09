#!/bin/bash
# Launch Ghostty windows with tmux sessions and route each to its AeroSpace
# workspace on Mac boot.
#
# Idempotent: AeroSpace re-runs after-startup-command on every restart of the
# window manager, so a session whose Ghostty window already exists is skipped
# and left untouched (not even re-moved -- moving it would scramble a layout
# the user has since arranged). `--force` opts back into unconditional spawn.
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
FORCE=0
for arg in "$@"; do
	case "$arg" in
	--dry-run) DRY_RUN=1 ;;
	--force) FORCE=1 ;; # spawn windows even if one already exists
	esac
done

log() {
	echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >>"$LOG_FILE"
	[ "$DRY_RUN" -eq 1 ] && echo "$*"
}

# Runs "$@" with a hard wall-clock timeout (seconds). macOS ships no
# timeout(1)/gtimeout(1) by default, so this hand-rolls one: background the
# command, poll, force-kill if it overruns. Needed because `aerospace` can
# hang outright under contention with SketchyBar's own concurrent polling
# (the documented aerospace<->sketchybar deadlock class -- see
# macos/sketchybar/.config/sketchybar/plugins/aerospace.sh /
# docs/audio-priority-system.md) instead of just failing fast, so a bare
# retry COUNT around a blocking call is not enough on its own -- confirmed
# live: a bare `aerospace list-windows --all` call inside a loop hung
# indefinitely on the second invocation during testing.
run_with_timeout() {
	local secs="$1"
	shift
	"$@" &
	local pid=$! waited=0
	while kill -0 "$pid" 2>/dev/null; do
		if [ "$waited" -ge $((secs * 10)) ]; then
			kill -9 "$pid" 2>/dev/null
			wait "$pid" 2>/dev/null
			return 124
		fi
		waited=$((waited + 1))
		sleep 0.1
	done
	wait "$pid"
}

# Polls for a Ghostty window with an exact title match (tmux sets the window
# title to the session name on attach). Never relies on "current focus" --
# `aerospace move-node-to-workspace` without --window-id acts on whatever
# window the OS currently considers focused, which races against every other
# window we're launching in the same loop (confirmed live: it moved an
# unrelated already-focused window instead of the freshly spawned one).
# Prints the highest-numbered matching window-id (newest, since AeroSpace
# assigns window-ids in increasing creation order), or nothing if it never
# appears within a handful of tries. Kept short (not dozens of retries) to
# limit total `aerospace` call volume per the deadlock note above.
find_ghostty_window_id() {
	local title="$1" tries=0 id
	while [ "$tries" -lt 5 ]; do
		id="$(run_with_timeout 2 aerospace list-windows --all --format '%{window-id}|%{window-title}|%{app-name}' 2>/dev/null \
			| awk -F'|' -v t="$title" '$3=="Ghostty" && $2==t {print $1}' \
			| sort -n | tail -1)"
		if [ -n "$id" ]; then
			echo "$id"
			return 0
		fi
		tries=$((tries + 1))
		sleep 0.3
	done
	return 1
}

# True when a Ghostty window for this session already exists. AeroSpace re-runs
# after-startup-command on every `aerospace` restart, not just on Mac boot, so
# every launch below must no-op when its window is already up -- otherwise a
# bare `killall AeroSpace && open -a AeroSpace` duplicates every window and
# scrambles the workspace layout. Single attempt, no retry loop: an existing
# window is already listed, and a miss here is the normal boot path.
ghostty_window_exists() {
	local title="$1" id
	id="$(run_with_timeout 2 aerospace list-windows --all --format '%{window-id}|%{window-title}|%{app-name}' 2>/dev/null \
		| awk -F'|' -v t="$title" '$3=="Ghostty" && $2==t {print $1}' \
		| head -1)"
	[ -n "$id" ]
}

move_ghostty_window() {
	local title="$1" workspace="$2" win_id
	win_id="$(find_ghostty_window_id "$title")"
	if [ -n "$win_id" ]; then
		run_with_timeout 2 aerospace move-node-to-workspace --window-id "$win_id" "$workspace"
	else
		log "warning: no Ghostty window titled '$title' appeared within timeout; left unmoved (workspace $workspace)"
	fi
	# Small pacing gap: reduces how often our calls land concurrently with
	# SketchyBar's own aerospace polling (see run_with_timeout note above).
	sleep 0.4
}

launch_local_session() {
	local session="$1" workspace="$2"
	if [ "$FORCE" -eq 0 ] && ghostty_window_exists "$session"; then
		log "skip: local session '$session' already has a Ghostty window"
		return
	fi
	if [ "$DRY_RUN" -eq 1 ]; then
		log "dry-run: local session '$session' -> tmux new -A -s $session -> workspace $workspace"
		return
	fi
	open -na Ghostty --args --command="tmux new -A -s $session"
	move_ghostty_window "$session" "$workspace"
}

launch_remote_session() {
	local session="$1" workspace="$2"
	if [ "$FORCE" -eq 0 ] && ghostty_window_exists "$session"; then
		log "skip: remote session '$session' already has a Ghostty window"
		return
	fi
	if [ "$DRY_RUN" -eq 1 ]; then
		log "dry-run: remote session '$session' -> etc $session (via zsh -ic) -> workspace $workspace"
		return
	fi
	open -na Ghostty --args --command="/bin/zsh -ic 'etc $session'"
	move_ghostty_window "$session" "$workspace"
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
# Collected into arrays first, then iterated with a plain counting loop
# (no `read`, no pipe) -- confirmed live that piping into `while read` and
# calling `aerospace` inside the loop body silently drains the loop's stdin
# and kills it after the first iteration.
assign_types=()
assign_names=()
assign_workspaces=()
while IFS=' ' read -r type name workspace; do
	[ -z "$name" ] && continue
	assign_types[${#assign_types[@]}]="$type"
	assign_names[${#assign_names[@]}]="$name"
	assign_workspaces[${#assign_workspaces[@]}]="$workspace"
done <<EOF
$assignments
EOF

idx=0
n=${#assign_names[@]}
while [ "$idx" -lt "$n" ]; do
	case "${assign_types[$idx]}" in
	local) launch_local_session "${assign_names[$idx]}" "${assign_workspaces[$idx]}" ;;
	remote) launch_remote_session "${assign_names[$idx]}" "${assign_workspaces[$idx]}" ;;
	esac
	idx=$((idx + 1))
done
