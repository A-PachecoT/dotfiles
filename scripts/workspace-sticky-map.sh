#!/bin/bash
# Sticky workspace assignment for dynamic tmux sessions (local + remote).
#
# Reads "type name" pairs from stdin (one per line, type is "local" or
# "remote"), assigns each a workspace from WSMAP_POOL, reusing a session's
# previous assignment when it's seen again, and prints "type name workspace"
# per line in input order. Rewrites the map file to contain exactly the
# sessions seen in this run (stale entries for sessions that no longer exist
# are dropped). If more sessions are passed than pool slots, extra sessions
# share (stack on) already-assigned workspaces instead of being dropped.
#
# Test hook: set WSMAP_FILE to use a fixture path instead of the real
# machine-local state file.

WSMAP_POOL="3 4 5 6 7 10"

wsmap_file() {
	echo "${WSMAP_FILE:-$HOME/.local/state/dotfiles/dev-startup-workspace-map.txt}"
}

# Prints the recorded workspace for "type name", or nothing if not found.
wsmap_lookup() {
	local type="$1" name="$2" file
	file="$(wsmap_file)"
	[ -f "$file" ] || return 0
	awk -F'\t' -v n="$name" -v t="$type" '$1==n && $2==t {print $3; exit}' "$file"
}

wsmap_assign_all() {
	local file dir
	file="$(wsmap_file)"
	dir="$(dirname "$file")"
	mkdir -p "$dir"

	local -a in_types=() in_names=()
	local type name
	while read -r type name; do
		[ -z "$name" ] && continue
		in_types[${#in_types[@]}]="$type"
		in_names[${#in_names[@]}]="$name"
	done

	local n=${#in_names[@]}
	local -a ws_for=()
	local -a used_ws=()
	local i
	i=0
	while [ "$i" -lt "$n" ]; do
		ws_for[$i]="$(wsmap_lookup "${in_types[$i]}" "${in_names[$i]}")"
		if [ -n "${ws_for[$i]}" ]; then
			used_ws[${#used_ws[@]}]="${ws_for[$i]}"
		fi
		i=$((i + 1))
	done

	local -a pool
	pool=($WSMAP_POOL)
	local pool_size=${#pool[@]}
	local cursor=0
	i=0
	while [ "$i" -lt "$n" ]; do
		if [ -z "${ws_for[$i]}" ]; then
			local tries=0 candidate="" found="" taken u
			while [ "$tries" -lt "$pool_size" ]; do
				candidate="${pool[$((cursor % pool_size))]}"
				cursor=$((cursor + 1))
				tries=$((tries + 1))
				taken=0
				for u in "${used_ws[@]:-}"; do
					[ "$u" = "$candidate" ] && taken=1 && break
				done
				if [ "$taken" -eq 0 ]; then
					found="$candidate"
					break
				fi
			done
			if [ -z "$found" ]; then
				found="${pool[$((cursor % pool_size))]}"
				cursor=$((cursor + 1))
			fi
			ws_for[$i]="$found"
			used_ws[${#used_ws[@]}]="$found"
		fi
		i=$((i + 1))
	done

	: > "$file"
	i=0
	while [ "$i" -lt "$n" ]; do
		printf '%s\t%s\t%s\n' "${in_names[$i]}" "${in_types[$i]}" "${ws_for[$i]}" >> "$file"
		echo "${in_types[$i]} ${in_names[$i]} ${ws_for[$i]}"
		i=$((i + 1))
	done
}

wsmap_assign_all
