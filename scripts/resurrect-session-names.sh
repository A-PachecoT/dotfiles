#!/bin/bash
# Prints unique local tmux session names from tmux-resurrect's last snapshot,
# excluding the fixed/pinned sessions (cofoundy, notes). One name per line.
# Prints nothing (exit 0) if no snapshot exists yet.
#
# Test hook: set RESURRECT_DIR_OVERRIDE to point at a fixture directory
# instead of resolving tmux-resurrect's real save location.

PINNED_SESSIONS="cofoundy notes"

resurrect_dir() {
	if [ -n "${RESURRECT_DIR_OVERRIDE:-}" ]; then
		echo "$RESURRECT_DIR_OVERRIDE"
		return
	fi
	local override
	override="$(tmux show-option -gqv "@resurrect-dir" 2>/dev/null)"
	if [ -n "$override" ]; then
		echo "$override"
	elif [ -d "$HOME/.tmux/resurrect" ]; then
		echo "$HOME/.tmux/resurrect"
	else
		echo "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
	fi
}

is_pinned() {
	local name="$1" pinned
	for pinned in $PINNED_SESSIONS; do
		[ "$name" = "$pinned" ] && return 0
	done
	return 1
}

main() {
	local snapshot
	snapshot="$(resurrect_dir)/last"
	[ -f "$snapshot" ] || return 0

	local name
	while IFS= read -r name; do
		[ -z "$name" ] && continue
		is_pinned "$name" || echo "$name"
	done < <(awk -F'\t' '$1=="pane"{print $2}' "$snapshot" | sort -u)
}

main "$@"
