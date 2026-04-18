# dotfiles

> **My personal dotfiles.** Optimized for my workflow, hardware, and
> preferences. Feel free to use as inspiration, but this is not a
> general-purpose framework.

Multi-platform (macOS, Linux, WSL) GNU Stow dotfiles. **macOS is the
daily driver** — AeroSpace (tiling WM) + SketchyBar + Ghostty + tmux +
Neovim + Yazi. **Linux (Arch + HyDE + Hyprland)** mirrors the shared
tooling (nvim, tmux, yazi, starship) plus its own WM stack (hyprland,
waybar, dunst, kitty). Windows (WSL) is supported via the Linux
packages.

See [docs/dotfiles-architecture.md](docs/dotfiles-architecture.md) for
the full structural reference.

## Quick setup

### macOS (fresh Mac, one command)
```bash
git clone git@github.com:A-PachecoT/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./macos/bootstrap.sh
```

Bootstrap handles Xcode CLT, Homebrew, Brewfile (30+ packages), GNU
Stow symlinks, tmux plugins, GitHub auth, secrets from private repo,
and a health check.

### Linux (Arch + HyDE assumed)
```bash
git clone git@github.com:A-PachecoT/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo pacman -S stow     # if not already installed
./install.sh install    # auto-detects Linux → stows shared/* + linux/*
```

See [docs/linux-system-config.md](docs/linux-system-config.md) for
Arch+HyDE system-level config (mkinitcpio, SDDM, AQ_DRM_DEVICES,
waybar systemd unit, Hyprland v0.53+ syntax).

### WSL
Same as Linux. `install.sh` detects WSL via `/proc/version` but
currently treats it as Linux (uses `linux/` packages).

## Layout

```
~/dotfiles/
├── shared/          # installed everywhere
│   ├── claude/      # Claude Code settings template
│   ├── ghostty/     # Terminal emulator
│   ├── git/         # .gitconfig
│   ├── nvim/        # LazyVim
│   ├── starship/    # Prompt
│   ├── tmux/        # Multiplexer
│   ├── yazi/        # File manager
│   └── zellij/      # Alternate multiplexer
├── macos/           # installed on Darwin
│   ├── aerospace/   # Tiling WM
│   ├── sketchybar/  # Status bar
│   ├── hammerspoon/ # Automation (audio, hotkeys)
│   ├── zsh/         # .zshrc (homebrew-bound)
│   ├── Brewfile     # Homebrew bundle
│   └── bootstrap.sh # Fresh-Mac installer
├── linux/           # installed on Linux (incl. WSL)
│   ├── hyprland/    # Wayland compositor
│   ├── waybar/      # Status bar
│   ├── dunst/       # Notifications
│   ├── kitty/       # Terminal
│   └── zsh/         # HyDE ZDOTDIR zsh config
├── windows/wsl/     # reserved placeholder
├── scripts/         # flat: tw, ts, tp, tm, tmux-*, claude-*, smart-open, ...
├── setup/           # one-off scripts (secrets-setup.sh)
├── docs/            # architecture, linux system config, audio system, ...
├── install.sh       # platform-aware installer
└── CLAUDE.md        # AI agent guide (macOS workflow)
```

## Workflow (macOS)

```
AeroSpace workspaces (Alt+2/3/4/9)
└── Ghostty window with tmux session
    └── tmux windows = projects (Cmd+1-9)
        └── Dev layout: yazi + console + Claude Code

┌─────────────────┬──────────────┐
│   yazi (files)  │              │
│      80%        │  Claude Code │
├─────────────────┤     40%      │
│   Console 20%   │              │
└─────────────────┴──────────────┘
       60%
```

**Key commands:**
- `tw .` — Setup dev layout in current tmux window
- `ts cofoundy` — Switch/create tmux session
- `tp` — Project picker with fzf
- `tm` — Session manager TUI (CPU usage, kill sessions)
- `Cmd+f` — Hop: jump to file/URL on screen

Full walkthrough in [CLAUDE.md](CLAUDE.md).

## Secrets

API keys live in a [private repo](https://github.com/A-PachecoT/dotfiles-secrets) and are fetched by `setup/secrets-setup.sh` into `~/.zshrc.local` (cross-platform).

## Day-to-day commands

```bash
./install.sh install       # Stow shared/* + {platform}/*
./install.sh restow        # Re-symlink after updates (git pull)
./install.sh unstow        # Remove all symlinks
./install.sh list          # Show what would be stowed on this machine
./install.sh claude        # Configure Claude Code hooks
./install.sh jupyter       # Global Jupyter env (uv-managed)

# Platform-specific updates
brew bundle install --file=macos/Brewfile   # macOS
sudo pacman -Syu                            # Linux
```

## Dependencies

**macOS** — everything in [macos/Brewfile](macos/Brewfile).
**Linux (Arch)** — `stow`, `kitty`, `waybar`, `dunst`, `yazi`, `tmux`, `nvim`, `starship`, `fzf`, `ripgrep`, `fd`, `bat`, `eza`, `zoxide`, `gh`, `jq`, `lazygit`, plus the HyDE stack.

## Migrating from an older clone

If you cloned before the platform-split restructure (pre-April 2026):
```bash
./install.sh unstow   # remove old symlinks
git pull              # pick up new structure
./install.sh install  # re-stow from new paths
```
