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

## SketchyBar Theme System

Colors and styling are centralized in `sketchybar/.config/sketchybar/themes/tokyo-night`. The theme is sourced by the main config and plugins, creating a consistent HyDE-inspired aesthetic across all status bar elements.

## Conflict Resolution

The install script handles conflicts by backing up existing files to `backup/` before creating symlinks. If stow conflicts occur, use `stow --adopt` or manually resolve by moving existing files.