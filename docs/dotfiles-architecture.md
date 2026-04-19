# Dotfiles Architecture

Single source of truth for how this repo is organized across **macOS**,
**Linux**, and **Windows (WSL)**. Read this before adding a new package
or moving things around.

## Layout

```
~/dotfiles/
├── shared/          # Stow packages installed on every platform
│   ├── claude/      # Claude Code settings template
│   ├── ghostty/     # Terminal emulator config
│   ├── git/         # .gitconfig (aliases, credential helper, etc.)
│   ├── nvim/        # LazyVim config
│   ├── starship/    # Cross-shell prompt
│   ├── tmux/        # Terminal multiplexer
│   ├── yazi/        # File manager
│   └── zellij/      # Alternate multiplexer
│
├── macos/           # Stow packages installed only on Darwin
│   ├── aerospace/   # Tiling WM
│   ├── sketchybar/  # Status bar
│   ├── hammerspoon/ # Automation (audio, hotkeys)
│   ├── zsh/         # .zshrc (homebrew-bound)
│   ├── skhd/        # DEPRECATED; kept for reference
│   ├── Brewfile     # Homebrew bundle
│   └── bootstrap.sh # Fresh-Mac one-command installer
│
├── linux/           # Stow packages installed only on Linux (incl. WSL)
│   ├── hyprland/    # Wayland compositor config (HyDE-based)
│   ├── waybar/      # Status bar
│   ├── dunst/       # Notification daemon
│   ├── kitty/       # Terminal (Linux uses kitty; macOS uses ghostty)
│   └── zsh/         # HyDE-style .config/zsh/ (distinct from macos/zsh)
│
├── windows/         # Reserved for native Windows (not WSL — see below)
│   └── wsl/         # Empty placeholder; WSL uses linux/ today
│
├── scripts/         # All scripts at top level (not stowed)
│   ├── <shared>     # Cross-platform: claude-pending-*, tm, system-audit
│   └── <macOS>      # macOS-only: aerospace-*, tmux-smart-split-*, etc.
│
├── setup/           # One-off setup scripts (secrets-setup.sh)
├── docs/            # This file, audio-priority-system.md, etc.
├── install.sh       # Platform-aware installer (detects OS, stows groups)
├── CLAUDE.md        # AI agent guide (macOS workflow documentation)
└── README.md
```

## Rules

### 1. Every stow package lives under exactly one group
`shared/`, `macos/`, `linux/`, or `windows/wsl/`. No package at repo
root. `install.sh` finds packages by listing subdirs of the active
groups.

### 2. Platform detection
`install.sh` uses `uname -s`:

| uname -s | Group stowed (in addition to `shared/`) |
|---|---|
| `Darwin` | `macos/` |
| `Linux`  | `linux/` (WSL falls here too, `/proc/version` check sets `is_wsl` flag for informational logging) |
| `MSYS*`, `MINGW*`, `CYGWIN*` | `windows/native/` (not implemented yet) |

### 3. Cross-platform configs go in `shared/`
If the config has no platform-specific paths or commands, it belongs
in `shared/`. When portability breaks (e.g. `/opt/homebrew/...`),
either fix it or keep the file in `macos/` / `linux/`.

### 4. `shared/zsh` does NOT exist
zsh is divergent enough across OS that we have `macos/zsh/.zshrc`
(homebrew + darwin-specific PATHs) and `linux/zsh/.config/zsh/*`
(HyDE ZDOTDIR convention). Different target paths = no stow conflict.

### 5. `scripts/` is flat
All scripts live at `~/dotfiles/scripts/<name>` because ~20+
configs (`aerospace.toml`, `tmux.conf`, `yazi/keymap.toml`,
`CLAUDE.md`) reference them with that hardcoded prefix. Moving them
under `shared/scripts` or `macos/scripts` would break all those
references.

Platform-specificity is documented below; scripts that fail on the
"wrong" OS fail silently when invoked (e.g. Linux tmux bindings for
`tmux-smart-split-*` do nothing because those scripts require
`/opt/homebrew/bin/bash`).

### 6. `setup/` is also flat and not stowed
One-off utilities like `secrets-setup.sh` (pulls machine-local
secrets from a private GitHub repo into `~/.zshrc.local`).

## Platform classification of scripts

| Script | Platform | Why |
|---|---|---|
| `aerospace-cache-update.sh` | macOS | `aerospace` CLI |
| `audio-priority.sh` | macOS | `SwitchAudioSource` |
| `claude-active` | any | Pure tmux |
| `claude-block-dangerous.py` | any | Claude hook, pure Python |
| `claude-jump` | macOS | sketchybar integration |
| `claude-notify` | macOS | `osascript` voice |
| `claude-pending-clear` | macOS | sketchybar trigger |
| `claude-pending-count` | any | Filesystem only |
| `claude-pending-list` | any | Filesystem only |
| `claude-picker` | macOS | fzf + sketchybar |
| `claude-picker-fzf` | any | Pure fzf |
| `dev-startup.sh` | macOS | Launches Ghostty + AeroSpace |
| `hard-reset-all.sh` | macOS | `killall`, `open -a`, AppKit apps |
| `open-floating-terminal.sh` | macOS | AeroSpace + Ghostty |
| `open-in-yazi.sh` | any | yazi + bash |
| `quicklook.sh` | macOS | `qlmanage` |
| `reload-all.sh` | macOS | sketchybar, AeroSpace, Hammerspoon |
| `resume-project.sh` | any | tmux |
| `sketchybar-workspace-trigger.sh` | macOS | sketchybar |
| `smart-open.sh` | macOS | `pbcopy`, `open -a` |
| `switch-to-empty-workspace.sh` | macOS | aerospace |
| `system-audit` | any | `top`/`ps` portable |
| `tm` | any | tmux + fzf |
| `tmux-kill-pane` | macOS | `#!/opt/homebrew/bin/bash` shebang |
| `tmux-kill-window` | any | pure tmux |
| `tmux-smart-split-h` | macOS | shebang + `declare -A` |
| `tmux-smart-split-v` | macOS | shebang + `declare -A` |
| `tmux-window-picker` | any | pure tmux |
| `work-session.sh` | macOS | sketchybar + aerospace |

## Adding a new package

1. Decide the group: is the tool/config used on all your machines
   (`shared/`), only on macOS (`macos/`), only on Linux (`linux/`)?
2. Create the package dir mirroring the target path:
   - `shared/foo/.config/foo/config.toml` → `~/.config/foo/config.toml`
   - `macos/bar/.barrc` → `~/.barrc`
3. Optional: add `<group>/<pkg>/.stow-local-ignore` to exclude files
   (README.md, etc.) from being stowed.
4. Run `./install.sh install` — new package is picked up automatically.

## Adding a new script

Put it in `scripts/` at top level. If it's platform-specific, add a
row to the table above AND either:
- Exit gracefully when the platform is wrong (`uname -s` check at top), or
- Document that it fails silently on the wrong OS.

## Install / uninstall

```bash
./install.sh install   # stow shared/* + {platform}/*
./install.sh unstow    # remove all symlinks
./install.sh restow    # reinstall (after pulling updates)
./install.sh list      # show what would be stowed on this machine
./install.sh claude    # wire Claude Code hooks
./install.sh jupyter   # create global uv-managed Jupyter env
```

## Migration notes (from pre-platform-split)

If you have an older clone where packages were at repo root:
```bash
./install.sh unstow   # safe: removes old symlinks
git pull              # pulls the new structure
./install.sh install  # re-stow from new paths
```

Verify:
```bash
readlink ~/.gitconfig       # should → dotfiles/shared/git/.gitconfig
readlink ~/.aerospace.toml  # (macOS) should → dotfiles/macos/aerospace/.aerospace.toml
readlink ~/.config/hypr/monitors.conf  # (Linux) should → dotfiles/linux/hyprland/.config/hypr/monitors.conf
```

## Why not chezmoi/Nix/YADM?

See context in the PR description for `restructure/platform-dirs`.
TL;DR: Stow with platform-split directories is the minimum viable
multi-OS solution. If the machine count grows past 5+ or we need
templating for per-machine variables (e.g., different monitor configs),
revisit chezmoi.

## Related docs

- `docs/linux-system-config.md` — Arch+HyDE system-level config (kernel,
  SDDM, mkinitcpio, waybar systemd unit, awww, Hyprland v0.53+ syntax).
- `docs/audio-priority-system.md` — HammerSpoon audio routing (macOS).
- `docs/macos-ricing-requirements.md` — SketchyBar/AeroSpace theme notes.
