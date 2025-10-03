# Dotfiles Architecture Proposal

## Overview
This document proposes a new architecture for the dotfiles repository that maintains cross-platform compatibility while addressing the issues identified in SYSTEM_MIGRATION_NOTES.md.

## Design Principles
1. **Platform Priority**: Linux (Arch > Ubuntu) > macOS > Windows/WSL
2. **Modularity**: Each platform/component is independent
3. **Documentation**: Every configuration has clear documentation
4. **Synchronization**: Changes in repo reflect in OS via install.sh
5. **Safety**: No destructive operations without user confirmation

## Proposed Directory Structure

```
dotfiles/
├── install.sh              # Main installer with OS detection
├── sync.sh                 # Sync changes from repo to system
├── README.md               # Main documentation
├── docs/                   # Detailed documentation
│   ├── ARCHITECTURE.md     # This file
│   ├── PYTHON_SETUP.md     # Python environment docs
│   ├── SHELL_SETUP.md      # Shell configuration docs
│   └── PLATFORM_GUIDES/    # Platform-specific guides
│       ├── ARCH_LINUX.md
│       ├── UBUNTU.md
│       ├── MACOS.md
│       └── WINDOWS_WSL.md
├── common/                 # Cross-platform configurations
│   ├── shell/
│   │   ├── aliases.zsh     # Common aliases
│   │   ├── exports.zsh     # Common exports
│   │   └── functions.zsh   # Common functions
│   ├── git/
│   │   └── .gitconfig
│   └── editors/
│       ├── vscode/
│       └── nvim/
├── platform/               # Platform-specific configs
│   ├── linux/
│   │   ├── arch/
│   │   │   ├── packages.txt     # Arch packages to install
│   │   │   ├── aur.txt          # AUR packages
│   │   │   └── setup.sh         # Arch-specific setup
│   │   ├── ubuntu/
│   │   │   ├── packages.txt     # APT packages
│   │   │   └── setup.sh         # Ubuntu-specific setup
│   │   └── common/              # Common Linux configs
│   │       ├── .Xresources
│   │       └── systemd/
│   ├── macos/
│   │   ├── packages.txt         # Homebrew packages
│   │   ├── setup.sh             # macOS-specific setup
│   │   └── defaults.sh          # macOS defaults
│   └── windows/
│       ├── wsl/
│       │   └── setup.sh         # WSL-specific setup
│       └── native/
│           └── setup.ps1        # PowerShell setup
├── home/                   # Files that go directly to $HOME
│   ├── .zshrc             # Main zsh config (sources modular configs)
│   ├── .bashrc            # Bash config (minimal, just exec zsh)
│   └── .config/           # XDG config directory structure
│       └── zsh/
│           └── conf.d/    # Modular zsh configs
└── scripts/               # Utility scripts
    ├── backup.sh          # Backup current configs
    ├── test.sh            # Test installations
    └── utils/             # Shared utility functions
```

## Implementation Plan

### Phase 1: Structure Creation
1. Create new directory structure
2. Move existing files to appropriate locations
3. Update all path references

### Phase 2: Modular Installation
1. Rewrite install.sh with proper OS detection
2. Create platform-specific setup scripts
3. Implement safe shell switching (no .bashrc exec)

### Phase 3: Synchronization
1. Create sync.sh for updating system from repo
2. Add file watchers for automatic sync (optional)
3. Implement rollback mechanism

### Phase 4: Documentation
1. Document each subsystem configuration
2. Create platform-specific guides
3. Add troubleshooting section

## Key Changes from Current System

### 1. Shell Management
- Remove dangerous `exec zsh` from .bashrc
- Use proper `chsh` with user confirmation
- Keep minimal .bashrc for compatibility

### 2. Package Management
```bash
# Platform detection in install.sh
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v pacman &> /dev/null; then
            echo "arch"
        elif command -v apt-get &> /dev/null; then
            echo "ubuntu"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    fi
}
```

### 3. Configuration Loading
```bash
# .zshrc will source configs in this order:
1. Common configurations
2. Platform-specific configurations
3. Local overrides (not in git)
```

### 4. HyDE Integration (Arch Linux)
- Detect HyDE installation
- Load HyDE configs first
- Apply our customizations on top
- Never override HyDE core functionality

## Benefits
1. **Maintainable**: Clear separation of concerns
2. **Safe**: No destructive operations
3. **Flexible**: Easy to add new platforms
4. **Documented**: Everything is clearly explained
5. **Testable**: Can test each component independently

## Migration Strategy
1. Backup current working configuration
2. Create new structure alongside old
3. Test new structure in isolated environment
4. Gradually migrate configurations
5. Update documentation as we go

## Next Steps
1. Review and approve this proposal
2. Create directory structure
3. Begin migration with lowest-risk components
4. Test on fresh Arch Linux installation
5. Expand to other platforms