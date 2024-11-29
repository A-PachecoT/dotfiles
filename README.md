# Dotfiles Setup Guide

This repository contains configuration files for Git, Zsh (with Zinit), and terminal customization with support for both standard Linux and WSL environments.

## Overview

This repository uses two scripts:
- `setup.sh`: First-time installation script that sets up the complete environment
- `sync.sh`: Lightweight script for syncing and maintaining dotfiles

## Prerequisites

- Git
- Internet connection
- Writable home directory
- Basic packages (will be installed by setup.sh if missing):
  - zsh
  - curl
  - vim/neovim
  - python3
  - fzf
  - fonts-powerline

## Installation

### First-Time Setup
```bash
# Clone the repository
git clone <repository-url> ~/.dotfiles
cd ~/.dotfiles

# Run the setup script
./setup.sh
```

### Setup Script Options
```bash
./setup.sh [-c|--clean] [-h|--help]
  -c, --clean    Clean install (removes existing configurations)
  -h, --help     Show this help message
```

### Syncing Dotfiles
```bash
./sync.sh [-f|--force] [--save-p10k] [-h|--help]
  -f, --force    Force sync without backup
  --save-p10k    Save current p10k configuration to dotfiles
  -h, --help     Show this help message
```

## Features

### Shell Features
- Powerlevel10k theme
- Syntax highlighting
- Auto-suggestions
- FZF integration
- Command history search
- Custom key bindings
- Directory navigation with zoxide

### Safety Features
- Automatic backup of existing configurations
- Remote session detection
- Permission checks
- Sudo access detection
- Installation verification

### Git Integration
- Custom Git configuration
- Useful Git aliases
- Global Git settings

## Directory Structure
```
.
├── setup.sh           # First-time installation script
├── sync.sh           # Dotfiles sync script
├── .gitconfig        # Git configuration
├── .zshrc           # Zsh configuration
└── .p10k.zsh        # Powerlevel10k configuration
```

## Backup System

The sync script automatically backs up your existing configurations before making changes:
- Backups are stored in `~/.dotfiles_backups/YYYYMMDD_HHMMSS/`
- Each backup includes `.zshrc`, `.gitconfig`, and `.p10k.zsh`
- A `latest` symlink points to the most recent backup
- Use the `-f` flag to skip backup creation

## Post-Installation

1. Log out and log back in for changes to take effect
2. Run `p10k configure` to set up your Powerlevel10k theme
3. Verify your backup files in `~/.dotfiles_backups/`

## Customization

You can customize your setup by:
1. Editing `.zshrc` for shell settings
2. Modifying `.gitconfig` for Git configurations
3. Running `sync.sh --save-p10k` after modifying p10k settings

## Troubleshooting

### Common Issues
1. **Font Issues**
   - Fonts are installed in `~/.local/share/fonts`
   - Run `fc-cache -f -v` to rebuild font cache

2. **Permission Issues**
   - Script will warn about limited permissions
   - Some features may be restricted without sudo
   - All user-level configurations will still work

### Getting Help
- Check the backup directory for original configs
- Review script output for error messages
- Restore from backups in `~/.dotfiles_backups/`

## Maintenance

### Regular Updates
Syncs the dotfiles repository with the latest changes from the remote repository
```bash
cd ~/.dotfiles
git pull
./sync.sh
```

### Saving P10k Changes
Saves the current p10k configuration to the dotfiles repository
```bash
./sync.sh --save-p10k
```

### Forced Update
Forces an update without creating a backup
```bash
./sync.sh --force
```

## Security Notes

- Scripts run with user permissions by default
- Sudo is only used for package installation (setup.sh only)
- No system-wide changes without explicit permission
- All configurations are user-specific
- Automatic backups before changes

## Contributing

Feel free to submit issues and enhancement requests!