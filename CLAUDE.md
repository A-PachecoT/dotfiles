# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
PHILOSOPHY: I'm a POWER user of terminal; Keyboard shortcuts>>mouse

---

## User Persona: Andre Pacheco

### Who I Am
- **Power user** - keyboard shortcuts over mouse, always
- **Multi-company worker** - Cofoundy, Bilio, personal projects
- **AI-assisted developer** - Claude Code is my pair programmer

### My Dev Environment
- macOS (Apple Silicon) with AeroSpace (tiling WM) + SketchyBar
- Ghostty + tmux (terminal multiplexer)
- Neovim + LazyVim (editor), Yazi (file manager)
- Claude Code in every project

### My Mental Model
```
AeroSpace Workspace = Company/Context (Alt+2/3/4 to switch)
└── Ghostty window with tmux session
    └── tmux windows = Projects (Cmd+1-9 to switch)
        └── Dev layout: yazi + console + Claude Code
```

### What I Need (Non-Negotiable)
1. **Persist everything** through OS restarts - no manual reconstruction
2. **Instant actions** - no confirmation prompts, no extra keystrokes
3. **Simple commands** - `tw` to setup project, `ts` to switch context
4. **Clear architecture** - one way to do things, no ambiguity

### Dev Layout (per project window)
```
┌─────────────────┬──────────────┐
│   yazi (files)  │              │
│      80%        │  Claude Code │
├─────────────────┤     40%      │
│   Console 20%   │              │
└─────────────────┴──────────────┘
       60%
```

### What Frustrates Me
- Workflows that break or behave inconsistently
- Having to remember which command does what
- Losing state on restart
- Confirmation dialogs and extra prompts
- Mixing paradigms (sessions vs windows vs tabs)

### Success Criteria
Open laptop → everything restored → `tw .` → coding in 5 seconds.

---

## Current State

**Architecture (Implemented):**
```
Startup (via dev-startup.sh):
├── Workspace 1: Comet (browser)
├── Workspace 2: Ghostty → tmux session "cofoundy"
├── Workspace 3: Ghostty → tmux session "bilio"
├── Workspace 4: Ghostty → tmux session "personal"
├── Workspace 5: Fallback for ad-hoc Ghostty/Cursor
└── Workspace 9: Obsidian + Ghostty → tmux session "notes"

Each session has project windows, restored by tmux-continuum.
AeroSpace routes Ghostty windows by title (session name).
```

**Commands:**
- `tw .` - Setup dev layout in current window (yazi + console + claude)
- `ts cofoundy` - Switch to session
- `tp` - Project picker with fzf → new window with dev layout
- `y` - Launch yazi file manager (exits into browsed directory)
- `Cmd+1-9` - Switch project windows
- `Alt+2/3/4/9` - Switch company workspaces

---

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

## Hardware Setup

### Physical Configuration

**MacBook Pro** (USB-C only)
- Connected to **Hub 1** (USB-C adapter directly on Mac)
  - Hub 2 (desk hub) → contains fixed desk peripherals
    - **fifine Microphone** (USB-A, 100mA) - **⚠️ HAS PHYSICAL VOLUME KNOB**
    - **Logitech PRO Gaming Keyboard** (USB-A)
    - **HDMI connection** for monitor
  - Other USB-C devices can connect directly to Hub 1

**Monitor:**
- **VG27VQ** (DisplayPort connection)

### USB Hub Topology

```
MacBook Pro (USB-C ports)
    ↓
Hub 1 (USB-C adapter on Mac)
    ↓
Hub 2 (desk hub - contains peripherals)
    ├─ fifine Microphone (USB-A)
    ├─ Logitech Keyboard (USB-A)
    └─ HDMI (monitor)
```

**Power Requirements:**
- fifine: 100mA required, 500mA available
- Hub 2 devices: up to 500mA each
- **Important**: Hubs in chain (hub → hub) can cause USB bandwidth/power issues if not powered externally

### Known Hardware Issues & Solutions

**1. fifine Microphone Not Working:**
- ✅ **FIRST CHECK**: Physical volume knob on the fifine device itself (common oversight!)
- Check macOS permissions: System Settings → Privacy & Security → Microphone
- Verify device detection: `system_profiler SPUSBDataType | grep -A 10 "fifine"`
- Reset USB audio driver: `sudo pkill -9 usbaudiod && sudo killall coreaudiod`
- Try different USB port on Mac (left vs right side use different controllers)
- If all else fails: Connect fifine directly to Mac with USB-A to USB-C adapter (bypass hubs)

**2. Microsoft Teams Audio Device Interference:**
- Teams Audio driver can cause buffer overruns on ALL microphones
- Symptoms: `rec WARN coreaudio: coreaudio: unhandled buffer overrun. Data discarded.`
- Solution: Remove corrupted audio preferences and restart Core Audio:
  ```bash
  rm -f ~/Library/Preferences/com.apple.audio.DeviceSettings.plist
  sudo killall coreaudiod
  ```
- Disable in apps: Discord → Settings → Voice & Video → Audio Subsystem: Legacy

**3. Hub Chain Issues:**
- Symptoms: USB devices disconnect randomly, slow data transfer, microphone dropouts
- Cause: Hub 1 → Hub 2 chain without sufficient power
- Solution: Use powered USB hub (with external power adapter) for Hub 2
- Alternative: Reduce number of devices on Hub 2, connect high-bandwidth devices directly to Hub 1

**4. MacBook Pro Microphone (Lid Closed):**
- MacBook Pro internal microphone does NOT work when lid is closed
- This is expected behavior - use fifine or external mic instead

### Hardware Troubleshooting Commands

```bash
# Check all USB devices and their power consumption
system_profiler SPUSBDataType

# Check all audio input devices
hs -c "for i, device in ipairs(hs.audiodevice.allInputDevices()) do print(device:name()) end"

# Check current default input device
hs -c "print(hs.audiodevice.defaultInputDevice():name())"

# Reset audio system completely
rm -f ~/Library/Preferences/com.apple.audio.*.plist
sudo killall coreaudiod
hs -c "hs.reload()"

# Check for USB audio driver issues
ps aux | grep usbaudiod
log show --predicate 'subsystem == "com.apple.audio"' --last 5m
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

### Zellij (Terminal Multiplexer)

Modern terminal multiplexer optimized for Claude Code workflow with vim keybindings.

**Installation:**
```bash
brew install zellij yazi
./install.sh restow  # Symlink zellij config
```

**Quick Start:**
```bash
# Start with dev layout (CC left + Editor right)
zjdev

# Start project session (auto-names from directory)
zjp

# Create named session with layout
zjnew my-project dev

# List/attach sessions
zjl                    # List sessions
zja my-project         # Attach to session
```

**Layouts Available:**
- `dev` - Claude Code (40%) + Editor (60%) + floating yazi
- `project` - 3 tabs: Dev, Terminal, Git
- `fullstack` - 4 tabs: AI, Frontend, Backend, Services
- `default` - Simple single pane

**Key Bindings (Normal Mode):**
| Key | Action |
|-----|--------|
| `Alt+h/j/k/l` | Navigate panes (vim style) |
| `Alt+1-9` | Switch tabs (workspaces) |
| `Alt+n` | New tab |
| `Alt+w` | Close tab |
| `Alt+d` | Split right |
| `Alt+D` | Split down |
| `Alt+x` | Close pane |
| `Alt+z` | Zoom/fullscreen pane |
| `Alt+f` | Toggle floating pane (yazi) |
| `Alt+r` | Resize mode |
| `Alt+s` | Scroll mode |
| `Alt+/` | Search |
| `Ctrl+Alt+d` | Detach session |

**Modes:**
- `Alt+p` → Pane mode (move, swap, rename panes)
- `Alt+r` → Resize mode (h/j/k/l to resize)
- `Alt+s` → Scroll mode (vim-like: j/k/d/u/g/G)
- `Alt+o` → Session mode (detach, session manager)

**Session Persistence:**
Sessions survive terminal close but NOT macOS restart. To restore after restart:
```bash
# Sessions are named, just reattach or recreate
zja my-project                    # Attach if exists
zjnew my-project project          # Create with layout if not
```

**Save/Load Custom Layouts:**
```bash
# Export current layout
zellij action dump-layout > ~/.config/zellij/layouts/custom.kdl

# Load custom layout
zellij --layout custom --session my-session
```

### Ghostty + tmux (Power User Setup) [RECOMMENDED]

Primary workflow for Claude Code development. Ghostty intercepts Cmd keys and sends them to tmux, allowing shortcuts to work even inside Claude Code.

**Architecture:**
```
AeroSpace Workspaces (Alt+2/3/4/9 to switch companies)
├── Workspace 2: Ghostty → tmux session "cofoundy"
├── Workspace 3: Ghostty → tmux session "bilio"
├── Workspace 4: Ghostty → tmux session "personal"
└── Workspace 9: Obsidian + Ghostty → tmux session "notes"

Each session contains project windows (Cmd+1-9 to switch).
tmux-continuum auto-saves/restores everything.
```

**Installation:**
```bash
brew install --cask ghostty
brew install tmux
./install.sh restow
# Then in tmux: Ctrl+b I to install plugins
```

**Project Commands:**
```bash
tw .            # Setup dev layout in current window (most used!)
tw ~/path       # Setup dev layout for specific project
ts cofoundy     # Switch to session (or create if needed)
tp              # Project picker with fzf → new window with dev layout
tm              # Session manager TUI (see below)
```

**Session Manager (`tm` command):**
TUI for monitoring and managing tmux sessions with CPU visibility.
```
┌─ tmux sessions ─────────────────────────────────────────┐
│ > cofoundy     6 wins   ATTACHED   187% CPU  ← uvicorn │
│   bilio        1 win    detached     2% CPU            │
│   per          3 wins   detached     0% CPU            │
├─────────────────────────────────────────────────────────┤
│ Preview: windows + high CPU processes                   │
└─────────────────────────────────────────────────────────┘
 Enter: attach │ Ctrl-k: kill session │ Ctrl-x: kill all detached
```
- Shows all sessions with CPU usage and top process
- Preview pane shows windows and processes using >1% CPU
- **Ctrl-k**: Kill selected session + all child processes (uvicorn, claude, etc.)
- **Ctrl-x**: Kill ALL detached sessions (cleanup orphans)

**Process Cleanup:**
Cmd+x (pane) and Cmd+w (window) now automatically kill child processes, preventing orphaned servers and Claude instances from running in the background.

**Dev Layout (`tw` command):**
```
┌─────────────────────┬────────────────┐
│   yazi (files)      │                │
│       80%           │  Claude Code   │
├─────────────────────┤     (40%)      │
│   Console  20%      │                │
└─────────────────────┴────────────────┘
        (60%)
```

**Ghostty Key Bindings (work inside Claude Code!):**
| Key | Action |
|-----|--------|
| `Cmd+h/j/k/l` | Navigate panes |
| `Cmd+1-9` | Switch tmux windows (projects) |
| `Cmd+c` | New tmux window |
| `Cmd+w` | Close tmux window |
| `Cmd+d` | Split right |
| `Cmd+z` | Zoom pane |
| `Cmd+x` | Close pane |
| `Cmd+r` | Reload tmux config |

**Session Persistence:**
Sessions auto-save every 10 minutes and auto-restore on tmux start (via tmux-continuum plugin). On macOS restart, `dev-startup.sh` opens Ghostty windows that reconnect to saved sessions.

**Daily Workflow:**
```bash
# Boot up → 4 Ghostty windows auto-open in correct workspaces

# In cofoundy workspace (Alt+2):
Cmd+c           # New window
tw .            # Setup dev layout for current project
Cmd+1, Cmd+2    # Switch between project windows

# Switch companies:
Alt+3           # Jump to bilio workspace
Alt+4           # Jump to personal workspace
```

### Yazi (File Manager)

Terminal file manager with vim keybindings. Integrated into dev layout via `tw` command.

**Alias:**
```bash
y               # Launch yazi (exits into browsed directory)
```

**Key Bindings:**
| Key | Action |
|-----|--------|
| `s` | Recursive file search (uses `fd`) |
| `S` | Content search (uses `rg`) |
| `/` | Filter in current directory |
| `h/j/k/l` | Navigate (vim style) |
| `Enter` | Open file in `$EDITOR` (neovim) |
| `o` | Open file with system default |
| `y` | Yank (copy) file |
| `p` | Paste file |
| `d` | Trash file |
| `D` | Permanently delete |
| `a` | Create file |
| `r` | Rename |
| `q` | Quit (shell exits into current directory) |

### Neovim + LazyVim (Editor)

Default editor for terminal workflows. LazyVim provides IDE-like features with inline markdown rendering.

**Installation:**
```bash
brew install neovim node  # node required for some plugins
./install.sh restow       # Symlink nvim config
nvim                      # First launch installs plugins (~30 sec)
```

**Aliases:**
```bash
nv              # nvim
vim             # nvim
vi              # nvim
```

**Integration with Yazi:**
When you press `Enter` on a file in yazi, it opens in neovim (via `$EDITOR`).

**Key Bindings (Space = Leader):**
| Key | Action |
|-----|--------|
| `Space` | Show which-key menu (all commands) |
| `Space mr` | Toggle markdown rendering |
| `Space e` | File explorer (neo-tree) |
| `Space ff` | Find files (telescope) |
| `Space fg` | Live grep |
| `Space /` | Search in buffer |
| `Space w` | Save file |
| `Space q` | Quit |
| `Ctrl+h/j/k/l` | Navigate windows |
| `Ctrl+d/u` | Scroll down/up (centered) |

**Markdown Rendering:**
Markdown files render inline with:
- Colored headers with icons (󰲡 󰲣 󰲥)
- Styled code blocks with borders
- Bullet icons (● ○ ◆ ◇)
- Checkboxes (󰄱 unchecked, 󰱒 checked)
- Tables with borders
- GitHub-style callouts (`[!NOTE]`, `[!TIP]`, `[!WARNING]`)

Toggle rendering: `Space mr`

**Plugin Management:**
```bash
# In neovim
:Lazy              # Open plugin manager
:Lazy sync         # Update all plugins
:Lazy clean        # Remove unused plugins
:Lazy health       # Check plugin status
```

**Config Location:**
- `nvim/.config/nvim/lua/config/options.lua` - Editor settings
- `nvim/.config/nvim/lua/config/keymaps.lua` - Custom keybindings
- `nvim/.config/nvim/lua/plugins/init.lua` - Plugin configuration

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
- `zellij/.config/zellij/` → `~/.config/zellij/`
- `ghostty/.config/ghostty/` → `~/.config/ghostty/`
- `nvim/.config/nvim/` → `~/.config/nvim/`
- `tmux/.tmux.conf` → `~/.tmux.conf`
- `git/.gitconfig` → `~/.gitconfig`

## Deprecated Packages

- **skhd/**: DEPRECATED - App launch shortcuts now handled directly by AeroSpace for better integration and consistency across empty/occupied workspaces. The skhd service has been disabled from startup (LaunchAgent renamed to `.disabled`).
- **yabai/**: NOT IN USE - AeroSpace has replaced yabai as the window manager. The yabai service has been disabled from startup (LaunchAgent renamed to `.disabled`).

## Deprecated Projects (deprecated/)

Projects in `deprecated/` are archived experiments that didn't reach production due to technical limitations or alternative solutions being superior.

### TuneUp (Audio Profile Manager)
**Status:** DEPRECATED (22 Oct 2024)
**Reason:** macOS security restrictions prevent system-wide audio processing without Audio Unit extensions

**What it was:** An attempt to create a system-wide audio equalizer with profile management (Normal, Bass Boosted, etc.) integrated with HammerSpoon and SketchyBar.

**What was completed:**
- ✅ Profile management system with SketchyBar widget
- ✅ HammerSpoon integration with hotkey (`Cmd+Alt+E`)
- ✅ Persistence and state management
- ✅ Swift AVAudioEngine implementation (10-band EQ)

**Why it failed:**
- ❌ AVAudioEngine cannot process system audio (only app-generated audio)
- ❌ Real system-wide EQ requires Audio Unit v3 extension (weeks of work + $99/year Apple Developer account)
- ❌ Alternative integration with eqMac blocked (no API, buggy, security concerns)

**Lesson learned:** Always research macOS sandboxing and security limitations BEFORE implementing audio/system-level features. Use existing solutions (eqMac, SoundSource) rather than reinventing the wheel.

**Full documentation:** `deprecated/TuneUp/DEPRECATED.md`

## Startup Configuration

### AeroSpace-Managed Startup (aerospace/.aerospace.toml)

These apps launch automatically via `after-startup-command` and move to assigned workspaces:

```toml
after-startup-command = [
    'exec-and-forget sketchybar',
    'exec-and-forget open -a "Obsidian"',                           # → workspace 9
    'exec-and-forget open -a "Comet"',                              # → workspace 1
    'exec-and-forget /Users/styreep/dotfiles/scripts/dev-startup.sh' # → workspaces 2,3,4,9
]
```

**dev-startup.sh** launches 4 Ghostty windows with named tmux sessions:
- `cofoundy` → workspace 2
- `bilio` → workspace 3
- `personal` → workspace 4
- `notes` → workspace 9 (alongside Obsidian)

AeroSpace routes each Ghostty window by matching the tmux session name in the window title.

**Browser Configuration:**
- **Comet browser** is configured as the primary browser (workspace 1, `alt-q` hotkey)
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
