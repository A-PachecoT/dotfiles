# Hyprland (HyDE) Configuration Package

## Overview
This package contains **user-customizable** Hyprland configurations for the HyDE (HyprDots Ecosystem) framework. It only includes files that are safe to version control and won't conflict with HyDE's managed files.

## What's Included

### Safe to Edit (Included Here)
- `userprefs.conf` - Personal Hyprland settings, autostart apps, keybindings
- `monitors.conf` - Monitor configuration
- `pyprland.toml` - Pyprland extensions configuration
- `scripts/` - Custom user scripts:
  - `autostart-clipboard.sh` - Multi-manager clipboard startup
  - `clipboard-restart.sh` - Clipboard recovery mechanism
  - `clipboard-wofi.sh` - Clipboard selector integration
  - `clipse-cliphist-bridge.sh` - Sync between clipboard managers
  - `clipsync.sh` - X11/Wayland clipboard synchronization
  - `launch-or-focus-obsidian.sh` - Smart window focus launcher

### NOT Included (HyDE-Managed)
These files are managed by the HyDE framework and should NOT be stowed:
- `hyprland.conf` - Main config (sources from `~/.local/share/hyde/`)
- `animations.conf` - Managed by animation selector
- `shaders.conf` - Managed by shader selector
- `workflows.conf` - Managed by workflow system
- `windowrules.conf` - Managed by HyDE
- `keybindings.conf` - Managed by HyDE (unless heavily customized)

## Installation

### Prerequisites
```bash
# Install GNU Stow if not already installed
sudo pacman -S stow
```

### Initial Setup (if Stow not used yet)
**IMPORTANT**: This assumes your current files are NOT symlinks. Check first:
```bash
ls -la ~/.config/hypr/userprefs.conf
# If it shows "-> /home/andre/dotfiles/..." it's already a symlink - SKIP BACKUP
```

If files are real (not symlinks), backup and stow:
```bash
# Backup existing files
mkdir -p ~/.config/hypr.backup
cp ~/.config/hypr/{userprefs.conf,monitors.conf,pyprland.toml} ~/.config/hypr.backup/ 2>/dev/null || true
cp -r ~/.config/hypr/scripts ~/.config/hypr.backup/ 2>/dev/null || true

# Remove originals (they'll be replaced by symlinks)
rm ~/.config/hypr/{userprefs.conf,monitors.conf,pyprland.toml} 2>/dev/null || true
rm -r ~/.config/hypr/scripts 2>/dev/null || true

# Create symlinks
cd ~/dotfiles
stow hyprland
```

### Verify Installation
```bash
# Check symlinks were created
ls -la ~/.config/hypr/userprefs.conf
# Should show: ... -> /home/andre/dotfiles/hyprland/.config/hypr/userprefs.conf

# Reload Hyprland to test
hyprctl reload
```

## Usage

### Making Changes
Edit files in the repository, changes are live immediately:
```bash
# Edit user preferences
vim ~/dotfiles/hyprland/.config/hypr/userprefs.conf

# Reload Hyprland
hyprctl reload
```

### Version Control
```bash
cd ~/dotfiles
git add hyprland/
git commit -m "feat(hyprland): update user preferences"
git push
```

## Integration with HyDE

### Configuration Loading Order
1. HyDE core (`~/.local/share/hyde/hyprland.conf`)
2. `keybindings.conf` (HyDE-managed)
3. `windowrules.conf` (HyDE-managed)
4. `monitors.conf` (user-managed ✓)
5. `userprefs.conf` (user-managed ✓)
6. `workflows.conf` (HyDE-managed, overrides all)

### HyDE Updates
When updating HyDE, your user files remain safe:
```bash
cd ~/HyDE
./Scripts/install.sh -u
# Your symlinked files in ~/dotfiles/hyprland/ are untouched
```

## Customizations Included

### Input Configuration
- US International keyboard layout
- Caps Lock ⇄ Escape swap
- Mouse: Flat acceleration, -0.3 sensitivity
- Touchpad: Natural scroll, 2-finger scrolling

### Auto-start Applications
- Workspace 1: Vivaldi browser
- Workspace 2: Cursor editor
- Workspace 3: ZapZap messenger
- Workspace 4: Obsidian

### Custom Keybindings
- `Super + PageUp/Down` - Color temperature adjustment
- `Super + Alt + PageUp/Down` - Brightness adjustment
- `Super + =/−` - Zoom in/out (pypr magnify)

### Background Services
- Enhanced clipboard management (clipse + cliphist)
- Pyprland daemon (zoom, extensions)
- wl-gammarelay (color temperature)

## Troubleshooting

### Reload Hyprland configuration
```bash
hyprctl reload
```

### Restore from backup (if something breaks)
```bash
# Unstow symlinks
cd ~/dotfiles
stow -D hyprland

# Restore originals
cp ~/.config/hypr.backup/* ~/.config/hypr/
```

### Check for conflicts
```bash
cd ~/dotfiles
stow --no --verbose hyprland  # Dry-run
```

## Notes
- Only user-customizable files are included
- HyDE framework files are excluded via `.stow-local-ignore`
- Changes are live immediately (symlinks)
- Safe to update HyDE framework independently
