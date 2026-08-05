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
- **WhatsApp** — usually the single biggest thing on the disk (measured 38 GB,
  2026-08-04). **The media IS separable from the DB — see the recipe below.**
  The in-app cleanup is file-by-file and impractical at this scale; don't
  punt the user there when they have tens of GB in group forwards.
- **Docker** (`com.docker.docker/Data/vms`): see above, Docker Desktop UI only.
- **Other apps**: ask before touching — these are app state, not caches.

For `Package manager caches`: offer `rm -rf` per cache (huggingface, .bun,
.cargo/registry). All regenerable but rebuilds are slow (huggingface
re-downloads model weights, cargo re-fetches crates). Default recommendation:
skip unless desperate for space.
**`~/Library/pnpm` is NOT all cache** — it holds `store/` (the content cache,
safe) *and* `global/` (globally installed binaries the user actually runs,
e.g. `chrome-mcp-bridge`). Only ever delete `~/Library/pnpm/store`.

---

## WhatsApp media — the bulk-delete recipe

The layout (verified 2026-08-04, WhatsApp for macOS):

```
group.net.whatsapp.WhatsApp.shared/
├── ChatStorage.sqlite      ← THE MESSAGE DB. Never touch. (~700 MB)
├── LocalKeyValue.sqlite, Axolotl.sqlite, fts/   ← never touch
└── Message/Media/          ← PURE MEDIA, safe to prune (~37 GB)
    └── <JID>/x/y/<uuid>.<ext>
```

`Message/Media/` contains **only** media files, one directory per chat, keyed
by JID. **Deleting media does not touch the message DB** — every message, its
text, and the full chat history survive; the attachment shows as unavailable.

- **JID suffixes:** `@g.us` = group chat · `@s.whatsapp.net` / `@lid` =
  individual. Groups are almost always the bulk (measured: 31.5 GB of 37 GB
  across 252 groups; `.mp4` alone was 15.4 GB).
- **Target heavy assets in groups**, ranked by regret-risk: videos >10 MB
  older than 180 days (viral forwards) → all videos >10 MB → all videos →
  PDFs (careful: work documents and invoices hide here).
- **Never filter individual chats the same way** without asking per chat —
  that's where personal photos live.

### Mandatory procedure

1. **Quit WhatsApp first** (`osascript -e 'tell application "WhatsApp" to quit'`,
   then poll `pgrep -x WhatsApp`). Never move files under a running app.
2. **Two-phase, never a straight delete.** Move to `~/whatsapp-media-staging-<date>/`
   preserving the relative path (`<JID>/x/y/file`), have the user open WhatsApp
   and confirm nothing else broke, and only then delete the staging dir. A move
   within the same volume is instant and frees nothing until phase 2 — that
   delay is the whole point. Print the inverse `mv` command as the restore path.
3. **Materialize the file list BEFORE moving anything.** Piping `find` straight
   into a move loop makes `find` lose entries as the tree changes underneath it
   — measured: it moved 1232 of 2366 files and reported success. Write the list
   to a file first, then iterate over the static list.
4. **Never suppress stderr on the `mv`.** Count successes and failures
   separately and verify the remaining count is zero at the end.
5. **Say the irreversible part out loud** before starting: WhatsApp *may*
   re-download from its servers, but the window is limited and not guaranteed.
   Media still on the user's phone is unaffected — but don't assert that without
   checking.

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
