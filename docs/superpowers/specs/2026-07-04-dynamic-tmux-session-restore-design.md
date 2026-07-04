# Dynamic tmux session restore + workspace assignment

Date: 2026-07-04
Status: Approved, pending implementation

## Problem

`scripts/dev-startup.sh` hardcodes exactly 4 tmux sessions to relaunch at
boot (`cofoundy`, `bilio`, `personal`, `notes`), each pinned to a fixed
AeroSpace workspace. In practice the user now runs more sessions than that
(`aeda`, `portfolio`, `thesis` observed live, on top of the 4 fixed ones),
and those extra sessions are never given a Ghostty window at boot — even
though `tmux-resurrect`/`continuum` silently restores them into the tmux
server in the background, there's no visible window to reach them, so the
user has to manually recreate access after every reboot.

Separately, sessions on the headless Arch box (reached via `etc <session>`,
which wraps Eternal Terminal) are never reopened automatically at all —
today that's 100% manual.

## Goal

On Mac boot, reopen **every** tmux session that existed at shutdown — both
local (macOS) and remote (Arch box, via `et`) — with a visible Ghostty
window, distributed across AeroSpace workspaces. A small, fixed set of
sessions/apps keep permanently pinned workspaces; everything else is
discovered dynamically and assigned workspaces that stay stable across
reboots as long as the session keeps existing.

## Fixed (pinned) assignments

| Workspace | Content |
|---|---|
| 1 | Comet (browser) — unchanged |
| 2 | `cofoundy` tmux session — unchanged |
| 8 | Bitwarden desktop app, **tiled** (not floating) — new |
| 9 | Obsidian + `notes` tmux session — unchanged |

The Cursor→workspace 5 rule is removed entirely; Cursor windows behave like
any other ad-hoc app (stay wherever opened, no forced routing). This frees
workspace 5 to join the variable pool below.

Note: the `personal` tmux session (currently pinned to workspace 4) is
**not** in this fixed table. It and `notes` currently serve the same
purpose (Brainflow/Obsidian). The long-term intent is to retire `personal`
in favor of `notes` as the single Brainflow session at workspace 9 — but
`personal` is the session this very design conversation is running in, so
it cannot be killed as part of this change. For now, `personal` simply
drops out of the pinned set and falls into the variable pool like any other
session; its manual retirement is a separate, later, deliberate action by
the user (kill the session once its work is migrated into `notes`, remove
any leftover reference to it).

## Variable pool

Workspace pool: `{3, 4, 5, 6, 7, 10}`.

Everything not in the fixed table — local sessions (`bilio`, `personal`,
`aeda`, `portfolio`, `thesis`, and any future ones) and remote sessions
discovered on the Arch box — competes for these six workspaces. et-Arch
windows are not treated specially; they're just more entries in the same
variable pool as local sessions.

### Discovery

- **Local sessions**: parsed directly from tmux-resurrect's last snapshot
  file (the same data `continuum` already uses to restore — no separate
  bookkeeping, no drift). Implemented in a new
  `scripts/resurrect-session-names.sh`, independent of any third-party
  plugin's internal helpers (dotfiles doesn't take a hard dependency on
  `tmux-assistant-resurrect`'s `lib-detect.sh`). Session names already
  covered by the fixed table (`cofoundy`, `notes`) are excluded from this
  list.
- **Remote sessions**: `scripts/arch-session-names.sh` runs
  `ssh -o ConnectTimeout=3 -o BatchMode=yes andre-arch "tmux list-sessions -F '#S'"`.
  Bounded by a short connect timeout so an unreachable/offline Arch box
  never delays or blocks the local part of the boot sequence. On any
  failure (timeout, no route, auth failure), the remote list is treated as
  empty and a line is logged — local sessions are unaffected.

### Stable assignment ("sticky map")

A small machine-local state file (`~/.local/state/dotfiles/dev-startup-workspace-map.txt`,
not committed to the dotfiles repo — analogous to `~/.claude/settings.json`
being per-machine) records `name<TAB>local|remote<TAB>workspace` one line
per session ever seen. On each boot:

- A session already in the map reclaims its recorded workspace (as long as
  that workspace is still a valid pool member).
- A session not yet in the map claims the next free slot from the pool, in
  fixed scan order `3, 4, 5, 6, 7, 10`.
- If there are more variable sessions than free pool slots, additional
  sessions are assigned to already-used workspaces (AeroSpace tiles
  multiple windows per workspace automatically) rather than being dropped.
  This is logged, never silent.
- Local and remote sessions are namespaced separately in the map (`local:foo`
  vs `remote:foo`) so an Arch session happening to share a name with a local
  one doesn't collide.

This makes placement stable across reboots for sessions that keep
existing, while gracefully accommodating sessions that come and go, without
needing a fixed pre-registered list.

## `scripts/dev-startup.sh` sequence

1. Launch the fixed trio exactly as today: `cofoundy`→WS2, `notes`→WS9,
   Bitwarden→WS8 (tiled). Creating the first tmux session on a fresh server
   also triggers `continuum`'s on-first-session auto-restore in the
   background, silently recreating all previously-saved local sessions on
   the tmux server (no visible window yet).
2. Short sleep to give continuum's restore a head start, then run
   `resurrect-session-names.sh` to enumerate local sessions, minus the
   fixed ones.
3. Run `arch-session-names.sh` (timeout-guarded) to enumerate remote
   sessions.
4. Resolve the combined variable list against the sticky map, assigning/
   reusing workspace numbers, and persist the updated map.
5. For each variable session, open a Ghostty window (`tmux new -A -s <name>`
   for local, `etc <name>` for remote) and
   `aerospace move-node-to-workspace <n>`. Each iteration is isolated — one
   failing window doesn't abort the rest.

## `.aerospace.toml` changes

- Remove the `cursor` → `move-node-to-workspace 5` rule.
- Change the Bitwarden **app-name** rule from `layout floating` to
  `move-node-to-workspace 8` (tiled). Leave the separate Bitwarden
  **window-title** rule (the browser-extension popup inside Comet)
  untouched — it keeps floating wherever it appears.
- Remove the static Ghostty title-routing rules for `bilio` (→3) and
  `personal|dotfiles` (→4). Those sessions are now dynamically placed by
  `dev-startup.sh`; leaving the static rules in place would race against
  the dynamic placement and cause inconsistent behavior.

## Error handling

- Arch unreachable/timeout → skip remote sessions, log to
  `~/.local/state/dotfiles/dev-startup.log`, local sessions unaffected.
- Resurrect snapshot missing/corrupt (e.g. very first boot with this
  script) → empty variable list, only the fixed trio launches, no crash.
- Sticky map missing/corrupt → treated as empty and regenerated; worst case
  is a one-time reshuffle of workspace assignments, never a broken boot.
- Workspace pool exhausted → sessions stack (tiled) on already-used
  workspaces instead of being dropped; logged.
- Each Ghostty-window launch is isolated so one failure doesn't abort the
  rest of the loop.

## Testing

- `--dry-run` flag on `dev-startup.sh`: prints the computed plan (session
  name, local/remote, assigned workspace) without opening any window or
  touching AeroSpace — used to validate discovery + assignment logic
  without spawning a dozen real windows during development.
- Manual smoke test: run twice in a row (or simulate two boots) and confirm
  the fixed trio is correct, variable sessions land on the same workspaces
  both times (sticky map holds), Arch sessions appear, Bitwarden is tiled
  on WS8, and Cursor is no longer force-routed to WS5.

## Explicitly out of scope

- Actually retiring the `personal` tmux session — that's a manual,
  deliberate action by the user later, once its work is migrated into
  `notes`.
- Any change to how `notes`/Obsidian/Brainflow are used day-to-day.
