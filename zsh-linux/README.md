# Zsh Linux (HyDE) Configuration Package

## Overview
This package contains **user-customizable** Zsh configurations for HyDE's XDG-compliant Zsh setup. It only includes files that won't conflict with HyDE-managed base configurations.

## What's Included

### Safe to Edit (Included Here)
- `user.zsh` - Personal configurations, aliases, OMZ plugins, startup commands
- `.p10k.zsh` - Powerlevel10k prompt customization
- `conf.d/98-zoxide.zsh` - Zoxide (smart cd) configuration

### NOT Included (HyDE-Managed)
These files are managed by HyDE and should NOT be stowed:
- `.zshenv` - Environment variables loader (managed by HyDE)
- `.zshrc` - Main config that sources user.zsh (managed by HyDE)
- `prompt.zsh` - Prompt loader (managed by HyDE)
- `conf.d/00-hyde.zsh` - HyDE base configuration
- `conf.d/hyde/` - HyDE modules directory
- `completions/` - Auto-generated completions
- `functions/` - HyDE-provided functions

## Structure

```
~/.zshenv               → Loads $ZDOTDIR (HyDE-managed)
~/.config/zsh/
  ├── .zshenv           → HyDE base env vars (HyDE-managed)
  ├── .zshrc            → HyDE main config, sources user.zsh (HyDE-managed)
  ├── user.zsh          → YOUR customizations ✓ (this package)
  ├── .p10k.zsh         → YOUR prompt config ✓ (this package)
  └── conf.d/
      ├── 00-hyde.zsh   → HyDE base (HyDE-managed)
      └── 98-zoxide.zsh → YOUR zoxide config ✓ (this package)
```

## Installation

### Prerequisites
```bash
# Ensure GNU Stow is installed
sudo pacman -S stow
```

### Backup & Install
```bash
# Backup existing user configs
mkdir -p ~/.config/zsh.backup
cp ~/.config/zsh/user.zsh ~/.config/zsh.backup/ 2>/dev/null || true
cp ~/.config/zsh/.p10k.zsh ~/.config/zsh.backup/ 2>/dev/null || true
cp ~/.config/zsh/conf.d/98-zoxide.zsh ~/.config/zsh.backup/ 2>/dev/null || true

# Remove originals
rm ~/.config/zsh/user.zsh
rm ~/.config/zsh/.p10k.zsh
rm ~/.config/zsh/conf.d/98-zoxide.zsh

# Create symlinks
cd ~/dotfiles
stow zsh-linux

# Verify symlinks
ls -la ~/.config/zsh/user.zsh
ls -la ~/.config/zsh/.p10k.zsh

# Reload shell
exec zsh
```

## Customizations Included

### user.zsh
- **Startup**: Pokemon/fastfetch display on shell start
- **OMZ Plugins**: sudo plugin enabled
- **Arduino CLI aliases**: acc, acu, accu, acm, acb, ach
- **HyDE overrides**: Optional flags for plugins/prompt customization

### .p10k.zsh
- **Powerlevel10k prompt**: Your personalized prompt configuration
- **Run `p10k configure`** to regenerate if needed

### conf.d/98-zoxide.zsh
- **Zoxide integration**: Smart directory jumping
- Automatically loaded by HyDE's conf.d system

## Usage

### Making Changes
Edit files in the repository, changes are live immediately:
```bash
# Edit user configurations
vim ~/dotfiles/zsh-linux/.config/zsh/user.zsh

# Edit prompt
p10k configure  # Interactive wizard
# OR manually edit:
vim ~/dotfiles/zsh-linux/.config/zsh/.p10k.zsh

# Reload shell
exec zsh
```

### HyDE Compatibility
This package is designed to work alongside HyDE's Zsh configuration:
- HyDE manages base `.zshrc` which sources your `user.zsh`
- Your customizations in `user.zsh` load after HyDE's base config
- conf.d files load in alphabetical order (98-zoxide loads near the end)

## Troubleshooting

### Prompt not loading
```bash
# Check if p10k is sourced in .zshrc
grep -n "p10k" ~/.config/zsh/.zshrc

# Manually source
source ~/.config/zsh/.p10k.zsh
```

### Zoxide not working
```bash
# Check if zoxide is installed
which zoxide

# Install if missing
sudo pacman -S zoxide
```

### Restore from backup
```bash
# Unstow symlinks
cd ~/dotfiles
stow -D zsh-linux

# Restore originals
cp ~/.config/zsh.backup/* ~/.config/zsh/
```

## Notes
- Only user-customizable files are included
- HyDE framework files are excluded via `.stow-local-ignore`
- Changes are live immediately (symlinks)
- Safe to update HyDE independently
- This uses XDG Base Directory standard (`~/.config/zsh/`)
