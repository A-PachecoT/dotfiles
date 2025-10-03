# Deprecated HyDE Dotfiles - Migration Plan

## Status
This directory contains the archived Linux/WSL dotfiles from before the macOS transition (archived 2025-09-02). These configurations are **deprecated** but preserved for staged migration back to Arch Linux.

## Original Architecture
- **Platform**: Linux/WSL/VM environments
- **Structure**: Traditional symlink-based dotfiles (non-Stow)
- **Focus**: HyDE desktop environment compatibility, Python development, Zsh with Zinit

## Key Features to Migrate

### High Priority
- [ ] **Zsh Configuration** (`.zsh/` modular setup)
  - `aliases.zsh`, `bindings.zsh`, `completion.zsh`
  - `exports.zsh`, `functions.zsh`, `history.zsh`
  - `plugins.zsh`, `wsl.zsh`
- [ ] **Powerlevel10k Theme** (`.p10k.zsh`)
- [ ] **Python Development Environment** (`scripts/setup_python_env.sh`)
  - uv-based base environment
  - Data science libraries
  - Jupyter integration

### Medium Priority
- [ ] **Zsh Custom Python Config** (`.config/zsh/conf.d/99-custom-python.zsh`)
- [ ] **Git Configuration** (compare with current `git/.gitconfig`)
- [ ] **Utility Scripts**
  - `scripts/fix_zsh_history.sh`
  - Platform detection logic from `setup.sh`

### Low Priority
- [ ] **GitHub Actions Workflow** (`.github/workflows/sync-dotfiles.yml`)
  - VM sync automation (may not be needed)
- [ ] **Windows Configs** (`win11_config/`, `.zshrc.windows`)
  - Evaluate relevance for current setup

## Migration Strategy

### Phase 1: Zsh Integration
Convert modular Zsh configs to Stow package:
```
zsh-extended/
  .config/zsh/
    conf.d/
      aliases.zsh
      bindings.zsh
      etc...
  .p10k.zsh
```

### Phase 2: Python Environment
Integrate `setup_python_env.sh` into `scripts/` with Arch Linux adaptations.

### Phase 3: Platform Detection
Update main `install.sh` to detect OS and install platform-specific packages:
- macOS: aerospace, sketchybar, hammerspoon
- Linux: zsh-extended, python-dev, (future: i3/hyprland)

## Current Dotfiles Structure
The new repository uses **GNU Stow** for package management with per-application directories. See main `README.md` and `CLAUDE.md` for architecture details.

## References
- Original README: `README.md` (in this directory)
- Python setup docs: `PYTHON_SETUP.md`
- System migration notes: `SYSTEM_MIGRATION_NOTES.md`

## Notes
- Archive preserved as-is for reference
- Do not modify files in this directory
- Extract and adapt features to new Stow-based structure
- Delete this directory once migration is complete
