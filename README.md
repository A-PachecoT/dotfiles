# dotfiles

> **These are my personal dotfiles.** Optimized for my specific workflow, hardware, and preferences. Feel free to use as inspiration, but this is not a general-purpose framework.

macOS power-user setup: AeroSpace (tiling WM) + SketchyBar (status bar) + Ghostty + tmux + Neovim + Yazi. Managed with GNU Stow.

## Setup (fresh Mac)

```bash
# 1. Clone
git clone git@github.com:A-PachecoT/dotfiles.git ~/dotfiles

# 2. Bootstrap everything
cd ~/dotfiles && ./bootstrap.sh
```

That's it. The bootstrap script handles:

| Step | What it does |
|------|-------------|
| Xcode CLT | Installs command line tools (git, etc.) |
| Homebrew | Installs package manager |
| Brewfile | Installs 30+ packages, casks, and fonts |
| GNU Stow | Creates symlinks for all configs |
| tmux plugins | Installs TPM + plugins |
| GitHub auth | `gh auth login` for secrets access |
| Secrets | Fetches API keys from private repo to `~/.zshrc.local` |
| Health check | Verifies everything works |

After bootstrap: restart Mac, open Ghostty, `tw .` -> coding.

## What's included

```
~/dotfiles/
├── aerospace/       # Tiling window manager (i3/Hyprland-style)
├── sketchybar/      # Custom status bar (per-monitor workspaces, app icons)
├── ghostty/         # Terminal emulator (Cmd keys -> tmux)
├── tmux/            # Multiplexer (sessions, dev layout, hop)
├── nvim/            # Neovim + LazyVim
├── zsh/             # Shell (starship, zoxide, fzf, eza, bat)
├── git/             # Git config
├── yazi/            # File manager
├── hammerspoon/     # Audio device switching
├── scripts/         # tw, ts, tp, tm, dev-startup, smart-open, etc.
├── Brewfile         # All brew dependencies
├── bootstrap.sh     # One-command setup for fresh Mac
├── install.sh       # Stow symlink management
└── setup/
    └── secrets-setup.sh  # Fetch secrets from private repo
```

## Workflow

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

## Secrets management

API keys live in a [private repo](https://github.com/A-PachecoT/dotfiles-secrets) and are fetched on setup:

```
Private repo (dotfiles-secrets)     Local machine
┌─────────────────────┐            ┌──────────────────┐
│  secrets.json       │  gh api    │  ~/.zshrc.local   │
│  {                  │ ────────>  │  export KEY="..." │
│    "API_KEY": "..." │            │  export TOKEN="." │
│  }                  │            │                   │
└─────────────────────┘            └──────────────────┘
                                    sourced by .zshrc
```

To rotate keys: update `secrets.json` in private repo, run `setup/secrets-setup.sh`.

## Day-to-day commands

```bash
# Config management
./install.sh restow          # Re-symlink after changes
./install.sh unstow          # Remove all symlinks

# Optional setup
./install.sh jupyter         # Global Jupyter environment
./install.sh claude          # Claude Code notification hooks

# Updates
brew bundle install          # Install new Brewfile entries
stow <package>               # Symlink individual package
```

## Dependencies

Everything is declared in the [Brewfile](Brewfile). Key components:

- **Window management:** AeroSpace, SketchyBar, HammerSpoon
- **Terminal:** Ghostty, tmux, Yazi, Neovim
- **Shell:** Starship, Zoxide, fzf, eza, bat
- **Fonts:** JetBrains Mono Nerd Font, Hack Nerd Font, sketchybar-app-font
- **Dev:** git, gh, node, jq, lazygit
