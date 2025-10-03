# System Configuration Reference

## Shell Setup
- **Shell**: Zsh (`/usr/bin/zsh`)
- **Framework**: Oh My Zsh (installed at `~/.oh-my-zsh`)
- **Theme**: Powerlevel10k (config at `~/.p10k.zsh`)

## Configuration File Locations

```
~/.zshenv                    # Points to ~/.config/zsh/
├── Sets ZDOTDIR to ~/.config/zsh/
└── Sources ~/.config/zsh/.zshenv

~/.config/zsh/               # Main zsh config directory
├── .zshenv                  # Environment variables
├── .zshrc                   # Main zsh configuration
└── (other zsh configs)

~/.user.zsh                  # USER CUSTOMIZATIONS
├── Startup commands (pokego/fastfetch)
├── Aliases (commented out)
└── Plugins list (sudo, direnv)

~/.p10k.zsh                  # Powerlevel10k theme config
└── (symlinked to ~/dotfiles/.p10k.zsh)
```

## Key Points
1. **No ~/.zshrc** in home directory - it's in `~/.config/zsh/.zshrc`
2. **Customizations** go in `~/.user.zsh` (plugins, aliases, startup)
3. **Oh My Zsh plugins** are defined in `~/.user.zsh`, not `.zshrc`
4. **Dotfiles** are symlinked from `~/dotfiles/`

## Installed Tools
- **direnv**: `/home/andre/.bun/bin/direnv` (Oh My Zsh plugin configured)
- **uv**: Python package manager (use `uv run` for Python projects)
- **ruff**: Python linter/formatter (available system-wide)

## Quick Commands
- Add Oh My Zsh plugin: Edit `~/.user.zsh` plugins section
- Add alias: Edit `~/.user.zsh` aliases section
- Reload shell config: `source ~/.user.zsh && source ~/.config/zsh/.zshrc`