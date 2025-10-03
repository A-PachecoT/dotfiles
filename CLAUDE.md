# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a **GNU Stow-managed dotfiles repository** that uses symlinks to create a Single Source of Truth (SSOT) for cross-platform configuration files. The architecture centers around:

- **Package-based organization**: Each application/tool has its own directory (aerospace/, sketchybar/, hyprland/, git/, zsh/)
- **Symlink management**: GNU Stow creates symlinks from `~/.config/` to the repository
- **Live configuration**: Changes in the repo are immediately reflected in the system via symlinks
- **Platform-specific packages**:
  - **macOS**: AeroSpace + SketchyBar (window manager with custom status bar)
  - **Linux**: Hyprland + Waybar (HyDE-based Wayland compositor)

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
- **Output**: WH-1000XM4 > fifine > Echo Dot > MacBook Pro Speakers
- **Input**: fifine Microphone > MacBook Pro Microphone (never WH-1000XM4)

**SPEAKER MODE** (toggle with Cmd+Alt+0):
- **Output**: MacBook Pro Speakers only (skips fifine/headphones/Echo Dot)
- **Input**: Same as headphone mode

Uses HammerSpoon's audio device watcher for instant response to device connect/disconnect events

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

## Platform-Specific Packages

### macOS Packages
- **aerospace/**: AeroSpace window manager configuration
- **sketchybar/**: Status bar with dynamic workspace indicators
- **hammerspoon/**: Audio device automation and window management
- **skhd/**: DEPRECATED - Now handled by AeroSpace

### Linux Packages
- **hyprland/**: User-customizable HyDE (Hyprland) configurations
  - Only includes user-editable files (`userprefs.conf`, `monitors.conf`, custom scripts)
  - Excludes HyDE-managed files (see `hyprland/.stow-local-ignore`)
  - See `hyprland/README.md` for HyDE integration details

### Shared Packages
- **git/**: Git configuration
- **zsh/**: Zsh shell configuration

## Deprecated Packages

- **skhd/**: DEPRECATED - App launch shortcuts now handled directly by AeroSpace for better integration and consistency across empty/occupied workspaces. The skhd service has been disabled from startup.
- **deprecated-hyde/**: Archived pre-macOS Linux/WSL dotfiles (2025-09-02). See `deprecated-hyde/README_DEPRECATED_PLAN.md` for migration plan.

## SketchyBar Theme System

Colors and styling are centralized in `sketchybar/.config/sketchybar/themes/tokyo-night`. The theme is sourced by the main config and plugins, creating a consistent HyDE-inspired aesthetic across all status bar elements.

## Conflict Resolution

The install script handles conflicts by backing up existing files to `backup/` before creating symlinks. If stow conflicts occur, use `stow --adopt` or manually resolve by moving existing files.
- in references/ folder we have others dotfiles. a notable one is from the creator of sketchbar, which has a beautiful design