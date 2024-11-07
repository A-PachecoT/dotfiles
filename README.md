# Dotfiles Setup Guide

This repository contains configuration files for Git, Zsh (with Zinit), and terminal customization for both Ubuntu and Windows/WSL environments.

## ⚠️ Important Safety Notes

### For Remote VMs/SSH Sessions
- The script includes safety measures for remote sessions
- Original shell (bash) is preserved as backup
- Multiple recovery methods are available
- All changes are confined to your home directory
- Configurations are automatically backed up

### Emergency Recovery
If anything goes wrong:
```bash
# Method 1: Use the built-in function
switch_to_backup_shell

# Method 2: Direct shell execution
exec /bin/bash

# Method 3: SSH back in (will use original shell)
```

Your original configurations are backed up to: `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`

## Prerequisites

### Ubuntu/Remote VM
- Git
- Internet connection
- Writable home directory
- Basic packages (will be installed if missing):
  - zsh
  - curl
  - vim/neovim
  - python3
  - fzf
  - fonts-powerline

### Windows/WSL
- Windows Terminal
- WSL2 with Ubuntu
- Git for Windows
- Meslo Nerd Font (automatically installed)

## Installation

### Safe Installation (Recommended for Remote/VM)
```bash
# Clone the repository
git clone <repository-url> ~/.dotfiles
cd ~/.dotfiles

# Regular installation (preserves existing configs)
./setup.sh

# After confirming everything works:
./setup.sh --clean  # Optional: for clean installation
```

### Command Line Options
```bash
./setup.sh [-c|--clean] [-h|--help]
  -c, --clean    Clean install (removes existing configurations)
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
- Backup shell preservation
- Remote session detection
- Permission checks
- Sudo access detection
- Installation verification
- Recovery functions

### Git Integration
- Custom Git configuration
- Useful Git aliases
- Global Git settings

## Directory Structure
```
.
├── setup.sh           # Installation script
├── .gitconfig         # Git configuration
├── .zshrc            # Zsh configuration for Ubuntu
└── .zshrc.windows    # Zsh configuration for WSL
```

## Post-Installation

1. Log out and log back in for changes to take effect
2. Run `p10k configure` to set up your Powerlevel10k theme
3. Test the shell switch function: `switch_to_backup_shell`
4. Verify your backup files in `~/.dotfiles_backup_*`

## Customization

You can customize your setup by:
1. Editing `.zshrc` for shell settings
2. Modifying `.gitconfig` for Git configurations
3. Adding custom aliases and functions

## Troubleshooting

### Common Issues
1. **Shell Change Failed**
   - Your original shell is preserved
   - Use `switch_to_backup_shell` to revert
   - Check `chsh` permissions

2. **Font Issues**
   - Fonts are installed in `~/.local/share/fonts`
   - Run `fc-cache -f -v` to rebuild font cache

3. **Permission Issues**
   - Script will warn about limited permissions
   - Some features may be restricted without sudo
   - All user-level configurations will still work

### Getting Help
- Check the backup directory for original configs
- Use the emergency recovery methods
- Review script output for error messages

## Maintenance

### Updating
```bash
cd ~/.dotfiles
git pull
./setup.sh
```

### Uninstalling
```bash
# Switch back to original shell
switch_to_backup_shell

# Restore backups
cp -r ~/.dotfiles_backup_<timestamp>/* ~/
```

## Security Notes

- Script runs with user permissions by default
- Sudo is only used for package installation
- No system-wide changes without explicit permission
- All configurations are user-specific
- Backup shell is always preserved

## Contributing

Feel free to submit issues and enhancement requests!

## License

[Your License Here]