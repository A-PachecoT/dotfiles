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

**For comprehensive documentation, see [docs/audio-priority-system.md](docs/audio-priority-system.md)**

HammerSpoon automatically manages audio device switching with two modes:

**HEADPHONE MODE** (default):
- **Output**: Philips TAT1215 > WH-1000XM4 > fifine > Echo Dot > MacBook Pro Speakers
- **Input**: fifine Microphone > MacBook Pro Microphone (never WH-1000XM4)

**SPEAKER MODE** (toggle with Cmd+Alt+0 or click SketchyBar indicator):
- **Output**: Echo Dot > MacBook Pro Speakers (skips fifine/headphones)
- **Input**: Same as headphone mode

Features:
- HammerSpoon audio device watcher for instant response to device connect/disconnect events
- Mode persists across HammerSpoon restarts using `hs.settings`
- SketchyBar shows current mode with icon (󰋋 headphone / 󰓃 speaker) and device name on hover
- Click the SketchyBar icon to toggle modes

See the [comprehensive audio system documentation](docs/audio-priority-system.md) for architecture details, debugging, troubleshooting, and implementation specifics.

## Essential Commands

### Dotfiles Management
```bash
# Install all configurations (creates symlinks)
./install.sh install

# Remove all symlinks (safe uninstall)
./install.sh unstow

# Reinstall after updates
./install.sh restow

# Setup global Jupyter environment
./install.sh jupyter

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

### Python & Jupyter Management

This dotfiles repository includes automatic setup for a **global Jupyter environment** using `uv` (per global CLAUDE.md instructions).

**Setup:**
```bash
# Create global Jupyter environment (done automatically during install)
./install.sh jupyter

# Or setup manually
cd ~ && uv venv .jupyter-env
uv pip install --python ~/.jupyter-env/bin/python ipykernel jupyter jupyterlab pandas numpy matplotlib seaborn scikit-learn
~/.jupyter-env/bin/python -m ipykernel install --user --name=jupyter-global --display-name="Python (Global Jupyter)"
```

**Usage:**
```bash
# Activate environment for terminal work
source ~/.jupyter-env/bin/activate

# Install additional packages
uv pip install --python ~/.jupyter-env/bin/python <package-name>

# In VS Code: Select kernel "Python (Global Jupyter)" for notebooks
# Cmd+Shift+P → "Notebook: Select Notebook Kernel" → "jupyter-global"
```

**Architecture:**
- **Location**: `~/.jupyter-env/` (global environment, outside dotfiles repo)
- **Kernel**: Registered as `jupyter-global` in Jupyter/VS Code
- **Packages**: Pre-installed with common data science libraries (pandas, numpy, matplotlib, seaborn, scikit-learn)
- **Purpose**: Single environment for all notebooks across projects (unless project-specific dependencies needed)

**When to use project-specific environments:**
Create a local `.venv` in your project directory when:
- Project has conflicting dependency versions
- Project requires specific Python version
- Project needs isolated environment for deployment

```bash
# Project-specific environment
cd /path/to/project
uv venv
source .venv/bin/activate
uv pip install ipykernel <other-packages>
python -m ipykernel install --user --name=project-name
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
    'exec-and-forget open -a "Comet"',       # → workspace 1 (replaced Dia browser)
    'exec-and-forget open -a "Cursor"'       # → workspace 2
]
```

**Browser Configuration:**
- **Comet browser** is configured as the primary browser (workspace 1, `alt-q` hotkey)
- Replaced Dia browser throughout the config (2025-10-17)
- Icon mapping: `["Comet"] = ":comet:"` in `app_icons.lua`

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

### SketchyBar App Icons

App icons are managed via **sketchybar-app-font**, a ligature-based font that displays custom icons for applications in the status bar. The icon mappings are stored in `sketchybar/.config/sketchybar/helpers/app_icons.lua`.

**Updating App Icons:**

The upstream repository is frequently updated with new app icons. To pull the latest icons:

```bash
# Download latest font
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf -o ~/Library/Fonts/sketchybar-app-font.ttf

# Download latest icon mappings
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/icon_map.lua -o ~/.config/sketchybar/helpers/app_icons.lua

# Reload SketchyBar
sketchybar --reload
```

**Note:** Keep a backup of your `app_icons.lua` before updating in case you have custom mappings: `cp ~/.config/sketchybar/helpers/app_icons.lua ~/.config/sketchybar/helpers/app_icons.lua.backup`

**Current Icon Count:** 516+ applications supported (as of last update)

## Maintenance Tasks

### Regular Updates

**SketchyBar App Icons** (check monthly or when adding new apps):
```bash
# Backup current icons
cp ~/.config/sketchybar/helpers/app_icons.lua ~/.config/sketchybar/helpers/app_icons.lua.backup

# Update font and mappings
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf -o ~/Library/Fonts/sketchybar-app-font.ttf
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/icon_map.lua -o ~/.config/sketchybar/helpers/app_icons.lua

# Reload to apply
sketchybar --reload
```

**Homebrew Packages:**
```bash
brew update && brew upgrade
brew upgrade --cask
```

**Git Repository:**
```bash
# Commit configuration changes regularly
git add -A
git commit -m "Update configurations"
git push
```

## Conflict Resolution

The install script handles conflicts by backing up existing files to `backup/` before creating symlinks. If stow conflicts occur, use `stow --adopt` or manually resolve by moving existing files.

## Reference Dotfiles

The `references/` folder contains other dotfiles configurations for inspiration:
- **dotfiles-felixkratz-creator-sketchybar**: From the creator of SketchyBar, featuring beautiful design patterns
- **dotfiles-full-aerospace-and-sketchybar-falleco**: Complete AeroSpace + SketchyBar setup
- **dotfiles-omerxx**: Additional configuration examples