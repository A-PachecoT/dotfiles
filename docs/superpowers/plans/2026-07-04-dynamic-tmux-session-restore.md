# Dynamic tmux Session Restore + Workspace Assignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 4-hardcoded-sessions boot flow in `scripts/dev-startup.sh` with dynamic discovery (local sessions from tmux-resurrect's snapshot, remote sessions from the Arch box over SSH) and a stable per-name AeroSpace workspace assignment, plus fix two `.aerospace.toml` routing rules (Bitwarden pinned+tiled to workspace 8, Cursor no longer forced to workspace 5).

**Architecture:** Three new small, independently-testable bash scripts (`resurrect-session-names.sh`, `arch-session-names.sh`, `workspace-sticky-map.sh`) each do one job and print plain text to stdout. `dev-startup.sh` composes them: launch the fixed trio, discover variable sessions, resolve workspaces via the sticky map, open one Ghostty window per variable session. `.aerospace.toml` gets three targeted edits.

**Tech Stack:** bash (must run under bash 3.2 — macOS's `/bin/bash` — no associative arrays, no `mapfile`), tmux, AeroSpace CLI (`aerospace`), Ghostty (`open -na Ghostty --args --command=...`), SSH.

## Global Constraints

- All new/modified scripts must run correctly under bash 3.2 (macOS's default `/bin/bash`) — **no** `declare -A`, **no** `mapfile`, **no** `readarray`. Use indexed arrays (`local -a`) and `while read` loops instead. (Source: spec "Error handling" + this Mac's `/bin/bash --version` = 3.2.57; GUI-launched `exec-and-forget` processes cannot be assumed to have Homebrew's bash on `PATH`.)
- Do not use `set -e` or `set -u` in `dev-startup.sh` or its helpers — one failing session/window must not abort the rest of the loop, and bash 3.2 has a known bug where `set -u` + an empty array expansion throws "unbound variable". Use `set -o pipefail` only where useful, and explicit `|| true` / return-code checks instead of `-e`.
- Local sticky-map state lives at `~/.local/state/dotfiles/dev-startup-workspace-map.txt` and log at `~/.local/state/dotfiles/dev-startup.log` — both machine-local, **not** committed to the dotfiles repo (same convention as `~/.claude/settings.json`).
- Fixed pool for dynamic sessions: `3 4 5 6 7 10` (spec: "Variable pool").
- Pinned workspaces, unchanged by this plan except where noted: 1=Comet, 2=cofoundy, 9=Obsidian+notes. New pin: 8=Bitwarden (tiled).
- Spec reference: `docs/superpowers/specs/2026-07-04-dynamic-tmux-session-restore-design.md`.

---

### Task 1: `scripts/resurrect-session-names.sh`

**Files:**
- Create: `scripts/resurrect-session-names.sh`
- Test: manual (bash has no test framework in this repo; verified via direct invocation with fixture files, shown in the steps below)

**Interfaces:**
- Produces: no args; prints one local tmux session name per line to stdout, excluding `cofoundy` and `notes`; exits 0 even if the snapshot file is missing (prints nothing). Honors env var `RESURRECT_DIR_OVERRIDE` (takes priority over the tmux `@resurrect-dir` option and the default path) so it can be tested without a live tmux server.
- Consumes: tmux option `@resurrect-dir` (optional, read via `tmux show-option -gqv @resurrect-dir`), tmux-resurrect's snapshot file format: tab-delimited lines, first field `pane`, second field session name (verified live on this machine: `awk -F'\t' '$1=="pane"{print $2}' ~/.local/share/tmux/resurrect/last`).

- [ ] **Step 1: Write the script**

Create `scripts/resurrect-session-names.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x ~/dotfiles/scripts/resurrect-session-names.sh`

- [ ] **Step 3: Test against a fixture snapshot**

Run:
```bash
FIXTURE_DIR=$(mktemp -d)
printf 'pane\taeda\t1\t1\t:*\t1\tfoo\t:/tmp\t1\tzsh\t:\n' > "$FIXTURE_DIR/last"
printf 'pane\tcofoundy\t1\t0\t:\t1\tbar\t:/tmp\t1\tzsh\t:\n' >> "$FIXTURE_DIR/last"
printf 'pane\tnotes\t1\t0\t:\t1\tbaz\t:/tmp\t1\tzsh\t:\n' >> "$FIXTURE_DIR/last"
printf 'pane\tbilio\t1\t0\t:\t1\tqux\t:/tmp\t1\tzsh\t:\n' >> "$FIXTURE_DIR/last"
RESURRECT_DIR_OVERRIDE="$FIXTURE_DIR" ~/dotfiles/scripts/resurrect-session-names.sh
```
Expected output (order-independent, but this exact set):
```
aeda
bilio
```
(`cofoundy` and `notes` must NOT appear — they're pinned.)

- [ ] **Step 4: Test the missing-snapshot case**

Run:
```bash
EMPTY_DIR=$(mktemp -d)
RESURRECT_DIR_OVERRIDE="$EMPTY_DIR" ~/dotfiles/scripts/resurrect-session-names.sh; echo "exit=$?"
```
Expected output: nothing printed, then `exit=0`.

- [ ] **Step 5: Sanity-check against the real snapshot on this machine**

Run: `~/dotfiles/scripts/resurrect-session-names.sh`
Expected: prints the current non-pinned local sessions — at the time this plan was written that was `aeda`, `bilio`, `personal`, `portfolio`, `thesis` (one per line, `cofoundy` and `notes` absent). The exact set may differ by the time you run this if sessions changed — just confirm `cofoundy`/`notes` are absent and the rest match `tmux ls`.

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
git add scripts/resurrect-session-names.sh
git commit -m "feat(dev-startup): add resurrect-session-names.sh for dynamic session discovery"
```

---

### Task 2: `scripts/arch-session-names.sh`

**Files:**
- Create: `scripts/arch-session-names.sh`

**Interfaces:**
- Produces: no args; prints one remote tmux session name per line to stdout (from the Arch box); prints nothing (exit 0) on any SSH failure/timeout — never hangs longer than the connect timeout.
- Consumes: env var `ET_REMOTE` (same override used by the existing `etc` zsh function in `shared/zsh/tmux-workflow.zsh`, default `andre@andre-arch`).

- [ ] **Step 1: Write the script**

Create `scripts/arch-session-names.sh`:

```bash
#!/bin/bash
# Prints tmux session names currently active on the Arch box, one per line.
# Prints nothing (exit 0) if the host is unreachable, auth fails, or the
# connection attempt exceeds the timeout — never blocks the rest of
# dev-startup.sh waiting on a dead remote.

REMOTE="${ET_REMOTE:-andre@andre-arch}"

ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
	"$REMOTE" "tmux list-sessions -F '#S'" 2>/dev/null
exit 0
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x ~/dotfiles/scripts/arch-session-names.sh`

- [ ] **Step 3: Test the unreachable-host case (deterministic, no network dependency on Arch's actual state)**

Run:
```bash
time ET_REMOTE="andre@10.255.255.1" ~/dotfiles/scripts/arch-session-names.sh; echo "exit=$?"
```
Expected: no output, `exit=0`, and the `time` output shows it returned in ~3 seconds or less (bounded by `ConnectTimeout=3`), not hanging.

- [ ] **Step 4: Test against the real Arch box**

Run: `~/dotfiles/scripts/arch-session-names.sh`
Expected: if the Arch box is reachable right now, prints its active tmux session names (one per line, e.g. `cofoundy`). If it's offline, prints nothing and returns quickly — both are acceptable; the important thing is it doesn't hang or error loudly.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add scripts/arch-session-names.sh
git commit -m "feat(dev-startup): add arch-session-names.sh for remote session discovery"
```

---

### Task 3: `scripts/workspace-sticky-map.sh`

**Files:**
- Create: `scripts/workspace-sticky-map.sh`

**Interfaces:**
- Produces: reads `"type name"` pairs (space-separated, one per line, `type` is `local` or `remote`) from stdin; prints `"type name workspace"` for each, one per line, preserving input order; persists the full resolved map to `wsmap_file()`'s path (overridable via env var `WSMAP_FILE`, dropping entries not present in this run's input).
- Consumes: `WSMAP_POOL` pool of workspace numbers (hardcoded `"3 4 5 6 7 10"` per the global constraints); previously-persisted map file (tab-delimited `name<TAB>type<TAB>workspace`).

- [ ] **Step 1: Write the script**

Create `scripts/workspace-sticky-map.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x ~/dotfiles/scripts/workspace-sticky-map.sh`

- [ ] **Step 3: Test fresh assignment (no prior map)**

Run:
```bash
FIXTURE_MAP=$(mktemp -u)
printf 'local aeda\nlocal bilio\nlocal personal\n' | WSMAP_FILE="$FIXTURE_MAP" ~/dotfiles/scripts/workspace-sticky-map.sh
```
Expected output (exact — pool scan order is `3 4 5 6 7 10`):
```
local aeda 3
local bilio 4
local personal 5
```

- [ ] **Step 4: Test stability across two runs (the core "sticky" requirement)**

Run:
```bash
printf 'local aeda\nlocal bilio\nlocal personal\n' | WSMAP_FILE="$FIXTURE_MAP" ~/dotfiles/scripts/workspace-sticky-map.sh
```
Expected output: identical to Step 3 — `aeda`→3, `bilio`→4, `personal`→5, unchanged on a second run with the same input.

- [ ] **Step 5: Test a session dropping out and a new one appearing**

Run:
```bash
printf 'local aeda\nlocal thesis\nlocal personal\n' | WSMAP_FILE="$FIXTURE_MAP" ~/dotfiles/scripts/workspace-sticky-map.sh
```
Expected output: `aeda` and `personal` keep their old workspaces (3 and 5); `bilio` is gone from the map (dropped, since it wasn't in this run's input); `thesis` is new and claims the next free slot in scan order, which is 4 (bilio's old slot, now free since bilio wasn't passed this run):
```
local aeda 3
local thesis 4
local personal 5
```

- [ ] **Step 6: Test pool exhaustion (stacking, never silently dropping)**

Run:
```bash
FIXTURE_MAP2=$(mktemp -u)
printf 'local a\nlocal b\nlocal c\nlocal d\nlocal e\nlocal f\nlocal g\n' | WSMAP_FILE="$FIXTURE_MAP2" ~/dotfiles/scripts/workspace-sticky-map.sh
```
Expected output: 7 lines, one per session, all with a non-empty workspace number (the pool only has 6 slots `3 4 5 6 7 10`, so the 7th session — `g` — reuses one of them rather than being omitted):
```
local a 3
local b 4
local c 5
local d 6
local e 7
local f 10
local g 3
```

- [ ] **Step 7: Test remote/local namespacing (no collision on same name)**

Run:
```bash
FIXTURE_MAP3=$(mktemp -u)
printf 'local cofoundy2\nremote cofoundy2\n' | WSMAP_FILE="$FIXTURE_MAP3" ~/dotfiles/scripts/workspace-sticky-map.sh
```
Expected output: two distinct workspace assignments, since `local cofoundy2` and `remote cofoundy2` are different keys:
```
local cofoundy2 3
remote cofoundy2 4
```

- [ ] **Step 8: Clean up fixture files and commit**

```bash
rm -f "$FIXTURE_MAP" "$FIXTURE_MAP2" "$FIXTURE_MAP3"
cd ~/dotfiles
git add scripts/workspace-sticky-map.sh
git commit -m "feat(dev-startup): add workspace-sticky-map.sh for stable dynamic workspace assignment"
```

---

### Task 4: Rewrite `scripts/dev-startup.sh`

**Files:**
- Modify: `scripts/dev-startup.sh` (full rewrite)

**Interfaces:**
- Consumes: `scripts/resurrect-session-names.sh` (Task 1, no args, stdout = newline-separated local session names), `scripts/arch-session-names.sh` (Task 2, no args, stdout = newline-separated remote session names), `scripts/workspace-sticky-map.sh` (Task 3, stdin = `"type name"` lines, stdout = `"type name workspace"` lines).
- Produces: no output contract for other tasks to consume (this is the top-level orchestrator); accepts optional `--dry-run` argv[1].

- [ ] **Step 1: Write the new script**

Replace the full contents of `scripts/dev-startup.sh`:

```bash
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
```

- [ ] **Step 2: Dry-run against the real machine state**

Run: `~/dotfiles/scripts/dev-startup.sh --dry-run`
Expected: prints lines like:
```
dry-run: local session 'cofoundy' -> tmux new -A -s cofoundy -> workspace 2
dry-run: local session 'notes' -> tmux new -A -s notes -> workspace 9
dry-run: local session 'aeda' -> tmux new -A -s aeda -> workspace 3
dry-run: local session 'bilio' -> tmux new -A -s bilio -> workspace 4
dry-run: local session 'personal' -> tmux new -A -s personal -> workspace 5
dry-run: local session 'portfolio' -> tmux new -A -s portfolio -> workspace 6
dry-run: local session 'thesis' -> tmux new -A -s thesis -> workspace 7
```
(plus a `remote session ...` line per Arch session if the box is reachable). No Ghostty windows open, no AeroSpace calls made. Exact workspace numbers for the variable sessions depend on what's already in `~/.local/state/dotfiles/dev-startup-workspace-map.txt` from earlier testing in Task 3 — if that file has stale test fixtures in it, this is the wrong file (it's a different path, `WSMAP_FILE` fixtures in Task 3 used `mktemp -u` paths, not this real one) so it should be clean on first real run.

- [ ] **Step 3: Confirm stability — run dry-run again**

Run: `~/dotfiles/scripts/dev-startup.sh --dry-run`
Expected: byte-for-byte the same workspace numbers per session as Step 2 (confirms the sticky map is doing its job against the real state file).

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles
git add scripts/dev-startup.sh
git commit -m "refactor(dev-startup): dynamic session discovery + sticky workspace assignment

Replaces the 4-hardcoded-sessions boot flow with discovery from the
tmux-resurrect snapshot (local) and an SSH query (Arch box, remote),
resolved through workspace-sticky-map.sh for stable placement."
```

---

### Task 5: `.aerospace.toml` routing changes

**Files:**
- Modify: `macos/aerospace/.aerospace.toml`

- [ ] **Step 1: Add Bitwarden to after-startup-command**

Find:
```toml
after-startup-command = [
    'exec-and-forget sketchybar',
    'exec-and-forget open -a "Obsidian"',
    'exec-and-forget open -a "Comet"',
    'exec-and-forget $HOME/dotfiles/scripts/dev-startup.sh'
]
```
Replace with:
```toml
after-startup-command = [
    'exec-and-forget sketchybar',
    'exec-and-forget open -a "Obsidian"',
    'exec-and-forget open -a "Comet"',
    'exec-and-forget open -a "Bitwarden"',
    'exec-and-forget $HOME/dotfiles/scripts/dev-startup.sh'
]
```

- [ ] **Step 2: Pin the Bitwarden desktop app to workspace 8, tiled**

Find:
```toml
[[on-window-detected]]
if.app-name-regex-substring = 'bitwarden'
run = 'layout floating'
```
Replace with:
```toml
[[on-window-detected]]
if.app-name-regex-substring = 'bitwarden'
run = 'move-node-to-workspace 8'
```
Do **not** touch the next rule (the browser-extension popup, matched by `if.window-title-regex-substring = 'Bitwarden'`) — it stays floating.

- [ ] **Step 3: Remove the stale Ghostty title-routing rules for bilio and personal**

Find and delete these two blocks entirely:
```toml
[[on-window-detected]]
if.app-name-regex-substring = 'ghostty'
if.window-title-regex-substring = 'bilio'
run = 'move-node-to-workspace 3'

[[on-window-detected]]
if.app-name-regex-substring = 'ghostty'
if.window-title-regex-substring = 'personal|dotfiles'
run = 'move-node-to-workspace 4'
```
(Leave the `cofoundy` and `notes` Ghostty title rules — those two sessions stay pinned.)

- [ ] **Step 4: Remove the Cursor -> workspace 5 rule**

Find and delete:
```toml
[[on-window-detected]]
if.app-name-regex-substring = 'cursor'
run = 'move-node-to-workspace 5'
```

- [ ] **Step 5: Validate the TOML by reloading AeroSpace**

Run: `aerospace reload-config`
Expected: no error output. If AeroSpace prints a parse error, fix the TOML syntax before continuing (a missing/extra bracket is the most likely mistake after manual edits).

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
git add macos/aerospace/.aerospace.toml
git commit -m "fix(aerospace): pin Bitwarden to workspace 8 tiled, drop stale bilio/personal/cursor routing

bilio and personal are now dynamically placed by dev-startup.sh instead
of statically pinned, so their static title-routing rules would race
against it. Cursor no longer has a forced workspace."
```

---

### Task 6: End-to-end validation before reboot

**Files:** none (validation only)

- [ ] **Step 1: Confirm the sticky map survived Task 4's testing correctly**

Run: `cat ~/.local/state/dotfiles/dev-startup-workspace-map.txt`
Expected: one line per variable session seen during Task 4's dry runs, e.g.:
```
aeda	local	3
bilio	local	4
personal	local	5
portfolio	local	6
thesis	local	7
```
(plus any remote lines, if the Arch box was reachable).

- [ ] **Step 2: Live rehearsal — run dev-startup.sh for real**

Run: `~/dotfiles/scripts/dev-startup.sh`

This opens real Ghostty windows: two more attaching to the already-running `cofoundy`/`notes` sessions (harmless — `tmux new -A` just attaches), and one per variable session (`aeda`, `bilio`, `personal`, `portfolio`, `thesis`, plus remote ones if applicable). Expected: each new Ghostty window lands on the workspace printed in Step 1/Task 4's dry-run output — check with `alt-3`, `alt-4`, etc. or `aerospace list-windows --workspace <n>`. Close the extra windows afterward with `alt-shift-q` (or leave them — `tmux new -A` means no duplicate session state was created, just an extra terminal attached to the same session).

- [ ] **Step 3: Confirm Bitwarden landed correctly**

Check: Bitwarden.app should already be open (launched by `after-startup-command`) and tiled on workspace 8, not floating. If it was already running before this session started, quit and relaunch it once (`open -a "Bitwarden"`) to pick up the new routing rule.

- [ ] **Step 4: Update BITACORA.md per this repo's session-close convention**

Since this changed `scripts/dev-startup.sh` and `.aerospace.toml` (both covered by CLAUDE.md's "Bitácora" section), append a dated entry to `BITACORA.md` per the existing convention in this repo (contexto, qué shipeó, validación, decisiones, learnings) before considering the work done.

- [ ] **Step 5: Give the go-ahead to reboot**

Once Steps 1-4 pass, the Mac is ready to reboot: pinned sessions (cofoundy/notes/Bitwarden) and dynamically-discovered sessions (local + Arch) will all reopen with stable workspace placement.
