# chrome-guardian (Linux)

Watchdog that kills **runaway headless Chrome** processes on this headless Arch box.

## Why
`playwright-mcp` / `firecrawl` MCP servers sometimes leak a headless Chrome that
falls back to **SwiftShader** (software GL, no GPU on a headless box). The leaked
browser can peg several CPU cores indefinitely and cook the laptop
(observed: one `--type=gpu-process` at 758% CPU for ~3h, package temp 80 °C).

## What it does
A `systemd --user` timer runs `chrome-guardian` every 2 min. Each run:
1. Finds Chrome processes whose cmdline contains `--headless` (interactive
   browsers are never touched).
2. Measures **instantaneous** CPU over a short window (`/proc/<pid>/stat` delta).
3. Counts consecutive "hot" checks per pid. After `STRIKES_TO_KILL` strikes it
   walks up to the **topmost chrome ancestor** and kills the whole browser tree
   (TERM, then KILL) — not just the hot child, which Chrome would relaunch.

Defaults: kill if a headless Chrome stays **≥200% CPU for 3 consecutive checks**
(~6 min sustained). Idle/short bursts are ignored.

## Files
| Path | Purpose |
|------|---------|
| `.local/bin/chrome-guardian` | the watcher script |
| `.config/systemd/user/chrome-guardian.service` | oneshot runner |
| `.config/systemd/user/chrome-guardian.timer` | every-2-min trigger |

## Install
```bash
stow --dir=linux --target="$HOME" --no-folding chrome-guardian   # (./install.sh does this)
systemctl --user daemon-reload
systemctl --user enable --now chrome-guardian.timer
loginctl enable-linger "$USER"      # run even with no active session
```

## Tuning (env vars, set in the .service or shell)
| Var | Default | Meaning |
|-----|---------|---------|
| `CHROME_GUARDIAN_THRESHOLD` | `200` | CPU% (>100 = multi-core) to count as hot |
| `CHROME_GUARDIAN_STRIKES` | `3` | consecutive hot checks before kill |
| `CHROME_GUARDIAN_SAMPLE` | `3` | seconds to measure instantaneous CPU |
| `CHROME_GUARDIAN_MATCH` | `--headless` | cmdline substring a target must contain |
| `CHROME_GUARDIAN_DRY_RUN` | `0` | `1` = log only, don't kill |

## Observe
```bash
systemctl --user list-timers chrome-guardian.timer
cat ~/.local/state/chrome-guardian.log          # kill/dry-run events
```
