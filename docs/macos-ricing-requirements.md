# macOS Ricing Requirements & Setup Guide

## Purpose
This is the single source of truth for all system configurations and customizations on this macOS setup. All relevant OS actions, configurations, and modifications should be documented here.

## Background
Transitioning from HyDE (Hyprland + Arch Linux) to macOS while maintaining a customized, efficient workflow.

## Current Setup
### Hardware
- **Model**: MacBook Pro (Mac16,8)
- **Chip**: Apple M4 Pro
- **Memory**: 24 GB
- **OS**: macOS 15.2 Sequoia (24C101)

### Installed Applications
- **Terminal**: Warp
- **Browser**: Dia Browser (default)
- **Package Manager**: Homebrew (installed)
- **Password Manager**: 1Password
- **Clipboard Manager**: Clippy
- **App Launcher**: Raycast
- **Speech to Text**: Super Whisper
- **Music**: Spotify
- **Peripherals**: G-Hub (Logitech devices)
- **Note Taking**: Obsidian

---

## Core Requirements

### 1. Window Management & Tiling
**Goal**: Hyprland-like tiling and workspace management

#### Requirements:
- [x] Tiling window manager with multiple layouts (AeroSpace)
- [x] Keyboard-driven window navigation (`Alt+hjkl`)
- [x] Window movement controls (`Alt+Shift+hjkl`)
- [x] Workspace/desktop switching (`Alt+1/2/3/4...`)
- [x] Window gaps/margins for aesthetics
- [x] Visual workspace indicators in menu bar (SketchyBar)
- [ ] Dynamic workspace creation/destruction

#### Window Movement Between Spaces/Workspaces:

**Native macOS Methods:**
1. **Drag to top of screen**: Window becomes small, drag to desired space
2. **Mission Control**: F3 or swipe up with 3 fingers → drag window to space
3. **Right-click title bar**: Options → Move to Desktop [number]

**With Amethyst (Installed):**
- `Ctrl+Option+Shift+H`: Move window to previous space
- `Ctrl+Option+Shift+L`: Move window to next space
- `Ctrl+Option+Shift+[1-9]`: Move window to specific space

**Workspace Navigation:**
- `Ctrl+Left/Right`: Switch between spaces
- `Ctrl+[1-9]`: Jump to specific space (needs setup in System Settings)

**Setup Better Keybindings:**
1. **System Settings → Keyboard → Keyboard Shortcuts → Mission Control**
   - Enable "Switch to Desktop 1-9" shortcuts
   - Set to `Cmd+[1-9]` or your preference

2. **For Hyprland-like behavior, consider yabai:**
```bash
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd
# More powerful but requires SIP partial disable
```

#### Previous Solution: yabai + skhd (DEACTIVATED)

**Status:** ⚠️ Deactivated on 2025-09-08 in favor of AeroSpace

**Keybindings that were configured (Hyprland-like):**
- `Alt + h/j/k/l` - Focus windows (left/down/up/right)
- `Shift + Alt + h/j/k/l` - Move windows
- `Shift + Alt + 1-9` - Move window to space
- `Ctrl + Alt + h/j/k/l` - Resize windows
- `Alt + f` - Toggle fullscreen
- `Alt + t` - Toggle float
- `Alt + r` - Rotate layout
- `Shift + Alt + 0` - Balance windows
- `Shift + Alt + c` - Create new space
- `Shift + Alt + d` - Destroy current space

**Service management:**
```bash
# Services have been stopped and won't auto-start
yabai --stop-service
skhd --stop-service

# Config files still exist at:
# ~/.yabairc
# ~/.skhdrc

# LaunchAgent files exist but are unloaded:
# ~/Library/LaunchAgents/com.koekeishiya.yabai.plist
# ~/Library/LaunchAgents/com.koekeishiya.skhd.plist
```

#### Current Solution: AeroSpace

**Installed:** 2025-09-08

**Why AeroSpace over yabai:**
- Actively developed and maintained
- Doesn't require SIP (System Integrity Protection) modification
- Simpler configuration
- Better integration with modern macOS

**Installation:**
```bash
brew install --cask nikitabobko/tap/aerospace
```

**Configuration:**
- Config file location: `~/.aerospace.toml` (needs to be created)
- Start AeroSpace: `open -a AeroSpace`
- Grant accessibility permissions when prompted

**Configuration Details:**
- Config file: `~/.aerospace.toml` (✅ created and configured)
- SketchyBar integration: `~/.config/sketchybar/` (✅ installed and themed)
- Workspace switching: `Alt+1-9` (✅ working)
- Window management: `Alt+hjkl` for focus, `Alt+Shift+hjkl` for movement (✅ working)
- Tiling layouts and gaps configured (✅ working)

#### Current Status:
- ✅ yabai/skhd installed but deactivated (not running, won't auto-start)
- ✅ AeroSpace installed and configured
- ✅ AeroSpace configuration complete with Hyprland-like keybindings
- ✅ SketchyBar installed and integrated with AeroSpace
- ✅ Workspace indicators working (Hyprland-style occupied workspaces only)
- ✅ **Dotfiles management implemented with GNU Stow**
- ✅ **SSOT setup: All configs symlinked from ~/dotfiles/**
- ✅ **Install script and documentation complete**
- ✅ Configuration files preserved (~/.yabairc, ~/.skhdrc) for reference

### Dotfiles Management

**Implemented:** 2025-09-10

**What it does:**
- Single Source of Truth (SSOT) for all configuration files
- Uses GNU Stow for symlink management
- Version controlled with Git
- Cross-machine synchronization
- Modular package system

**Structure:**
```
~/dotfiles/
├── aerospace/           # AeroSpace window manager
├── sketchybar/          # SketchyBar status bar  
├── git/                 # Git configuration
├── zsh/                 # Zsh shell
├── install.sh           # Automated setup
└── backup/              # Automatic backups
```

**Key Benefits:**
- ✅ Zero duplication - one source, symlinked everywhere
- ✅ Git version control for all configuration changes
- ✅ Easy setup on new machines with `./install.sh`
- ✅ Safe - can unstow and revert anytime
- ✅ Modular - enable/disable specific packages

**Usage:**
```bash
./install.sh install    # Setup all configs
./install.sh unstow     # Remove all symlinks
./install.sh restow     # Reinstall (after updates)
stow aerospace          # Install specific package
```

---

### 2. Terminal Enhancement
**Goal**: Powerful, beautiful terminal experience

#### Requirements:
- [ ] Custom prompt with git info, directory, etc.
- [ ] Better CLI tools (modern replacements)
- [ ] Syntax highlighting
- [ ] Auto-suggestions
- [ ] Fast search/navigation

#### Tools to Install:
```bash
# Prompt
brew install starship

# Better CLI tools
brew install exa          # Better ls
brew install bat          # Better cat with syntax highlighting
brew install ripgrep      # Better grep
brew install fd           # Better find
brew install tree         # Directory tree view
brew install htop         # Better top
brew install ncdu         # Disk usage analyzer
brew install fzf          # Fuzzy finder
brew install jq           # JSON processor

# Development tools
brew install git
brew install neovim
brew install tmux
```

#### Status:
- ✅ Warp terminal already provides good experience
- ⏳ Need to install enhanced CLI tools

---

### 3. System Appearance & Customization
**Goal**: Clean, minimal, functional aesthetic

#### Requirements:
- [x] Menu bar organization and cleanup (SketchyBar)
- [x] System monitoring in menu bar (SketchyBar ready)
- [ ] Custom dock configuration
- [ ] Icon customization
- [x] Color scheme consistency (HyDE-inspired theme)
- [ ] Wallpaper management
- [x] System-wide programming font (MonoLisa installed)

#### Tools:
```bash
# Menu bar management
brew install --cask bartender     # Menu bar organization
brew install --cask hiddenbar     # Alternative, free option

# System monitoring
brew install --cask stats         # System stats in menu bar

# Dock customization
brew install dockutil             # CLI dock management

# Screenshots
brew install --cask codeshot      # Stylized screenshots
```

#### Fonts:
**MonoLisa** - Premium programming font installed system-wide (2025-09-10)
- Location: `~/Library/Fonts/`
- Variants: Regular and Italic (.ttf files)
- Available in all applications (Terminal, IDEs, browsers, etc.)
- Use for: Terminal, code editors, and any monospaced text needs

#### Menu Bar Customization: SketchyBar

**Installed:** 2025-09-10

**What it does:**
- Replaces macOS menu bar with fully customizable status bar
- Shows AeroSpace workspace indicators (1-10) with active highlighting
- Clean, minimal HyDE-inspired aesthetic
- Real-time workspace switching feedback

**Installation:**
```bash
brew tap FelixKratz/formulae
brew install sketchybar
```

**Configuration:**
- Main config: `~/.config/sketchybar/sketchybarrc`
- AeroSpace integration: `~/.config/sketchybar/plugins/aerospace.sh`
- Theme: `~/.config/sketchybar/themes/tokyo-night`
- Auto-starts with AeroSpace

**Features:**
- ✅ Workspace numbers 1-10 with active highlighting (white/gray)
- ✅ Clean bold MonoLisa font styling
- ✅ Automatic workspace change detection
- ✅ Click-to-switch workspace functionality
- ✅ HyDE-inspired dark theme with subtle transparency

#### Status:
- ✅ MonoLisa font installed globally
- ✅ SketchyBar installed and configured
- ✅ Menu bar workspace indicators working

---

### 4. Keyboard & Input Customization
**Goal**: Efficient keyboard-driven workflow

#### Keyboard Layout:
- **Current**: US International PC layout
- **Reason**: Preferred for international characters and programming

#### Key Remapping:
- **Caps Lock ↔ Escape**: Swap for better vim/terminal workflow
- **Tool**: Karabiner-Elements (industry standard, open source)

#### Requirements:
- [x] Escape/Caps Lock swap
- [ ] Advanced keyboard remapping
- [ ] Custom shortcuts for all actions
- [ ] Application-specific keybindings
- [x] Vim-like navigation system-wide (kindavim installed)

#### Tools:
```bash
# Advanced keyboard customization
brew install --cask karabiner-elements
```

#### Custom Shortcuts Needed:
- Window management (Cmd+hjkl)
- Workspace switching (Cmd+1-9)
- Application launching
- System controls

#### Setup Instructions for US International Keyboard:

**Adding US International Layout:**
1. Open System Settings → Keyboard → Text Input → Input Sources
2. Click "+" to add new keyboard
3. Select "English" → "U.S. International - PC"
4. Enable "Show input menu in menu bar" checkbox

**Activating the Layout (Command Line Method):**
```bash
# Add US International layout via terminal
defaults write ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources -array-add '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout Name</key><string>USInternational-PC</string></dict>'

# Refresh the system to apply changes
killall Dock
```

**Using US International Layout:**
- **Switch layouts**: Use menu bar icon or Ctrl+Space
- **Accents**: Type `'a` for `á`, `` `a `` for `à`, `~n` for `ñ`, etc.
- **Special chars**: `"u` for `ü`, `'c` for `ç`
- **French/Portuguese**: Perfect for café, São Paulo, français, etc.

#### Vim Navigation System-wide: kindavim

**Installed:** 2025-09-08

**What it does:**
- Brings vim motions to all macOS applications
- Use hjkl navigation, word jumping (w/b), and other vim commands everywhere
- Toggle between Normal and Insert modes via menu bar icon

**Installation:**
```bash
brew install --cask kindavim
```

**Configuration:**
1. Grant accessibility permissions (System Settings → Privacy & Security → Accessibility)
2. Click menu bar icon to toggle modes
3. Configure ignored apps in Preferences:
   - Drag apps from `/Applications` to ignore list
   - Common apps to ignore: Warp, Terminal (if using vim/neovim), IDEs with vim plugins

**Usage:**
- Menu bar icon shows current mode
- Click to toggle between vim mode and normal typing
- Works in any text field across macOS

#### Status:
- ✅ Keyboard layout set to US International PC
- ✅ Menu bar input source enabled
- ✅ Command line activation method documented
- ✅ Karabiner-Elements installed
- ✅ Escape/Caps Lock swapped
- ✅ kindavim installed for system-wide vim navigation
- ⏳ Advanced customization not started

---

### 5. Application Management
**Goal**: Quick app launching and switching

#### Requirements:
- [x] Fast application launcher
- [ ] App switching with keyboard
- [ ] Window switching within apps
- [x] Search functionality

#### Options:
- **Raycast** ✅ (Installed - Alfred alternative, free tier)
- **Alfred** (paid, very powerful)
- Built-in Spotlight (basic but functional)

#### Status:
- ✅ Raycast installed and configured

---

### 6. Development Environment
**Goal**: Efficient coding setup

#### Requirements:
- [x] Version control integration
- [ ] Multiple terminal sessions
- [ ] Code editor integration
- [ ] Project management

#### Tools Installed:
- **Git**: Version control system
- **GitHub CLI (gh)**: GitHub integration from terminal

#### Configuration:
✅ **Git configured with custom .gitconfig including:**
- User: A-PachecoT (andre.pacheco.t@uni.pe)
- Default branch: main
- Editor: vim
- Merge/diff tool: vimdiff
- Auto setup remote on push
- Pull with rebase by default
- Custom aliases (st, ci, co, aa, pr, amend, etc.)

```bash
# GitHub authentication
gh auth login
```

#### Essential Git Commands:
```bash
# Repository basics
git init                    # Initialize new repo
git clone <url>             # Clone remote repo
git status                  # Check working tree status
git add .                   # Stage all changes
git commit -m "message"     # Commit changes
git push                    # Push to remote
git pull                    # Pull from remote

# Branching
git branch <name>           # Create branch
git checkout <branch>       # Switch branch
git checkout -b <branch>    # Create and switch
git merge <branch>          # Merge branch

# GitHub CLI
gh repo create              # Create GitHub repo
gh repo clone <owner/repo>  # Clone GitHub repo
gh pr create                # Create pull request
gh pr list                  # List pull requests
gh issue create             # Create issue
gh issue list              # List issues
```

#### Additional Tools to Install:
```bash
# Terminal multiplexer
brew install tmux

# Git enhancements
brew install git-delta          # Better git diff
brew install lazygit            # TUI for git

# Development utilities
brew install mas                # Mac App Store CLI
```

#### Status:
- ✅ Git and GitHub CLI installed
- ✅ Basic configuration documented
- ⏳ Git enhancements not installed

---

### 7. System Monitoring & Maintenance
**Goal**: Keep system running smoothly

#### Requirements:
- [ ] Resource monitoring
- [ ] Network monitoring
- [ ] Disk usage tracking
- [ ] Process management

#### Tools:
```bash
# Monitoring
brew install --cask lulu         # Network monitor/firewall
brew install bottom             # Resource monitor
```

#### Status:
- ⏳ Not started

---

## Priority Order

### Phase 1: Core Functionality
1. ✅ Window Management (AeroSpace installed, config pending)
2. Terminal Enhancement (starship + CLI tools)
3. ✅ Basic keyboard customization (kindavim + Karabiner)

### Phase 2: Polish & Efficiency
4. Menu bar organization
5. Application launcher
6. Advanced keybindings

### Phase 3: Fine-tuning
7. System monitoring
8. Visual customization
9. Automation scripts

---

## Next Steps

### Immediate Actions:
1. Configure AeroSpace with Hyprland-like keybindings
2. Install and configure Starship prompt
3. Install enhanced CLI tools
4. Create additional macOS Spaces/Desktops
5. Test kindavim with different applications

### Research Needed:
- AeroSpace advanced configuration options
- Raycast vs Alfred for app launching
- Integration between AeroSpace and kindavim

---

## Troubleshooting & Solutions

### Display Scaling for 4K Monitors
**Problem**: 4K monitor (3840x2160) displaying everything too small with no apparent scaling option in System Settings.

**Solution**: Use `displayplacer` to enable HiDPI scaling:

```bash
# Install displayplacer
brew install displayplacer

# List available display modes and current configuration
displayplacer list

# Apply scaled resolution (example for 2560x1440 with scaling)
displayplacer "id:[MACBOOK_ID] res:1512x982 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" \
             "id:[MONITOR_ID] res:2560x1440 hz:60 color_depth:8 enabled:true scaling:on origin:(-2560,-49) degree:0"
```

**Key Points**:
- Look for modes with `scaling:on` in the list
- Common scaled resolutions: 2560x1440, 1920x1080, 3200x1800 (all with scaling:on)
- The `scaling:on` flag enables HiDPI/Retina quality while making UI elements larger
- Monitor ID and available modes can be found using `displayplacer list`

## Notes
- Coming from Arch Linux, expect different philosophy (enhance vs replace)
- macOS has good defaults, focus on augmenting rather than completely replacing
- Some features (like true tiling) require accessibility permissions
- Keep security in mind with system-level modifications

---

### 8. Docker Desktop (Terminal-Focused Setup)
**Goal**: Docker daemon running without GUI interference

#### Installation:
```bash
# Install Docker Desktop via Homebrew
brew install --cask docker

# If sudo required for symlinks:
sudo brew install --cask docker
```

#### Configuration for Terminal-Only Usage:

##### Auto-start minimized (no GUI window):
```bash
# Configure Docker to auto-start without opening GUI
defaults write com.docker.docker autoStart -bool true
defaults write com.docker.docker hideWindowOnLaunch -bool true
```

##### Create LaunchAgent for automatic startup:
```bash
# Create the plist file
cat > ~/Library/LaunchAgents/com.docker.autostart.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.docker.autostart</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>Docker</string>
        <string>--hide</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LaunchOnlyOnce</key>
    <true/>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.docker.autostart.plist
```

##### Start Docker initially:
```bash
open -a Docker
```

#### Result:
- ✅ Docker daemon runs automatically on login
- ✅ No GUI window opens (only menu bar icon)
- ✅ Full `docker` CLI access in terminal
- ✅ Works with docker-compose, Tilt, Kubernetes, etc.

#### Verify Installation:
```bash
docker version
docker ps
docker run hello-world
```

#### Alternative: Colima (Pure CLI Docker)
If you want completely GUI-free Docker without any menu bar icon:
```bash
# Install Colima and Docker CLI tools
brew install colima docker docker-compose

# Start Colima with custom resources
colima start --cpu 4 --memory 8

# Set Docker context to use Colima
docker context use colima
```

#### Status:
- ✅ Docker Desktop installed via Homebrew
- ✅ Configured to auto-start minimized
- ✅ LaunchAgent created for boot startup
- ✅ Terminal-only workflow enabled

---

### 9. Audio Device Management
**Goal**: Automatic audio device prioritization with menu bar control

#### Requirements:
- [x] Auto-switch to WH-1000XM4 when available (output only)
- [x] Fallback to Fifine speaker, then MacBook speakers
- [x] Always use Fifine mic when available
- [x] Never use WH-1000XM4 microphone
- [x] Menu bar control via Background Music

#### Implementation:
**Tools:**
- Background Music (menu bar control and per-app volume)
- switchaudio-osx (CLI device switching)
- Custom priority script with LaunchAgent

**Installation:**
```bash
brew install --cask background-music
brew install switchaudio-osx
```

**Script Location:** `~/dotfiles/scripts/audio-priority.sh`
- Checks every 10 seconds for device changes
- Automatically applies priority rules
- Logs to `/tmp/audio-priority.log`

**LaunchAgent:** `~/Library/LaunchAgents/com.audio.priority.plist`
- Auto-starts on login
- Runs priority script continuously

**Manual Control:**
```bash
# Run priority script manually
~/dotfiles/scripts/audio-priority.sh

# Stop automatic switching
launchctl unload ~/Library/LaunchAgents/com.audio.priority.plist

# Restart automatic switching
launchctl load ~/Library/LaunchAgents/com.audio.priority.plist

# Switch to specific device
SwitchAudioSource -s "Device Name"
```

#### Status:
- ✅ Background Music installed with menu bar icon
- ✅ switchaudio-osx installed
- ✅ Priority script created and deployed
- ✅ LaunchAgent configured for auto-start
- ✅ Tested and working

---

*Last updated: 2025-09-10*
