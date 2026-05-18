---
name: space-clean
description: >
  Use when the user asks about disk space, free space, "mi disco está lleno",
  "limpia el disco", "no me queda espacio", "disk full", "free up space",
  "/space-clean", or when system-audit shows critical disk usage. Two-phase
  cleanup: auto-deletes 100% safe items (regenerable caches, IPC sockets,
  /tmp folders older than 7 days), then walks the user through risky buckets
  (Downloads, Xcode simulators, Docker, large app data) one decision at a time.
---

# space-clean — macOS disk space cleanup, auto-safe + interactive

Reclaim disk space without losing work. Designed for the workflow that
already works in conversation: scan → group culprits into buckets → auto-nuke
the obvious garbage → ask the user once per risky bucket.

> **Andre's preference (validated 2026-05-15):** Auto-handle what's guaranteed
> safe. For anything that might be active work (Downloads, recent /tmp folders,
> app data), present grouped buckets with sizes + dates and let the user decide
> per group. Never ask file-by-file.

---

## When to invoke

- "está lleno mi disco", "no me queda espacio", "libera espacio", "limpia"
- "disk full", "free up space", "/space-clean"
- `df -h /` shows < 20 GB free or > 85% used
- After `system-audit` flags disk pressure

---

## Workflow

### 0. Snapshot before

Always start with:

```bash
df -h /
```

Remember the "Avail" number — quote it at the end for "freed X GB".

### 1. Auto-safe phase (no confirmation)

Run `scripts/auto-safe-clean.sh` from this skill folder. It deletes:

- **IPC sockets / launchd droppings:** `/private/tmp/zeb_def_ipc_*`,
  `/private/tmp/com.apple.launchd.*`
- **Regenerable app caches** (lose nothing):
  - `~/Library/Caches/com.spotify.client/*`
  - `~/Library/Caches/ms-playwright/*`
  - `~/Library/Caches/pip/*`
  - `~/Library/Caches/go-build/*`
  - `~/Library/Caches/Google/*`
  - `~/Library/Caches/camoufox/*`
  - `~/Library/Caches/Homebrew/downloads/*` (re-downloadable)
  - `~/.cache/uv/*` (Python wheels — uv re-fetches on demand; often 10G+)
  - `~/.cache/puppeteer/*` (Chromium for puppeteer)
  - `~/.npm/_cacache/*` and `~/.npm/_npx/*` (npm/npx package caches)
- **Stale /tmp work folders:** anything in `/private/tmp/` whose mtime is
  > 7 days old AND is not a system file (skip `tmux-*`, `.X*-lock`,
  `com.apple.*`).

Report total bytes freed by this phase.

### 2. Diagnostic scan (read-only)

Run `scripts/scan.sh`. It produces a categorized report:

```
== TOP APP-SUPPORT (>500M) ==
== TOP CACHES (>500M, not auto-cleaned) ==
== CONTAINERS / GROUP CONTAINERS (>500M) ==
== PACKAGE MANAGER CACHES ==
== DOWNLOADS (grouped) ==
  installers (.dmg/.pkg): N files, X GB
  tool screenshots (timestamp pattern): N files, X GB
  whatsapp media: N files, X GB
  audio/video sueltos: N files, X GB
  archives (.zip/.rar): N files, X GB
  pdfs > 5M: N files, X GB
  others: N files, X GB
== /tmp folders < 7 days (potentially active) ==
== XCODE / IOS SIMULATORS ==
== DOCKER / COLIMA ==
```

### 3. Present buckets, one at a time

For each non-empty bucket, present it as a markdown table with size + date +
filename, then ask if the user wants the whole bucket gone, individual files,
or skip. Don't merge multiple buckets into one question — Andre likes deciding
per bucket.

For `Downloads → tool screenshots`: these are outputs of agent runs
(`*_2026-XX-XXTXX-XX-XX-XXXZ.png`) — almost always already committed to a repo.
Default recommendation: delete.

For `/tmp folders < 7 days`: list files inside with dates. Flag any with `.venv/`,
`build.py`, recent edits as "possible WIP — confirm".

For `Xcode simulators`: offer `xcrun simctl delete unavailable` (safe — only
removes simulators for SDKs you no longer have).

For `Docker/colima`: offer `docker system prune -af --volumes` only after
showing what's running. Note: that prune does NOT shrink the Docker Desktop
VM disk (`~/Library/Containers/com.docker.docker/Data/vms/*.raw`) — to actually
reclaim that space, user must open Docker Desktop → Troubleshoot → "Clean /
Purge data" (nukes all images/containers, requires re-pull).

For `Containers / Group Containers > 500M`:
- **WhatsApp** (`group.net.whatsapp.WhatsApp.shared/Message`): NEVER `rm` —
  it's the live message DB. Direct user to WhatsApp → Settings → Storage and
  Data → Manage Storage to delete per-chat media.
- **Docker** (`com.docker.docker/Data/vms`): see above, Docker Desktop UI only.
- **Other apps**: ask before touching — these are app state, not caches.

For `Package manager caches`: offer `rm -rf` per cache (huggingface, .bun,
.cargo/registry, ~/Library/pnpm). All regenerable but rebuilds are slow
(huggingface re-downloads model weights, cargo re-fetches crates). Default
recommendation: skip unless desperate for space.

### 4. Final report

```
Before: X GB free
After:  Y GB free
Recovered: (Y-X) GB
```

If anything was relocated (e.g. an important file moved out of Downloads into
its proper home), list those moves explicitly.

---

## Hard rules

1. **Never delete inside Library/Application Support without asking.** That's
   where apps store user data (Claude history, browser profiles, game saves).
2. **Never delete `~/Documents`, `~/Desktop`, `~/Pictures`, `~/Movies`** without
   per-file confirmation — those are user-curated.
3. **Never `rm -rf ~/Library/Developer` blindly** — contains Xcode projects.
   Only `Caches/`, `DerivedData/`, and `xcrun simctl delete unavailable`.
4. **For Downloads, propose relocation before deletion** when the filename
   suggests it belongs in a project (e.g. `*sponsorship*.pdf` → `cofoundy/legal/`).
5. **Confirm before reboot suggestions** — only suggest reboot if swap > 8 GB
   AND uptime > 5 days.
6. **NEVER `rm` inside `~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared`** —
   that's the live message DB. Always direct user to WhatsApp in-app cleanup.
7. **NEVER `rm` inside `~/Library/Containers/com.docker.docker/Data/vms`** —
   that's the Docker Desktop VM disk; deleting corrupts Docker. Use Docker
   Desktop → Troubleshoot → Clean / Purge data instead.

---

## Files in this skill

- `SKILL.md` — this file
- `scripts/auto-safe-clean.sh` — phase 1 (no confirmation)
- `scripts/scan.sh` — phase 2 (read-only diagnostic, structured output)
