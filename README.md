# Dotfiles Setup Guide

This repository contains configuration files for Git, Zsh (with Zinit), and terminal customization with support for Linux, WSL, and VM environments.

## Installation Methods

### 1. Local Installation
```bash
git clone https://github.com/A-PachecoT/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

### 2. VM Installation

#### A. Manual VM Setup
```bash
# 1. Clone repository
git clone https://github.com/A-PachecoT/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Run setup with safety checks
./setup.sh --clean  # Clean installation recommended for VMs
```

#### B. Automated VM Sync (Using GitHub Actions)
1. **Setup GitHub Secrets**:
   ```bash
   # Generate SSH key pair on your local machine
   ssh-keygen -t rsa -b 4096 -C "github-actions"
   
   # Add these secrets to your GitHub repository:
   - SSH_PRIVATE_KEY: Your private key content
   - KNOWN_HOSTS: Output of `ssh-keyscan your-vm-host`
   - REMOTE_USER: VM username
   - REMOTE_HOST: VM hostname/IP
   ```

2. **Configure VM**:
   ```bash
   # On your VM
   mkdir -p ~/.dotfiles
   cd ~/.dotfiles
   
   # Add public key to authorized_keys
   echo "your-public-key" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   
   # Initial setup
   git clone <your-repo-url> .
   chmod +x sync.sh
   ./sync.sh
   ```

3. **Automatic Updates**:
   - Push changes to main branch
   - GitHub Actions will automatically sync to VM
   - Weekly sync runs every Sunday at midnight

## Directory Structure
```
.
├── .github/
│   └── workflows/
│       └── sync-dotfiles.yml    # GitHub Actions workflow
├── .zsh/
│   ├── aliases.zsh             # Shell aliases
│   ├── bindings.zsh           # Key bindings
│   ├── completion.zsh         # Completion settings
│   ├── exports.zsh           # Environment variables
│   ├── functions.zsh         # Custom functions
│   ├── history.zsh          # History settings
│   ├── plugins.zsh         # Plugin configurations
│   └── wsl.zsh            # WSL-specific settings
├── setup.sh               # First-time installation
├── sync.sh               # Dotfiles sync
├── .gitconfig           # Git configuration
├── .zshrc              # Main Zsh configuration
└── .p10k.zsh          # Powerlevel10k theme
```

## VM-Specific Features

### Safety Measures
- Remote session detection
- Backup shell fallback
- Permission checks
- Automatic backups
- Force flag for CI/CD

### Sync Options
```bash
# Force sync (useful for CI/CD)
./sync.sh --force

# Save p10k changes
./sync.sh --save-p10k

# Clean installation
./setup.sh --clean
```

### Backup System
- Location: `~/.dotfiles_backups/YYYYMMDD_HHMMSS/`
- Latest symlink: `~/.dotfiles_backups/latest`
- Includes all configuration files
- Automatic backup before changes

## Troubleshooting VM Installation

### Common Issues
1. **SSH Connection**:
   ```bash
   # Test SSH connection
   ssh -i path/to/key REMOTE_USER@REMOTE_HOST
   ```

2. **Permission Issues**:
   ```bash
   # Fix permissions
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

3. **GitHub Actions**:
   - Check Actions tab for logs
   - Verify secrets are set correctly
   - Test manual workflow dispatch

### Recovery Options
```bash
# Restore from latest backup
cp -r ~/.dotfiles_backups/latest/* ~/

# Force clean installation
./setup.sh --clean

# Manual sync
./sync.sh --force
```

## Maintenance

### Regular Updates
```bash
# Pull latest changes
cd ~/.dotfiles
git pull

# Sync configurations
./sync.sh
```

### CI/CD Pipeline
- Automatic sync on push to main
- Weekly sync for updates
- Manual trigger available
- Backup creation on sync

## Security Notes

### VM Considerations
- Uses SSH key authentication
- Separate keys for GitHub Actions
- Limited sudo usage
- User-level configurations only
- Automatic backup system

### Best Practices
1. Use separate SSH keys for different VMs
2. Regular backup verification
3. Test changes locally before push
4. Monitor GitHub Actions logs
5. Keep SSH keys secure

## Contributing
Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request