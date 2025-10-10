# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a **GNU Stow-managed dotfiles repository** that uses symlinks to create a Single Source of Truth (SSOT) for macOS configuration files. The architecture centers around:

- **Package-based organization**: Each application/tool has its own directory (aerospace/, sketchybar/, git/, zsh/)
- **Symlink management**: GNU Stow creates symlinks from `~/.config/` to the repository
- **Live configuration**: Changes in the repo are immediately reflected in the system via symlinks
- **AeroSpace + SketchyBar integration**: Window manager with custom status bar showing occupied workspaces

## Critical Integration Points

### AeroSpace ↔ SketchyBar Integration
The `aerospace/.aerospace.toml` contains `exec-on-workspace-change` that triggers SketchyBar updates:
```toml
exec-on-workspace-change = ['/bin/bash', '-c', 
    'sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE'
]
```

SketchyBar listens for this event in `sketchybar/.config/sketchybar/plugins/aerospace.sh` to highlight active workspaces.

### Hyprland-style Workspace Logic
SketchyBar shows only **occupied workspaces** using:
```bash
for sid in $((aerospace list-workspaces --monitor focused --empty no; aerospace list-workspaces --focused) | sort -u); do
```

### Audio Priority System
HammerSpoon automatically manages audio device switching with two modes:

**HEADPHONE MODE** (default):
- **Output**: fifine > Philips TAT1215 > WH-1000XM4 > Echo Dot > MacBook Pro Speakers
- **Input**: fifine Microphone > MacBook Pro Microphone (never WH-1000XM4)

**SPEAKER MODE** (toggle with Cmd+Alt+0 or click SketchyBar indicator):
- **Output**: Echo Dot > MacBook Pro Speakers (skips fifine/headphones)
- **Input**: Same as headphone mode

Features:
- HammerSpoon audio device watcher for instant response to device connect/disconnect events
- Mode persists across HammerSpoon restarts using `hs.settings`
- SketchyBar shows current mode with icon (󰋋 headphone / 󰓃 speaker) and device name on hover
- Click the SketchyBar icon to toggle modes

## Essential Commands

### Dotfiles Management
```bash
# Install all configurations (creates symlinks)
./install.sh install

# Remove all symlinks (safe uninstall)
./install.sh unstow

# Reinstall after updates
./install.sh restow

# Individual package management
stow aerospace        # Install specific package
stow -D sketchybar   # Remove specific package
```

### Live Configuration Testing
```bash
# Test AeroSpace changes
aerospace reload-config

# Test SketchyBar changes  
sketchybar --reload

# Check symlink status
ls -la ~/.aerospace.toml ~/.config/sketchybar ~/.gitconfig
```

### Workspace Debugging
```bash
# Check current workspace
aerospace list-workspaces --focused

# List occupied workspaces
aerospace list-workspaces --monitor focused --empty no

# Manual SketchyBar trigger
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=1
```

### Audio Management
```bash
# Reload HammerSpoon configuration
hs -c "hs.reload()"

# Check HammerSpoon console for audio logs
hs -c "hs.console.show()"

# Manual audio switching hotkey
Ctrl+Alt+A

# Toggle between HEADPHONE/SPEAKER modes
Cmd+Alt+0

# Run original audio priority script manually (backup)
./scripts/audio-priority.sh
```

## Configuration Flow

1. **Edit** files in `/Users/styreep/dotfiles/`
2. **Changes are live** immediately (symlinks)
3. **Reload** applications to see changes
4. **Commit** changes for version control

## Package Structure Requirements

Each package directory must mirror the home directory structure:
- `aerospace/.aerospace.toml` → `~/.aerospace.toml`
- `sketchybar/.config/sketchybar/` → `~/.config/sketchybar/`
- `git/.gitconfig` → `~/.gitconfig`

## Deprecated Packages

- **skhd/**: DEPRECATED - App launch shortcuts now handled directly by AeroSpace for better integration and consistency across empty/occupied workspaces. The skhd service has been disabled from startup (LaunchAgent renamed to `.disabled`).
- **yabai/**: NOT IN USE - AeroSpace has replaced yabai as the window manager. The yabai service has been disabled from startup (LaunchAgent renamed to `.disabled`).

## Startup Configuration

### AeroSpace-Managed Startup (aerospace/.aerospace.toml)

These apps launch automatically via `after-startup-command` and move to assigned workspaces:

```toml
after-startup-command = [
    'exec-and-forget sketchybar',
    'exec-and-forget open -a "Obsidian"',    # → workspace 9
    'exec-and-forget open -a "Dia"',         # → workspace 1
    'exec-and-forget open -a "Cursor"'       # → workspace 2
]
```

### macOS Login Items (System Settings)

Apps that auto-start via macOS (not controlled by AeroSpace):

**Active:**
- **Docker** - Launches hidden in background via `~/Library/LaunchAgents/com.docker.autostart.plist` (uses `--hide` flag)
- **AeroSpace** - Window manager
- **Flux** - Screen color temperature
- **Hammerspoon** - Automation engine (audio switching, hotkeys)
- **Warp** - Terminal
- **Raycast** - App launcher
- **1Password** - Password manager (Browser Helper + Launcher)
- **SketchyBar** - Status bar (via `~/Library/LaunchAgents/homebrew.mxcl.sketchybar.plist`)

**Disabled/Removed:**
- **Gather/GatherV2** - Removed from Login Items (use `alt-g` to launch manually)
- **skhd** - LaunchAgent disabled (see Deprecated Packages)
- **yabai** - LaunchAgent disabled (see Deprecated Packages)

### Managing Startup Apps

```bash
# View current Login Items
osascript -e 'tell application "System Events" to get the name of every login item'

# Remove an app from Login Items
osascript -e 'tell application "System Events" to delete login item "AppName"'

# List all LaunchAgents
ls -la ~/Library/LaunchAgents/

# Disable a LaunchAgent
mv ~/Library/LaunchAgents/com.example.plist ~/Library/LaunchAgents/com.example.plist.disabled
```

## SketchyBar Theme System

Colors and styling are centralized in `sketchybar/.config/sketchybar/themes/tokyo-night`. The theme is sourced by the main config and plugins, creating a consistent HyDE-inspired aesthetic across all status bar elements.

## Conflict Resolution

The install script handles conflicts by backing up existing files to `backup/` before creating symlinks. If stow conflicts occur, use `stow --adopt` or manually resolve by moving existing files.
- in references/ folder we have others dotfiles. a notable one is from the creator of sketchbar, which has a beautiful design